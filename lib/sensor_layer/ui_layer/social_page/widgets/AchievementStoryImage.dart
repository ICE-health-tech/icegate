import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves [relativePath] from [ObjectDatabaseBlock.saveAnyLocalImage] to a file.
Future<File?> resolveAchievementStoryFile(String? relativePath) async {
  if (relativePath == null || relativePath.trim().isEmpty) return null;
  final appDir = await getApplicationDocumentsDirectory();
  final absolute = p.isAbsolute(relativePath)
      ? relativePath
      : p.join(appDir.path, relativePath);
  final file = File(absolute);
  if (await file.exists()) return file;
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
