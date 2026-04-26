import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LocalFirstImage extends StatefulWidget {
  final String localPath;
  final String remoteUrl;
  final Widget? placeholder;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double opacity;
  final BorderRadius? borderRadius;
  final String subFolder;
  final String? ownerId;

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
    this.subFolder = 'profile_images',
    this.ownerId,
  });

  @override
  State<LocalFirstImage> createState() => _LocalFirstImageState();
}

class _LocalFirstImageState extends State<LocalFirstImage> {
  String? _resolvedAbsolutePath;
  int _fileSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolvePath();
  }

  @override
  void didUpdateWidget(LocalFirstImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localPath != widget.localPath ||
        oldWidget.remoteUrl != widget.remoteUrl ||
        oldWidget.subFolder != widget.subFolder ||
        oldWidget.ownerId != widget.ownerId) {
      debugPrint(
        '🔄 [LocalFirstImage] Widget Update: "${oldWidget.localPath}" -> "${widget.localPath}" (Owner: ${widget.ownerId})',
      );
      _resolvePath();
    }
  }

  Future<void> _resolvePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    debugPrint(
      '🔄 [LocalFirstImage] _resolvePath for: "${widget.localPath}" (Owner: ${widget.ownerId}, Sub: ${widget.subFolder})',
    );

    String filename = p.basename(widget.localPath);

    if (filename.isEmpty || filename == '.' || filename == '/') {
      // SMART FALLBACK: If localPath is empty, try to guess filename from remoteUrl
      if (widget.remoteUrl.isNotEmpty) {
        final uri = Uri.tryParse(widget.remoteUrl);
        if (uri != null && uri.path.isNotEmpty) {
          filename = p.basename(uri.path);
          if (filename.isNotEmpty && filename != '.' && filename != '/') {
            debugPrint(
              '💡 [LocalFirstImage] Guessed filename from URL: $filename',
            );
          }
        }
      }
    }

    if (filename.isEmpty || filename == '.' || filename == '/') {
      debugPrint(
        'ℹ️ [LocalFirstImage] No filename available, setting to remote',
      );
      if (mounted) {
        setState(() {
          _resolvedAbsolutePath = null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 1. Check if it's already a DIRECT RELATIVE path (e.g., "userId/subFolder/filename")
      if (widget.localPath.contains('/')) {
        final fullPath = p.join(appDir.path, widget.localPath);
        debugPrint('🔎 [LocalFirstImage] Checking Direct Relative: $fullPath');
        if (File(fullPath).existsSync()) {
          final size = await File(fullPath).length();
          if (mounted) {
            setState(() {
              _resolvedAbsolutePath = fullPath;
              _fileSize = size;
              _isLoading = false;
            });
          }
          return;
        }

        if (File(widget.localPath).existsSync()) {
          final size = await File(widget.localPath).length();
          if (mounted) {
            setState(() {
              _resolvedAbsolutePath = widget.localPath;
              _fileSize = size;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // 2. SEARCH WITHIN OWNER DIRECTORY (STRICT ISOLATION)
      if (widget.ownerId != null && widget.ownerId!.isNotEmpty) {
        final List<String> filenames = [filename];
        if (filename == 'avatar.png' || filename == 'admin.png') {
          if (!filenames.contains('avatar.png')) filenames.add('avatar.png');
          if (!filenames.contains('admin.png')) filenames.add('admin.png');
        }

        for (var fname in filenames) {
          // Path: appDir/{ownerId}/{subFolder}/{fname}
          final isolatedPath = p.join(
            appDir.path,
            widget.ownerId!,
            widget.subFolder,
            fname,
          );
          debugPrint('🔎 [LocalFirstImage] Checking Isolated: $isolatedPath');
          if (File(isolatedPath).existsSync()) {
            final size = await File(isolatedPath).length();
            debugPrint('✅ [LocalFirstImage] Found in isolated folder');
            if (mounted) {
              setState(() {
                _resolvedAbsolutePath = isolatedPath;
                _fileSize = size;
                _isLoading = false;
              });
            }
            return;
          }

          // Path: appDir/{ownerId}/{fname}
          final isolatedRootPath = p.join(appDir.path, widget.ownerId!, fname);
          debugPrint(
            '🔎 [LocalFirstImage] Checking Isolated Root: $isolatedRootPath',
          );
          if (File(isolatedRootPath).existsSync()) {
            final size = await File(isolatedRootPath).length();
            debugPrint('✅ [LocalFirstImage] Found in isolated root');
            if (mounted) {
              setState(() {
                _resolvedAbsolutePath = isolatedRootPath;
                _fileSize = size;
                _isLoading = false;
              });
            }
            return;
          }
        }
      }

      // 3. Fallback to general folders (Only if ownerId is NOT provided or not found in owner folder)
      if (widget.ownerId == null) {
        final generalPath = p.join(appDir.path, widget.subFolder, filename);
        if (File(generalPath).existsSync()) {
          final size = await File(generalPath).length();
          debugPrint('💡 [LocalFirstImage] Found in general folder');
          if (mounted) {
            setState(() {
              _resolvedAbsolutePath = generalPath;
              _fileSize = size;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // Not found locally, fallback to remote
      if (mounted) {
        setState(() {
          _resolvedAbsolutePath = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [LocalFirstImage] Path resolution error: $e');
      if (mounted) {
        setState(() {
          _resolvedAbsolutePath = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    Widget image;

    if (_resolvedAbsolutePath != null) {
      image = Image.file(
        File(_resolvedAbsolutePath!),
        key: ValueKey(
          '${widget.ownerId}_${widget.localPath}_${_resolvedAbsolutePath}_$_fileSize',
        ),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        opacity: AlwaysStoppedAnimation(widget.opacity),
        errorBuilder: (context, error, stackTrace) {
          return _buildRemoteImage();
        },
      );
    } else {
      image = _buildRemoteImage();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[400],
          size: (widget.width != null && widget.width! < 40) ? 16 : 32,
        ),
      ),
    );
  }

  Widget _buildRemoteImage() {
    if (widget.remoteUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      widget.remoteUrl,
      key: ValueKey('${widget.ownerId}_${widget.remoteUrl}'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      opacity: AlwaysStoppedAnimation(widget.opacity),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }
}
