import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveActions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveWarm.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';
import 'package:intl/intl.dart';

/// Chronological memory lane from [project_notes].
class AchievementUnifiedFeed extends StatelessWidget {
  const AchievementUnifiedFeed({
    super.key,
    required this.items,
    required this.projects,
    required this.photoMemories,
  });

  final List<ProjectNoteData> items;
  final List<ProjectProtocol> projects;
  final List<ProjectNoteData> photoMemories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
        child: Text(
          l10n.achievement_archive_empty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    final groups = ProjectNoteArchiveUtils.groupByMonth(items);
    final children = <Widget>[];

    for (var gi = 0; gi < groups.length; gi++) {
      final group = groups[gi];
      children.add(
        _MonthHeader(label: DateFormat.yMMMM().format(group.month)),
      );
      for (var ii = 0; ii < group.items.length; ii++) {
        final note = group.items[ii];
        if (ProjectNoteArchiveUtils.hasPhoto(note)) {
          final storyIndex = photoMemories.indexWhere((s) => s.id == note.id);
          children.add(
            _PhotoFeedTile(
              note: note,
              projectLabel: ProjectNoteArchiveUtils.projectLabel(
                note,
                projects,
              ),
              yearsAgoLabel: _yearsAgoLabel(l10n, note.createdAt),
              onTap: () {
                if (storyIndex >= 0) {
                  ProjectNoteArchiveActions.openViewer(
                    context,
                    photoMemories,
                    storyIndex,
                    projects: projects,
                  );
                }
              },
            ),
          );
        } else {
          children.add(
            _TextFeedTile(
              note: note,
              projectLabel: ProjectNoteArchiveUtils.projectLabel(
                note,
                projects,
              ),
              yearsAgoLabel: _yearsAgoLabel(l10n, note.createdAt),
              onTap: () => ProjectNoteArchiveActions.openNote(context, note),
              onOpenProject: () {
                final routeId = ProjectNoteArchiveUtils.routeProjectId(
                  note.projectID,
                  projects,
                );
                if (routeId != null) context.push('/projects/$routeId');
              },
            ),
          );
        }
        if (ii < group.items.length - 1) {
          children.add(const SizedBox(height: 10));
        }
      }
      if (gi < groups.length - 1) {
        children.add(const SizedBox(height: 16));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  String? _yearsAgoLabel(AppLocalizations l10n, DateTime createdAt) {
    final years = ProjectNoteArchiveUtils.yearsAgo(createdAt);
    if (years <= 0) return null;
    return l10n.achievement_years_ago(years);
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: ProjectNoteArchiveWarm.accent.withValues(alpha: 0.9),
              ),
            ),
          ),
          Expanded(
            child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _PhotoFeedTile extends StatelessWidget {
  const _PhotoFeedTile({
    required this.note,
    required this.projectLabel,
    required this.onTap,
    this.yearsAgoLabel,
  });

  final ProjectNoteData note;
  final String projectLabel;
  final VoidCallback onTap;
  final String? yearsAgoLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ring = ProjectNoteArchiveUtils.ringColorForCategory(note.category);
    final when = DateFormat.MMMd().add_Hm().format(note.createdAt.toLocal());
    final mood = ProjectNoteArchiveUtils.moodDisplay(note);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ring.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ProjectNoteArchiveImage(note: note, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(mood, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              when,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.photo_library_outlined,
                            size: 16,
                            color: cs.primary.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                      if (yearsAgoLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          yearsAgoLabel!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: ProjectNoteArchiveWarm.accent
                                .withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                      if (projectLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          projectLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
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
    );
  }
}

class _TextFeedTile extends StatelessWidget {
  const _TextFeedTile({
    required this.note,
    required this.projectLabel,
    required this.onTap,
    required this.onOpenProject,
    this.yearsAgoLabel,
  });

  final ProjectNoteData note;
  final String projectLabel;
  final VoidCallback onTap;
  final VoidCallback onOpenProject;
  final String? yearsAgoLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final when = DateFormat.MMMd().add_Hm().format(note.createdAt.toLocal());
    final mood = ProjectNoteArchiveUtils.moodDisplay(note);
    final preview = ProjectNoteArchiveUtils.plainBody(note);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(mood, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      when,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (note.projectID?.trim().isNotEmpty == true)
                    TextButton(
                      onPressed: onOpenProject,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(l10n.achievement_open_project),
                    ),
                ],
              ),
              if (yearsAgoLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  yearsAgoLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ProjectNoteArchiveWarm.accent.withValues(alpha: 0.95),
                  ),
                ),
              ],
              if (projectLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  projectLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
