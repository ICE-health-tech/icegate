import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/MoodTrendsChart.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SocialNotesDashboard extends StatefulWidget {
  const SocialNotesDashboard({super.key});

  @override
  State<SocialNotesDashboard> createState() => _SocialNotesDashboardState();
}

class _SocialNotesDashboardState extends State<SocialNotesDashboard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Watch((context) {
      final personBlock = context.read<PersonBlock>();
      final personId = personBlock.currentPersonID.value;

      if (personId == null || personId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildQuickEntryBar(context, colorScheme, textTheme),
                const Divider(height: 1, thickness: 0.2),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StreamBuilder<List<MindLogData>>(
                    stream: context.read<MindBlock>().watchMindLogsByDay(personId, DateTime.now()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "MOOD TRENDS",
                            style: textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          MoodTrendsChart(logs: snapshot.data!),
                          const SizedBox(height: 24),
                          _buildRecentLogsPreview(context, snapshot.data!),
                          const SizedBox(height: 24),
                          Text(
                            "SOCIAL NOTES",
                            style: textTheme.labelSmall?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<List<ProjectNoteData>>(
            stream: context.read<ProjectNoteDAO>().watchNotesByCategory(
              personId,
              'social',
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
                  child: _buildEmptyState(context, colorScheme, textTheme),
                );
              }

              // Sort by updatedAt descending
              final sortedNotes = List<ProjectNoteData>.from(notes)
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _SocialNoteCard(note: sortedNotes[index]),
                    childCount: sortedNotes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
      });
  }

  Widget _buildQuickEntryBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final personBlock = context.read<PersonBlock>();
    final person = personBlock.information.value.profiles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          
          Expanded(
            child: GestureDetector(
              onTap: () => _createNewNote(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                
                    Text(
                      "What's on your mind?",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () => _pickAndCreateImageNote(context),
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.4),
              foregroundColor: colorScheme.secondary,
            ),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your story begins here',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture moments, thoughts, and ideas.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _createNewNote(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Reflection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogsPreview(BuildContext context, List<MindLogData> logs) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Sort by logDate descending
    final sortedLogs = List<MindLogData>.from(logs)
      ..sort((a, b) => b.logDate.compareTo(a.logDate));
      
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sortedLogs.length.clamp(0, 10),
        itemBuilder: (context, index) {
          final log = sortedLogs[index];
          final activities = jsonDecode(log.activities) as List;
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      _getMoodEmoji(log.moodScore),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, HH:mm').format(log.logDate),
                        style: textTheme.labelSmall?.copyWith(fontSize: 9),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activities.join(", "),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getMoodEmoji(int score) {
    switch (score) {
      case 1: return "😫";
      case 2: return "😔";
      case 3: return "😐";
      case 4: return "😊";
      case 5: return "🤩";
      default: return "😐";
    }
  }

  void _createNewNote(BuildContext context) {
    context.push('/projects/editor', extra: {'category': 'social'});
  }

  Future<void> _pickAndCreateImageNote(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null && context.mounted) {
      final personBlock = context.read<PersonBlock>();
      final objectBlock = context.read<ObjectDatabaseBlock>();
      final personId = personBlock.currentPersonID.value;

      final savedPath = await objectBlock.saveAnyLocalImage(
        image,
        subFolder: 'user_markdown_documentation',
        personId: personId,
      );

      if (context.mounted) {
        context.push('/projects/editor', extra: {
          'category': 'social',
          'initialImage': savedPath,
        });
      }
    }
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
    final previewText = _getPreviewText(note.content);

    return Hero(
      tag: 'note_${note.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
              child: InkWell(
                onTap: () => context.push('/projects/editor', extra: note),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null)
                            LocalFirstImage(
                              ownerId: note.personID ?? "",
                              localPath: imageUrl,
                              remoteUrl: "",
                              subFolder: "user_markdown_documentation",
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                                    colorScheme.secondaryContainer.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: colorScheme.primary.withValues(alpha: 0.2),
                                size: 40,
                              ),
                            ),
                          // Premium overlay gradient
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.3),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Text(
                              DateFormat('MMM d').format(note.updatedAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (note.mood != null && note.mood!.isNotEmpty)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  note.mood!.toUpperCase(),
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                previewText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  height: 1.4,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

  String _getPreviewText(String content) {
    if (content.isEmpty) return "";
    
    String plainText = content;
    
    // 1. Handle JSON (Quill Delta)
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
        plainText = buffer.toString();
      }
    } catch (_) {}

    // 2. STICKY FIX: Robust Markdown Strip
    // Strip images: ![alt](url)
    plainText = plainText.replaceAll(RegExp(r'!\[.*?\]\((.*?)\)'), '');
    // Strip links: [text](url) -> text
    plainText = plainText.replaceAllMapped(RegExp(r'\[(.*?)\]\(.*?\文明\)'), (match) => match.group(1) ?? '');
    // Strip bold/italic: **bold**, __bold__, *italic*, _italic_
    plainText = plainText.replaceAll(RegExp(r'(\*\*|__|\*|_|~~)'), '');
    // Strip headers: # Header
    plainText = plainText.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');
    // Strip horizontal rules
    plainText = plainText.replaceAll(RegExp(r'^\s*([-*_])\s*\1\s*\1\s*$', multiLine: true), '');
    // Strip multiple newlines
    plainText = plainText.replaceAll(RegExp(r'\n+'), ' ');

    return plainText.trim();
  }

  String? _getPreviewImage(String content) {
    if (content.isEmpty) return null;
    
    String textToSearch = content;

    // 1. Handle JSON (Quill Delta)
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            
            // Check for direct image map
            if (insert is Map && insert.containsKey('image')) {
              return insert['image'] as String;
            }
            
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        textToSearch = buffer.toString();
      }
    } catch (_) {}

    // 2. Robust Markdown extraction
    // Also support standard markdown image
    final regExp = RegExp(r'!\[.*?\]\((.*?)\)');
    final match = regExp.firstMatch(textToSearch);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    
    return null;
  }
}

