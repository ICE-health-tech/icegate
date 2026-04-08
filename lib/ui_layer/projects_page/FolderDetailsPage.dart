import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'dart:math' as math;

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
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, folderName, colorScheme),
          SliverToBoxAdapter(
            child: _buildSearchBar(colorScheme),
          ),
          _buildGridOrList(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String title, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
        centerTitle: false,
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list_rounded : Icons.grid_view_rounded),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search files...',
            border: InputBorder.none,
            icon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
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
            (context, index) => _buildGridItem(filtered[index], colorScheme),
            childCount: filtered.length,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildListItem(filtered[index], colorScheme),
        childCount: filtered.length,
      ),
    );
  }

  Widget _buildGridItem(FileSystemEntity entity, ColorScheme colorScheme) {
    final isDir = entity is Directory;
    final name = p.basename(entity.path);

    return InkWell(
      onTap: () => _handleTap(entity),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDir ? Icons.folder_rounded : _getFileIcon(name),
            size: 48,
            color: isDir ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(FileSystemEntity entity, ColorScheme colorScheme) {
    final isDir = entity is Directory;
    final name = p.basename(entity.path);
    final stats = entity.statSync();
    final date = DateFormat('MMM d, yyyy').format(stats.modified);
    final size = isDir ? '--' : _formatSize(stats.size);

    return ListTile(
      leading: Icon(
        isDir ? Icons.folder_rounded : _getFileIcon(name),
        color: isDir ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(name),
      subtitle: Text('$date • $size'),
      onTap: () => _handleTap(entity),
      trailing: PopupMenuButton<String>(
        onSelected: (val) => _handleMenuAction(val, entity),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
        ],
      ),
    );
  }

  void _handleTap(FileSystemEntity entity) {
    if (entity is Directory) {
      context.push('/projects/documents/folder', extra: entity);
    } else {
      context.push('/projects/editor', extra: entity as File);
    }
  }

  void _handleMenuAction(String action, FileSystemEntity entity) {
    if (action == 'delete') {
      _showDeleteConfirm(entity);
    }
  }

  void _showDeleteConfirm(FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${p.basename(entity.path)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              if (entity is Directory) {
                context.read<DocumentationBlock>().deleteFolder(entity);
              } else {
                entity.deleteSync();
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.md': return Icons.article_rounded;
      case '.pdf': return Icons.picture_as_pdf_rounded;
      case '.json': return Icons.code_rounded;
      case '.docx': return Icons.description_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }
}
