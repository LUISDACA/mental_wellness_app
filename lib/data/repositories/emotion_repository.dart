import 'package:supabase_flutter/supabase_flutter.dart';

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
    await _db.from('emotion_entries').insert({
      'user_id': userId,
      'text_input': text, // 👈 nombre real
      'detected_emotion': emotion, // 👈 nombre real
      'score': score,
      'severity': severity,
      'advice': advice,
      'model': model,
    });
  }

  Future<List<Map<String, dynamic>>> listForUser(String userId) async {
    final rows = await _db
        .from('emotion_entries')
        .select(
            'id, created_at, text_input, detected_emotion, score, severity, advice')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50) as List<dynamic>;

    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
