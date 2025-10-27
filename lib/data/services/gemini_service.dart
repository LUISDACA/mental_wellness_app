import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/env.dart';

class EmotionResult {
  final String emotion; // happiness|sadness|anxiety|anger|neutral
  final double score; // 0..1
  final int severity; // 0..100
  final String advice; // breve consejo (es)

  EmotionResult({
    required this.emotion,
    required this.score,
    required this.severity,
    required this.advice,
  });
}

class GeminiService {
  static final _fallbackModels = <String>[
    if (Env.geminiModel.isNotEmpty) Env.geminiModel,
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash',
  ];

  GenerativeModel? _jsonModel;
  GenerativeModel? _chatModel;
  bool _ready = false;

  GeminiService() {
    if (Env.geminiApiKey.isEmpty && !Env.offlineMode) {
      throw StateError(
          'GEMINI_API_KEY not set. Add it to .env and run with --dart-define-from-file=.env');
    }
  }

  // ---------------- helpers ----------------
  Map<String, dynamic>? _tryParseJson(String raw) {
    // 1) directo
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {}

    // 2) bloque ```json ... ```
    final fenced =
        RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', multiLine: true);
    final m = fenced.firstMatch(raw);
    if (m != null) {
      try {
        return json.decode(m.group(1)!);
      } catch (_) {}
    }

    // 3) del primer '{' al último '}'
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

  EmotionResult _heuristicAnalyze(String text) {
    final t = text.toLowerCase();
    String emotion = 'neutral';
    int severity = 30;
    double score = 0.7;
    String advice =
        'Tómate 1 minuto para respirar 4–4–4 y escribe una línea sobre cómo te sientes.';

    // crisis (palabras de riesgo alto)
    final crisis = RegExp(
        r'(suicid|matarme|quitarme la vida|quiero morir|no quiero vivir)');
    if (crisis.hasMatch(t)) {
      return EmotionResult(
        emotion: 'sadness',
        score: 0.9,
        severity: 95,
        advice:
            'Siento que te sientas así. No estás solo/a. Busca ayuda inmediata: en muchos países marca el 112/911 o la línea local de prevención. '
            'Habla con alguien de confianza ahora mismo.',
      );
    }

    if (t.contains('ansie') || t.contains('nervio') || t.contains('preocup')) {
      emotion = 'anxiety';
      severity = 60;
      advice =
          'Prueba 4–7–8 y una pausa breve. Reduce estímulos y enfócate en un paso pequeño.';
    } else if (t.contains('triste') ||
        t.contains('deprim') ||
        t.contains('solo')) {
      emotion = 'sadness';
      severity = 55;
      advice =
          'Escribe 3 cosas pequeñas para hoy y contacta a alguien de confianza.';
    } else if (t.contains('enojo') ||
        t.contains('rabia') ||
        t.contains('molest') ||
        t.contains('ira')) {
      emotion = 'anger';
      severity = 65;
      advice =
          'Respira lento 10 veces y camina 5 min antes de responder o actuar.';
    } else if (t.contains('feliz') ||
        t.contains('content') ||
        t.contains('alegr')) {
      emotion = 'happiness';
      severity = 20;
      advice =
          'Celebra el momento y anótalo en tu diario: fortalece el hábito positivo.';
    }

    return EmotionResult(
        emotion: emotion, score: score, severity: severity, advice: advice);
  }

  // -----------------------------------------

  Future<void> _ensureReady() async {
    if (Env.offlineMode) return;

    if (_ready && _jsonModel != null && _chatModel != null) return;
    for (final name in _fallbackModels) {
      try {
        final test = GenerativeModel(
          model: name,
          apiKey: Env.geminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.2,
            // fuerza salida json cuando el modelo lo soporte
            responseMimeType: 'application/json',
            maxOutputTokens: 256,
          ),
        );
        final r = await test.generateContent([Content.text('{"ping":"ok"}')]);
        if ((r.text ?? '').isNotEmpty) {
          _jsonModel = test;
          _chatModel = GenerativeModel(
            model: name,
            apiKey: Env.geminiApiKey,
            generationConfig:
                GenerationConfig(temperature: 0.7, maxOutputTokens: 512),
          );
          _ready = true;
          return;
        }
      } catch (_) {
        // intenta siguiente
      }
    }
    throw StateError(
      'No hay modelos de Gemini disponibles con esta API key. Prueba con otro modelo o revisa tu clave de Google AI Studio.',
    );
  }

