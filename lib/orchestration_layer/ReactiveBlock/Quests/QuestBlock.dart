import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

import 'package:ice_gate/orchestration_layer/Services/DailyLoopService.dart';
import 'package:ice_gate/orchestration_layer/Services/QuestService.dart';

class QuestBlock {
  final numberOfQuests = signal<int>(0);
  final quests = signal<List<QuestData>>([]);

  late QuestService _questService;
  late DailyLoopService _dailyLoopService;
  StreamSubscription? _questsSubscription;
  AppDatabase? _db;

  void init(AppDatabase db, String personId) {
    _db = db;
    _questService = QuestService(db);
    _dailyLoopService = DailyLoopService(db);
    final dao = db.questDAO;
    _questsSubscription?.cancel();

    if (personId.isEmpty) {
      debugPrint("QuestBlock: Skipping init, personId is empty.");
      return;
    }

    _questService.generateDailyQuestsIfNeeded(personId);

    dao.deleteSecretQuestsForPerson(personId);

    _questsSubscription = dao.watchAllQuests(personId).listen((allQuests) {
      final now = DateTime.now();
      final todayDailies = allQuests.where((q) {
        if (q.type != 'daily') return false;
        final c = q.createdAt;
        return c.year == now.year &&
            c.month == now.month &&
            c.day == now.day;
      }).toList();
      quests.value = todayDailies;
      numberOfQuests.value =
          todayDailies.where((q) => q.isCompleted != true).length;
    });
  }

  Future<List<QuestData>> syncDailyLoop({
    required String personId,
    required int steps,
    required int focusMinutes,
    required int water,
    required int calories,
    required MindLogData? latestMood,
    required List<TransactionData> transactions,
  }) {
    if (_db == null) return Future.value(const []);
    return _dailyLoopService.syncProgress(
      personId: personId,
      steps: steps,
      focusMinutes: focusMinutes,
      water: water,
      calories: calories,
      latestMood: latestMood,
      transactions: transactions,
    );
  }

  void dispose() {
    _questsSubscription?.cancel();
  }
}
