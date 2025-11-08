import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';

enum AnalysisType {
  ai,
  heuristic,
}

class EmotionResult {
  final String emotion; // happiness|sadness|anxiety|anger|neutral
  final double score; // 0..1
  final int severity; // 0..100
  final String advice; // breve consejo (es)
  final AnalysisType type;

  EmotionResult({
    required this.emotion,
    required this.score,
    required this.severity,
    required this.advice,
    this.type = AnalysisType.ai,
  });

  bool get isAiGenerated => type == AnalysisType.ai;

  bool get isCrisis => severity >= AppConstants.crisisSeverityThreshold;
}

// Internal topic rule loaded from DB
class _TopicRule {
  final String pattern;
  final String kind; // 'emotion' | 'crisis'
  final String matchType; // 'contains' | 'regex'

  _TopicRule({
    required this.pattern,
    required this.kind,
    required this.matchType,
  });

  bool matches(String text) {
    final t = text.toLowerCase();
    final p = pattern.toLowerCase();

    switch (matchType) {
      case 'regex':
        return RegExp(p).hasMatch(t);
      case 'contains':
      default:
        return t.contains(p);
    }
  }

  bool get isEmotion => kind == 'emotion';
  bool get isCrisis => kind == 'crisis';
}

class GeminiService {
  static final _fallbackModels = <String>[
    if (Env.geminiModel.isNotEmpty) Env.geminiModel,
    ...AppConstants.geminiModelFallbacks,
  ];

  final SupabaseClient _supabase = Supabase.instance.client;

  GenerativeModel? _jsonModel;
  GenerativeModel? _chatModel;
  String? _activeModelName;
  bool _ready = false;

  // Cached prompts (key -> content)
  final Map<String, String> _prompts = {};
  bool _promptsLoaded = false;

  // Cached topic rules
  final List<_TopicRule> _topicRules = [];
  bool _topicRulesLoaded = false;

  GeminiService() {
    if (Env.geminiApiKey.isEmpty && !Env.offlineMode) {
      AppLogger.error(
        'GEMINI_API_KEY not configured',
        tag: 'GeminiService',
      );
      throw StateError(AppConstants.errorMissingGeminiKey);
    }
  }

  // ---------------- LOAD CONFIG FROM SUPABASE ----------------

  Future<void> _ensurePromptsLoaded() async {
    if (_promptsLoaded) return;
    try {
      final rows =
          await _supabase.from('empathy_prompts').select('key, content');
      for (final row in rows as List<dynamic>) {
        final k = row['key'] as String?;
        final c = row['content'] as String?;
        if (k != null && c != null) {
          _prompts[k] = c;
        }
      }
      AppLogger.info(
        'Prompts loaded from Supabase (${_prompts.length})',
        tag: 'GeminiService',
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load prompts from Supabase: $e',
        tag: 'GeminiService',
      );
      AppLogger.debug('Stacktrace: $stack', tag: 'GeminiService');
    } finally {
      _promptsLoaded = true;
    }
  }

  Future<void> _ensureTopicRulesLoaded() async {
    if (_topicRulesLoaded) return;
    try {
      final rows = await _supabase
          .from('empathy_topic_rules')
          .select('pattern, kind, match_type')
          .eq('active', true);

      for (final row in rows as List<dynamic>) {
        final pattern = row['pattern'] as String?;
        final kind = row['kind'] as String?;
        final matchType = (row['match_type'] as String?) ?? 'contains';

        if (pattern != null &&
            pattern.isNotEmpty &&
            (kind == 'emotion' || kind == 'crisis')) {
          _topicRules.add(
            _TopicRule(
              pattern: pattern,
              kind: kind!,
              matchType: matchType,
            ),
          );
        }
      }

      AppLogger.info(
        'Topic rules loaded from Supabase (${_topicRules.length})',
        tag: 'GeminiService',
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load topic rules from Supabase: $e',
        tag: 'GeminiService',
      );
      AppLogger.debug('Stacktrace: $stack', tag: 'GeminiService');
    } finally {
      _topicRulesLoaded = true;
    }
  }

