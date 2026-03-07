import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class QuestBlock {
  final numberOfQuests = signal<int>(0);
  final quests = signal<List<QuestData>>([]);

  StreamSubscription? _questsSubscription;

  void init(QuestDAO dao, String personId) {
    _questsSubscription?.cancel();

    if (personId.isEmpty) {
      debugPrint("QuestBlock: Skipping init, personId is empty.");
      return;
    }

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
