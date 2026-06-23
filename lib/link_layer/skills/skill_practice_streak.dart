import 'dart:convert';

import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillCatalog.dart';

/// Consecutive-day practice streaks from mind logs (`skill:<name>` activities).
abstract final class SkillPracticeStreak {
  static Map<String, Set<DateTime>> buildDayIndex(List<MindLogData> logs) {
    final index = <String, Set<DateTime>>{};
    for (final log in logs) {
      final day = DateTime(
        log.logDate.year,
        log.logDate.month,
        log.logDate.day,
      );
      for (final name in _skillNamesFromLog(log)) {
        final key = name.trim().toLowerCase();
        if (key.isEmpty) continue;
        index.putIfAbsent(key, () => {}).add(day);
      }
    }
    return index;
  }

  static int streakFor(Map<String, Set<DateTime>> dayIndex, String skillName) {
    final key = skillName.trim().toLowerCase();
    return _currentStreak(dayIndex[key] ?? {});
  }

  static int streakForSkill(List<MindLogData> logs, String skillName) {
    return streakFor(buildDayIndex(logs), skillName);
  }

  static Iterable<String> _skillNamesFromLog(MindLogData log) sync* {
    try {
      final acts = jsonDecode(log.activities) as List<dynamic>;
      for (final a in acts) {
        if (a is! String || !a.startsWith('skill:')) continue;
        yield a.substring('skill:'.length);
      }
    } catch (_) {}
  }

  static int _currentStreak(Set<DateTime> practiceDays) {
    if (practiceDays.isEmpty) return 0;

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    late DateTime cursor;
    if (practiceDays.contains(todayKey)) {
      cursor = todayKey;
    } else {
      final yesterday = todayKey.subtract(const Duration(days: 1));
      if (!practiceDays.contains(yesterday)) return 0;
      cursor = yesterday;
    }

    var streak = 0;
    while (practiceDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Case-insensitive lookup including [MindSkillCatalog.namesMatch] aliases.
  static int streakForProtocol(
    Map<String, Set<DateTime>> dayIndex,
    String skillName,
  ) {
    final direct = streakFor(dayIndex, skillName);
    if (direct > 0) return direct;

    for (final entry in dayIndex.entries) {
      if (MindSkillCatalog.namesMatch(entry.key, skillName)) {
        return _currentStreak(entry.value);
      }
    }
    return 0;
  }
}
