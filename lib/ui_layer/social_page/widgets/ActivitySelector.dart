import 'package:flutter/material.dart';

class ActivitySelector extends StatelessWidget {
  final List<String> selectedActivities;
  final Function(String) onActivityToggled;

  const ActivitySelector({
    super.key,
    required this.selectedActivities,
    required this.onActivityToggled,
  });

  static const Map<String, List<Map<String, dynamic>>> categories = {
    "Productivity": [
      {"name": "Deep Work", "icon": Icons.psychology_rounded},
      {"name": "Learning", "icon": Icons.local_library_rounded},
      {"name": "Finance", "icon": Icons.payments_rounded},
      {"name": "Planning", "icon": Icons.event_note_rounded},
    ],
    "Health": [
      {"name": "Exercise", "icon": Icons.fitness_center_rounded},
      {"name": "Meditation", "icon": Icons.self_improvement_rounded},
      {"name": "Healthy Meal", "icon": Icons.restaurant_rounded},
      {"name": "Great Sleep", "icon": Icons.bedtime_rounded},
    ],
    "Social": [
      {"name": "Family", "icon": Icons.family_restroom_rounded},
      {"name": "Friends", "icon": Icons.group_rounded},
      {"name": "Dating", "icon": Icons.favorite_rounded},
      {"name": "Kindness", "icon": Icons.volunteer_activism_rounded},
    ],
    "Rest": [
      {"name": "Gaming", "icon": Icons.sports_esports_rounded},
      {"name": "Reading", "icon": Icons.menu_book_rounded},
      {"name": "Cinema", "icon": Icons.movie_rounded},
      {"name": "Walking", "icon": Icons.directions_walk_rounded},
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
                category.key,
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
                          : colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
                          name,
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
}
