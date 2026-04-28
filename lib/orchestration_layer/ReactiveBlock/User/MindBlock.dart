import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:rxdart/rxdart.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MindBlock {
  final MindLogsDAO dao;

  Timer? _updateTimer;
  // Daily mood signal
  final dailyMoodValue = signal<int>(3);
  final latestMoodLog = signal<MindLogData?>(null);

  MindBlock(this.dao);

  void init(String personId) {
    dao.watchLatestLog(personId).delay(Duration(milliseconds: 300)).listen((
      log,
    ) {
      // Timer(Duration.zero, () {
      batch(() {
        latestMoodLog.value = log;
        // });
      });
    });
  }

  Stream<List<MindLogData>> watchMindLogs(String personId) {
    return dao.watchLogsByPerson(personId);
  }

  /// Watch ALL logs for a person (for debugging / total history)
  Stream<List<MindLogData>> watchAllMindLogs(String personId) {
    print("🔭 [MindBlock] Watching ALL logs for $personId");
    return dao.watchAllLogs(personId).map((logs) {
      debugPrint("📊 [MindBlock] Total logs in local DB: ${logs.length}");
      return logs;
    });
  }

  Stream<List<MindLogData>> watchMindLogsByDay(String personId, DateTime date) {
    return dao.watchLogsByDay(personId, date).map((logs) {
      debugPrint(
        '📊 [MindBlock] Found ${logs.length} logs for $personId on ${date.toIso8601String().split('T')[0]}',
      );
      return logs;
    });
  }

  /// Watch logs for a specific range of days
  Stream<List<MindLogData>> watchMindLogsRange(String personId, int days) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days));
    final end = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    return dao.watchLogsByRange(personId, start, end).map((logs) {
      debugPrint(
        '📊 [MindBlock] Found ${logs.length} logs for $personId in last $days days',
      );
      return logs;
    });
  }

  // Calculate top activity for a specific mood
  Future<Map<String, int>> getTopActivitiesForMood(
    String personId,
    int moodScore,
  ) async {
    final logsArr = await dao.watchLogsByMood(personId, moodScore).first;
    final activityCounts = <String, int>{};

    for (var log in logsArr) {
      try {
        final List<dynamic> activities = jsonDecode(log.activities);
        for (var activity in activities) {
          final name = activity.toString();
          activityCounts[name] = (activityCounts[name] ?? 0) + 1;
        }
      } catch (e) {
        // Silently skip malformed JSON
      }
    }
    return activityCounts;
  }

  Future<void> addMindLog({
    required int moodScore,
    required List<String> activities,
    required String? note,
    required String personId,
    required String? tenantId,
  }) async {
    final now = DateTime.now();
    // Normalize logDate to local midnight to ensure grouping by day works reliably across timezones
    final localMidnight = DateTime(now.year, now.month, now.day);

    final entry = MindLogsTableCompanion.insert(
      id: IDGen.UUIDV7(),
      tenantID: tenantId != null
          ? drift.Value(tenantId)
          : const drift.Value.absent(),
      personID: drift.Value(personId),
      moodScore: moodScore,
      activities: jsonEncode(activities),
      note: note != null && note.isNotEmpty
          ? drift.Value(note)
          : const drift.Value.absent(),
      logDate: drift.Value(localMidnight), // PINNED TO LOCAL DAY
      createdAt: drift.Value(now.toUtc()), // ACTUAL INSERT TIME IN UTC
    );

    await dao.insertLog(entry);
    debugPrint("✅ [MindBlock] Mind log added successfully");
  }
}
