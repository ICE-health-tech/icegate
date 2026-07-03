import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/CalendarEventEnvironment.dart';
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

/// Payload while dragging a movable timeline block (reserved for future use).
class CalendarTimelineDragPayload {
  const CalendarTimelineDragPayload({
    required this.entry,
    required this.durationMinutes,
    required this.originalStartMinutes,
    required this.anchorDy,
  });

  final CalendarTimelineEntry entry;
  final int durationMinutes;

  /// Minutes from midnight on [CalendarDayTimeline.selectedDay] before drag.
  final int originalStartMinutes;

  /// Where the pointer grabbed within the block (top = 0).
  final double anchorDy;
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
    this.canMove = false,
    this.onMoved,
  });

  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final Color color;
  final String? subtitle;

  /// Tap the event block (opens modify / delete sheet from parent).
  final VoidCallback? onTap;

  /// Press-and-hold (or mouse drag after hold) to reschedule on another slot.
  final bool canMove;
  final Future<void> Function(DateTime newStart, DateTime newEnd)? onMoved;
}

/// Close [dialogContext] first, then run [action] on the next frame (avoids
/// Navigator `!_debugLocked` when chaining pop + push).
void calendarTimelineAfterDialogClose(
  BuildContext dialogContext,
  VoidCallback action,
) {
  Navigator.of(dialogContext).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) => action());
}

double _safeClamp(double value, double min, double max) {
  if (min > max) return min;
  return value.clamp(min, max);
}

/// Detail sheet when the user taps a timeline event block.
Future<void> showCalendarTimelineEventDetailSheet(
  BuildContext context, {
  required String title,
  required DateTime start,
  DateTime? end,
  required Color accentColor,
  String? sourceLabel,
  String? description,
  bool allDay = false,
  required bool canEdit,
  required bool canDelete,
  VoidCallback? onEdit,
  Future<void> Function()? onDelete,
  CalendarEnvironmentAssessment? environment,
  VoidCallback? onStartFocus,
}) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toString();
  final timeFmt = DateFormat.jm(locale);
  final dateFmt = DateFormat.yMMMd(locale);
  final timeLabel = allDay
      ? l10n.projects_calendar_all_day
      : end != null
          ? '${timeFmt.format(start)} – ${timeFmt.format(end)}'
          : timeFmt.format(start);
  final trimmedDescription = description?.trim();
  final trimmedSource = sourceLabel?.trim();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      final cs = Theme.of(ctx).colorScheme;
      final focusAction = onStartFocus;
      final startFocusAction = focusAction == null
          ? null
          : () => calendarTimelineAfterDialogClose(ctx, focusAction);
      final size = MediaQuery.sizeOf(ctx);
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      final isWide = size.width >= 900;
      final cardWidth = isWide
          ? (size.width * 0.42).clamp(380.0, 560.0)
          : size.width * 0.94;
      final cardHeight = isWide
          ? (size.height * 0.68).clamp(440.0, 720.0)
          : (size.height * 0.78).clamp(420.0, 720.0);

      Widget panel = DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.38),
                      ),
                    ),
                    child: Icon(
                      Icons.event_rounded,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFmt.format(start),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TimelineDetailChip(
                    icon: Icons.schedule_rounded,
                    label: timeLabel,
                    accent: accentColor,
                  ),
                  if (trimmedSource != null && trimmedSource.isNotEmpty)
                    _TimelineDetailChip(
                      icon: Icons.calendar_month_outlined,
                      label: trimmedSource,
                      accent: cs.primary,
                    ),
                ],
              ),
            ),
            if (environment != null && !allDay)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: _EnvironmentReadinessCard(
                  assessment: environment,
                  accent: accentColor,
                  onStartFocus: startFocusAction,
                ),
              ),
            if (trimmedDescription != null && trimmedDescription.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.55),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 22,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              trimmedDescription,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: cs.onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + bottomInset),
              child: Row(
                children: [
                  if (canEdit && onEdit != null)
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: cs.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () =>
                            calendarTimelineAfterDialogClose(ctx, onEdit),
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        label: Text(l10n.projects_calendar_edit_event),
                      ),
                    ),
                  if (canEdit &&
                      onEdit != null &&
                      canDelete &&
                      onDelete != null)
                    const SizedBox(width: 12),
                  if (canDelete && onDelete != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(
                            color: cs.error.withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: ctx,
                            useRootNavigator: true,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text(l10n.projects_calendar_delete_event),
                              content: Text(
                                l10n.projects_calendar_timeline_remove_confirm(
                                  title,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, false),
                                  child: Text(l10n.cancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, true),
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          );
                          if (ok != true || !ctx.mounted) return;
                          Navigator.pop(ctx);
                          await onDelete();
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.delete),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            Align(
              alignment: isWide ? const Alignment(0.58, 0.0) : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 20 : 12,
                  isWide ? 64 : 16,
                  isWide ? 20 : 12,
                  isWide ? 40 : 16,
                ),
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: panel,
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curve),
          child: child,
        ),
      );
    },
  );
}