  String _prompt(String key, String fallback) {
    return _prompts[key] ?? fallback;
  }

  // ---------------- HELPERS ----------------

  Map<String, dynamic>? _tryParseJson(String raw) {
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {}

    final fenced =
        RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', multiLine: true);
    final m = fenced.firstMatch(raw);
    if (m != null) {
      try {
        return json.decode(m.group(1)!);
      } catch (_) {}
    }

    final s = raw.indexOf('{');
    final e = raw.lastIndexOf('}');
    if (s != -1 && e != -1 && e > s) {
      final cut = raw.substring(s, e + 1);
      try {
        return json.decode(cut);
      } catch (_) {}
    }

    return null;
  }

  Future<void> _ensureReady() async {
    if (Env.offlineMode) {
      AppLogger.info('Running in offline mode', tag: 'GeminiService');
      return;
    }

    if (_ready && _jsonModel != null && _chatModel != null) return;

    AppLogger.info('Initializing Gemini models...', tag: 'GeminiService');

    for (final name in _fallbackModels) {
      try {
        final test = GenerativeModel(
          model: name,
          apiKey: Env.geminiApiKey,
          generationConfig: GenerationConfig(
            temperature: AppConstants.emotionAnalysisTemperature,
            responseMimeType: 'application/json',
            maxOutputTokens: AppConstants.emotionAnalysisMaxTokens,
          ),
        );

        final r = await test.generateContent([Content.text('{"ping":"ok"}')]);
        if ((r.text ?? '').isNotEmpty) {
          _jsonModel = test;
          _chatModel = GenerativeModel(
            model: name,
            apiKey: Env.geminiApiKey,
            generationConfig: GenerationConfig(
              temperature: AppConstants.chatTemperature,
              maxOutputTokens: AppConstants.chatMaxTokens,
            ),
          );
          _activeModelName = name;
          _ready = true;

          AppLogger.info(
            'Successfully connected with model: $name',
            tag: 'GeminiService',
          );
          return;
        }
      } catch (e) {
        AppLogger.warning(
          'Model $name failed, trying next: $e',
          tag: 'GeminiService',
        );
      }
    }

    AppLogger.error(
      'All Gemini models failed to initialize',
      tag: 'GeminiService',
    );
    throw StateError(AppConstants.errorNoGeminiModels);
  }

