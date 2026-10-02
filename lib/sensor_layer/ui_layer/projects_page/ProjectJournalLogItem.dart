import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

enum ProjectJournalLogLayout { list, grid }

/// Mood + image journal entry on a project detail page ([category] == project_log).
class ProjectJournalLogItem extends StatelessWidget {
  const ProjectJournalLogItem({
    super.key,
    required this.note,
    required this.personId,
    this.layout = ProjectJournalLogLayout.grid,
  });

  final ProjectNoteData note;
  final String? personId;
  final ProjectJournalLogLayout layout;

  int _moodScoreFromEmoji(String? mood) {
    return switch (mood) {
      '😫' => 1,
      '😔' => 2,
      '😐' => 3,
      '😊' => 4,
      '🤩' => 5,
      _ => 3,
    };
  }

  String? _imageUrl() {
    final local = note.localPath;
    if (local == null || local.isEmpty) return null;
    if (local.startsWith('http://') || local.startsWith('https://')) {
      return local;
    }
    final normalized = local.replaceAll('\\', '/');
    final key = normalized.contains('/')
        ? normalized
        : (personId != null && personId!.isNotEmpty
            ? '$personId/user_markdown_documentation/${p.basename(normalized)}'
            : normalized);
    return MinioService().publicUrlForKey(key);
  }

  String get _previewText =>
      note.content.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '').trim();

  @override
  Widget build(BuildContext context) {
    return layout == ProjectJournalLogLayout.list
        ? _buildListCard(context)
        : _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodColor = mindMoodAccent(_moodScoreFromEmoji(note.mood));
    final imageUrl = _imageUrl();
    final preview = _previewText;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: cs.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.4 : 0.55,
          ),
          child: InkWell(
            onTap: () => context.push('/projects/editor', extra: note),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: moodColor.withValues(alpha: 0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          LocalFirstImage(
                            localPath: note.localPath!,
                            remoteUrl: imageUrl,
                            subFolder: 'user_markdown_documentation',
                            ownerId: personId,
                            fit: BoxFit.cover,
                            placeholder: _imagePlaceholder(cs, moodColor),
                          )
                        else
                          _imagePlaceholder(cs, moodColor),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: moodColor.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: moodColor.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              note.mood ?? '😐',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.MMMd().add_Hm().format(
                            note.createdAt.toLocal(),
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme cs, Color moodColor) {
    return Container(
      color: moodColor.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(
        Icons.sentiment_satisfied_alt_rounded,
        size: 36,
        color: moodColor.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodColor = mindMoodAccent(_moodScoreFromEmoji(note.mood));
    final imageUrl = _imageUrl();
    final preview = _previewText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: cs.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.35 : 0.55,
            ),
            child: InkWell(
              onTap: () => context.push('/projects/editor', extra: note),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: moodColor.withValues(alpha: 0.2),
                        border: Border.all(
                          color: moodColor.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        note.mood ?? '😐',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.MMMd().add_Hm().format(
                              note.createdAt.toLocal(),
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          if (preview.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.7),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (imageUrl != null) ...[
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LocalFirstImage(
                          localPath: note.localPath!,
                          remoteUrl: imageUrl,
                          subFolder: 'user_markdown_documentation',
                          ownerId: personId,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            width: 56,
                            height: 56,
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              color: cs.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
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