/// Parses calendar list subtitles like `Work · 6:30 PM` into a source label.
String? calendarTimelineSourceLabel(
  String? subtitle,
  DateTime start,
  String locale,
) {
  final text = subtitle?.trim();
  if (text == null || text.isEmpty) return null;
  if (text.contains(' · ')) return text.split(' · ').first.trim();

  final timeOnly = DateFormat.jm(locale).format(start);
  if (text == timeOnly) return null;
  return text;
}

class _TimelineDetailChip extends StatelessWidget {
  const _TimelineDetailChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.78,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentReadinessCard extends StatelessWidget {
  const _EnvironmentReadinessCard({
    required this.assessment,
    required this.accent,
    this.onStartFocus,
  });

  final CalendarEnvironmentAssessment assessment;
  final Color accent;
  final VoidCallback? onStartFocus;

  String _summary(AppLocalizations l10n) {
    return switch (assessment.level) {
      CalendarEnvironmentLevel.ready => l10n.projects_calendar_env_ready,
      CalendarEnvironmentLevel.caution => l10n.projects_calendar_env_caution,
      CalendarEnvironmentLevel.notReady => l10n.projects_calendar_env_not_ready,
    };
  }

  Color _levelColor(ColorScheme cs) {
    return switch (assessment.level) {
      CalendarEnvironmentLevel.ready => cs.primary,
      CalendarEnvironmentLevel.caution => cs.tertiary,
      CalendarEnvironmentLevel.notReady => cs.error,
    };
  }

  String _factorLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'past' => l10n.projects_calendar_env_past,
      'too_early' => l10n.projects_calendar_env_too_early,
      'starting_soon' => l10n.projects_calendar_env_starting_soon,
      'low_mood' => l10n.projects_calendar_env_low_mood,
      'neutral_mood' => l10n.projects_calendar_env_neutral_mood,
      'good_mood' => l10n.projects_calendar_env_good_mood,
      'no_mood' => l10n.projects_calendar_env_no_mood,
      'heavy_overlap' => l10n.projects_calendar_env_heavy_overlap,
      'some_overlap' => l10n.projects_calendar_env_some_overlap,
      'focus_fatigue' => l10n.projects_calendar_env_focus_fatigue,
      'low_sleep' => l10n.projects_calendar_env_low_sleep,
      'good_sleep' => l10n.projects_calendar_env_good_sleep,
      _ => id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final levelColor = _levelColor(cs);
    final negatives = assessment.factors.where((f) => f.impact < 0).toList();
    final positives = assessment.factors.where((f) => f.impact > 0).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, size: 18, color: levelColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.projects_calendar_env_title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                l10n.projects_calendar_env_score(assessment.score),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: levelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _summary(l10n),
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: cs.onSurface.withValues(alpha: 0.78),
            ),
          ),
          if (negatives.isNotEmpty || positives.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in negatives)
                  _TimelineDetailChip(
                    icon: Icons.remove_circle_outline,
                    label: _factorLabel(l10n, f.id),
                    accent: cs.error,
                  ),
                for (final f in positives)
                  _TimelineDetailChip(
                    icon: Icons.add_circle_outline,
                    label: _factorLabel(l10n, f.id),
                    accent: cs.primary,
                  ),
              ],
            ),
          ],
          if (onStartFocus != null &&
              assessment.level != CalendarEnvironmentLevel.notReady) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onStartFocus,
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: Text(l10n.projects_calendar_env_start_focus),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hour grid for a single day — calendar events and reminders by time.
///
/// Intentionally not scrollable: parent [ProjectsCalendarPage] owns the
/// single page scroll to avoid nested scroll overlap on mobile.
class CalendarDayTimeline extends StatefulWidget {
  const CalendarDayTimeline({
    super.key,
    required this.entries,
    required this.selectedDay,
    this.onHourTap,
    this.onDragActiveChanged,
    this.scrollController,
    this.startHour = 6,
    this.endHour = 23,
    this.hourHeight = 44,
  });

