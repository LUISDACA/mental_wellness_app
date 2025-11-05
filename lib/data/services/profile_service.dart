import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/profile.dart';

class ProfileService {
  final _sb = Supabase.instance.client;
  static const String _bucket = 'avatars';

  /// Si el bucket es público, con cache-busting
  String? publicAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final url = _sb.storage.from(_bucket).getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Para bucket privado (alternativa)
  Future<String?> signedAvatarUrl(String? path,
      {Duration ttl = const Duration(minutes: 30)}) async {
    if (path == null || path.isEmpty) return null;
    return _sb.storage.from(_bucket).createSignedUrl(path, ttl.inSeconds);
  }

  Future<String> uploadAvatarBytes({
    required Uint8List bytes,
    required String originalName,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw StateError('No hay sesión');

    final ext = _ext(originalName);
    final path = 'u_${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _sb.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(ext),
          ),
        );
    return path;
  }

  Future<Profile> getOrCreateMyProfile() async {
    final user = _sb.auth.currentUser;
    if (user == null) throw StateError('No hay sesión');

    final rows = await _sb.from('profiles').select().eq('id', user.id).limit(1);
    if (rows.isNotEmpty) return Profile.fromMap(rows.first);

    final now = DateTime.now().toIso8601String();
    final insert = await _sb
        .from('profiles')
        .insert({
          'id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'],
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return Profile.fromMap(insert);
  }

  Future<Profile> upsert({
    String? firstName,
    String? lastName,
    String? fullName,
    String? gender,
    DateTime? birthDate,
    String? phone,
    String? address,
    String? avatarPath,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw StateError('No hay sesión');

    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String()
    };
    void put(String k, dynamic v) {
      if (v != null) patch[k] = v;
    }

    put('first_name', firstName);
    put('last_name', lastName);
    put('full_name', fullName);
    put('gender', gender);
    if (birthDate != null) {
      put('birth_date', birthDate.toIso8601String().substring(0, 10));
    }
    put('phone', phone);
    put('address', address);
    put('avatar_path', avatarPath);

    final row = await _sb
        .from('profiles')
        .update(patch)
        .eq('id', user.id)
        .select()
        .single();
    return Profile.fromMap(row);
  }

  String _ext(String name) {
    final i = name.lastIndexOf('.');
    return (i >= 0) ? name.substring(i + 1).toLowerCase() : 'jpg';
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
