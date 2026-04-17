import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/ui_layer/projects_page/text_editor_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DocumentationPage extends StatefulWidget {
  const DocumentationPage({super.key});

  @override
  State<DocumentationPage> createState() => _DocumentationPageState();
}

class _DocumentationPageState extends State<DocumentationPage> {
  final _notionSecretController = TextEditingController();
  bool _showConfig = false;

  @override
  void dispose() {
    _notionSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentationBlock = context.watch<DocumentationBlock>();
    final colorScheme = Theme.of(context).colorScheme;

    if (_notionSecretController.text.isEmpty && documentationBlock.notionSecret.value != null) {
      _notionSecretController.text = documentationBlock.notionSecret.value!;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Documentation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => WidgetNavigatorAction.smartPop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => documentationBlock.importFromDevice(),
            tooltip: 'Import from Device',
          ),
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => context.push('/sync-engine'),
            tooltip: 'Sync Engine',
          ),
          IconButton(
            icon: Icon(_showConfig ? Icons.settings : Icons.settings_outlined),
            onPressed: () => setState(() => _showConfig = !_showConfig),
            tooltip: 'Configure Pipeline',
          ),
          _buildSyncButton(documentationBlock, colorScheme),
        ],
      ),
      body: Watch((context) {
        final files = documentationBlock.files.value;
        final syncStatus = documentationBlock.syncStatus.value;

        return Column(
          children: [
            if (_showConfig)
              _buildConfigSection(documentationBlock, colorScheme),
            if (syncStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: colorScheme.primaryContainer,
                child: Text(
                  syncStatus,
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: files.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : ListView.builder(
                      itemCount: files.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return _buildFileTile(file, colorScheme, context);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildConfigSection(DocumentationBlock block, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Source of Truth: Notion Ingestion',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ingest ALL shared Notion databases and pages automatically.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _notionSecretController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Notion Integration Secret',
                    hintText: 'secret_...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  block.setNotionSecret(_notionSecretController.text.trim());
                  block.fetchFromNotionAuto();
                  setState(() => _showConfig = false);
                },
                icon: const Icon(Icons.download_for_offline),
                label: const Text('Ingest'),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Mirroring: Google Drive is configured automatically.',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(DocumentationBlock block, ColorScheme colorScheme) {
    return Watch((context) {
      final isSyncing = block.isSyncing.value;

      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: isSyncing
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.cloud_sync),
                onPressed: () async {
                  try {
                    await block.syncWithGoogleDrive();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sync Error: $e')),
                    );
                  }
                },
                tooltip: 'Sync with Google Drive',
              ),
      );
    });
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No documentation files found',
            style: TextStyle(color: colorScheme.outline, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Ingest from Notion or create local files to begin.'),
        ],
      ),
    );
  }

  Widget _buildFileTile(File file, ColorScheme colorScheme, BuildContext context) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final stats = file.statSync();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(stats.modified);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.article, color: colorScheme.primary),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Modified: $formattedDate'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 22),
              onPressed: () => _openEditor(context, file),
              tooltip: 'Edit File',
            ),
            const Icon(Icons.visibility_outlined, size: 20),
          ],
        ),
        onTap: () => _showPreview(context, file, fileName),
      ),
    );
  }

  void _openEditor(BuildContext context, File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextEditorPage(initialFile: file),
      ),
    );
  }

  void _showPreview(BuildContext context, File file, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<String>(
                    future: file.readAsString(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      return Markdown(
                        controller: scrollController,
                        data: snapshot.data ?? '',
                        selectable: true,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