  final List<CalendarTimelineEntry> entries;
  final DateTime selectedDay;

  /// Tap an empty hour row → add event at that hour on [selectedDay].
  final void Function(int hour)? onHourTap;

  /// Parent can lock page scroll while a block is being dragged.
  final ValueChanged<bool>? onDragActiveChanged;

  /// Optional page scroll controller for edge auto-scroll during drag.
  final ScrollController? scrollController;
  final int startHour;
  final int endHour;
  final double hourHeight;

  static const dragLongPressDelay = Duration(milliseconds: 150);

  @override
  State<CalendarDayTimeline> createState() => _CalendarDayTimelineState();
}

class _CalendarDayTimelineState extends State<CalendarDayTimeline> {
  static const _labelWidth = 52.0;
  static const _laneInset = 8.0;
  static const _laneRightPadding = 8.0;
  static const _columnGap = 3.0;
  static const _snapMinutes = 15;
  static const _autoScrollEdge = 72.0;
  static const _autoScrollStep = 14.0;

  final _laneKey = GlobalKey();
  final _dragFocusNode = FocusNode();

  bool _dragActive = false;
  int? _dropSnapMinutes;
  int _dragDurationMinutes = 60;
  int _dragOriginalStartMinutes = 0;
  int _dragVisibleStartHour = 8;
  double _dragAnchorDy = 0;
  CalendarTimelineEntry? _draggingEntry;
  String? _draggingKey;

  String _entryKey(CalendarTimelineEntry e) =>
      '${e.title}|${e.start.millisecondsSinceEpoch}';

