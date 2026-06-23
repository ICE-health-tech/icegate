import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementBuilderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementFeedUtils.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryActions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/achievement_story_utils.dart';
import 'package:intl/intl.dart';

/// Chronological mix of photo stories and logged text feats (slice B).
class AchievementUnifiedFeed extends StatelessWidget {
  const AchievementUnifiedFeed({
    super.key,
    required this.items,
    required this.projects,
    required this.photoStories,
  });

  final List<AchievementData> items;
  final List<ProjectProtocol> projects;
  final List<AchievementData> photoStories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
        child: Text(
          l10n.social_no_achievements_msg,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final a = items[index];
        if (achievementIsPhotoStory(a)) {
          final storyIndex = photoStories.indexWhere((s) => s.id == a.id);
          return _PhotoFeedTile(
            achievement: a,
            projectLabel: AchievementFeedUtils.projectLabel(a, projects),
            onTap: () {
              if (storyIndex >= 0) {
                AchievementStoryActions.openViewer(
                  context,
                  photoStories,
                  storyIndex,
                  projects: projects,
                );
              }
            },
          );
        }
        return _TextFeedTile(
          achievement: a,
          projectLabel: AchievementFeedUtils.projectLabel(a, projects),
          onTap: () => AchievementBuilderDialog.show(context, initialData: a),
          onOpenProject: () {
            final routeId =
                AchievementFeedUtils.routeProjectId(a.projectID, projects);
            if (routeId != null) context.push('/projects/$routeId');
          },
        );
      },
    );
  }
}

class _PhotoFeedTile extends StatelessWidget {
  const _PhotoFeedTile({
    required this.achievement,
    required this.projectLabel,
    required this.onTap,
  });

  final AchievementData achievement;
  final String projectLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ring = achievementDomainRingColor(achievement.domain);
    final when = DateFormat.MMMd().add_Hm().format(
      achievement.createdAt.toLocal(),
    );
    final mood = achievement.moodPost ?? '😐';

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
                child: AchievementStoryImage(
                  relativePath: achievement.localImagePath,
                  fit: BoxFit.cover,
                ),
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
                        achievement.title,
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
    required this.achievement,
    required this.projectLabel,
    required this.onTap,
    required this.onOpenProject,
  });

  final AchievementData achievement;
  final String projectLabel;
  final VoidCallback onTap;
  final VoidCallback onOpenProject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final when = DateFormat.MMMd().add_Hm().format(
      achievement.createdAt.toLocal(),
    );
    final mood = achievement.moodPost ?? achievement.moodPre;

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
                  if (mood != null && mood.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(mood, style: const TextStyle(fontSize: 18)),
                    ),
                  Expanded(
                    child: Text(
                      when,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (achievement.projectID?.trim().isNotEmpty == true)
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
                achievement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
