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
        oldWidget.subFolder != widget.subFolder) {
      debugPrint(
        '🔄 [LocalFirstImage] Widget Update: "${oldWidget.localPath}" -> "${widget.localPath}" (Sub: ${widget.subFolder})',
      );
      _resolvePath();
    }
  }

  Future<void> _resolvePath() async {
    debugPrint(
      '🔄 [LocalFirstImage] _resolvePath for: "${widget.localPath}" (Sub: ${widget.subFolder})',
    );

    String filename = p.basename(widget.localPath);
    bool isGuess = false;

    if (filename.isEmpty || filename == '.' || filename == '/') {
      // SMART FALLBACK: If localPath is empty, try to guess filename from remoteUrl
      if (widget.remoteUrl.isNotEmpty) {
        final uri = Uri.tryParse(widget.remoteUrl);
        if (uri != null && uri.path.isNotEmpty) {
          filename = p.basename(uri.path);
          if (filename.isNotEmpty && filename != '.' && filename != '/') {
            isGuess = true;
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
      // 1. If it's already an absolute path and exists, use it (Backward compatibility)
      if (widget.localPath.isNotEmpty && File(widget.localPath).existsSync()) {
        final size = await File(widget.localPath).length();
        debugPrint(
          '✅ [LocalFirstImage] Found direct: ${widget.localPath} ($size bytes)',
        );
        if (mounted) {
          setState(() {
            _resolvedAbsolutePath = widget.localPath;
            _fileSize = size;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Prepare candidate filenames (Support legacy names)
      final List<String> filenames = [filename];
      if (filename == 'avatar.png' || filename == 'admin.png') {
        if (!filenames.contains('avatar.png')) filenames.add('avatar.png');
        if (!filenames.contains('admin.png')) filenames.add('admin.png');
      }

      // 3. Resolve it against the CURRENT documents directory
      final appDir = await getApplicationDocumentsDirectory();

      for (var fname in filenames) {
        final isAlt = fname != filename;

        // Try Path A: Person ID-based folder (NEW - preferred structure)
        // Look for {personId}/{filename} pattern in localPath
        final personIdMatch = RegExp(r'^([^/]+)/([^/]+)$').firstMatch(widget.localPath);
        if (personIdMatch != null) {
          final personId = personIdMatch.group(1);
          final actualFilename = personIdMatch.group(2);
          if (personId != null && actualFilename != null) {
            final personPath = p.join(appDir.path, personId, widget.subFolder, actualFilename);
            debugPrint('🔎 [LocalFirstImage] Checking A (Person ID): $personPath');
            final personFile = File(personPath);
            if (personFile.existsSync()) {
              final size = await personFile.length();
              debugPrint(
                '✅ [LocalFirstImage] Found at A (Person ID) - Size: $size bytes ${isAlt ? "(via ALT name)" : ""}',
              );
              if (mounted) {
                setState(() {
                  _resolvedAbsolutePath = personPath;
                  _fileSize = size;
                  _isLoading = false;
                });
                debugPrint('🎨 [LocalFirstImage] setState for $fname');
              }
              return;
            }
          }
        }

        // Try Path A2: Search for person ID in any folder (NEW - comprehensive search)
        // This handles cases where we don't know the person ID from the localPath
        try {
          final appDirDir = Directory(appDir.path);
          if (await appDirDir.exists()) {
            final personFolders = await appDirDir.list().toList();
            for (var personFolderEntity in personFolders) {
              if (personFolderEntity is Directory) {
                final personId = p.basename(personFolderEntity.path);
                final subFolderDir = Directory(p.join(personFolderEntity.path, widget.subFolder));
                if (await subFolderDir.exists()) {
                  final personImagePath = p.join(subFolderDir.path, fname);
                  final personImageFile = File(personImagePath);
                  if (await personImageFile.exists()) {
                    final size = await personImageFile.length();
                    debugPrint(
                      '✅ [LocalFirstImage] Found at A2 (Person ID Search) in $personId - Size: $size bytes ${isAlt ? "(via ALT name)" : ""}',
                    );
                    if (mounted) {
                      setState(() {
                        _resolvedAbsolutePath = personImagePath;
                        _fileSize = size;
                        _isLoading = false;
                      });
                      debugPrint('🎨 [LocalFirstImage] setState for $fname');
                    }
                    return;
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [LocalFirstImage] Person ID search failed: $e');
        }

        // Try Path B: Primary Location (Specified subfolder)
        final primaryPath = p.join(appDir.path, widget.subFolder, fname);
        debugPrint('🔎 [LocalFirstImage] Checking B: $primaryPath');
        final primaryFile = File(primaryPath);
        if (primaryFile.existsSync()) {
          final size = await primaryFile.length();
          debugPrint(
            '✅ [LocalFirstImage] Found at B - Size: $size bytes ${isAlt ? "(via ALT name)" : ""}',
          );
          if (mounted) {
            setState(() {
              _resolvedAbsolutePath = primaryPath;
              _fileSize = size;
              _isLoading = false;
            });
            debugPrint('🎨 [LocalFirstImage] setState for $fname');
          }
          return;
        }

        // Try Path C: Root Documents Directory (Legacy/Fallback)
        final rootPath = p.join(appDir.path, fname);
        debugPrint('🔎 [LocalFirstImage] Checking C: $rootPath');
        final rootFile = File(rootPath);
        if (rootFile.existsSync()) {
          final size = await rootFile.length();
          debugPrint(
            '💡 [LocalFirstImage] Found legacy in root - Size: $size bytes ${isAlt ? "(via ALT name)" : ""}',
          );
          if (mounted) {
            setState(() {
              _resolvedAbsolutePath = rootPath;
              _fileSize = size;
              _isLoading = false;
            });
          }
          return;
        }
        
        // Try Path D: profile_images folder (Specific legacy fallback)
        if (widget.subFolder != 'profile_images') {
          final profilePath = p.join(appDir.path, 'profile_images', fname);
          debugPrint('🔎 [LocalFirstImage] Checking D: $profilePath');
          final profileFile = File(profilePath);
          if (profileFile.existsSync()) {
            final size = await profileFile.length();
            debugPrint(
              '💡 [LocalFirstImage] Found in profile fallback - Size: $size bytes ${isAlt ? "(via ALT name)" : ""}',
            );
            if (mounted) {
              setState(() {
                _resolvedAbsolutePath = profilePath;
                _fileSize = size;
                _isLoading = false;
              });
            }
            return;
          }
        }
      }

      // Not found locally in any searched path, fallback to remote
      debugPrint(
        '⚠️ [LocalFirstImage] Not found locally for: ${filenames.join(', ')}',
      );
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
      debugPrint(
        '🖼️ [LocalFirstImage] Rendering: ${_resolvedAbsolutePath!.split('/').last} ($_fileSize bytes)',
      );
      image = Image.file(
        File(_resolvedAbsolutePath!),
        key: ValueKey(
          '${_resolvedAbsolutePath}_$_fileSize',
        ), // Path + Size ensures reload if file changes
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        opacity: AlwaysStoppedAnimation(widget.opacity),
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '❌ [LocalFirstImage] DECODING FAILED for ${_resolvedAbsolutePath!.split('/').last}: $error',
          );
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
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      opacity: AlwaysStoppedAnimation(widget.opacity),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [LocalFirstImage] Remote image failed: $error');
        return _buildPlaceholder();
      },
    );
  }
}