  @override
  void dispose() {
    _dragFocusNode.dispose();
    super.dispose();
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  ({int start, int end}) _visibleHourRange() {
    final timed = widget.entries.where((e) => !e.allDay).toList();
    final hours = <int>[];

    for (final entry in timed) {
      hours.add(entry.start.hour);
      final end = _eventEnd(entry);
      hours.add(end.hour);
    }

    if (_isToday(widget.selectedDay)) {
      hours.add(DateTime.now().hour);
    }

    if (hours.isEmpty) {
      return (start: 8, end: 20);
    }

    final minHour = hours.reduce((a, b) => a < b ? a : b);
    final maxHour = hours.reduce((a, b) => a > b ? a : b);
    return (
      start: (minHour - 1).clamp(widget.startHour, 22),
      end: (maxHour + 1).clamp(9, widget.endHour),
    );
  }

  static DateTime _eventEnd(CalendarTimelineEntry e) =>
      e.end ?? e.start.add(const Duration(hours: 1));

  bool _prefersImmediateDrag(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 600) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        true,
      _ => false,
    };
  }

  int _minutesFromMidnight(DateTime time) =>
      time.hour * 60 + time.minute;

  int _snapMinutesFromDy(
    double dy,
    int visibleStartHour, {
    required double anchorDy,
  }) {
    final gridStartMin = visibleStartHour * 60.0;
    final blockTopDy = (dy - anchorDy).clamp(0.0, double.infinity);
    final raw = gridStartMin + (blockTopDy / widget.hourHeight) * 60.0;
    final snapped = (raw / _snapMinutes).round() * _snapMinutes;
    final minStart = visibleStartHour * 60;
    final maxStart = widget.endHour * 60 + 45 - _dragDurationMinutes;
    final upper = math.max(minStart, maxStart);
    return snapped.clamp(minStart, upper);
  }

  void _beginDrag({
    required CalendarTimelineEntry entry,
    required int durationMinutes,
    required double anchorDy,
    required int initialSnapMinutes,
    required int visibleStartHour,
  }) {
    HapticFeedback.selectionClick();
    final wasActive = _dragActive;
    setState(() {
      _dragActive = true;
      _draggingEntry = entry;
      _draggingKey = _entryKey(entry);
      _dragDurationMinutes = durationMinutes;
      _dragAnchorDy = anchorDy;
      _dropSnapMinutes = initialSnapMinutes;
      _dragOriginalStartMinutes = initialSnapMinutes;
      _dragVisibleStartHour = visibleStartHour;
    });
    if (!wasActive) widget.onDragActiveChanged?.call(true);
    _dragFocusNode.requestFocus();
  }

  void _handleDragMove(Offset globalPosition) {
    if (!_dragActive) return;
    final box = _laneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _autoScrollForGlobalDy(globalPosition.dy);
    final local = box.globalToLocal(globalPosition);
    final snap = _snapMinutesFromDy(
      local.dy,
      _dragVisibleStartHour,
      anchorDy: _dragAnchorDy,
    );
    _updateDropSnap(snap);
  }

  Future<void> _finishDrag() async {
    if (!_dragActive) return;
    await _commitDrop();
  }

  void _nudgeSnap(int deltaMinutes) {
    final current = _dropSnapMinutes;
    if (current == null) return;
    final range = _visibleHourRange();
    final minStart = range.start * 60;
    final maxStart = widget.endHour * 60 + 45 - _dragDurationMinutes;
    final upper = math.max(minStart, maxStart);
    final next = (current + deltaMinutes).clamp(minStart, upper);
    if (next == current) return;
    HapticFeedback.selectionClick();
    setState(() => _dropSnapMinutes = next);
  }

  Future<void> _commitDrop() async {
    final snap = _dropSnapMinutes;
    final entry = _draggingEntry;
    final onMoved = entry?.onMoved;
    final original = _dragOriginalStartMinutes;
    final duration = _dragDurationMinutes;
    _clearDragState();
    if (snap == null || onMoved == null || entry == null) return;
    if (snap == original) return;

    final day = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
    );
    final newStart = day.add(Duration(minutes: snap));
    final newEnd = newStart.add(Duration(minutes: duration));
    await onMoved(newStart, newEnd);
  }

  KeyEventResult _handleDragKey(FocusNode node, KeyEvent event) {
    if (!_dragActive || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _nudgeSnap(-_snapMinutes);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _nudgeSnap(_snapMinutes);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      unawaited(_commitDrop());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _clearDragState();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _updateDropSnap(int snap) {
    if (snap == _dropSnapMinutes) return;
    setState(() => _dropSnapMinutes = snap);
  }

  void _autoScrollForGlobalDy(double globalDy) {
    final scroll = widget.scrollController;
    if (scroll == null || !scroll.hasClients) return;

    final height = MediaQuery.sizeOf(context).height;
    if (globalDy < _autoScrollEdge) {
      final next = (scroll.offset - _autoScrollStep).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      );
      if (next != scroll.offset) scroll.jumpTo(next);
    } else if (globalDy > height - _autoScrollEdge) {
      final next = (scroll.offset + _autoScrollStep).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      );
      if (next != scroll.offset) scroll.jumpTo(next);
    }
  }

  void _clearDragState() {
    if (!_dragActive && _dropSnapMinutes == null) return;
    final wasActive = _dragActive;
    setState(() {
      _dragActive = false;
      _dropSnapMinutes = null;
      _dragAnchorDy = 0;
      _draggingEntry = null;
      _draggingKey = null;
    });
    if (wasActive) widget.onDragActiveChanged?.call(false);
  }

  Widget _buildDragPreview(
    BuildContext context, {
    required AppLocalizations l10n,
    required int visibleStartHour,
    required double gridHeight,
    required double laneWidth,
    required DateFormat timeFmt,
  }) {
    if (!_dragActive || _dropSnapMinutes == null || _draggingEntry == null) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final entry = _draggingEntry!;
    final snapMinutes = _dropSnapMinutes!;
    final animDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    final day = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
    );
    final dropStart = day.add(Duration(minutes: snapMinutes));
    final dropEnd = dropStart.add(Duration(minutes: _dragDurationMinutes));
    final timeRange =
        '${timeFmt.format(dropStart)} – ${timeFmt.format(dropEnd)}';

    return Positioned(
      left: 0,
      right: _laneRightPadding,
      top: 0,
      height: gridHeight,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: _labelWidth + 4,
              right: 0,
              top: 0,
              height: gridHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.04),
                ),
              ),
            ),
            _buildTargetHourBand(
              cs,
              entry: entry,
              visibleStartHour: visibleStartHour,
              snapMinutes: snapMinutes,
              durationMinutes: _dragDurationMinutes,
              animDuration: animDuration,
            ),
            _buildTargetSnapLines(
              cs,
              entry: entry,
              visibleStartHour: visibleStartHour,
              snapMinutes: snapMinutes,
              durationMinutes: _dragDurationMinutes,
              laneWidth: laneWidth,
              animDuration: animDuration,
            ),
            _buildDropIndicator(
              cs,
              entry: entry,
              timeFmt: timeFmt,
              visibleStartHour: visibleStartHour,
              snapMinutes: snapMinutes,
              durationMinutes: _dragDurationMinutes,
              laneWidth: laneWidth,
              animDuration: animDuration,
            ),
            _buildTargetTimeBadge(
              l10n: l10n,
              cs: cs,
              entry: entry,
              timeRange: timeRange,
              visibleStartHour: visibleStartHour,
              snapMinutes: snapMinutes,
              gridHeight: gridHeight,
              animDuration: animDuration,
            ),
            _buildTargetGutterTime(
              cs,
              entry: entry,
              timeFmt: timeFmt,
              dropStart: dropStart,
              visibleStartHour: visibleStartHour,
              snapMinutes: snapMinutes,
              animDuration: animDuration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetHourBand(
    ColorScheme cs, {
    required CalendarTimelineEntry entry,
    required int visibleStartHour,
    required int snapMinutes,
    required int durationMinutes,
    required Duration animDuration,
  }) {
    final gridStartMin = visibleStartHour * 60.0;
    final top =
        ((snapMinutes - gridStartMin) / 60.0) * widget.hourHeight;
    final height = (durationMinutes / 60.0) * widget.hourHeight;

    return AnimatedPositioned(
      duration: animDuration,
      curve: Curves.easeOutCubic,
      top: top.clamp(0, double.infinity),
      left: _labelWidth + 4,
      right: 0,
      height: height.clamp(widget.hourHeight * 0.5, double.infinity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: 0.08),
          border: Border.symmetric(
            horizontal: BorderSide(
              color: entry.color.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetSnapLines(
    ColorScheme cs, {
    required CalendarTimelineEntry entry,
    required int visibleStartHour,
    required int snapMinutes,
    required int durationMinutes,
    required double laneWidth,
    required Duration animDuration,
  }) {
    final gridStartMin = visibleStartHour * 60.0;
    final startTop =
        ((snapMinutes - gridStartMin) / 60.0) * widget.hourHeight + _laneInset / 2;
    final blockHeight =
        (durationMinutes / 60.0) * widget.hourHeight - _laneInset;
    final endTop = startTop + blockHeight.clamp(28, 200);

    Widget line(Color color, {bool dashed = false}) {
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 2),
            ),
          ),
          Expanded(
            child: dashed
                ? CustomPaint(
                    painter: _DashedLinePainter(color: color),
                    size: const Size(double.infinity, 2),
                  )
                : Container(height: 2, color: color),
          ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned(
          duration: animDuration,
          curve: Curves.easeOutCubic,
          top: startTop,
          left: _labelWidth + 4,
          width: laneWidth,
          child: line(entry.color),
        ),
        AnimatedPositioned(
          duration: animDuration,
          curve: Curves.easeOutCubic,
          top: endTop,
          left: _labelWidth + 4,
          width: laneWidth,
          child: line(entry.color.withValues(alpha: 0.55), dashed: true),
        ),
      ],
    );
  }

  Widget _buildTargetTimeBadge({
    required AppLocalizations l10n,
    required ColorScheme cs,
    required CalendarTimelineEntry entry,
    required String timeRange,
    required int visibleStartHour,
    required int snapMinutes,
    required double gridHeight,
    required Duration animDuration,
  }) {
    final gridStartMin = visibleStartHour * 60.0;
    final blockTop =
        ((snapMinutes - gridStartMin) / 60.0) * widget.hourHeight + _laneInset / 2;
    final badgeTop = _safeClamp(blockTop - 34, 4.0, math.max(4.0, gridHeight - 36));

    return AnimatedPositioned(
      duration: animDuration,
      curve: Curves.easeOutCubic,
      top: badgeTop,
      left: _labelWidth + 8,
      right: 8,
      child: Material(
        elevation: 6,
        shadowColor: entry.color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        color: cs.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: entry.color.withValues(alpha: 0.85),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: entry.color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.projects_calendar_drag_move_to(timeRange),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetGutterTime(
    ColorScheme cs, {
    required CalendarTimelineEntry entry,
    required DateFormat timeFmt,
    required DateTime dropStart,
    required int visibleStartHour,
    required int snapMinutes,
    required Duration animDuration,
  }) {
    final gridStartMin = visibleStartHour * 60.0;
    final top =
        ((snapMinutes - gridStartMin) / 60.0) * widget.hourHeight + 2;

    return AnimatedPositioned(
      duration: animDuration,
      curve: Curves.easeOutCubic,
      top: top.clamp(0, double.infinity),
      left: 4,
      width: _labelWidth - 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          timeFmt.format(dropStart),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: cs.surface,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final timeFmt = DateFormat.jm(locale);

    final range = _visibleHourRange();
    final visibleStartHour = range.start;
    final visibleEndHour = range.end;

    final allDay = widget.entries.where((e) => e.allDay).toList();
    final timedLayouts = _layoutOverlappingTimed(
      widget.entries.where((e) => !e.allDay).toList(),
    );

    final hourCount = visibleEndHour - visibleStartHour + 1;
    final gridHeight = hourCount * widget.hourHeight;

    return Focus(
      focusNode: _dragFocusNode,
      onKeyEvent: _handleDragKey,
      child: Column(
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
              height: gridHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth -
                      _labelWidth -
                      4 -
                      _laneRightPadding;
                  return Stack(
                    key: _laneKey,
                    children: [
                      ...List.generate(hourCount, (i) {
                        final hour = visibleStartHour + i;
                        final top = i * widget.hourHeight;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: widget.hourHeight,
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
                                    onTap: widget.onHourTap == null
                                        ? null
                                        : () => widget.onHourTap!(hour),
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
                          visibleStartHour: visibleStartHour,
                          visibleEndHour: visibleEndHour,
                          immediateDrag: _prefersImmediateDrag(context),
                        ),
                      ),
                      _buildDragPreview(
                        context,
                        l10n: l10n,
                        visibleStartHour: visibleStartHour,
                        gridHeight: gridHeight,
                        laneWidth: laneWidth,
                        timeFmt: timeFmt,
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
      ],
      ),
    );
  }

  Widget _buildDropIndicator(
    ColorScheme cs, {
    required CalendarTimelineEntry entry,
    required DateFormat timeFmt,
    required int visibleStartHour,
    required int snapMinutes,
    required int durationMinutes,
    required double laneWidth,
    required Duration animDuration,
  }) {
    final gridStartMin = visibleStartHour * 60.0;
    final top =
        ((snapMinutes - gridStartMin) / 60.0) * widget.hourHeight + _laneInset / 2;
    final height = (durationMinutes / 60.0) * widget.hourHeight - _laneInset;
    final day = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
    );
    final dropStart = day.add(Duration(minutes: snapMinutes));
    final dropEnd = dropStart.add(Duration(minutes: durationMinutes));
    final timeRange =
        '${timeFmt.format(dropStart)} – ${timeFmt.format(dropEnd)}';
    final blockHeight = height.clamp(28, 200).toDouble();

    return AnimatedPositioned(
      duration: animDuration,
      curve: Curves.easeOutCubic,
      top: top.clamp(0, double.infinity),
      left: _labelWidth + 4,
      width: laneWidth,
      height: blockHeight,
      child: IgnorePointer(
        child: Material(
          elevation: 4,
          shadowColor: entry.color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          color: entry.color.withValues(alpha: 0.22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: entry.color.withValues(alpha: 0.75),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: entry.color.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          children: allDay.map((e) => _allDayChip(context, cs, e)).toList(),
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

  static bool _eventsOverlap(CalendarTimelineEntry a, CalendarTimelineEntry b) {
    final aEnd = _eventEnd(a);
    final bEnd = _eventEnd(b);
    return a.start.isBefore(bEnd) && aEnd.isAfter(b.start);
  }

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
    required int visibleStartHour,
    required int visibleEndHour,
    required bool immediateDrag,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final e = layout.entry;
    final cs = Theme.of(context).colorScheme;
    final dayStart = DateTime(e.start.year, e.start.month, e.start.day);
    final startMin = e.start.difference(dayStart).inMinutes.toDouble();
    final endLocal = _eventEnd(e);
    var endMin = endLocal.difference(dayStart).inMinutes.toDouble();
    if (endMin <= startMin) endMin = startMin + 30;
    // Timed events past midnight still belong to this day row — cap for layout.
    endMin = math.min(endMin, 24 * 60);

    final gridStartMin = visibleStartHour * 60.0;
    final gridEndMin = (visibleEndHour + 1) * 60.0;
    final visibleStart = _safeClamp(
      startMin,
      gridStartMin,
      math.max(gridStartMin, gridEndMin - 15),
    );
    final visibleEnd = _safeClamp(endMin, visibleStart + 15, gridEndMin);

    if (visibleStart >= gridEndMin || visibleEnd <= gridStartMin) {
      return const SizedBox.shrink();
    }

    final top = ((visibleStart - gridStartMin) / 60.0) * widget.hourHeight +
        _laneInset / 2;
    final height =
        ((visibleEnd - visibleStart) / 60.0) * widget.hourHeight - _laneInset;
    const minHeight = 44.0;

    final columns = layout.columnCount.clamp(1, 6);
    final column = layout.column.clamp(0, columns - 1);
    final totalGap = _columnGap * (columns - 1);
    final columnWidth =
        ((laneWidth - totalGap) / columns).clamp(24.0, laneWidth);
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

    final movable = e.canMove && e.onMoved != null && !e.allDay;
    final durationMinutes = endLocal.difference(e.start).inMinutes.clamp(15, 24 * 60);

    Widget block = Material(
      color: e.color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10),
      child: blockBody,
    );

    final isBeingDragged =
        _dragActive && _draggingKey == _entryKey(e);

    if (movable) {
      final dragHint = immediateDrag
          ? l10n.projects_calendar_drag_hint_desktop
          : l10n.projects_calendar_drag_hint_mobile;
      block = Semantics(
        label: e.title,
        hint: dragHint,
        child: _MovableTimelineBlock(
          immediateDrag: immediateDrag,
          block: isBeingDragged ? _emptySlotPlaceholder(e.color) : block,
          onTap: e.onTap,
          onPressDown: () {
            if (!_dragActive) widget.onDragActiveChanged?.call(true);
          },
          onPressUpWithoutDrag: () {
            if (!_dragActive) widget.onDragActiveChanged?.call(false);
          },
          onDragStarted: (anchorDy) {
            _beginDrag(
              entry: e,
              durationMinutes: durationMinutes,
              anchorDy: anchorDy,
              initialSnapMinutes: _minutesFromMidnight(e.start),
              visibleStartHour: visibleStartHour,
            );
          },
          onDragMove: _handleDragMove,
          onDragFinished: _finishDrag,
          onDragCancelled: _clearDragState,
        ),
      );
    } else if (e.onTap != null) {
      block = Material(
        color: e.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: e.onTap,
          child: blockBody,
        ),
      );
    }

    return Positioned(
      top: top,
      left: blockLeft,
      width: columnWidth,
      height: blockHeight,
      child: block,
    );
  }

  Widget _emptySlotPlaceholder(Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
        color: color.withValues(alpha: 0.04),
      ),
    );
  }
}

class _MovableTimelineBlock extends StatefulWidget {
  const _MovableTimelineBlock({
    required this.immediateDrag,
    required this.block,
    this.onTap,
    required this.onDragStarted,
    required this.onDragMove,
    required this.onDragFinished,
    required this.onDragCancelled,
    this.onPressDown,
    this.onPressUpWithoutDrag,
  });

  final bool immediateDrag;
  final Widget block;
  final VoidCallback? onTap;
  final ValueChanged<double> onDragStarted;
  final ValueChanged<Offset> onDragMove;
  final Future<void> Function() onDragFinished;
  final VoidCallback onDragCancelled;
  final VoidCallback? onPressDown;
  final VoidCallback? onPressUpWithoutDrag;

  @override
  State<_MovableTimelineBlock> createState() => _MovableTimelineBlockState();
}

class _MovableTimelineBlockState extends State<_MovableTimelineBlock> {
  static const _dragThreshold = 4.0;

  bool _dragging = false;
  bool _hovering = false;
  Offset? _pointerDownGlobal;
  double _pointerDownLocalDy = 0;

  Future<void> _endDrag() async {
    if (!_dragging) return;
    _dragging = false;
    await widget.onDragFinished();
  }

  void _resetPointer() {
    _pointerDownGlobal = null;
    _dragging = false;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    if (widget.immediateDrag) {
      return MouseRegion(
        cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: _hovering && !_dragging
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                )
              : null,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _pointerDownGlobal = event.position;
              _pointerDownLocalDy = event.localPosition.dy;
              _dragging = false;
              widget.onPressDown?.call();
            },
            onPointerMove: (event) {
              if (_pointerDownGlobal == null) return;
              if (!_dragging) {
                final delta = event.position - _pointerDownGlobal!;
                if (delta.distance < _dragThreshold) return;
                _dragging = true;
                widget.onDragStarted(_pointerDownLocalDy);
              }
              widget.onDragMove(event.position);
            },
            onPointerUp: (_) {
              if (_dragging) {
                unawaited(_endDrag());
              } else {
                widget.onTap?.call();
                widget.onPressUpWithoutDrag?.call();
              }
              _resetPointer();
            },
            onPointerCancel: (_) {
              if (_dragging) {
                widget.onDragCancelled();
              } else {
                widget.onPressUpWithoutDrag?.call();
              }
              _resetPointer();
            },
            child: widget.block,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) {
        _dragging = true;
        HapticFeedback.selectionClick();
        widget.onDragStarted(details.localPosition.dy);
      },
      onLongPressMoveUpdate: (details) =>
          widget.onDragMove(details.globalPosition),
      onLongPressEnd: (_) => unawaited(_endDrag()),
      onLongPressCancel: () {
        _dragging = false;
        widget.onDragCancelled();
      },
      onTap: widget.onTap,
      child: widget.block,
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 1), Offset(x + dashWidth, 1), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
