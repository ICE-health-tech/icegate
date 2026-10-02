import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PulseFeedBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Home-page card showing the last 5 activity events as a live pulse feed.
///
/// Design intent (AdSMind / Play layer):
///   - Ambient: always shows something when the user opens the app again.
///   - Variable reward: bonus items are visually distinct (glow color, badge).
///   - Non-intrusive: hidden when empty, max 5 rows.
class PulseFeedCard extends StatelessWidget {
  const PulseFeedCard({super.key});

  static const _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final block = context.read<PulseFeedBlock>();

    return Watch((context) {
      final items = block.feed.value;
      if (items.isEmpty) return const SizedBox.shrink();

      final visible = items.take(_maxVisible).toList();
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header label
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 15, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'PULSE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                ],
              ),
            ),

            // Feed container
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < visible.length; i++) ...[
                    _PulseRow(
                      item: visible[i],
                      isLast: i == visible.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({required this.item, required this.isLast});

  final PulseFeedItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bonusColor = colorScheme.tertiary;
    final textColor = item.isBonus
        ? bonusColor
        : colorScheme.onSurface.withValues(alpha: 0.78);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.isBonus
                      ? bonusColor.withValues(alpha: 0.15)
                      : colorScheme.primaryContainer.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(item.type),
                  size: 15,
                  color: item.isBonus ? bonusColor : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textColor,
                            fontWeight: item.isBonus
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.isBonus || item.subtitle != null)
                      Text(
                        item.isBonus
                            ? (item.bonusLabel ?? item.subtitle ?? '')
                            : item.subtitle!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: item.isBonus
                                  ? bonusColor.withValues(alpha: 0.75)
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.42),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Relative timestamp
              Text(
                _relativeTime(item.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.32),
                    ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  IconData _iconFor(PulseEventType type) => switch (type) {
        PulseEventType.questCompleted => Icons.check_circle_outline_rounded,
        PulseEventType.moodLogged => Icons.sentiment_satisfied_alt_rounded,
        PulseEventType.focusSessionDone => Icons.timer_rounded,
        PulseEventType.streakMilestone => Icons.local_fire_department_rounded,
        PulseEventType.musicSuggestion => Icons.music_note_rounded,
      };

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
