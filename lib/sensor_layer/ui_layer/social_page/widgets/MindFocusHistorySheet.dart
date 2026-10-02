import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusWeekHistory.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:intl/intl.dart';

/// Weekly journal history per focus area (computed from [mind_logs]).
class MindFocusHistorySheet extends StatefulWidget {
  const MindFocusHistorySheet({
    super.key,
    required this.trends,
    required this.logs,
  });

  final List<MindFocusTrend> trends;
  final List<MindLogData> logs;

  static Future<void> show(
    BuildContext context, {
    required List<MindFocusTrend> trends,
    required List<MindLogData> logs,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MindFocusHistorySheet(trends: trends, logs: logs),
    );
  }

  @override
  State<MindFocusHistorySheet> createState() => _MindFocusHistorySheetState();
}

class _MindFocusHistorySheetState extends State<MindFocusHistorySheet> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final trends = widget.trends;
    final trend = trends[_selectedIndex];
    final snapshots = MindFocusWeekHistory.snapshotsForTrend(
      logs: widget.logs,
      trend: trend,
    );
    final dateFmt = DateFormat.MMMd();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: trend.color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.mind_focus_history_title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              if (trends.length > 1)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final t = trends[index];
                      final selected = index == _selectedIndex;
                      return FilterChip(
                        selected: selected,
                        avatar: Icon(
                          MindFocusTrend.resolveIcon(t.iconCodePoint),
                          size: 16,
                          color: selected ? t.color : cs.onSurfaceVariant,
                        ),
                        label: Text(
                          t.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onSelected: (_) => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: snapshots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final snap = snapshots[index];
                    final weekEnd = snap.weekStart.add(const Duration(days: 6));
                    final goal = trend.weeklyGoal;
                    final hitGoal = snap.logCount >= goal;
                    final moodColor = snap.avgMood == null
                        ? cs.onSurface.withValues(alpha: 0.35)
                        : mindMoodAccent(snap.avgMood!.round().clamp(1, 5));

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: snap.isCurrentWeek
                            ? trend.color.withValues(alpha: 0.08)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: snap.isCurrentWeek
                              ? trend.color.withValues(alpha: 0.35)
                              : cs.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snap.isCurrentWeek
                                      ? l10n.mind_focus_this_week
                                      : l10n.mind_focus_history_week_range(
                                          dateFmt.format(snap.weekStart),
                                          dateFmt.format(weekEnd),
                                        ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.mind_focus_history_logs(
                                    snap.logCount,
                                    goal,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (snap.avgMood != null) ...[
                            Icon(
                              Icons.sentiment_satisfied_alt_rounded,
                              size: 18,
                              color: moodColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              snap.avgMood!.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: moodColor,
                              ),
                            ),
                          ] else
                            Text(
                              l10n.mind_focus_history_no_logs,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                  ),
                            ),
                          if (hitGoal && snap.logCount > 0) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: trend.color,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
