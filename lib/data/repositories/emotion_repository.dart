import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';

class EmotionRepository {
  final _db = Supabase.instance.client;

  Future<void> save({
    required String userId,
    required String text,
    required String emotion,
    required double score,
    required int severity,
    required String advice,
    required String model,
  }) async {
    try {
      await _db.from('emotion_entries').insert({
        'user_id': userId,
        'text_input': text,
        'detected_emotion': emotion,
        'score': score,
        'severity': severity,
        'advice': advice,
        'model': model,
      });
      AppLogger.debug('Emotion entry saved for user: $userId', tag: 'EmotionRepo');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to save emotion entry',
        error: e,
        stack: stack,
        tag: 'EmotionRepo',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listForUser(String userId) async {
    try {
      final response = await _db
          .from('emotion_entries')
          .select(
              'id, created_at, text_input, detected_emotion, score, severity, advice')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(AppConstants.maxEmotionEntriesLimit) as List;

      // Filter and convert to Maps, skipping invalid entries
      final entries = response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      AppLogger.debug(
        'Retrieved ${entries.length} emotion entries for user: $userId',
        tag: 'EmotionRepo',
      );

      return entries;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to list emotion entries',
        error: e,
        stack: stack,
        tag: 'EmotionRepo',
      );
      rethrow;
    }
  }
}