  Future<void> _logInteraction({
    required String kind, // 'analysis' or 'chat'
    required String userText,
    String? responseText,
    EmotionResult? emotion,
  }) async {
    try {
      // Extra guard: never log out-of-scope analysis
      if (kind == 'analysis') {
        final isOutOfScopeByAdvice = responseText != null &&
            responseText.contains(
              'No puedo analizar este mensaje porque no está relacionado con tus emociones o tu bienestar emocional',
            );

        final isOutOfScopeByValues = emotion != null &&
            emotion.emotion == AppConstants.emotionNeutral &&
            emotion.severity == 0 &&
            emotion.score == 0.0;

        if (isOutOfScopeByAdvice || isOutOfScopeByValues) {
          AppLogger.debug(
            'Skipping log for out-of-scope analysis',
            tag: 'GeminiService',
          );
          return;
        }
      }

      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('empathy_logs').insert({
        'user_id': userId,
        'kind': kind,
        'model': _activeModelName,
        'request_text': userText,
        'response_text': responseText,
        'emotion': emotion?.emotion,
        'severity': emotion?.severity,
        'is_crisis': emotion?.isCrisis,
        'is_ai': emotion?.isAiGenerated,
      });
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to log interaction in Supabase: $e',
        tag: 'GeminiService',
      );
      AppLogger.debug('Stacktrace: $stack', tag: 'GeminiService');
    }
  }

  bool _isEmotionalTopicSync(String text) {
    final t = text.toLowerCase();

    // 1) Use DB rules if available
    if (_topicRules.isNotEmpty) {
      final crisisMatch = _topicRules.any((r) => r.isCrisis && r.matches(t));
      if (crisisMatch) return true;

      final emotionMatch = _topicRules.any((r) => r.isEmotion && r.matches(t));
      if (emotionMatch) return true;

      // With rules present and none matching => out-of-scope
      return false;
    }

    // 2) Fallback keywords if no DB rules exist
    const fallbackKeywords = [
      'ansiedad',
      'ansioso',
      'ansiosa',
      'angustia',
      'estres',
      'estrés',
      'miedo',
      'triste',
      'tristeza',
      'deprim',
      'soledad',
      'solo',
      'sola',
      'feliz',
      'alegr',
      'culpa',
      'vergüenza',
      'preocup',
      'ira',
      'enojo',
      'rabia',
      'frustración',
      'autoestima',
      'me siento',
      'no me siento bien',
      'emocion',
      'emociones',
      'llorando',
      'desesperado',
      'desesperada',
      'crisis',
    ];

    for (final kw in fallbackKeywords) {
      if (t.contains(kw)) return true;
    }

    return false;
  }

  EmotionResult _heuristicAnalyze(String text) {
    final t = text.toLowerCase();
    String emotion = AppConstants.emotionNeutral;
    int severity = 30;
    double score = 0.7;

    // Crisis detection via DB rules + fallback
    bool crisisMatch = _topicRules.any((r) => r.isCrisis && r.matches(t));
    if (!crisisMatch && AppConstants.crisisKeywords.isNotEmpty) {
      final crisisPattern = AppConstants.crisisKeywords.join('|');
      crisisMatch = RegExp('($crisisPattern)').hasMatch(t);
    }

    if (crisisMatch) {
      AppLogger.warning(
        'Crisis detected in heuristic analysis',
        tag: 'GeminiService',
      );
      final crisisAdvice = _prompt(
        'chat_offline_crisis',
        'Siento mucho que te sientas así. No estás solo/a. Busca ayuda inmediata llamando a una línea de emergencia o de apoyo emocional en tu país.',
      );
      return EmotionResult(
        emotion: AppConstants.emotionSadness,
        score: 0.9,
        severity: 95,
        advice: '⚠️ (Análisis básico) $crisisAdvice',
        type: AnalysisType.heuristic,
      );
    }

    if (t.contains('ansie') || t.contains('preocup') || t.contains('nervio')) {
      emotion = AppConstants.emotionAnxiety;
      severity = 60;
    } else if (t.contains('triste') ||
        t.contains('deprim') ||
        t.contains('solo') ||
        t.contains('soledad')) {
      emotion = AppConstants.emotionSadness;
      severity = 55;
    } else if (t.contains('enojo') ||
        t.contains('rabia') ||
        t.contains('molest') ||
        t.contains('ira')) {
      emotion = AppConstants.emotionAnger;
      severity = 65;
    } else if (t.contains('feliz') || t.contains('alegr')) {
      emotion = AppConstants.emotionHappiness;
      severity = 20;
    }

    final baseAdvice = _prompt(
      'chat_offline_default',
      'Estoy aquí para escucharte y acompañarte. Cuéntame un poco más sobre cómo te estás sintiendo.',
    );

    return EmotionResult(
      emotion: emotion,
      score: score,
      severity: severity,
      advice: '⚠️ (Análisis básico) $baseAdvice',
      type: AnalysisType.heuristic,
    );
  }

  // ---------------- ANALYZE TEXT ----------------
  // Solo analiza si el texto es emocional.
  // Si NO lo es: mensaje configurable, NO IA, NO logs.

  Future<EmotionResult> analyzeText(String text) async {
    await _ensurePromptsLoaded();
    await _ensureTopicRulesLoaded();

    final isEmotional = _isEmotionalTopicSync(text);

    if (!isEmotional) {
      final msg = _prompt(
        'analysis_out_of_scope',
        'No puedo analizar este mensaje porque no está relacionado con tus emociones o tu bienestar emocional. '
            'Si lo deseas, cuéntame cómo te sientes y te ayudo con eso.',
      );

      return EmotionResult(
        emotion: AppConstants.emotionNeutral,
        score: 0.0,
        severity: 0,
        advice: msg,
        type: AnalysisType.heuristic,
      );
    }

    if (Env.offlineMode) {
      final result = _heuristicAnalyze(text);
      await _logInteraction(
        kind: 'analysis',
        userText: text,
        responseText: json.encode({
          'emotion': result.emotion,
          'score': result.score,
          'severity': result.severity,
          'advice': result.advice,
          'type': result.type.name,
        }),
        emotion: result,
      );
      return result;
    }

    await _ensureReady();

    final baseTemplate = _prompt(
      'emotion_analysis_base',
      'Eres un asistente empático de bienestar mental. Devuelve SOLO JSON válido con '
          '{"emotion":"happiness|sadness|anxiety|anger|neutral","score":0..1,"severity":0..100,"advice":"breve consejo en español"}. '
          'Texto: "{text}"',
    );
    final basePrompt = baseTemplate.replaceAll('{text}', text);

    try {
      final res = await _jsonModel!.generateContent([Content.text(basePrompt)]);
      final raw = (res.text ?? '{}').trim();
      final map = _tryParseJson(raw);
      if (map == null) throw StateError('no-json');

      final result = EmotionResult(
        emotion: (map['emotion'] ?? AppConstants.emotionNeutral) as String,
        score: ((map['score'] ?? 0.0) as num).toDouble(),
        severity: ((map['severity'] ?? 0) as num).toInt(),
        advice: (map['advice'] ?? '') as String,
        type: AnalysisType.ai,
      );

      await _logInteraction(
        kind: 'analysis',
        userText: text,
        responseText: raw,
        emotion: result,
      );

      return result;
    } catch (_) {
      final strictTemplate = _prompt(
        'emotion_analysis_strict',
        'SOLO JSON. {"emotion":"happiness|sadness|anxiety|anger|neutral","score":0..1,'
            '"severity":0..100,"advice":"breve consejo en español"}. Texto: "{text}"',
      );
      final strictPrompt = strictTemplate.replaceAll('{text}', text);

      try {
        final res2 =
            await _jsonModel!.generateContent([Content.text(strictPrompt)]);
        final raw2 = (res2.text ?? '{}').trim();
        final map2 = _tryParseJson(raw2);
        if (map2 == null) throw StateError('no-json-2');

        final result = EmotionResult(
          emotion: (map2['emotion'] ?? AppConstants.emotionNeutral) as String,
          score: ((map2['score'] ?? 0.0) as num).toDouble(),
          severity: ((map2['severity'] ?? 0) as num).toInt(),
          advice: (map2['advice'] ?? '') as String,
          type: AnalysisType.ai,
        );

        await _logInteraction(
          kind: 'analysis',
          userText: text,
          responseText: raw2,
          emotion: result,
        );

        return result;
      } catch (e2, stack2) {
        AppLogger.error(
          'AI analysis failed, using heuristic',
          error: e2,
          stack: stack2,
          tag: 'GeminiService',
        );

        final result = _heuristicAnalyze(text);

        await _logInteraction(
          kind: 'analysis',
          userText: text,
          responseText: json.encode({
            'emotion': result.emotion,
            'score': result.score,
            'severity': result.severity,
            'advice': result.advice,
            'type': result.type.name,
          }),
          emotion: result,
        );

        return result;
      }
    }
  }

  // ---------------- CHAT ONCE ----------------
  // Solo responde si es emocional.
  // Si NO lo es: mensaje out_of_scope (configurable), SÍ se guarda (auditoría).

  Future<String> chatOnce(
    String message, {
    List<({String role, String content})> history = const [],
  }) async {
    await _ensurePromptsLoaded();
    await _ensureTopicRulesLoaded();

    if (!_isEmotionalTopicSync(message)) {
      final outOfScope = _prompt(
        'chat_out_of_scope',
        'No te puedo ayudar con ese tema, soy un chat empático enfocado únicamente en cómo te sientes y en tu bienestar emocional.',
      );

      await _logInteraction(
        kind: 'chat',
        userText: message,
        responseText: outOfScope,
      );
      return outOfScope;
    }

    if (Env.offlineMode) {
      final m = message.toLowerCase();

      final crisisMatch = _topicRules.any(
            (r) => r.isCrisis && r.matches(m),
          ) ||
          (AppConstants.crisisKeywords.isNotEmpty &&
              RegExp('(${AppConstants.crisisKeywords.join('|')})').hasMatch(m));

      String response;
      if (crisisMatch) {
        response = _prompt(
          'chat_offline_crisis',
          'Siento mucho que te sientas así. No estás solo/a. Busca ayuda urgente llamando a una línea de emergencia o de apoyo emocional en tu país.',
        );
      } else if (m.contains('triste')) {
        response = _prompt(
          'chat_offline_sad',
          'Lamento que te sientas así. Probemos unas respiraciones lentas juntos. ¿Quieres contarme qué pasó?',
        );
      } else if (m.contains('ansie')) {
        response = _prompt(
          'chat_offline_anxiety',
          'La ansiedad puede ser muy abrumadora. Intentemos la respiración 4–7–8 un minuto.',
        );
      } else if (m.contains('enojo') || m.contains('rabia')) {
        response = _prompt(
          'chat_offline_anger',
          'Es válido sentir enojo. Antes de reaccionar, probemos respirar profundo o tomar distancia unos minutos.',
        );
      } else {
        response = _prompt(
          'chat_offline_default',
          'Estoy aquí para escucharte y acompañarte. Cuéntame un poco más sobre cómo te estás sintiendo.',
        );
      }

      await _logInteraction(
        kind: 'chat',
        userText: message,
        responseText: response,
      );
      return response;
    }

    try {
      await _ensureReady();

      final system = _prompt(
        'chat_system',
        'Eres un asistente empático de bienestar emocional. Responde en español, breve, cálido y práctico. '
            'Limita tus respuestas a emociones, bienestar mental, autocuidado y manejo de situaciones difíciles. '
            'Si el usuario pregunta algo fuera de ese ámbito, explícales amablemente que solo puedes ayudar con temas emocionales.',
      );

      final buf = StringBuffer()..writeln(system);

      if (history.isNotEmpty) {
        buf.writeln('\nHistorial:');
        for (final h in history) {
          buf.writeln(
            h.role == 'user'
                ? 'Usuario: ${h.content}'
                : 'Asistente: ${h.content}',
          );
        }
      }

      buf.writeln('\nUsuario: $message');
      buf.writeln('Asistente:');

      final r =
          await _chatModel!.generateContent([Content.text(buf.toString())]);
      var response = (r.text ?? '').trim();

      if (response.isEmpty) {
        response = _prompt(
          'chat_offline_default',
          'Estoy aquí para escucharte. Cuéntame un poco más sobre cómo te sientes.',
        );
      }

      await _logInteraction(
        kind: 'chat',
        userText: message,
        responseText: response,
      );

      return response;
    } catch (e, stack) {
      AppLogger.error(
        'Chat generation failed',
        error: e,
        stack: stack,
        tag: 'GeminiService',
      );

      final fallback = _prompt(
        'chat_fallback_error',
        'Lo siento, tuve un problema técnico. Pero sigo aquí para escucharte. ¿Quieres contarme cómo te sientes en este momento?',
      );

      await _logInteraction(
        kind: 'chat',
        userText: message,
        responseText: fallback,
      );

      return fallback;
    }
  }
}
