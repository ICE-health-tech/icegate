import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// S3 keys to try (current `memories/` layout + legacy `achievement_stories/`).
List<String> achievementStoryS3Keys(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/').trim();
  final keys = <String>{normalized};
  if (normalized.contains('/achievement_stories/')) {
    keys.add(normalized.replaceFirst('/achievement_stories/', '/memories/'));
  } else if (normalized.contains('/memories/')) {
    keys.add(normalized.replaceFirst('/memories/', '/achievement_stories/'));
  }
  return keys.toList();
}

/// Canonical local path: prefer `…/memories/…` under the person folder.
String normalizeAchievementStoryLocalPath(String s3Path) {
  return s3Path.replaceAll('\\', '/').replaceAll(
        '/achievement_stories/',
        '/memories/',
      );
}

/// Resolves [relativePath] from [ObjectDatabaseBlock.saveAnyLocalImage] to a file.
Future<File?> resolveAchievementStoryFile(String? relativePath) async {
  if (relativePath == null || relativePath.trim().isEmpty) return null;
  final localPath = normalizeAchievementStoryLocalPath(relativePath);
  final appDir = await getApplicationDocumentsDirectory();
  final absolute = p.isAbsolute(localPath)
      ? localPath
      : p.join(appDir.path, localPath);
  final file = File(absolute);
  if (await file.exists()) return file;

  final minio = MinioService();
  for (final key in achievementStoryS3Keys(relativePath)) {
    final ok = await minio.downloadToFile(objectName: key, outFile: file);
    if (ok) return file;
  }
  return null;
}

class AchievementStoryImage extends StatelessWidget {
  final String? relativePath;
  final BoxFit fit;
  final Widget? placeholder;

  const AchievementStoryImage({
    super.key,
    required this.relativePath,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: resolveAchievementStoryFile(relativePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return placeholder ?? const ColoredBox(color: Colors.black12);
        }
        final file = snapshot.data;
        if (file == null) {
          return placeholder ??
              const ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.white54),
                ),
              );
        }
        return Image.file(file, fit: fit, width: double.infinity, height: double.infinity);
      },
    );
  }
}
