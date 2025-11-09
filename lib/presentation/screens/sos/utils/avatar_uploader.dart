import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/sos_repository.dart';

class AvatarUploader {
  static Future<String> upload({
    required SupabaseClient sb,
    required SosRepository repo,
    required String contactId,
    String? oldAvatarPath,
    required Uint8List bytes,
    required String extension,
  }) async {
    // Evict old image from cache and try to remove from storage
    if (oldAvatarPath != null && oldAvatarPath.isNotEmpty) {
      try {
        final oldUrl = _publicUrl(sb, oldAvatarPath);
        PaintingBinding.instance.imageCache.evict(NetworkImage(oldUrl));
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}
      try {
        String cleanOldPath = oldAvatarPath;
        if (oldAvatarPath.startsWith('sos_avatars/')) {
          cleanOldPath = oldAvatarPath.substring('sos_avatars/'.length);
        }
        await sb.storage.from('sos_avatars').remove([cleanOldPath]);
      } catch (_) {}
    }

    final fileName = '${contactId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final uploadPath = await sb.storage.from('sos_avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );

    final pathToSave = uploadPath.contains('/')
        ? uploadPath.split('/').last
        : uploadPath;

    await repo.upsert(id: contactId, data: {'avatar_path': pathToSave});
    return pathToSave;
  }

  static String _publicUrl(SupabaseClient sb, String path) {
    String cleanPath = path;
    if (path.startsWith('sos_avatars/')) {
      cleanPath = path.substring('sos_avatars/'.length);
    }
    return sb.storage.from('sos_avatars').getPublicUrl(cleanPath);
  }
}