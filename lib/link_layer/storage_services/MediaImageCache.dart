import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ice_gate/link_layer/storage_services/MediaS3Paths.dart';
import 'package:ice_gate/utils/app_log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persistent on-disk cache for user media under app documents.
///
/// Used by [LocalFirstImage]: once a remote image is fetched, it is stored at
/// the canonical relative path so journal / note cards load instantly offline.
abstract final class MediaImageCache {
  static final Map<String, Future<File?>> _inFlight = {};

  /// Absolute file if [relativePath] already exists under documents.
  static Future<File?> existingFile(String relativePath) async {
    final rel = _normalizeRelative(relativePath);
    if (rel.isEmpty) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final abs = p.join(appDir.path, rel);
    final file = File(abs);
    if (await file.exists()) {
      final size = await file.length();
      if (size > 0) return file;
    }
    return null;
  }

  /// Download [remoteUrl] into documents/[relativePath] when missing.
  static Future<File?> ensureRelativePath({
    required String relativePath,
    required String remoteUrl,
  }) async {
    final rel = _normalizeRelative(relativePath);
    if (rel.isEmpty || remoteUrl.isEmpty) return null;

    final existing = await existingFile(rel);
    if (existing != null) return existing;

    final pending = _inFlight[rel];
    if (pending != null) return pending;

    final future = _download(rel, remoteUrl);
    _inFlight[rel] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(rel);
    }
  }

  static String canonicalRelativePath({
    required String localPath,
    required String subFolder,
    String? ownerId,
  }) {
    var path = localPath.replaceAll('\\', '/').trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.tryParse(path);
      final name = uri != null ? p.basename(uri.path) : '';
      if (name.isEmpty || name == '.' || name == '/') return '';
      path = name;
    }

    if (path.contains('/')) {
      return canonicalLocalMediaPath(path);
    }

    if (ownerId != null && ownerId.isNotEmpty) {
      return '$ownerId/$subFolder/$path';
    }
    if (subFolder.isNotEmpty) return '$subFolder/$path';
    return path;
  }

  static String _normalizeRelative(String relativePath) {
    return canonicalLocalMediaPath(relativePath.replaceAll('\\', '/').trim());
  }

  static Future<File?> _download(String relativePath, String remoteUrl) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final abs = p.join(appDir.path, relativePath);
      final dir = Directory(p.dirname(abs));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final response = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 45));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        appLog(
          'MediaImageCache: HTTP ${response.statusCode} for $remoteUrl',
        );
        return null;
      }

      final tmp = File('$abs.download');
      await tmp.writeAsBytes(response.bodyBytes, flush: true);
      final out = await tmp.rename(abs);
      appLog('MediaImageCache: saved $relativePath (${response.bodyBytes.length} B)');
      return out;
    } catch (e) {
      appLog('MediaImageCache: download failed ($relativePath): $e');
      return null;
    }
  }
}
