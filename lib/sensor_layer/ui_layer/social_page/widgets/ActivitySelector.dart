import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';

import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindGratitudePanel.dart';

class ActivitySelector extends StatelessWidget {
  final List<String> selectedActivities;
  final Function(String) onActivityToggled;
  /// Synced custom options for this user (filtered per category in build).
  final List<JournalActivityOptionData> customOptions;
  final void Function(String categoryKey) onAddCustomOption;
  /// Shown directly under Xã hội when [act_gratitude] is selected.
  final Widget? gratitudePicker;

  const ActivitySelector({
    super.key,
    required this.selectedActivities,
    required this.onActivityToggled,
    required this.customOptions,
    required this.onAddCustomOption,
    this.gratitudePicker,
  });

  static const _gratitudeAccent = MindGratitudePanel.flagColor;

  static const Map<String, List<Map<String, dynamic>>> categories = {
    "cat_productivity": [
      {"name": "act_deep_work", "icon": Icons.psychology_rounded},
      {"name": "act_learning", "icon": Icons.local_library_rounded},
      {"name": "act_finance", "icon": Icons.payments_rounded},
      {"name": "act_planning", "icon": Icons.event_note_rounded},
    ],
    "cat_health": [
      {"name": "act_exercise", "icon": Icons.fitness_center_rounded},
      {"name": "act_meditation", "icon": Icons.self_improvement_rounded},
      {"name": "act_healthy_meal", "icon": Icons.restaurant_rounded},
      {"name": "act_great_sleep", "icon": Icons.bedtime_rounded},
    ],
    "cat_social": [
      {"name": "act_family", "icon": Icons.family_restroom_rounded},
      {"name": "act_friends", "icon": Icons.group_rounded},
      {"name": "act_dating", "icon": Icons.favorite_rounded},
      {"name": "act_kindness", "icon": Icons.volunteer_activism_rounded},
      {"name": "act_gratitude", "icon": Icons.flag_rounded},
    ],
    "cat_rest": [
      {"name": "act_gaming", "icon": Icons.sports_esports_rounded},
      {"name": "act_reading", "icon": Icons.menu_book_rounded},
      {"name": "act_cinema", "icon": Icons.movie_rounded},
      {"name": "act_walking", "icon": Icons.directions_walk_rounded},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: categories.entries.map((category) {
        final customsForCat = customOptions
            .where((o) => o.categoryKey == category.key)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                _getCategoryLabel(context, category.key),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.7,
                      ),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...category.value.map((activity) {
                  final String name = activity['name'] as String;
                  final IconData icon = activity['icon'] as IconData;
                  final isSelected = selectedActivities.contains(name);
                  final colorScheme = Theme.of(context).colorScheme;

                  final isGratitude = name == MindActivityTokens.gratitudeToken;
                  final accent = isGratitude ? _gratitudeAccent : colorScheme.primary;

                  return GestureDetector(
                    onTap: () => onActivityToggled(name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withValues(alpha: isGratitude ? 0.22 : 0.15)
                            : isGratitude
                                ? accent.withValues(alpha: 0.1)
                                : colorScheme.surfaceContainerHighest.withValues(
                                    alpha: 0.3,
                                  ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : isGratitude
                                  ? accent.withValues(alpha: 0.55)
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                          width: isGratitude ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected
                                ? accent
                                : isGratitude
                                    ? accent
                                    : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            MindActivityTokens.presetLabel(l10n, name),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? accent
                                  : isGratitude
                                      ? accent
                                      : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected || isGratitude
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                ...customsForCat.map((o) {
                  final token = MindActivityTokens.refToken(o.id);
                  final isSelected =
                      selectedActivities.contains(token);
                  final colorScheme = Theme.of(context).colorScheme;
                  return GestureDetector(
                    onTap: () => onActivityToggled(token),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.3,
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            o.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Builder(
                  builder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return GestureDetector(
                      onTap: () => onAddCustomOption(category.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.25,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                colorScheme.outlineVariant.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.mind_activity_custom_chip,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (category.key == 'cat_social' && gratitudePicker != null)
              gratitudePicker!,
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  String _getCategoryLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case "cat_productivity":
        return l10n.cat_productivity;
      case "cat_health":
        return l10n.cat_health;
      case "cat_social":
        return l10n.cat_social;
      case "cat_rest":
        return l10n.cat_rest;
      default:
        return key;
    }
  }
}
