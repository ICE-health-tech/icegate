import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class ActivitySelector extends StatelessWidget {
  final List<String> selectedActivities;
  final Function(String) onActivityToggled;

  const ActivitySelector({
    super.key,
    required this.selectedActivities,
    required this.onActivityToggled,
  });

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
    return Column(
      children: categories.entries.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                _getCategoryLabel(context, category.key),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.value.map((activity) {
                final String name = activity['name'];
                final IconData icon = activity['icon'];
                final isSelected = selectedActivities.contains(name);
                final colorScheme = Theme.of(context).colorScheme;

                return GestureDetector(
                  onTap: () => onActivityToggled(name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getActivityLabel(context, name),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  String _getCategoryLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case "cat_productivity": return l10n.cat_productivity;
      case "cat_health": return l10n.cat_health;
      case "cat_social": return l10n.cat_social;
      case "cat_rest": return l10n.cat_rest;
      default: return key;
    }
  }

  String _getActivityLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case "act_deep_work": return l10n.act_deep_work;
      case "act_learning": return l10n.act_learning;
      case "act_finance": return l10n.act_finance;
      case "act_planning": return l10n.act_planning;
      case "act_exercise": return l10n.act_exercise;
      case "act_meditation": return l10n.act_meditation;
      case "act_healthy_meal": return l10n.act_healthy_meal;
      case "act_great_sleep": return l10n.act_great_sleep;
      case "act_family": return l10n.act_family;
      case "act_friends": return l10n.act_friends;
      case "act_dating": return l10n.act_dating;
      case "act_kindness": return l10n.act_kindness;
      case "act_gaming": return l10n.act_gaming;
      case "act_reading": return l10n.act_reading;
      case "act_cinema": return l10n.act_cinema;
      case "act_walking": return l10n.act_walking;
      default: return key;
    }
  }
}
