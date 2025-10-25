import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationService {
  final _sb = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> byEmotion(String emotion) async {
    final res = await _sb
        .from('recommendations')
        .select()
        .eq('emotion', emotion)
        .eq('active', true);
    return (res as List).cast<Map<String, dynamic>>();
  }
}
