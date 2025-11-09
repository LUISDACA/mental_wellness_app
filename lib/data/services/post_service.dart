// lib/data/services/post_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/post.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../core/errors.dart';

class PostService {
  final SupabaseClient _sb = Supabase.instance.client;
  final _uuid = const Uuid();

  // ---------- STREAM ----------
  Stream<List<Post>> streamPosts() {
    return _sb
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => Post.fromMap(r)).toList());
  }

  // ---------- CREATE ----------
  Future<void> createPost({
    required String text,
    PlatformFile? file, // opcional (imagen/pdf)
  }) async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        throw const AuthException(AppConstants.errorNoSession);
      }

      if (text.trim().isEmpty) {
        throw ArgumentError(AppConstants.errorEmptyText);
      }

      // Lee perfil para nombre y avatar
      final prof = await _sb
          .from('profiles')
          .select('full_name, avatar_path')
          .eq('id', user.id)
          .maybeSingle();

      final authorName = (prof?['full_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          (user.email?.split('@').first ?? 'Usuario');

      final authorAvatarPath = prof?['avatar_path'] as String?;

      String? mediaPath;
      String? mediaType;

      // Subida de archivo (si hay)
      if (file != null) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw StateError(AppConstants.errorFileReadFailed);
        }

        // Validar tamaño de archivo
        if (bytes.length > AppConstants.maxFileSizeBytes) {
          final sizeMB = bytes.length / 1024 / 1024;
          throw ArgumentError(AppConstants.errorFileTooLarge(sizeMB));
        }

        final ext = _ext(file.name);
        if (_isImage(ext)) {
          mediaType = AppConstants.mediaTypeImage;
        } else if (_isPdf(ext)) {
          mediaType = AppConstants.mediaTypePdf;
        } else {
          throw ArgumentError(AppConstants.errorInvalidFileType);
        }

        final path = '${user.id}/${_uuid.v4()}_${_safeName(file.name)}';

        AppLogger.debug(
          'Uploading file: ${file.name} (${(bytes.length / 1024).toStringAsFixed(2)} KB)',
          tag: 'PostService',
        );

        await _sb.storage.from(AppConstants.postMediaBucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: _contentType(ext),
                upsert: false,
              ),
            );
        mediaPath = path;
      }

      await _sb.from('posts').insert({
        'user_id': user.id,
        'author_name': authorName,
        'author_avatar_path': authorAvatarPath,
        'content': text.trim(),
        'media_path': mediaPath,
        'media_type': mediaType,
      });

      AppLogger.info('Post created successfully', tag: 'PostService');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to create post',
        error: e,
        stack: stack,
        tag: 'PostService',
      );
      throw StateError(AppErrors.humanize(e));
    }
  }

  // ---------- UPDATE ----------
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

  // ---------- DELETE ----------
  Future<void> deletePost(Post p) async {
    try {
      await _sb.from('posts').delete().eq('id', p.id);

      // Intenta eliminar el archivo multimedia si existe
      if (p.mediaPath != null) {
        try {
          await _sb.storage.from(AppConstants.postMediaBucket).remove([p.mediaPath!]);
          AppLogger.debug('Media file deleted: ${p.mediaPath}', tag: 'PostService');
        } catch (e) {
          AppLogger.warning(
            'Failed to delete media file, but post was deleted: $e',
            tag: 'PostService',
          );
        }
      }

      AppLogger.info('Post deleted: ${p.id}', tag: 'PostService');
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete post',
        error: e,
        stack: stack,
        tag: 'PostService',
      );
      rethrow;
    }
  }

  // ---------- URLS ----------
  String? publicUrlFor(Post p) {
    if (p.mediaPath == null) return null;
    return _sb.storage.from(AppConstants.postMediaBucket).getPublicUrl(p.mediaPath!);
  }

  String? authorAvatarUrlFor(Post p) {
    final path = p.authorAvatarPath;
    if (path == null || path.isEmpty) return null;
    return _sb.storage.from(AppConstants.avatarsBucket).getPublicUrl(path);
  }

  // ---------- helpers ----------
  String _ext(String name) {
    final i = name.lastIndexOf('.');
    return (i >= 0) ? name.substring(i + 1).toLowerCase() : '';
  }

  bool _isImage(String ext) => AppConstants.allowedImageExtensions.contains(ext);

  bool _isPdf(String ext) => AppConstants.allowedDocumentExtensions.contains(ext);

  String _contentType(String ext) {
    if (_isImage(ext)) {
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          return AppConstants.contentTypeJpeg;
        case 'png':
          return AppConstants.contentTypePng;
        case 'gif':
          return AppConstants.contentTypeGif;
        case 'webp':
          return AppConstants.contentTypeWebp;
      }
    }
    if (_isPdf(ext)) return AppConstants.contentTypePdf;
    return AppConstants.contentTypeOctetStream;
  }

  String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
}
