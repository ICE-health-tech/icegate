import 'dart:convert';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MindBlock {
  final MindLogsDAO dao;
  
  // Daily mood signal
  final dailyMoodValue = signal<int>(3);
  
  MindBlock(this.dao);

  Stream<List<MindLogData>> watchMindLogs(String personId) {
    return dao.watchLogsByPerson(personId);
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
