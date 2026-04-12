import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';

import 'package:ice_gate/orchestration_layer/Services/QuestService.dart';

class QuestBlock {
  final numberOfQuests = signal<int>(0);
  final quests = signal<List<QuestData>>([]);

  late QuestService _questService;
  StreamSubscription? _questsSubscription;

  void init(AppDatabase db, String personId) {
    _questService = QuestService(db);
    final dao = db.questDAO;
    _questsSubscription?.cancel();

    if (personId.isEmpty) {
      debugPrint("QuestBlock: Skipping init, personId is empty.");
      return;
    }

    // Generate daily quests if needed
    _questService.generateDailyQuestsIfNeeded(personId);

    // Watch active quests filtered by person
    _questsSubscription = dao.watchActiveQuests(personId).listen((
      activeQuests,
    ) {
      quests.value = activeQuests;
      numberOfQuests.value = activeQuests.length;
    });
  }

  void dispose() {
    _questsSubscription?.cancel();
  }
}
