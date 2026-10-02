import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'dart:math' as math;
import 'package:ice_gate/utils/L10nExtensions.dart';
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
    final l10n = context.l10n;
    final block = context.watch<DocumentationBlock>();
    final breadcrumb = _breadcrumbTrail(widget.directory, block.rootDir);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.surface,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFab(
            context,
            icon: Icons.sync_rounded,
            onTap: () => block.syncWithGoogleDrive(),
            color: colorScheme.secondary,
            tooltip: 'Sync with Cloud',
          ),
          const SizedBox(height: 12),
          _buildFab(
            context,
            icon: Icons.add_comment_rounded,
            onTap: () => _createNote(context),
            color: colorScheme.primary,
            tooltip: 'New Note',
          ),
        ],
      ),
      body: Stack(
        children: [
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
              _buildSliverAppBar(context, breadcrumb, colorScheme, l10n),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildSearchBar(colorScheme, l10n),
                ),
              ),
              Watch((context) {
                final syncBlock = context.read<DocumentationBlock>();
                syncBlock.files.value;
                syncBlock.directories.value;
                if (_isVaultRoot(syncBlock)) {
                  final personId =
                      context.read<PersonBlock>().currentPersonID.value ?? '';
                  return StreamBuilder<List<ProjectNoteData>>(
                    stream: context
                        .read<ProjectNoteDAO>()
                        .watchNotesByCategory(
                          personId,
                          ProjectNoteArchiveUtils.archiveCategory,
                        ),
                    builder: (context, snapshot) {
                      final dbNotes = _filterDbNotes(snapshot.data ?? const []);
                      return _buildVaultRootBody(
                        context,
                        colorScheme,
                        l10n,
                        dbNotes,
                      );
                    },
                  );
                }
                return _buildFolderBody(context, colorScheme, l10n);
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createNote(BuildContext context) async {
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
          'category': ProjectNoteArchiveUtils.archiveCategory,
        },
      );
      if (mounted) setState(() {});
    }
  }

  List<_BreadcrumbSegment> _breadcrumbTrail(Directory current, Directory? root) {
    final rootLabel = context.l10n.vault_breadcrumb_root;
    if (root == null) {
      return [
        _BreadcrumbSegment(
          label: p.basename(current.path),
          directory: current,
        ),
      ];
    }

    final rootPath = p.normalize(root.path);
    final currentPath = p.normalize(current.path);

    if (!currentPath.startsWith(rootPath)) {
      return [
        _BreadcrumbSegment(label: p.basename(current.path), directory: current),
      ];
    }

    final segments = <_BreadcrumbSegment>[
      _BreadcrumbSegment(label: rootLabel, directory: root),
    ];

    final relative = currentPath.length > rootPath.length
        ? currentPath.substring(rootPath.length + 1)
        : '';
    if (relative.isEmpty) return segments;

    var accum = rootPath;
    for (final part in p.split(relative)) {
      accum = p.join(accum, part);
      segments.add(_BreadcrumbSegment(label: part, directory: Directory(accum)));
    }
    return segments;
  }

  bool _isVaultRoot(DocumentationBlock block) {
    final root = block.rootDir;
    if (root == null) return false;
    return p.normalize(widget.directory.path) == p.normalize(root.path);
  }

  List<ProjectNoteData> _filterDbNotes(List<ProjectNoteData> notes) {
    final q = _searchQuery.trim().toLowerCase();
    final sorted = List<ProjectNoteData>.from(notes)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (q.isEmpty) return sorted;
    return sorted.where((n) {
      final title = n.title.toLowerCase();
      final body = ProjectNoteArchiveUtils.plainBody(n).toLowerCase();
      return title.contains(q) || body.contains(q);
    }).toList();
  }

  Widget _buildVaultRootBody(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    List<ProjectNoteData> dbNotes,
  ) {
    final filtered = _filteredEntities();
    final partition = _partitionEntities(filtered);
    final hasDbNotes = dbNotes.isNotEmpty;
    final hasFolders = partition.folders.isNotEmpty;
    final hasFsNotes = partition.notes.isNotEmpty;

    if (!hasDbNotes && !hasFolders && !hasFsNotes) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 56,
                color: colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.achievement_archive_empty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isGridView) {
      return SliverMainAxisGroup(
        slivers: [
          if (hasDbNotes || hasFolders || hasFsNotes)
            SliverToBoxAdapter(
              child: _buildStatsStrip(
                partition,
                colorScheme,
                l10n,
                dbNoteCount: dbNotes.length,
              ),
            ),
          if (hasDbNotes) ...[
            _sectionHeaderSliver(l10n.vault_section_notes, colorScheme),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildDbNoteGridItem(context, dbNotes[index], colorScheme),
                  childCount: dbNotes.length,
                ),
              ),
            ),
          ],
          if (hasFolders || hasFsNotes)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entity = filtered[index];
                    return _buildGridItem(context, entity, colorScheme);
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _buildStatsStrip(
            partition,
            colorScheme,
            l10n,
            dbNoteCount: dbNotes.length,
          ),
        ),
        if (hasDbNotes) ...[
          _sectionHeaderSliver(l10n.vault_section_notes, colorScheme),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildDbNoteRow(
                context,
                dbNotes[index],
                colorScheme,
              ),
              childCount: dbNotes.length,
            ),
          ),
        ],
        if (hasFolders) ...[
          _sectionHeaderSliver(l10n.vault_section_folders, colorScheme),
          SliverToBoxAdapter(
            child: _buildFolderLane(partition.folders, colorScheme),
          ),
        ],
        if (hasFsNotes) ...[
          _sectionHeaderSliver(l10n.vault_section_other, colorScheme),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFileRow(
                context,
                partition.notes[index],
                colorScheme,
              ),
              childCount: partition.notes.length,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDbNoteRow(
    BuildContext context,
    ProjectNoteData note,
    ColorScheme colorScheme,
  ) {
    final date = DateFormat('MMM d, yyyy').format(note.updatedAt.toLocal());
    final preview = ProjectNoteArchiveUtils.plainBody(note);
    final mood = ProjectNoteArchiveUtils.moodDisplay(note);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ProjectNoteArchiveUtils.ringColorForCategory(note.category)
              .withValues(alpha: 0.22),
        ),
      ),
      child: ListTile(
        onTap: () => context.push('/projects/editor', extra: note),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(mood, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: _compactPhone(context) ? 13 : 15,
          ),
        ),
        subtitle: Text(
          preview.isEmpty ? date : '$date · $preview',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildDbNoteGridItem(
    BuildContext context,
    ProjectNoteData note,
    ColorScheme colorScheme,
  ) {
    final mood = ProjectNoteArchiveUtils.moodDisplay(note);
    final date = DateFormat('MMM d').format(note.updatedAt.toLocal());

    return InkWell(
      onTap: () => context.push('/projects/editor', extra: note),
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
                color: ProjectNoteArchiveUtils.ringColorForCategory(note.category)
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  note.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _compactPhone(context) ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _FolderPartition _partitionEntities(List<FileSystemEntity> entities) {
    final folders = <Directory>[];
    final notes = <File>[];

    for (final entity in entities) {
      if (entity is Directory) {
        folders.add(entity);
      } else if (entity is File) {
        notes.add(entity);
      }
    }

    return _FolderPartition(folders: folders, notes: notes);
  }

  bool _isNoteFile(String name) {
    final ext = p.extension(name).toLowerCase();
    return ext == '.md' || ext == '.txt' || ext == '.docx';
  }

  /// Vault explorer shows folders + note files only (no image_picker attachments).
  bool _isVaultVisible(FileSystemEntity entity) {
    final name = p.basename(entity.path);
    if (name.startsWith('.')) return false;
    if (entity is Directory) return true;
    if (entity is! File) return false;
    if (name.toLowerCase().startsWith('image_picker_')) return false;
    return _isNoteFile(name);
  }

  int _vaultChildCount(Directory folder) {
    return folder.listSync().where(_isVaultVisible).length;
  }

  List<FileSystemEntity> _filteredEntities() {
    final entities = widget.directory.listSync()
      ..sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

    return entities.where((e) {
      if (!_isVaultVisible(e)) return false;
      final name = p.basename(e.path).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openFolder(Directory directory) {
    if (directory.path == widget.directory.path) return;
    context.push('/projects/documents/folder', extra: directory);
  }

  bool _compactPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 480;

  Widget _buildSliverAppBar(
    BuildContext context,
    List<_BreadcrumbSegment> breadcrumb,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final compact = _compactPhone(context);
    return SliverAppBar(
      expandedHeight: compact ? 108 : 120,
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
          0,
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
                    colorScheme.surface.withValues(alpha: 0.85),
                    colorScheme.surface.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: _buildBreadcrumbRow(breadcrumb, colorScheme, compact),
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
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
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

  Widget _buildBreadcrumbRow(
    List<_BreadcrumbSegment> breadcrumb,
    ColorScheme colorScheme,
    bool compact,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < breadcrumb.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: compact ? 14 : 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
              ),
            InkWell(
              onTap: breadcrumb[i].directory == null
                  ? null
                  : () => _openFolder(breadcrumb[i].directory!),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  breadcrumb[i].label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    fontWeight: i == breadcrumb.length - 1
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: i == breadcrumb.length - 1
                        ? colorScheme.onSurface
                        : colorScheme.primary.withValues(alpha: 0.85),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, dynamic l10n) {
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
                hintText: l10n.vault_search_files,
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

  Widget _buildFolderBody(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final filtered = _filteredEntities();

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.vault_empty_folder,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
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

    final partition = _partitionEntities(filtered);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _buildStatsStrip(partition, colorScheme, l10n),
        ),
        if (partition.folders.isNotEmpty) ...[
          _sectionHeaderSliver(l10n.vault_section_folders, colorScheme),
          SliverToBoxAdapter(
            child: _buildFolderLane(partition.folders, colorScheme),
          ),
        ],
        if (partition.notes.isNotEmpty) ...[
          _sectionHeaderSliver(l10n.vault_section_notes, colorScheme),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFileRow(
                context,
                partition.notes[index],
                colorScheme,
                emphasize: true,
              ),
              childCount: partition.notes.length,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsStrip(
    _FolderPartition partition,
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    int dbNoteCount = 0,
  }) {
    final parts = <String>[
      if (dbNoteCount > 0) l10n.vault_stats_notes(dbNoteCount),
      if (partition.folders.isNotEmpty)
        l10n.vault_stats_folders(partition.folders.length),
      if (partition.notes.isNotEmpty)
        l10n.vault_stats_notes(partition.notes.length),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Text(
        parts.join(' · '),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _sectionHeaderSliver(String title, ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderLane(List<Directory> folders, ColorScheme colorScheme) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: folders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final folder = folders[index];
          final name = p.basename(folder.path);
          final stats = folder.statSync();
          final date = DateFormat('MMM d').format(stats.modified);
          final childCount = _vaultChildCount(folder);

          return _FolderGlassCard(
            name: name,
            meta: '$date · $childCount items',
            colorScheme: colorScheme,
            onTap: () => _handleTap(folder),
            onMenuSelected: (action) => _handleMenuAction(action, folder),
          );
        },
      ),
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    File file,
    ColorScheme colorScheme, {
    bool emphasize = false,
  }) {
    return _buildListItem(context, file, colorScheme, emphasize: emphasize);
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
    ColorScheme colorScheme, {
    bool emphasize = false,
  }) {
    final isDir = entity is Directory;
    final name = p.basename(entity.path);
    final stats = entity.statSync();
    final date = DateFormat('MMM d, yyyy').format(stats.modified);
    final size = isDir ? '--' : _formatSize(stats.size);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: emphasize
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.45)
            : colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emphasize
              ? colorScheme.primary.withValues(alpha: 0.18)
              : colorScheme.onSurface.withValues(alpha: 0.03),
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

class _BreadcrumbSegment {
  const _BreadcrumbSegment({required this.label, this.directory});

  final String label;
  final Directory? directory;
}

class _FolderPartition {
  const _FolderPartition({required this.folders, required this.notes});

  final List<Directory> folders;
  final List<File> notes;
}

class _FolderGlassCard extends StatelessWidget {
  const _FolderGlassCard({
    required this.name,
    required this.meta,
    required this.colorScheme,
    required this.onTap,
    required this.onMenuSelected,
  });

  final String name;
  final String meta;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          onSelected: onMenuSelected,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
