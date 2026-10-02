import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/utils/app_log.dart';

class MindBlock {
  final MindLogsDAO dao;

  // Timer? _updateTimer;
  // Daily mood signal
  final dailyMoodValue = signal<int>(3);
  final latestMoodLog = signal<MindLogData?>(null);

  MindBlock(this.dao);

  void init(String personId) {
    dao.watchLatestLog(personId).listen((
      log,
    ) {
      // This callback can fire while another signal computation/batch is in
      // progress (especially during app boot). Deferring the write avoids
      // `SignalEffectException` from nested reactive work.
      untracked(() {
        scheduleMicrotask(() {
          latestMoodLog.value = log;
        });
      });
    });
  }

  Stream<List<MindLogData>> watchMindLogs(String personId) {
    return dao.watchLogsByPerson(personId);
  }

  /// Watch ALL logs for a person (for debugging / total history)
  Stream<List<MindLogData>> watchAllMindLogs(String personId) {
    appLog("🔭 [MindBlock] Watching ALL logs for $personId");
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

    final resolvedTenant = tenantId?.trim();
    if (resolvedTenant == null || resolvedTenant.isEmpty) {
      debugPrint(
        '⚠️ [MindBlock] addMindLog missing tenant_id for person $personId; '
        'using $DEFAULT_TENANT_ID',
      );
    }

    final entry = MindLogsTableCompanion.insert(
      id: IDGen.UUIDV7(),
      tenantID: drift.Value(
        (resolvedTenant != null && resolvedTenant.isNotEmpty)
            ? resolvedTenant
            : DEFAULT_TENANT_ID,
      ),
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

  /// Push local gratitude rows up, then pull from Supabase.
  Future<void> syncGratitude(String personId) async {
    if (personId.isEmpty) return;
    final db = dao.attachedDatabase;
    try {
      await db.gratitudeDAO.pushAllToCloud(personId);
      await db.syncTableDown('gratitude_entries', personId);
      final count = await db.gratitudeDAO.watchForPerson(personId).first;
      debugPrint(
        '📡 [MindBlock] gratitude sync done — ${count.length} local entries',
      );
    } catch (e) {
      debugPrint('MindBlock: gratitude sync failed: $e');
    }
  }
}
