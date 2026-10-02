import 'dart:convert';

import 'package:path/path.dart' as p;

/// Helpers for journal note images (local path + S3 key).
abstract final class JournalMedia {
  static final _markdownImage = RegExp(r'!\[.*?\]\((.*?)\)');

  static String? extractFirstImagePath(String content) {
    final all = extractAllImagePaths(content);
    return all.isEmpty ? null : all.first;
  }

  /// All image paths from Quill delta ops and markdown `![alt](path)`.
  static List<String> extractAllImagePaths(String content) {
    if (content.isEmpty) return const [];

    final paths = <String>[];
    var textToSearch = content;

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is Map && insert.containsKey('image')) {
              final path = insert['image']?.toString().trim();
              if (path != null && path.isNotEmpty) paths.add(path);
            } else if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        textToSearch = buffer.toString();
      }
    } catch (_) {}

    for (final match in _markdownImage.allMatches(textToSearch)) {
      final path = match.group(1)?.trim();
      if (path != null && path.isNotEmpty && !paths.contains(path)) {
        paths.add(path);
      }
    }
    return paths;
  }

  /// Plain text body (Quill delta → text, markdown stripped of image lines).
  static String extractPlainBody(String content) {
    if (content.isEmpty) return '';

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) buffer.write(insert);
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}

    return stripImageMarkdown(content);
  }

  /// Removes markdown image lines from note body (for editor display).
  static String stripImageMarkdown(String content) {
    return content
        .replaceAll(RegExp(r'!\[.*?\]\([^)]*\)\s*'), '')
        .trim();
  }

  /// Rebuilds persisted note content from inline images + body text.
  static String composeContent({
    required List<String> imagePaths,
    required String body,
  }) {
    if (imagePaths.isEmpty) return body.trim();
    final buffer = StringBuffer();
    for (final path in imagePaths) {
      buffer.writeln('![Image]($path)');
    }
    final trimmed = body.trim();
    if (trimmed.isNotEmpty) {
      buffer.writeln();
      buffer.write(trimmed);
    }
    return buffer.toString().trim();
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
