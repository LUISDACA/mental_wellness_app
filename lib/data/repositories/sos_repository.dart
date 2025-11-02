// lib/data/repositories/sos_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';

class SosRepository {
  final _sb = Supabase.instance.client;

  /// Gets the current authenticated user's ID or throws an error
  String _getUserId() {
    final user = _sb.auth.currentUser;
    if (user == null) {
      throw const AuthException(AppConstants.errorNoSession);
    }
    return user.id;
  }

  Future<List<Map<String, dynamic>>> list() async {
    try {
      final uid = _getUserId();
      final response = await _sb
          .from('sos_contacts')
          .select()
          .eq('user_id', uid)
          .order('created_at') as List;

      // Filter and convert to Maps, skipping invalid entries
      final contacts = response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      AppLogger.debug(
        'Retrieved ${contacts.length} SOS contacts for user: $uid',
        tag: 'SosRepo',
      );

      return contacts;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to list SOS contacts',
        error: e,
        stack: stack,
        tag: 'SosRepo',
      );
      rethrow;
    }
  }

  Future<void> add(Map<String, String> data) async {
    try {
      final uid = _getUserId();
      await _sb.from('sos_contacts').insert({
        'user_id': uid,
        'label': data['label'],
        'phone': data['phone'],
        'email': data['email'],
      });
      AppLogger.info(
        'SOS contact added: ${data['label']}',
        tag: 'SosRepo',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Failed to add SOS contact',
        error: e,
        stack: stack,
        tag: 'SosRepo',
      );
      rethrow;
    }
  }

  Future<void> upsert({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _sb.from('sos_contacts').update(data).eq('id', id);
      AppLogger.info('SOS contact updated: $id', tag: 'SosRepo');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to update SOS contact',
        error: e,
        stack: stack,
        tag: 'SosRepo',
      );
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    try {
      await _sb.from('sos_contacts').delete().eq('id', id);
      AppLogger.info('SOS contact removed: $id', tag: 'SosRepo');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to remove SOS contact',
        error: e,
        stack: stack,
        tag: 'SosRepo',
      );
      rethrow;
    }
  }
}
