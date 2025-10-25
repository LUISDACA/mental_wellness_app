import 'package:supabase_flutter/supabase_flutter.dart';

class SosRepository {
  final _sb = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list() async {
    final uid = _sb.auth.currentUser!.id;
    final res = await _sb
        .from('sos_contacts')
        .select()
        .eq('user_id', uid)
        .order('created_at');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> add({required String label, String? phone, String? email}) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('sos_contacts').insert({'user_id': uid, 'label': label, 'phone': phone, 'email': email});
  }

  Future<void> remove(String id) async {
    await _sb.from('sos_contacts').delete().eq('id', id);
  }
}
