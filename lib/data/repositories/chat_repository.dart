import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final _sb = Supabase.instance.client;

  Future<void> add({required String role, required String content}) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('messages').insert({'user_id': uid, 'role': role, 'content': content});
  }

  Future<List<Map<String, dynamic>>> all() async {
    final uid = _sb.auth.currentUser!.id;
    final res = await _sb
        .from('messages')
        .select()
        .eq('user_id', uid)
        .order('created_at');
    return (res as List).cast<Map<String, dynamic>>();
  }
}
