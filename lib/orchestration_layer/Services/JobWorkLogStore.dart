import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Per-job calendar days the user marked as worked (local prefs).
abstract final class JobWorkLogStore {
  JobWorkLogStore._();

  static String _key(String personId) => 'job_work_log_v1_$personId';

  static Future<Map<String, List<String>>> _readAll(String personId) async {
    if (personId.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(personId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((jobId, days) {
        final list = (days as List<dynamic>).map((d) => d.toString()).toList();
        return MapEntry(jobId, list);
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeAll(
    String personId,
    Map<String, List<String>> data,
  ) async {
    if (personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(personId), jsonEncode(data));
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static Future<Set<DateTime>> daysForJob(
    String personId,
    String jobId,
  ) async {
    final all = await _readAll(personId);
    final keys = all[jobId] ?? const [];
    return keys.map((k) {
      final parts = k.split('-');
      if (parts.length != 3) return null;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (y == null || m == null || day == null) return null;
      return DateTime(y, m, day);
    }).whereType<DateTime>().toSet();
  }

  static Future<bool> isLogged(
    String personId,
    String jobId,
    DateTime day,
  ) async {
    final days = await daysForJob(personId, jobId);
    return days.contains(_dateOnly(day));
  }

  static Future<void> toggleDay(
    String personId,
    String jobId,
    DateTime day,
  ) async {
    if (personId.isEmpty || jobId.isEmpty) return;
    final all = await _readAll(personId);
    final key = _dateKey(_dateOnly(day));
    final list = List<String>.from(all[jobId] ?? []);
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.add(key);
    }
    list.sort();
    if (list.isEmpty) {
      all.remove(jobId);
    } else {
      all[jobId] = list;
    }
    await _writeAll(personId, all);
  }

  static Future<void> logToday(String personId, String jobId) async {
    final today = _dateOnly(DateTime.now());
    if (await isLogged(personId, jobId, today)) return;
    await toggleDay(personId, jobId, today);
  }

  static int streakFor(Set<DateTime> workDays) {
    if (workDays.isEmpty) return 0;
    final today = _dateOnly(DateTime.now());
    late DateTime cursor;
    if (workDays.contains(today)) {
      cursor = today;
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      if (!workDays.contains(yesterday)) return 0;
      cursor = yesterday;
    }
    var streak = 0;
    while (workDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Last 7 days ending today — whether each day was logged.
  static List<bool> last7(Set<DateTime> workDays) {
    final today = _dateOnly(DateTime.now());
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return workDays.contains(day);
    });
  }
}
