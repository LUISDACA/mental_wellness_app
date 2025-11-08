// lib/data/gemini/gemini_client.dart
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/env.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';

class GeminiClient {
  GenerativeModel? _jsonModel;
  GenerativeModel? _chatModel;
  String? activeModel;
  bool _ready = false;

  Future<void> ensureReady() async {
    if (Env.offlineMode) return;
    if (_ready && _jsonModel != null && _chatModel != null) return;

    final candidates = <String>[
      if (Env.geminiModel.isNotEmpty) Env.geminiModel,
      ...AppConstants.geminiModelFallbacks,
    ];

    for (final name in candidates) {
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
          activeModel = name;
          _ready = true;
          return;
        }
      } catch (e) {
        AppLogger.warning(
          'Gemini model $name failed: $e',
          tag: 'GeminiClient',
        );
      }
    }

    throw StateError(AppConstants.errorNoGeminiModels);
  }

  Map<String, dynamic>? _parseJson(String raw) {
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
      try {
        return json.decode(raw.substring(s, e + 1));
      } catch (_) {}
    }
    return null;
  }

  Future<Map<String, dynamic>?> generateJson(String prompt) async {
    await ensureReady();
    final res = await _jsonModel!.generateContent([Content.text(prompt)]);
    final raw = (res.text ?? '').trim();
    return _parseJson(raw);
  }

  Future<String> generateChat(String prompt) async {
    await ensureReady();
    final res = await _chatModel!.generateContent([Content.text(prompt)]);
    return (res.text ?? '').trim();
  }
}
