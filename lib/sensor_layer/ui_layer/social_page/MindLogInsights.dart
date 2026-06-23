import 'dart:convert';

import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/link_layer/skills/skill_practice_streak.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillCatalog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindSkillsSessionCard.dart';

/// Aggregations for Mind / Social charts (mind logs + journal notes).
abstract final class MindLogInsights {
  /// Shared window for [MoodTrendsChart] on Journal and Analysis tabs.
  static const int moodChartDays = 14;

  /// Summary stats on the Analysis tab.
  static const int insightsSummaryDays = 30;

  static DateTime _dayKey(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Maps journal note mood labels to chart scores (1–5).
  static int moodLabelToScore(String? mood) {
    return switch (mood?.toLowerCase()) {
      'awful' => 1,
      'bad' => 2,
      'meh' => 3,
      'good' => 4,
      'awesome' => 5,
      _ => 0,
    };
  }

  static DateTime rangeStartDays(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  }

  /// Skill Boost timed sessions — keep for streaks, hide from NHẬT KÝ journal UI.
  static bool isSkillSessionLog(MindLogData log) {
    try {
      final raw = jsonDecode(log.activities) as List<dynamic>;
      var hasSkill = false;
      for (final entry in raw) {
        if (entry is! String) continue;
        if (entry.startsWith('skill:')) {
          hasSkill = true;
          continue;
        }
        if (MindActivityTokens.isInternalSessionToken(entry)) continue;
        return false;
      }
      return hasSkill;
    } catch (_) {
      return false;
    }
  }

  /// Synthetic mood point from a social [ProjectNoteData] (NHẬT KÝ entry).
  static MindLogData? moodPointFromNote(ProjectNoteData note) {
    final score = moodLabelToScore(note.mood);
    if (score == 0) return null;

    final when = note.createdAt.toLocal();
    final day = _dayKey(when);
    final title = note.title.trim().isEmpty ? 'Journal' : note.title.trim();

    return MindLogData(
      id: 'note_${note.id}',
      personID: note.personID,
      moodScore: score,
      activities: jsonEncode([title]),
      note: title,
      source: 'journal_note',
      logDate: day,
      createdAt: note.createdAt,
    );
  }

  /// Merges synced mind logs with local journal notes for charts.
  static List<MindLogData> mergeNotesWithMindLogs({
    required List<MindLogData> mindLogs,
    required List<ProjectNoteData> journalNotes,
    required int days,
  }) {
    final start = rangeStartDays(days);
    final merged = <String, MindLogData>{};

    for (final log in mindLogs) {
      if (!log.logDate.isBefore(start)) {
        merged[log.id] = log;
      }
    }

    for (final note in journalNotes) {
      if (note.category != 'social') continue;
      if (_dayKey(note.createdAt).isBefore(start)) continue;
      final point = moodPointFromNote(note);
      if (point != null) {
        merged[point.id] = point;
      }
    }

    return merged.values.toList()
      ..sort((a, b) {
        final byDay = a.logDate.compareTo(b.logDate);
        if (byDay != 0) return byDay;
        return a.createdAt.compareTo(b.createdAt);
      });
  }

  static ({int logCount, int activeDays, double avgMood}) summarize(
    List<MindLogData> logs,
  ) {
    if (logs.isEmpty) {
      return (logCount: 0, activeDays: 0, avgMood: 0);
    }
    final days = <DateTime>{};
    var sum = 0;
    for (final log in logs) {
      days.add(_dayKey(log.logDate));
      sum += log.moodScore;
    }
    return (
      logCount: logs.length,
      activeDays: days.length,
      avgMood: sum / logs.length,
    );
  }

  static Map<DateTime, List<MindLogData>> _logsByDay(List<MindLogData> logs) {
    final byDay = <DateTime, List<MindLogData>>{};
    for (final log in logs) {
      final day = _dayKey(log.logDate);
      byDay.putIfAbsent(day, () => []).add(log);
    }
    return byDay;
  }

  static double _avgMoodScore(List<MindLogData> dayLogs) =>
      dayLogs.fold<double>(0, (s, l) => s + l.moodScore) / dayLogs.length;

  /// One synthetic log per calendar day (avg mood) for charts.
  static List<MindLogData> dailyMoodSeries(List<MindLogData> logs) {
    if (logs.isEmpty) return const [];

    final byDay = _logsByDay(logs);
    final days = byDay.keys.toList()..sort();
    return [
      for (final day in days)
        () {
          final dayLogs = byDay[day]!;
          final avg = _avgMoodScore(dayLogs);
          final template = dayLogs.first;
          return template.copyWith(
            moodScore: avg.round().clamp(1, 6),
            logDate: day,
            createdAt: day,
          );
        }(),
    ];
  }

  /// Daily mood averages aligned with [dailyMoodSeries] (exact Y values for line chart).
  static List<double> dailyMoodAverages(List<MindLogData> logs) {
    if (logs.isEmpty) return const [];

    final byDay = _logsByDay(logs);
    final days = byDay.keys.toList()..sort();
    return [for (final day in days) _avgMoodScore(byDay[day]!)];
  }

  /// Log count per hour for today (local time).
  static Map<int, int> hourlyLogsToday(List<MindLogData> logs) {
    final today = _dayKey(DateTime.now());
    final counts = <int, int>{for (var h = 0; h < 24; h++) h: 0};
    for (final log in logs) {
      if (_dayKey(log.logDate) != today) continue;
      final hour = log.createdAt.toLocal().hour;
      counts[hour] = (counts[hour] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> activityLabelCounts(
    List<MindLogData> logs,
    AppLocalizations l10n,
    Map<String, String> optionLabels,
  ) {
    final counts = <String, int>{};
    for (final log in logs) {
      try {
        final raw = jsonDecode(log.activities);
        if (raw is! List) continue;
        for (final item in raw) {
          final token = item.toString();
          if (token.startsWith('learn:')) continue;
          final label = token.startsWith('skill:')
              ? token.substring('skill:'.length)
              : MindActivityTokens.displayLabel(l10n, token, optionLabels);
          if (label.trim().isEmpty) continue;
          counts[label] = (counts[label] ?? 0) + 1;
        }
      } catch (_) {}
    }
    return counts;
  }

  static ({
    int sessions,
    int minutes,
    String? topSkill,
    int topStreak,
  }) skillSummary(List<MindLogData> logs, {int days = 30}) {
    final stats = MindSkillsSessionCard.summarize(logs, days: days);
    final streakIndex = SkillPracticeStreak.buildDayIndex(logs);
    var topStreak = 0;
    if (stats.topSkill != null) {
      topStreak = SkillPracticeStreak.streakForProtocol(
        streakIndex,
        stats.topSkill!,
      );
    } else {
      for (final name in MindSkillCatalog.defaults) {
        final s = SkillPracticeStreak.streakForProtocol(streakIndex, name);
        if (s > topStreak) topStreak = s;
      }
    }
    return (
      sessions: stats.sessions,
      minutes: stats.minutes,
      topSkill: stats.topSkill,
      topStreak: topStreak,
    );
  }
}
