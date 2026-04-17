import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class NoteManagerPage extends StatefulWidget {
  const NoteManagerPage({super.key});

  @override
  State<NoteManagerPage> createState() => _NoteManagerPageState();
}

class _NoteManagerPageState extends State<NoteManagerPage> {
  final PageController _pageController = PageController();
  bool _isExpanded = false;

  final _searchController = TextEditingController();
  final _notionSecretController = TextEditingController();
  final _obsidianFolderController = TextEditingController();
  
  String _searchQuery = '';

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _notionSecretController.dispose();
    _obsidianFolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),

          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Sync with global header
              context.read<DocumentationBlock>().activeDocumentTab.value =
                  index;
            },
            children: [
              _buildExplorerView(context),
              Watch((context) => _buildSettingsView(context)),
            ],
          ),

          // Speed Dial FAB
          _buildSpeedDialFAB(context),
        ],
      ),
    );
  }

  Widget _buildExplorerView(BuildContext context) {
    final block = context.watch<DocumentationBlock>();
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final allFiles = block.files.value;
      final filteredFiles = allFiles.where((file) {
        final name = p.basename(file.path).toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();

      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              // Search Bar with Glassmorphism
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: colorScheme.primary),
                        hintText: 'Search notes...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Instant Status Feedback (Errors/Success)
              Watch((context) {
                final status = block.syncStatus.value;
                if (status == null) return const SizedBox.shrink();
                
                final isError = status.contains('❌');
                final isWarning = status.contains('⚠️');
                final color = isError 
                    ? colorScheme.error 
                    : (isWarning ? Colors.orange : colorScheme.primary);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isError ? Icons.error_outline : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline),
                              size: 18,
                              color: color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Library Heading
              Watch((context) {
                final selectedDir = block.selectedDirectory.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (selectedDir != null) ...[
                          IconButton(
                            onPressed: () => block.selectedDirectory.value = null,
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.surface.withValues(alpha: 0.5),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          selectedDir != null ? p.basename(selectedDir.path) : 'Note Hub',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '${allFiles.length} notes ${selectedDir != null ? "in this vault" : "total"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 32),
              
              // Folder Section
              Text(
                'FOLDER VAULTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Watch((context) {
                final dirs = context.read<DocumentationBlock>().directories.value;
                if (dirs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.03)),
                    ),
                    child: Center(
                      child: Text(
                        'No vaults found',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: dirs.length,
                    itemBuilder: (context, index) {
                      final dir = dirs[index];
                      final name = p.basename(dir.path);
                      return _buildFolderItem(context, name, dir);
                    },
                  ),
                );
              }),
              const SizedBox(height: 40),

              // Recent Notes
              Text(
                'LIVE NOTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (filteredFiles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notes found',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    return _buildLiveDocItem(file, context);
                  },
                ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLiveDocItem(File file, BuildContext context) {
    final name = p.basename(file.path);
    final stats = file.statSync();
    final timeStr = DateFormat('MMM d, HH:mm').format(stats.modified);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Source Indicators
    String source = 'LOCAL';
    IconData icon = Icons.article_rounded;
    Color color = colorScheme.primary;

    if (file.path.contains('/Notion/')) {
      source = 'NOTION';
      icon = Icons.grid_view_rounded;
      color = Colors.indigo;
    } else if (file.path.contains('/GoogleDrive/')) {
      source = 'DRIVE';
      icon = Icons.add_to_drive;
      color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        onTap: () => context.push('/projects/editor', extra: file),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          name.replaceAll('.md', ''),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                source,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (val) {
            HapticFeedback.selectionClick();
            if (val == 'delete') {
               _showFileDeleteConfirmation(context, name, file);
            } else if (val == 'move') {
              _showFolderPicker(context, source: file, isMove: true);
            } else if (val == 'copy') {
              _showFolderPicker(context, source: file, isMove: false);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'move', child: Row(children: [Icon(Icons.move_to_inbox_rounded, size: 18), SizedBox(width: 12), Text('Move to...')])),
            const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy_rounded, size: 18), SizedBox(width: 12), Text('Copy to...')])),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }
  void _showFetchDialog(BuildContext context) {
    final block = context.read<DocumentationBlock>();
    final remoteController = TextEditingController(text: _obsidianFolderController.text);
    final localController = TextEditingController(text: _obsidianFolderController.text);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Fetch Cloud Folder', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify how your cloud folder should be named on this device.',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: remoteController,
              decoration: InputDecoration(
                labelText: 'Remote Name (Drive)',
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: localController,
              decoration: InputDecoration(
                labelText: 'Local Name (Device)',
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (remoteController.text.isEmpty || localController.text.isEmpty) return;
              block.fetchFolderFromDrive(
                remoteName: remoteController.text.trim(),
                localName: localController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('FETCH NOW'),
          ),
        ],
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context) {
    final block = context.read<DocumentationBlock>();
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create New Vault',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a name for your new local vault folder.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Folder Name',
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              block.createLocalFolder(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(BuildContext context, String name, Directory dir) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () => context.push('/projects/documents/folder', extra: dir),
      onLongPress: () => _showDeleteConfirmation(context, name, dir),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder, color: colorScheme.primary, size: 24),
                const Spacer(),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'VAULT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                onSelected: (val) {
                  if (val == 'delete') {
                    _showDeleteConfirmation(context, name, dir);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Vault', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String name, Directory dir) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Vault "$name"?'),
        content: const Text(
          'This will permanently remove all documents inside this folder. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: () {
              context.read<DocumentationBlock>().deleteFolder(dir);
              Navigator.pop(context);
            },
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }


  Widget _buildSpeedDialFAB(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 40,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _isExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Visibility(
              visible: _isExpanded,
              child: Column(
                children: [
                  _buildSubButton(
                    'Sync Cloud',
                    Icons.cloud_sync,
                    1,
                    () => context
                        .read<DocumentationBlock>()
                        .syncWithGoogleDrive(),
                  ),
                  const SizedBox(height: 12),
                  _buildSubButton(
                    'Fetch Vault',
                    Icons.download_for_offline,
                    2,
                    () => _showFetchDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _buildSubButton(
                    'Upload File',
                    Icons.upload_file,
                    3,
                    () => context.read<DocumentationBlock>().importFromDevice(),
                  ),
                  const SizedBox(height: 12),
                  _buildSubButton(
                    'New Note',
                    Icons.note_add,
                    4,
                    () => context.push('/projects/editor'),
                  ),
                  const SizedBox(height: 12),
                  _buildSubButton(
                    'New Folder',
                    Icons.create_new_folder_outlined,
                    5,
                    () => _showNewFolderDialog(context),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: _isExpanded ? 0.125 : 0,
                child: Icon(Icons.add, color: colorScheme.onPrimary, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubButton(
    String label,
    IconData icon,
    int index,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: _isExpanded ? 1.0 : 0.0),
      duration: Duration(milliseconds: 200 + (index * 50)),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                onTap();
                setState(() => _isExpanded = false);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.onSurface.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.onSurface.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: colorScheme.primary, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildSettingsView(BuildContext context) {
    final block = context.read<DocumentationBlock>();
    final colorScheme = Theme.of(context).colorScheme;

    // Initialize controllers if needed
    if (_notionSecretController.text.isEmpty &&
        block.notionSecret.value != null) {
      _notionSecretController.text = block.notionSecret.value!;
    }
    if (_obsidianFolderController.text.isEmpty &&
        block.obsidianFolderName.value != null) {
      _obsidianFolderController.text = block.obsidianFolderName.value!;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        image: isDark ? null : const DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), // Subtle texture for light mode
          opacity: 0.03,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Stack(
        children: [
          // Ambient backgrounds
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -50,
              child: _buildBlurCircle(colorScheme.primary.withValues(alpha: 0.08), 300),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _buildBlurCircle(colorScheme.secondary.withValues(alpha: 0.05), 250),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60), // Room for Dynamic Island
                Expanded(
                  child: Watch((context) {
                    final syncing = block.isSyncing.value;
                    final status = block.syncStatus.value;

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Header Status (Only if syncing)
                        if (syncing)
                          _buildSyncStatusHeader(context, status),

                        // Section: Notion
                        _buildSettingsCard(
                          title: 'NOTION PIPELINE',
                          description: 'Auto-ingest pages from your Notion workspace.',
                          icon: Icons.hub_rounded,
                          iconColor: isDark ? Colors.white : Colors.black, // Notion Style
                          child: Column(
                            children: [
                              _buildConfigField(
                                'Integration Secret',
                                'secret_...',
                                _notionSecretController,
                                true,
                              ),
                              const SizedBox(height: 20),
                              _buildActionButton(
                                'Ingest Notion Content',
                                Icons.auto_awesome_rounded,
                                onPressed: () {
                                  block.setNotionSecret(_notionSecretController.text.trim());
                                  block.fetchFromNotionAuto();
                                },
                                isLoading: syncing,
                                color: isDark ? colorScheme.primary : Colors.black,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Section: Cloud Storage
                        _buildSettingsCard(
                          title: 'CLOUD VAULT (OBSIDIAN)',
                          description: 'Two-way synchronization with Google Drive.',
                          icon: Icons.cloud_sync_rounded,
                          iconColor: const Color(0xFF00B2FF), // Cloud Cyan
                          child: Column(
                            children: [
                              _buildConfigField(
                                'G-Drive Folder Name',
                                'KnowledgeVault',
                                _obsidianFolderController,
                                false,
                                onChanged: (val) => block.setObsidianFolderName(val.trim()),
                              ),
                              const SizedBox(height: 20),
                              _buildActionButton(
                                'Sync Cloud Folder',
                                Icons.download_for_offline_rounded,
                                onPressed: () => _showFetchDialog(context),
                                isLoading: syncing,
                                color: const Color(0xFF00B2FF),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Section: Maintenance
                        _buildSettingsCard(
                          title: 'MAINTENANCE',
                          description: 'Keep your local library healthy.',
                          icon: Icons.settings_suggest_rounded,
                          iconColor: const Color(0xFFFF9500), // Alert Amber
                          child: Column(
                            children: [
                              _buildSettingsTile(
                                'Rescan Library',
                                Icons.refresh_rounded,
                                'Refresh all local document indexing.',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Rescanning library...')),
                                  );
                                },
                              ),
                              Divider(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                              _buildSettingsTile(
                                'Clear App Cache',
                                Icons.delete_sweep_rounded,
                                'Clears temporary ingestion data.',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cache cleared.')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusHeader(BuildContext context, String? status) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                status ?? 'Processing...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? colorScheme.surface.withValues(alpha: 0.7) 
                  : colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              iconColor,
                              iconColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    required VoidCallback onPressed,
    bool isLoading = false,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  )
                else
                  Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigField(
    String label,
    String hint,
    TextEditingController controller,
    bool obscure, {
    ValueChanged<String>? onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          border: InputBorder.none,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
  void _showFileDeleteConfirmation(BuildContext context, String name, File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentationBlock>().deleteFile(file);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted $name')),
              );
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFolderPicker(BuildContext context, {required File source, required bool isMove}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FolderPickerSheet(
        onFolderSelected: (destination) {
          final block = context.read<DocumentationBlock>();
          if (isMove) {
            block.moveFile(source, destination);
          } else {
            block.copyFile(source, destination);
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isMove ? "Moved" : "Copied"} to ${p.basename(destination.path)}')),
          );
        },
      ),
    );
  }
}

class _FolderPickerSheet extends StatelessWidget {
  final Function(Directory) onFolderSelected;

  const _FolderPickerSheet({required this.onFolderSelected});

  @override
  Widget build(BuildContext context) {
    final block = context.watch<DocumentationBlock>();
    final allDirs = block.directories.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Destination',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allDirs.length,
              itemBuilder: (context, index) {
                final dir = allDirs[index];
                final name = p.basename(dir.path);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.folder_rounded, color: colorScheme.primary),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => onFolderSelected(dir),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
