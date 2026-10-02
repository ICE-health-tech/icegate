import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveActions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveWarm.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';
import 'package:intl/intl.dart';

/// "On this day" strip — memories from [project_notes] on the same date.
class AchievementNostalgiaBanner extends StatelessWidget {
  const AchievementNostalgiaBanner({
    super.key,
    required this.memories,
    required this.photoMemories,
    required this.projects,
  });

  final List<ProjectNoteData> memories;
  final List<ProjectNoteData> photoMemories;
  final List<ProjectProtocol> projects;

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now().toLocal();
    final dateLabel = DateFormat.MMMMd().format(today);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ProjectNoteArchiveWarm.accent.withValues(alpha: 0.14),
              cs.surface.withValues(alpha: 0.92),
              cs.primary.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(
            color: ProjectNoteArchiveWarm.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 20,
                    color: ProjectNoteArchiveWarm.accent.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.achievement_on_this_day_title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          l10n.achievement_on_this_day_subtitle(dateLabel),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 14),
                  itemCount: memories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final memory = memories[index];
                    return _MemoryChip(
                      memory: memory,
                      yearsLabel: l10n.achievement_years_ago(
                        ProjectNoteArchiveUtils.yearsAgo(memory.createdAt),
                      ),
                      onTap: () => _openMemory(context, memory),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMemory(BuildContext context, ProjectNoteData memory) {
    if (ProjectNoteArchiveUtils.hasPhoto(memory)) {
      final storyIndex = photoMemories.indexWhere((s) => s.id == memory.id);
      if (storyIndex >= 0) {
        ProjectNoteArchiveActions.openViewer(
          context,
          photoMemories,
          storyIndex,
          projects: projects,
        );
      }
      return;
    }
    ProjectNoteArchiveActions.openNote(context, memory);
  }
}

class _MemoryChip extends StatelessWidget {
  const _MemoryChip({
    required this.memory,
    required this.yearsLabel,
    required this.onTap,
  });

  final ProjectNoteData memory;
  final String yearsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPhoto = ProjectNoteArchiveUtils.hasPhoto(memory);

    return Material(
      color: cs.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: isPhoto
                    ? ProjectNoteArchiveImage(note: memory, fit: BoxFit.cover)
                    : ColoredBox(
                        color: cs.primary.withValues(alpha: 0.08),
                        child: Center(
                          child: Text(
                            ProjectNoteArchiveUtils.moodDisplay(memory),
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yearsLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ProjectNoteArchiveWarm.accent
                            .withValues(alpha: 0.95),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memory.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
