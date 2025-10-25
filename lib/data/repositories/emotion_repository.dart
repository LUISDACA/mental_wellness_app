import 'package:supabase_flutter/supabase_flutter.dart';

class EmotionRepository {
  final _sb = Supabase.instance.client;

  Future<void> save({
    required String userId,
    required String text,
    required String emotion,
    required double score,
    required int severity,
    required String advice,
    required String model,
  }) async {
    await _sb.from('emotion_entries').insert({
      'user_id': userId,
      'text_input': text,
      'detected_emotion': emotion,
      'score': score,
      'severity': severity,
      'advice': advice,
      'model': model,
    });
  }

  Future<List<Map<String, dynamic>>> history() async {
    final res = await _sb.from('emotion_entries').select().order('created_at');
    return (res as List).cast<Map<String, dynamic>>();
  }
}
