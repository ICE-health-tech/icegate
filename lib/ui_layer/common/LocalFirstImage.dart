import 'dart:io';
import 'package:flutter/material.dart';

class LocalFirstImage extends StatelessWidget {
  final String localPath;
  final String remoteUrl;
  final Widget? placeholder;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double opacity;
  final BorderRadius? borderRadius;

  const LocalFirstImage({
    super.key,
    required this.localPath,
    required this.remoteUrl,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.opacity = 1.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (localPath.isNotEmpty && File(localPath).existsSync()) {
      image = Image.file(
        File(localPath),
        fit: fit,
        width: width,
        height: height,
        opacity: AlwaysStoppedAnimation(opacity),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ [LocalFirstImage] Local file failed: $error');
          return _buildRemoteImage();
        },
      );
    } else {
      image = _buildRemoteImage();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildRemoteImage() {
    if (remoteUrl.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    return Image.network(
      remoteUrl,
      fit: fit,
      width: width,
      height: height,
      opacity: AlwaysStoppedAnimation(opacity),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [LocalFirstImage] Remote image failed: $error');
        return placeholder ?? const SizedBox.shrink();
      },
    );
  }
}
