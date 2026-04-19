import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MindBlock {
  final MindLogsDAO dao;
  
  // Daily mood signal
  final dailyMoodValue = signal<int>(3);
  
  MindBlock(this.dao);

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
      debugPrint('📊 [MindBlock] Found ${logs.length} logs for $personId on ${date.toIso8601String().split('T')[0]}');
      return logs;
    });
  }

  // Calculate top activity for a specific mood
  Future<Map<String, int>> getTopActivitiesForMood(String personId, int moodScore) async {
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
}
