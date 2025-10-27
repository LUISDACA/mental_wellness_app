import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/profile.dart';

class ProfileService {
  final _sb = Supabase.instance.client;
  static const _bucket = 'avatars';

  Future<Profile> getOrCreateMyProfile() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('No hay usuario autenticado');
    }
    final rows =
        await _sb.from('profiles').select().eq('id', uid).maybeSingle();
    if (rows != null) {
      return Profile.fromMap(rows);
    }
    // crea registro mínimo
    final insert = {
      'id': uid,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final r = await _sb.from('profiles').insert(insert).select().single();
    return Profile.fromMap(r);
  }

  Future<Profile> upsert({
    String? fullName,
    String? phone,
    String? address,
    String? avatarPath,
  }) async {
    final uid = _sb.auth.currentUser!.id;
    final payload = {
      'id': uid,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (avatarPath != null) 'avatar_path': avatarPath,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = await _sb.from('profiles').upsert(payload).select().single();
    return Profile.fromMap(row);
  }

  String? publicAvatarUrl(String? path) {
    if (path == null) return null;
    final url = _sb.storage.from(_bucket).getPublicUrl(path);
    // agrega versión para evitar caché
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Sube bytes como avatar. Devuelve la ruta guardada en el bucket.
  Future<String> uploadAvatarBytes({
    required Uint8List bytes,
    required String originalName,
  }) async {
    final uid = _sb.auth.currentUser!.id;
    final ext = p.extension(originalName).replaceFirst('.', '').toLowerCase();
    final contentType = lookupMimeType(originalName) ?? 'image/jpeg';
    final path =
        '$uid/${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';

    await _sb.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return path;
  }
}
