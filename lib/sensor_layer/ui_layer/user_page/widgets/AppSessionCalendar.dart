import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppSessionCalendar extends StatelessWidget {
  const AppSessionCalendar({
    super.key,
    required this.markedDays,
    required this.focusedMonth,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final Set<DateTime> markedDays;
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leadingEmpty = monthStart.weekday - 1;
    final today = _dateOnly(DateTime.now());
    final selected = _dateOnly(selectedDay);
    final weekdayLabels = MaterialLocalizations.of(context).narrowWeekdays;
    final mondayFirstLabels = [
      ...weekdayLabels.sublist(1),
      weekdayLabels.first,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(monthStart),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: mondayFirstLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();

              final day = index - leadingEmpty + 1;
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final hasUsage = markedDays.contains(_dateOnly(date));
              final isToday = _dateOnly(date) == today;
              final isSelected = _dateOnly(date) == selected;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onDaySelected(date),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : (hasUsage
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? Border.all(color: colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(
                                  alpha: hasUsage ? 0.95 : 0.45,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
