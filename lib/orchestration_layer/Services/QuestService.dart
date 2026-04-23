import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';

class QuestService {
  final AppDatabase _db;

  QuestService(this._db);

  /// Generates daily quests for a person if they haven't been generated today.
  Future<void> generateDailyQuestsIfNeeded(String personId) async {
    final profile = await _db.personManagementDAO.getProfileForPerson(personId);
    if (profile == null) return;

    final now = DateTime.now();
    final lastGenerated = profile.lastQuestGeneratedAt;

    if (lastGenerated == null || !_isSameDay(lastGenerated, now)) {
      await _generateNewDailyQuests(personId);
      await _db.personManagementDAO.updateLastQuestGeneratedAt(personId, now);
    }
  }

  /// Nuclear reset: wipes all quests, achievements, and resets the daily generation timer.
  Future<void> clearAllQuestData(String personId) async {
    await _db.questDAO.deleteAllQuestsForPerson(personId);
    await _db.achievementsDAO.deleteAllAchievementsForPerson(personId);
    await _db.personManagementDAO.updateLastQuestGeneratedAt(personId, null);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _generateNewDailyQuests(String personId) async {
    // Random daily quest generation has been disabled per user request.
    // Quests should now be managed manually or through specific triggers.
    debugPrint("Daily quest generation skipped for $personId");
  }
}