  Future<EmotionResult> analyzeText(String text) async {
    if (Env.offlineMode) return _heuristicAnalyze(text);

    await _ensureReady();
    final basePrompt = '''
Eres un asistente empático de bienestar mental. Devuelve SOLO JSON válido (sin markdown, sin texto extra) en minúsculas:
{"emotion":"happiness|sadness|anxiety|anger|neutral","score":0..1,"severity":0..100,"advice":"breve consejo en español"}
Usuario: "$text"
''';

    // 1er intento (JSON puro)
    try {
      final res = await _jsonModel!.generateContent([Content.text(basePrompt)]);
      final raw = (res.text ?? '{}').trim();
      final map = _tryParseJson(raw) ?? (throw StateError('no-json'));
      return EmotionResult(
        emotion: (map['emotion'] ?? 'neutral') as String,
        score: (map['score'] ?? 0.0).toDouble(),
        severity: (map['severity'] ?? 0).toInt(),
        advice: (map['advice'] ?? '') as String,
      );
    } catch (_) {
      // 2º intento: prompt ultra-restricto
      final strict = '''
SOLO JSON. NADA DE TEXTO EXTRA. Formato exacto:
{"emotion":"happiness|sadness|anxiety|anger|neutral","score":0..1,"severity":0..100,"advice":"texto"}
Texto: "$text"
''';
      try {
        final res2 = await _jsonModel!.generateContent([Content.text(strict)]);
        final raw2 = (res2.text ?? '{}').trim();
        final map2 = _tryParseJson(raw2) ?? (throw StateError('no-json-2'));
        return EmotionResult(
          emotion: (map2['emotion'] ?? 'neutral') as String,
          score: (map2['score'] ?? 0.0).toDouble(),
          severity: (map2['severity'] ?? 0).toInt(),
          advice: (map2['advice'] ?? '') as String,
        );
      } catch (_) {
        // heurística como último recurso
        return _heuristicAnalyze(text);
      }
    }
  }

  Future<String> chatOnce(String message,
      {List<({String role, String content})> history = const []}) async {
    if (Env.offlineMode) {
      // mini heurística
      final m = message.toLowerCase();
      if (RegExp(r'(suicid|quiero morir|quitarme la vida)').hasMatch(m)) {
        return 'Siento mucho que te sientas así. No estás solo/a. Si corres riesgo inmediato, busca ayuda urgente (112/911 o línea local). '
            '¿Puedo acompañarte mientras contactas a alguien de confianza?';
      }
      if (m.contains('triste')) {
        return 'Lamento que te sientas triste. Probemos 4 respiraciones lentas. ¿Qué te aliviaría un poquito ahora?';
      }
      if (m.contains('ansie')) {
        return 'La ansiedad es difícil. Intentemos 4–7–8 un minuto. ¿Qué pequeño paso puedes dar hoy?';
      }
      if (m.contains('enojo') || m.contains('rabia')) {
        return 'Es válido sentir enojo. Da 10 respiraciones y camina 5 min antes de actuar.';
      }
      return 'Estoy contigo. Respiremos 4–4–4. Cuéntame un poco más para ayudarte mejor.';
    }

    await _ensureReady();
    final buf = StringBuffer()
      ..writeln(
          'Eres un asistente empático de bienestar emocional. Responde en español, breve, cálido y práctico.')
      ..writeln(
          'Evita diagnósticos; sugiere respiración, pausas, journaling, contacto social seguro.');
    if (history.isNotEmpty) {
      buf.writeln('\nHistorial:');
      for (final h in history) {
        buf.writeln(h.role == 'user'
            ? 'Usuario: ${h.content}'
            : 'Asistente: ${h.content}');
      }
    }
    buf.writeln('\nUsuario: $message\nAsistente:');

    final r = await _chatModel!.generateContent([Content.text(buf.toString())]);
    return r.text ?? '';
  }
}
