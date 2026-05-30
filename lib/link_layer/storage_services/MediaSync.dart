import 'dart:io';

import 'package:ice_gate/link_layer/storage_services/MediaS3Paths.dart';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:ice_gate/utils/app_log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads local images to S3 using app-document relative paths as object keys.
abstract final class MediaSync {
  /// Uploads [relativePath] (and meal `food/` alias when applicable).
  /// Returns the public HTTPS URL for the primary key, or null on failure.
  static Future<String?> uploadRelativePath(String relativePath) async {
    final normalized = relativePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) return null;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localFile = File(p.join(appDir.path, normalized));
      if (!await localFile.exists()) {
        appLog('MediaSync: local file missing for $normalized');
        return null;
      }

      final minio = MinioService();
      final keys = mediaS3KeysForRelativePath(normalized);
      String? primaryUrl;

      for (final key in keys) {
        try {
          final url = await minio.uploadFileAtKey(localFile, objectKey: key);
          primaryUrl ??= url;
          appLog('MediaSync: uploaded s3://$key');
        } catch (e) {
          appLog('MediaSync: upload failed ($key): $e');
        }
      }

      if (normalized.contains('/profile_images/')) {
        await pushProfileMediaUrlsToSupabase(
          personId: normalized.split('/').first,
        );
      }

      return primaryUrl;
    } catch (e) {
      appLog('MediaSync: uploadRelativePath failed ($relativePath): $e');
      return null;
    }
  }

  /// Updates Supabase `profiles` when avatar/cover exist on S3.
  static Future<void> pushProfileMediaUrlsToSupabase({
    required String personId,
  }) async {
    if (personId.isEmpty) return;
    final client = Supabase.instance.client;
    if (client.auth.currentUser?.id != personId) return;

    final minio = MinioService();
    final updates = <String, dynamic>{};

    for (final key in [
      '$personId/profile_images/avatar.png',
      '$personId/profile_images/admin.png',
    ]) {
      if (await minio.objectExists(key)) {
        updates['profile_image_url'] = minio.publicUrlForKey(key);
        break;
      }
    }

    final coverRel = '$personId/profile_images/cover.png';
    if (await minio.objectExists(coverRel)) {
      updates['cover_image_url'] = minio.publicUrlForKey(coverRel);
    }

    if (updates.isEmpty) return;

    try {
      await client.from('profiles').update(updates).eq('id', personId);
      appLog('MediaSync: updated profile media URLs on Supabase');
    } catch (e) {
      appLog('MediaSync: profile URL push failed: $e');
    }
  }

  /// Lists S3 prefix and downloads missing files into local app documents.
  static Future<int> pullS3PrefixToLocal({
    required String personId,
    required String subFolder,
    String Function(String s3Key)? mapToLocalRelative,
  }) async {
    if (personId.isEmpty || subFolder.isEmpty) return 0;

    final minio = MinioService();
    final prefix = '$personId/$subFolder/';
    final keys = await minio.listObjectNames(prefix: prefix);
    final appDir = await getApplicationDocumentsDirectory();
    var pulled = 0;

    for (final key in keys) {
      final name = p.basename(key);
      if (name.isEmpty || name.startsWith('.')) continue;

      final localRel = mapToLocalRelative != null
          ? mapToLocalRelative(key)
          : key.replaceAll('\\', '/');
      final localFile = File(p.join(appDir.path, localRel));
      if (await localFile.exists()) continue;

      if (await minio.downloadToFile(objectName: key, outFile: localFile)) {
        pulled++;
      }
    }
    return pulled;
  }
}
