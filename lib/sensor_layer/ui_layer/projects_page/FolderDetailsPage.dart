import 'dart:io';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'dart:math' as math;
import 'package:signals_flutter/signals_flutter.dart';

class FolderDetailsPage extends StatefulWidget {
  final Directory directory;

  const FolderDetailsPage({super.key, required this.directory});

  @override
  State<FolderDetailsPage> createState() => _FolderDetailsPageState();
}

class _FolderDetailsPageState extends State<FolderDetailsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final folderName = p.basename(widget.directory.path);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.surface,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFab(
            context,
            icon: Icons.sync_rounded,
            onTap: () =>
                context.read<DocumentationBlock>().syncWithGoogleDrive(),
            color: colorScheme.secondary,
            tooltip: 'Sync with Cloud',
          ),
          const SizedBox(height: 12),
          _buildFab(
            context,
            icon: Icons.add_comment_rounded,
            onTap: () async {
              final ext = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Choose Note Type'),
                  children: [
                   SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, '.docx'),
                      child: const Text('Plain Text (.docx)'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, '.md'),
                      child: const Text('Markdown (.md)'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, '.txt'),
                      child: const Text('Plain Text (.txt)'),
                    ),
                  ],
                ),
              );
              if (ext != null && context.mounted) {
                await context.push(
                  '/projects/editor',
                  extra: {
                    'initialDirectory': widget.directory,
                    'extension': ext,
                  },
                );
                if (mounted) setState(() {});
              }
            },
            color: colorScheme.primary,
            tooltip: 'New Note',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, folderName, colorScheme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildSearchBar(colorScheme),
                ),
              ),
              Watch((context) {
                final block = context.read<DocumentationBlock>();
                // Re-run directory listing when sync finishes (Drive/Notion call _loadFiles).
                block.files.value;
                block.directories.value;
                return _buildGridOrList(context, colorScheme);
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  bool _compactPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 480;

  Widget _buildSliverAppBar(
    BuildContext context,
    String title,
    ColorScheme colorScheme,
  ) {
    final compact = _compactPhone(context);
    return SliverAppBar(
      expandedHeight: compact ? 76 : 90,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.fromLTRB(
          compact ? 44 : 56,
          12,
          compact ? 12 : 56,
          14,
        ),
        centerTitle: false,
        background: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.8),
                    colorScheme.surface.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: AutoSizeText(
          title,
          maxLines: compact ? 2 : 1,
          minFontSize: 9,
          maxFontSize: compact ? 12 : 14,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? -0.35 : -0.5,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _isGridView = !_isGridView);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                icon: Icon(Icons.search, size: 20, color: colorScheme.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridOrList(BuildContext context, ColorScheme colorScheme) {
    final List<FileSystemEntity> entities = widget.directory.listSync()
      ..sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

    final filtered = entities.where((e) {
      final name = p.basename(e.path).toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) && !name.startsWith('.');
    }).toList();

    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Empty folder')),
      );
    }

    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildGridItem(context, filtered[index], colorScheme),
            childCount: filtered.length,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _buildListItem(context, filtered[index], colorScheme),
        childCount: filtered.length,
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    FileSystemEntity entity,
    ColorScheme colorScheme,
  ) {
    final isDir = entity is Directory;
    final name = p.basename(entity.path);

    return InkWell(
      onTap: () => _handleTap(entity),
      onLongPress: () =>
          _handleMenuAction('delete', entity), // Quick delete on long press
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDir
                        ? [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.7),
                          ]
                        : [
                            colorScheme.secondary,
                            colorScheme.secondary.withValues(alpha: 0.7),
                          ],
                  ).createShader(bounds),
                  child: Icon(
                    isDir ? Icons.folder_rounded : _getFileIcon(name),
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _compactPhone(context) ? 10 : 12,
                    fontWeight: isDir ? FontWeight.bold : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    FileSystemEntity entity,
    ColorScheme colorScheme,
  ) {
    final isDir = entity is Directory;
    final name = p.basename(entity.path);
    final stats = entity.statSync();
    final date = DateFormat('MMM d, yyyy').format(stats.modified);
    final size = isDir ? '--' : _formatSize(stats.size);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.03),
        ),
      ),
      child: ListTile(
        onTap: () => _handleTap(entity),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDir ? colorScheme.primary : colorScheme.secondary)
                .withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDir ? Icons.folder_rounded : _getFileIcon(name),
            color: isDir ? colorScheme.primary : colorScheme.secondary,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isDir ? FontWeight.bold : FontWeight.w600,
            fontSize: _compactPhone(context) ? 13 : 15,
          ),
        ),
        subtitle: Text(
          '$date • $size',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) => _handleMenuAction(val, entity),
          icon: Icon(
            Icons.more_vert_rounded,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'move',
              child: Row(
                children: [
                  Icon(Icons.move_to_inbox_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('Move to...'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Icons.copy_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('Copy to...'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(FileSystemEntity entity) async {
    if (entity is Directory) {
      await context.push('/projects/documents/folder', extra: entity);
      if (mounted) setState(() {});
    } else {
      await context.push('/projects/editor', extra: entity as File);
      if (mounted) setState(() {});
    }
  }

  void _handleMenuAction(String action, FileSystemEntity entity) {
    HapticFeedback.selectionClick();
    if (action == 'delete') {
      _showDeleteConfirm(entity);
    } else if (action == 'move') {
      _showFolderPicker(entity, isMove: true);
    } else if (action == 'copy') {
      _showFolderPicker(entity, isMove: false);
    } else if (action == 'rename') {
      // Future: Rename implementation
    }
  }

  void _showFolderPicker(FileSystemEntity source, {required bool isMove}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FolderPickerSheet(
        onFolderSelected: (destination) {
          final block = context.read<DocumentationBlock>();
          if (source is File) {
            if (isMove) {
              block.moveFile(source, destination);
            } else {
              block.copyFile(source, destination);
            }
          } else if (source is Directory) {
            if (isMove) {
              block.moveFolder(source, destination);
            } else {
              block.copyFolder(source, destination);
            }
          }
          Navigator.pop(context);
          setState(() {});
        },
      ),
    );
  }

  void _showDeleteConfirm(FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete permanently?'),
        content: Text(
          'Are you sure you want to delete "${p.basename(entity.path)}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (entity is Directory) {
                context.read<DocumentationBlock>().deleteFolder(entity);
              } else {
                context.read<DocumentationBlock>().deleteFile(entity as File);
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.md':
        return Icons.article_rounded;
      case '.pdf':
        return Icons.picture_as_pdf_rounded;
      case '.json':
        return Icons.code_rounded;
      case '.docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  Widget _buildFab(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    String? tooltip,
  }) {
    final block = context.read<DocumentationBlock>();
    
    return Watch((context) {
      final isSyncingDrive = block.isSyncing.value && 
                             block.syncType.value == 'drive' && 
                             icon == Icons.sync_rounded;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'fab_${icon.hashCode}',
          onPressed: isSyncingDrive ? null : onTap,
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          tooltip: tooltip,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: isSyncingDrive
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 24),
        ),
      );
    });
  }
}

class _FolderPickerSheet extends StatefulWidget {
  final Function(Directory) onFolderSelected;

  const _FolderPickerSheet({required this.onFolderSelected});

  @override
  State<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<_FolderPickerSheet> {
  @override
  Widget build(BuildContext context) {
    final block = context.watch<DocumentationBlock>();
    final allDirs = block.directories.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Select Destination',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allDirs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: Icon(
                      Icons.home_work_rounded,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Documentation Root'),
                    onTap: () {
                      // Navigate to the root (the parent of all user docs)
                      // For now, we'll just use the first item in the list's parent if available
                      if (allDirs.isNotEmpty) {
                        widget.onFolderSelected(allDirs.first.parent);
                      }
                    },
                  );
                }
                final dir = allDirs[index - 1];
                final name = p.basename(dir.path);
                return ListTile(
                  leading: Icon(
                    Icons.folder_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(name),
                  onTap: () => widget.onFolderSelected(dir),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
