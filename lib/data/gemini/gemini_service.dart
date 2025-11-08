import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';

import 'emotion_result.dart';
import 'prompt_repository.dart';
import 'topic_filter.dart';
import 'interaction_logger.dart';
import 'heuristic_analyzer.dart';
import 'gemini_client.dart';

class GeminiService {
  final PromptRepository _prompts;
  final TopicFilter _topics;
  final InteractionLogger _logger;
  final GeminiClient _client;

  GeminiService(SupabaseClient supabase)
      : _prompts = PromptRepository(supabase),
        _topics = TopicFilter(supabase),
        _logger = InteractionLogger(supabase),
        _client = GeminiClient();

  // =============== ANALYZE TEXT ===============

  Future<EmotionResult> analyzeText(String text) async {
    // 1) Solo procesar si es emocional según reglas en BD
    final emotional = await _topics.isEmotional(text);

    if (!emotional) {
      final msg = await _prompts.get('analysis_out_of_scope', required: true);
      // No log, no Gemini, no afecta gráficas
      return EmotionResult(
        emotion: AppConstants.emotionNeutral,
        score: 0.0,
        severity: 0,
        advice: msg,
        type: AnalysisType.heuristic,
      );
    }

    // 2) OFFLINE → heurístico
    if (Env.offlineMode) {
      final res = await _heuristicAnalyze(text);
      await _logger.log(
        kind: 'analysis',
        userText: text,
        responseText: null,
        emotion: res,
        model: 'offline-heuristic',
      );
      return res;
    }

    // 3) ONLINE → Gemini JSON con prompts desde BD
    final base = await _prompts.get('emotion_analysis_base', required: true);

    try {
      final map = await _client.generateJson(
        base.replaceAll('{text}', text),
      );
      if (map == null) throw StateError('no-json');

      final res = _mapToEmotionResult(map, AnalysisType.ai);

      await _logger.log(
        kind: 'analysis',
        userText: text,
        responseText: null,
        emotion: res,
        model: _client.activeModel,
      );
      return res;
    } catch (e) {
      AppLogger.warning(
        'Primary JSON analysis failed: $e',
        tag: 'GeminiService',
      );

      final strict =
          await _prompts.get('emotion_analysis_strict', required: false);

      if (strict.isNotEmpty) {
        try {
          final map = await _client.generateJson(
            strict.replaceAll('{text}', text),
          );
          if (map == null) throw StateError('no-json-2');

          final res = _mapToEmotionResult(map, AnalysisType.ai);

          await _logger.log(
            kind: 'analysis',
            userText: text,
            responseText: null,
            emotion: res,
            model: _client.activeModel,
          );
          return res;
        } catch (_) {
          // cae abajo a heurístico
        }
      }

      // Fallback heurístico
      final res = await _heuristicAnalyze(text);
      await _logger.log(
        kind: 'analysis',
        userText: text,
        responseText: null,
        emotion: res,
        model: 'offline-fallback',
      );
      return res;
    }
  }

  // =============== CHAT ONCE ===============

  Future<String> chatOnce(
    String message, {
    List<({String role, String content})> history = const [],
  }) async {
    final emotional = await _topics.isEmotional(message);

    // Fuera de alcance → responde out_of_scope, sí se loguea como chat
    if (!emotional) {
      final oos = await _prompts.get('chat_out_of_scope', required: true);
      await _logger.log(
        kind: 'chat',
        userText: message,
        responseText: oos,
        model: _client.activeModel,
      );
      return oos;
    }

    // OFFLINE
    if (Env.offlineMode) {
      final reply = await _offlineReply(message);
      await _logger.log(
        kind: 'chat',
        userText: message,
        responseText: reply,
        model: 'offline-heuristic',
      );
      return reply;
    }

    // ONLINE
    final system = await _prompts.get('chat_system', required: true);

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

    try {
      var reply = await _client.generateChat(buf.toString());
      if (reply.trim().isEmpty) {
        reply = await _prompts.get('chat_offline_default', required: true);
      }

      await _logger.log(
        kind: 'chat',
        userText: message,
        responseText: reply,
        model: _client.activeModel,
      );
      return reply;
    } catch (e) {
      AppLogger.error(
        'Chat generation failed',
        error: e,
        tag: 'GeminiService',
      );
      final fb = await _prompts.get('chat_fallback_error', required: true);
      await _logger.log(
        kind: 'chat',
        userText: message,
        responseText: fb,
        model: _client.activeModel,
      );
      return fb;
    }
  }

  // =============== PRIVADOS ===============

  Future<EmotionResult> _heuristicAnalyze(String text) async {
    final analyzer = HeuristicAnalyzer(_topics);
    var res = await analyzer.analyze(text);

    if (res.isCrisis(AppConstants.crisisSeverityThreshold)) {
      final crisisAdvice =
          await _prompts.get('chat_offline_crisis', required: true);
      res = EmotionResult(
        emotion: res.emotion,
        score: res.score,
        severity: res.severity,
        advice: crisisAdvice,
        type: res.type,
      );
    } else {
      final advice = await _prompts.get('chat_offline_default', required: true);
      res = EmotionResult(
        emotion: res.emotion,
        score: res.score,
        severity: res.severity,
        advice: advice,
        type: res.type,
      );
    }

    return res;
  }

  EmotionResult _mapToEmotionResult(
    Map<String, dynamic> map,
    AnalysisType type,
  ) {
    return EmotionResult(
      emotion: (map['emotion'] ?? AppConstants.emotionNeutral) as String,
      score: ((map['score'] ?? 0.0) as num).toDouble(),
      severity: ((map['severity'] ?? 0) as num).toInt(),
      advice: (map['advice'] ?? '') as String,
      type: type,
    );
  }

  Future<String> _offlineReply(String message) async {
    final m = message.toLowerCase();
    final crisis = await _topics.isCrisis(message);

    String key;
    if (crisis) {
      key = 'chat_offline_crisis';
    } else if (m.contains('triste')) {
      key = 'chat_offline_sad';
    } else if (m.contains('ansie')) {
      key = 'chat_offline_anxiety';
    } else if (m.contains('enojo') || m.contains('rabia')) {
      key = 'chat_offline_anger';
    } else {
      key = 'chat_offline_default';
    }

    return _prompts.get(key, required: true);
  }
}
