import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/post.dart';

class PostService {
  final SupabaseClient _sb = Supabase.instance.client;
  static const String _bucket = 'post_media';

  Stream<List<Post>> streamPosts() {
    return _sb
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => Post.fromMap(r)).toList());
  }

  Future<void> createPost({
    required String text,
    PlatformFile? file, // opcional
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw StateError('No hay sesión');

    if (text.trim().isEmpty) {
      throw ArgumentError('El texto es obligatorio');
    }

    String? mediaPath;
    String? mediaType;

    if (file != null) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw StateError('No se pudo leer el archivo');
      }
      final ext = _ext(file.name);
      mediaType = _isImage(ext) ? 'image' : (_isPdf(ext) ? 'pdf' : null);
      if (mediaType == null) {
        throw ArgumentError('Solo se admiten imágenes o PDF');
      }
      final path = '${user.id}/${_uuid()}_${_safeName(file.name)}';
      await _sb.storage.from(_bucket).uploadBinary(
            path,
            bytes as Uint8List,
            fileOptions: FileOptions(
              contentType: _contentType(ext),
              upsert: false,
            ),
          );
      mediaPath = path;
    }

    final authorName = (user.userMetadata?['name'] as String?) ??
        (user.email?.split('@').first ?? 'Usuario');

    await _sb.from('posts').insert({
      'user_id': user.id,
      'author_name': authorName,
      'content': text.trim(),
      'media_path': mediaPath,
      'media_type': mediaType,
    });
  }

  Future<void> updatePost({
    required String postId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) {
      throw ArgumentError('El texto es obligatorio');
    }
    await _sb
        .from('posts')
        .update({'content': newText.trim()}).eq('id', postId);
  }

  Future<void> deletePost(Post p) async {
    await _sb.from('posts').delete().eq('id', p.id);
    if (p.mediaPath != null) {
      try {
        await _sb.storage.from(_bucket).remove([p.mediaPath!]);
      } catch (_) {
        // ignorar si ya no existe o no hay permiso
      }
    }
  }

  String? publicUrlFor(Post p) {
    if (p.mediaPath == null) return null;
    return _sb.storage.from(_bucket).getPublicUrl(p.mediaPath!);
  }

  // ------------- helpers -------------
  String _ext(String name) {
    final i = name.lastIndexOf('.');
    return (i >= 0) ? name.substring(i + 1).toLowerCase() : '';
  }

  bool _isImage(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  bool _isPdf(String ext) => ext == 'pdf';

  String _contentType(String ext) {
    if (_isImage(ext)) {
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'gif':
          return 'image/gif';
        case 'webp':
          return 'image/webp';
      }
    }
    if (_isPdf(ext)) return 'application/pdf';
    return 'application/octet-stream';
  }

  String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');

  String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return now;
  }
}
