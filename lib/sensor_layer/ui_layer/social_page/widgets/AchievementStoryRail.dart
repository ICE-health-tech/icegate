import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveActions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveWarm.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';
import 'package:intl/intl.dart';

/// Right column: photo memory grid from [project_notes].
class AchievementStoryRail extends StatelessWidget {
  final List<ProjectNoteData> notes;
  final List<ProjectProtocol> projects;
  final Set<String> nostalgiaIds;

  const AchievementStoryRail({
    super.key,
    required this.notes,
    this.projects = const [],
    this.nostalgiaIds = const {},
  });

  static const int imageColumnFlex = 10;
  static const int recordColumnFlex = 12;

  static const double _gridGap = 8;
  static const double _hPad = 10;
  static const double _cardRadius = 14;
  static const double _phoneBreakpoint = 600;

  static bool isWideLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= _phoneBreakpoint;
  }

  static int gridColumns(BuildContext context) => isWideLayout(context) ? 3 : 2;

  static int gridRows(BuildContext context) => isWideLayout(context) ? 3 : 2;

  static double _cellSize({
    required double maxWidth,
    required double maxHeight,
    required int cols,
    required int rows,
  }) {
    final innerW = maxWidth - _hPad * 2;
    final innerH = maxHeight - 52;
    final byW = (innerW - _gridGap * (cols - 1)) / cols;
    final byH = (innerH - _gridGap * (rows - 1)) / rows;
    return math.max(48, math.min(byW, byH));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final stories = ProjectNoteArchiveUtils.photoMemories(notes);
    final cols = gridColumns(context);
    final rows = gridRows(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = _cellSize(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          cols: cols,
          rows: rows,
        );
        final itemCount = 1 + stories.length;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.4),
            border: Border(
              left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Text(
                  l10n.achievement_story_section.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: isWideLayout(context) ? 13 : 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: cs.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(_hPad, 0, _hPad, 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: _gridGap,
                    crossAxisSpacing: _gridGap,
                    mainAxisExtent: cell,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AddStoryCell(
                        size: cell,
                        radius: _cardRadius,
                        compact: !isWideLayout(context),
                        onTap: () =>
                            ProjectNoteArchiveActions.addPhotoMemory(context),
                      );
                    }
                    final storyIndex = index - 1;
                    final note = stories[storyIndex];
                    final ring = nostalgiaIds.contains(note.id)
                        ? ProjectNoteArchiveWarm.accent
                        : ProjectNoteArchiveUtils.ringColorForCategory(
                            note.category,
                          );
                    return _StoryGridCell(
                      note: note,
                      projectLabel: ProjectNoteArchiveUtils.projectLabel(
                        note,
                        projects,
                      ),
                      ringColor: ring,
                      size: cell,
                      radius: _cardRadius,
                      onTap: () => ProjectNoteArchiveActions.openViewer(
                        context,
                        stories,
                        storyIndex,
                        projects: projects,
                      ),
                      onLongPress: () =>
                          ProjectNoteArchiveActions.showActionSheet(
                        context,
                        note,
                      ),
                    );
                  },
                ),
              ),
              if (stories.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 10),
                  child: Text(
                    l10n.achievement_story_empty_hint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StoryGridCell extends StatelessWidget {
  final ProjectNoteData note;
  final String projectLabel;
  final Color ringColor;
  final double size;
  final double radius;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _StoryGridCell({
    required this.note,
    required this.projectLabel,
    required this.ringColor,
    required this.size,
    required this.radius,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showMeta = size >= 72;
    final mood = ProjectNoteArchiveUtils.moodDisplay(note);
    final dateLabel = DateFormat.MMMd().format(note.createdAt.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: ringColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: ringColor.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProjectNoteArchiveImage(
                note: note,
                fit: BoxFit.cover,
                placeholder: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: ringColor,
                    size: size * 0.32,
                  ),
                ),
              ),
              if (showMeta)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(mood, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              if (showMeta)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0.45, 1],
                    ),
                  ),
                ),
              if (showMeta)
                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: size < 100 ? 8 : 9,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 3),
                          ],
                        ),
                      ),
                      if (projectLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          projectLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size < 100 ? 9 : 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 3),
                            ],
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
    );
  }
}

class _AddStoryCell extends StatelessWidget {
  final double size;
  final double radius;
  final bool compact;
  final VoidCallback onTap;

  const _AddStoryCell({
    required this.size,
    required this.radius,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconSize = size * (compact ? 0.28 : 0.32);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: cs.primary, size: iconSize),
              if (!compact && size >= 80) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    AppLocalizations.of(context)!.achievement_story_add,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size < 100 ? 9 : 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
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
