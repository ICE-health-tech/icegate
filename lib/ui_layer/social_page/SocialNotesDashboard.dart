import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';

class SocialNotesDashboard extends StatelessWidget {
  const SocialNotesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          _buildQuickEntryBar(context, colorScheme, textTheme),
          const Divider(height: 1, thickness: 0.5),
          Expanded(
            child: StreamBuilder<List<ProjectNoteData>>(
              stream: context.read<ProjectNoteDAO>().watchNotesByCategory(
                    personId,
                    'social',
                  ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = snapshot.data!;

                if (notes.isEmpty) {
                  return _buildEmptyState(context, colorScheme, textTheme);
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _SocialNoteCard(note: note);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickEntryBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final personBlock = context.read<PersonBlock>();
    final person = personBlock.information.value.profiles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: person.profileImageUrl != null
                ? NetworkImage(person.profileImageUrl!)
                : null,
            child: person.profileImageUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _createNewNote(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  "What's on your mind?",
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _createNewNote(context),
            icon: const Icon(Icons.photo_library, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 64,
            color: colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No mind notes yet',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _createNewNote(context),
            child: const Text('CREATE JOURNAL'),
          ),
        ],
      ),
    );
  }

  void _createNewNote(BuildContext context) {
    context.push('/projects/editor', extra: {'category': 'social'});
  }
}

class _SocialNoteCard extends StatelessWidget {
  final ProjectNoteData note;

  const _SocialNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = _getPreviewImage(note.content);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/projects/editor', extra: note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null)
              Expanded(
                flex: 3,
                child: LocalFirstImage(
                  ownerId: note.personID ?? "",
                  localPath: imageUrl,
                  remoteUrl: "",
                  subFolder: "quests", // Default subfolder for images
                  fit: BoxFit.cover,
                ),
              )
            else
              Expanded(
                flex: 3,
                child: Container(
                  color: colorScheme.primary.withOpacity(0.05),
                  child: Center(
                    child: Icon(
                      Icons.notes_rounded,
                      color: colorScheme.primary.withOpacity(0.2),
                      size: 32,
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        _getPreviewText(note.content),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.MMMd().format(note.updatedAt),
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return content.trim();
  }

  String? _getPreviewImage(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is Map && insert.containsKey('image')) {
              return insert['image'] as String;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
