// lib/data/gemini/interaction_logger.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import 'emotion_result.dart';

class InteractionLogger {
  final SupabaseClient supabase;

  InteractionLogger(this.supabase);

  Future<void> log({
    required String kind, // 'analysis' | 'chat'
    required String userText,
    String? responseText,
    EmotionResult? emotion,
    String? model,
  }) async {
    try {
      // No guardar análisis fuera de alcance (neutral + 0 + 0)
      if (kind == 'analysis' &&
          emotion != null &&
          emotion.emotion.toLowerCase() == 'neutral' &&
          emotion.severity == 0 &&
          (emotion.score == 0 || emotion.score == 0.0)) {
        AppLogger.debug(
          'Skipping out-of-scope analysis log',
          tag: 'InteractionLogger',
        );
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      await supabase.from('empathy_logs').insert({
        'user_id': userId,
        'kind': kind,
        'model': model,
        'request_text': userText,
        'response_text': responseText,
        'emotion': emotion?.emotion,
        'severity': emotion?.severity,
        'is_crisis': null, // calcula afuera si quieres
        'is_ai': emotion?.isAiGenerated,
      });
    } catch (e, stack) {
      AppLogger.error(
        'Error logging interaction',
        error: e,
        stack: stack,
        tag: 'InteractionLogger',
      );
    }
  }
}
