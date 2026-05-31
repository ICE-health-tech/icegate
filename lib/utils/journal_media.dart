import 'dart:convert';

import 'package:path/path.dart' as p;

/// Helpers for journal note images (local path + S3 key).
abstract final class JournalMedia {
  static String? extractFirstImagePath(String content) {
    if (content.isEmpty) return null;

    var textToSearch = content;

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is Map && insert.containsKey('image')) {
              return insert['image'] as String?;
            }
            if (insert is String) buffer.write(insert);
          }
        }
        textToSearch = buffer.toString();
      }
    } catch (_) {}

    final match = RegExp(r'!\[.*?\]\((.*?)\)').firstMatch(textToSearch);
    final path = match?.group(1)?.trim();
    return (path == null || path.isEmpty) ? null : path;
  }

  /// Canonical S3 object key for a journal image.
  static String? canonicalRemotePath(String? localPath, {String? personId}) {
    if (localPath == null || localPath.isEmpty) return null;
    final normalized = localPath.replaceAll('\\', '/').trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    if (normalized.contains('/')) return normalized;
    if (personId != null && personId.isNotEmpty) {
      return '$personId/user_markdown_documentation/${p.basename(normalized)}';
    }
    return normalized;
  }
}
