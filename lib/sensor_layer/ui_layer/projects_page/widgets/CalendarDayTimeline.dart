import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Column placement for a timed entry when multiple events overlap.
class _TimedEventLayout {
  const _TimedEventLayout({
    required this.entry,
    required this.column,
    required this.columnCount,
  });

  final CalendarTimelineEntry entry;
  final int column;
  final int columnCount;
}

/// One block on the daily timeline.
class CalendarTimelineEntry {
  const CalendarTimelineEntry({
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final Color color;
  final String? subtitle;

  /// Tap the event block (opens modify / delete sheet from parent).
  final VoidCallback? onTap;
}

/// Hour grid for a single day — calendar events and reminders by time.
class CalendarDayTimeline extends StatelessWidget {
  const CalendarDayTimeline({
    super.key,
    required this.entries,
    required this.selectedDay,
    this.onHourTap,
    this.startHour = 6,
    this.endHour = 23,
    this.hourHeight = 44,
  });

  final List<CalendarTimelineEntry> entries;
  final DateTime selectedDay;

  /// Tap an empty hour row → add event at that hour on [selectedDay].
  final void Function(int hour)? onHourTap;
  final int startHour;
  final int endHour;
  final double hourHeight;

  static const _labelWidth = 52.0;
  static const _laneInset = 8.0;
  static const _laneRightPadding = 8.0;
  static const _columnGap = 3.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final timeFmt = DateFormat.jm(locale);

    final allDay = entries.where((e) => e.allDay).toList();
    final timedLayouts = _layoutOverlappingTimed(
      entries.where((e) => !e.allDay).toList(),
    );

    final hourCount = endHour - startHour + 1;
    final gridHeight = hourCount * hourHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allDay.isNotEmpty) ...[
          _allDayStrip(context, l10n, allDay),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: gridHeight.clamp(280, 720),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: gridHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final laneWidth = constraints.maxWidth -
                          _labelWidth -
                          4 -
                          _laneRightPadding;
                      return Stack(
                        children: [
                          ...List.generate(hourCount, (i) {
                            final hour = startHour + i;
                            final top = i * hourHeight;
                            return Positioned(
                              top: top,
                              left: 0,
                              right: 0,
                              height: hourHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: _labelWidth,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4,
                                        right: 6,
                                      ),
                                      child: Text(
                                        timeFmt.format(
                                          DateTime(2000, 1, 1, hour),
                                        ),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: onHourTap == null
                                            ? null
                                            : () => onHourTap!(hour),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: cs.outlineVariant
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          ...timedLayouts.map(
                            (layout) => _positionedBlock(
                              context,
                              layout,
                              timeFmt,
                              laneWidth: laneWidth,
                            ),
                          ),
                          if (timedLayouts.isEmpty && allDay.isEmpty)
                            Positioned.fill(
                              left: _labelWidth,
                              child: Center(
                                child: Text(
                                  l10n.projects_calendar_timeline_empty,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _allDayStrip(
    BuildContext context,
    AppLocalizations l10n,
    List<CalendarTimelineEntry> allDay,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.projects_calendar_all_day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: allDay
              .map((e) => _allDayChip(context, cs, e))
              .toList(),
        ),
      ],
    );
  }

  Widget _allDayChip(
    BuildContext context,
    ColorScheme cs,
    CalendarTimelineEntry e,
  ) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: e.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: e.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        e.title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
    if (e.onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: e.onTap,
        child: chip,
      ),
    );
  }

  static DateTime _eventEnd(CalendarTimelineEntry e) =>
      e.end ?? e.start.add(const Duration(hours: 1));

  static bool _eventsOverlap(CalendarTimelineEntry a, CalendarTimelineEntry b) {
    final aEnd = _eventEnd(a);
    final bEnd = _eventEnd(b);
    return a.start.isBefore(bEnd) && aEnd.isAfter(b.start);
  }

  /// Groups events that overlap directly or transitively (A–B–C chain).
  static List<List<CalendarTimelineEntry>> _overlapGroups(
    List<CalendarTimelineEntry> events,
  ) {
    var groups = events.map((e) => [e]).toList();
    var merged = true;
    while (merged) {
      merged = false;
      for (var i = 0; i < groups.length; i++) {
        for (var j = i + 1; j < groups.length; j++) {
          final overlaps = groups[i].any(
            (a) => groups[j].any((b) => _eventsOverlap(a, b)),
          );
          if (overlaps) {
            groups[i] = [...groups[i], ...groups[j]];
            groups.removeAt(j);
            merged = true;
            break;
          }
        }
        if (merged) break;
      }
    }
    return groups;
  }

  /// Greedy column assignment within each overlap group (calendar-style lanes).
  static List<_TimedEventLayout> _layoutOverlappingTimed(
    List<CalendarTimelineEntry> timed,
  ) {
    if (timed.isEmpty) return [];

    final layouts = <_TimedEventLayout>[];
    for (final group in _overlapGroups(timed)) {
      final sorted = List<CalendarTimelineEntry>.from(group)
        ..sort((a, b) {
          final byStart = a.start.compareTo(b.start);
          if (byStart != 0) return byStart;
          return _eventEnd(b).compareTo(_eventEnd(a));
        });

      final columnEnds = <DateTime>[];
      final placements = <({CalendarTimelineEntry entry, int column})>[];

      for (final e in sorted) {
        final eEnd = _eventEnd(e);
        var column = 0;
        for (; column < columnEnds.length; column++) {
          if (!e.start.isBefore(columnEnds[column])) break;
        }
        if (column == columnEnds.length) {
          columnEnds.add(eEnd);
        } else {
          columnEnds[column] = eEnd;
        }
        placements.add((entry: e, column: column));
      }

      final columnCount = columnEnds.length.clamp(1, placements.length);
      for (final p in placements) {
        layouts.add(
          _TimedEventLayout(
            entry: p.entry,
            column: p.column,
            columnCount: columnCount,
          ),
        );
      }
    }

    layouts.sort((a, b) => a.entry.start.compareTo(b.entry.start));
    return layouts;
  }

  Widget _positionedBlock(
    BuildContext context,
    _TimedEventLayout layout,
    DateFormat timeFmt, {
    required double laneWidth,
  }) {
    final e = layout.entry;
    final cs = Theme.of(context).colorScheme;
    final dayStart = DateTime(e.start.year, e.start.month, e.start.day);
    final startMin = e.start.difference(dayStart).inMinutes.toDouble();
    final endLocal = _eventEnd(e);
    var endMin = endLocal.difference(dayStart).inMinutes.toDouble();
    if (endMin <= startMin) endMin = startMin + 30;

    final gridStartMin = startHour * 60.0;
    final gridEndMin = (endHour + 1) * 60.0;
    final visibleStart = startMin.clamp(gridStartMin, gridEndMin);
    final visibleEnd = endMin.clamp(visibleStart + 15, gridEndMin);

    if (visibleStart >= gridEndMin || visibleEnd <= gridStartMin) {
      return const SizedBox.shrink();
    }

    final top =
        ((visibleStart - gridStartMin) / 60.0) * hourHeight + _laneInset / 2;
    final height = ((visibleEnd - visibleStart) / 60.0) * hourHeight - _laneInset;
    final minHeight = 28.0;

    final columns = layout.columnCount.clamp(1, 6);
    final column = layout.column.clamp(0, columns - 1);
    final totalGap = _columnGap * (columns - 1);
    final columnWidth = ((laneWidth - totalGap) / columns).clamp(24.0, laneWidth);
    final blockLeft = _labelWidth + 4 + column * (columnWidth + _columnGap);
    final blockHeight = height.clamp(minHeight, 200).toDouble();
    final narrow = columns > 1 || columnWidth < 100;
    final showTime = !narrow && blockHeight >= 40;
    final titleMaxLines = narrow ? 3 : 2;
    final horizontalPad = narrow ? 5.0 : 8.0;

    final blockBody = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: e.color.withValues(alpha: 0.45)),
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  e.title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: narrow ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            if (showTime)
              Text(
                '${timeFmt.format(e.start)}${e.end != null ? ' – ${timeFmt.format(e.end!)}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
          ],
        ),
      ),
    );

    return Positioned(
      top: top,
      left: blockLeft,
      width: columnWidth,
      height: blockHeight,
      child: Material(
        color: e.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        child: e.onTap == null
            ? blockBody
            : InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: e.onTap,
                child: blockBody,
              ),
      ),
    );
  }
}
