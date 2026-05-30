import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryActions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/achievement_story_utils.dart';

/// Right column: photo story grid (3×3 laptop, 2×2 phone).
class AchievementStoryRail extends StatelessWidget {
  final List<AchievementData> achievements;

  const AchievementStoryRail({super.key, required this.achievements});

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
    final stories = achievementPhotoStories(achievements);
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
                            AchievementStoryActions.addStory(context),
                      );
                    }
                    final storyIndex = index - 1;
                    final a = stories[storyIndex];
                    return _StoryGridCell(
                      title: a.title,
                      ringColor: achievementDomainRingColor(a.domain),
                      imagePath: a.localImagePath,
                      size: cell,
                      radius: _cardRadius,
                      onTap: () => AchievementStoryActions.openViewer(
                        context,
                        stories,
                        storyIndex,
                      ),
                      onLongPress: () =>
                          AchievementStoryActions.showStoryActionSheet(
                        context,
                        a,
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
  final String title;
  final Color ringColor;
  final String? imagePath;
  final double size;
  final double radius;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _StoryGridCell({
    required this.title,
    required this.ringColor,
    required this.imagePath,
    required this.size,
    required this.radius,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showTitle = size >= 72;

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
              AchievementStoryImage(
                relativePath: imagePath,
                fit: BoxFit.cover,
                placeholder: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.emoji_events,
                    color: ringColor,
                    size: size * 0.32,
                  ),
                ),
              ),
              if (showTitle)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.5, 1],
                    ),
                  ),
                ),
              if (showTitle)
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 5,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size < 100 ? 9 : 11,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 3),
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
