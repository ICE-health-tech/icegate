import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

class ProjectNotesPage extends StatelessWidget {
  const ProjectNotesPage({super.key});

  static Widget icon(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.note),
      onPressed: () {
        context.go("/project_notes");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/projects/editor');
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Notes',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: colorScheme.onSurface),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
          ),
          StreamBuilder<List<ProjectNoteData>>(
            stream: context.read<ProjectNoteDAO>().watchAllNotes(
              context.read<PersonBlock>().information.value.profiles.id ?? "",
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final notes = snapshot.data!;

              if (notes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = notes[index];
                    return _NoteCard(note: note);
                  }, childCount: notes.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ProjectNoteData note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        context.push('/projects/editor', extra: note);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'note_title_${note.noteID}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  note.title ?? 'Untitled',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                _getPreviewText(note.content ?? ''),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  note.updatedAt != null
                      ? DateFormat.MMMd().format(note.updatedAt!)
                      : 'Unknown Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Note'),
                        content: const Text(
                          'Are you sure you want to delete this note?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<ProjectNoteDAO>().deleteNote(
                                note.id,
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: colorScheme.error.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    try {
      // Try to parse as Quill Delta JSON (legacy)
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            buffer.write(op['insert']);
          }
        }
        final text = buffer.toString().trim();
        return text.isEmpty ? 'No content' : text;
      }
    } catch (_) {}
    // Plain markdown — strip common markdown syntax for preview
    final stripped = content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'~~'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'>\s'), '')
        .replaceAll(RegExp(r'- '), '')
        .trim();
    return stripped.isEmpty ? 'No content' : stripped;
  }
}
