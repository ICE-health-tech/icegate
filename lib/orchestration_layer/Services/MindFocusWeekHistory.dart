import 'dart:convert';

import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';

/// One calendar week (Mon–Sun, local) of journal stats for a focus area.
class FocusWeekSnapshot {
  const FocusWeekSnapshot({
    required this.weekStart,
    required this.logCount,
    required this.avgMood,
    required this.isCurrentWeek,
  });

  final DateTime weekStart;
  final int logCount;
  final double? avgMood;
  final bool isCurrentWeek;
}

abstract final class MindFocusWeekHistory {
  MindFocusWeekHistory._();

  static DateTime weekStartLocal(DateTime date) {
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static List<String> decodeActivities(String json) {
    try {
      final raw = jsonDecode(json);
      if (raw is List) return raw.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  static bool logMatchesTrend(MindLogData log, MindFocusTrend trend) {
    final acts = decodeActivities(log.activities);
    if (acts.isEmpty || trend.activityTokens.isEmpty) return false;
    return acts.any(trend.activityTokens.contains);
  }

  /// Last [weekCount] weeks including the current one (index 0 = this week).
  static List<FocusWeekSnapshot> snapshotsForTrend({
    required List<MindLogData> logs,
    required MindFocusTrend trend,
    int weekCount = 12,
  }) {
    final thisWeek = weekStartLocal(DateTime.now());
    final result = <FocusWeekSnapshot>[];

    for (var i = 0; i < weekCount; i++) {
      final start = thisWeek.subtract(Duration(days: 7 * i));
      final end = start.add(const Duration(days: 7));
      final matched = logs.where((l) {
        final at = l.createdAt.toLocal();
        if (at.isBefore(start) || !at.isBefore(end)) return false;
        return logMatchesTrend(l, trend);
      }).toList();

      final avgMood = matched.isEmpty
          ? null
          : matched.fold<double>(0, (s, l) => s + l.moodScore) / matched.length;

      result.add(
        FocusWeekSnapshot(
          weekStart: start,
          logCount: matched.length,
          avgMood: avgMood,
          isCurrentWeek: i == 0,
        ),
      );
    }
    return result;
  }
}
