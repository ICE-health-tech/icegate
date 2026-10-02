import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Four-pillar daily habit loop — auto-detect progress from real activity.
class DailyLoopService {
  DailyLoopService(this._db);

  final AppDatabase _db;
  DateTime? _lastSyncAt;

  static const _questTypes = [
    'daily_health',
    'daily_finance',
    'daily_mind',
    'daily_projects',
  ];

  static const _templates = <String, ({String category, String title, String desc})>{
    'daily_health': (
      category: 'health',
      title: 'Health pulse',
      desc: 'Log steps, water, or focus',
    ),
    'daily_finance': (
      category: 'finance',
      title: 'Money check',
      desc: 'Log or review spending',
    ),
    'daily_mind': (
      category: 'social',
      title: 'Mood log',
      desc: 'How you feel today',
    ),
    'daily_projects': (
      category: 'projects',
      title: 'Project touch',
      desc: 'Update a note or task',
    ),
  };

  Future<void> ensureDailyQuests(String personId) async {
    if (personId.isEmpty) return;

    final profile = await _db.personManagementDAO.getProfileForPerson(personId);
    if (profile == null) return;

    final now = DateTime.now();
    final lastGenerated = profile.lastQuestGeneratedAt;
    if (lastGenerated != null && _isSameDay(lastGenerated, now)) return;

    await _db.questDAO.deleteIncompleteDailyQuestsForPerson(personId);

    for (final questType in _questTypes) {
      final t = _templates[questType]!;
      await _db.questDAO.insertQuest(
        QuestsTableCompanion(
          id: Value(IDGen.UUIDV7()),
          personID: Value(personId),
          title: Value(t.title),
          description: Value(t.desc),
          type: const Value('daily'),
          questType: Value(questType),
          targetValue: const Value(1.0),
          currentValue: const Value(0.0),
          category: Value(t.category),
          rewardExp: const Value(15),
          isCompleted: const Value(false),
        ),
      );
    }

    await _db.personManagementDAO.updateLastQuestGeneratedAt(personId, now);
    debugPrint('DailyLoop: generated 4 quests for $personId');
  }

  /// Returns quests that just completed during this sync (for celebration UI).
  Future<List<QuestData>> syncProgress({
    required String personId,
    required int steps,
    required int focusMinutes,
    required int water,
    required int calories,
    required MindLogData? latestMood,
    required List<TransactionData> transactions,
  }) async {
    if (personId.isEmpty) return const [];

    final now = DateTime.now();
    if (_lastSyncAt != null &&
        now.difference(_lastSyncAt!) < const Duration(seconds: 15)) {
      return const [];
    }
    _lastSyncAt = now;

    await ensureDailyQuests(personId);

    final quests = await _db.questDAO.getAllQuests(personId);
    final dailies = quests.where(
      (q) => q.type == 'daily' && q.isCompleted != true,
    );

    final healthDone = steps > 0 ||
        focusMinutes > 0 ||
        water > 0 ||
        calories > 0;
    final mindDone =
        latestMood != null && _isSameDay(latestMood.createdAt, now);
    final financeDone = transactions.any(
      (t) => _isSameDay(t.transactionDate, now),
    );
    final projectsDone = await _hasProjectActivityToday(personId, now);

    final progress = <String, double>{
      'daily_health': healthDone ? 1.0 : 0.0,
      'daily_finance': financeDone ? 1.0 : 0.0,
      'daily_mind': mindDone ? 1.0 : 0.0,
      'daily_projects': projectsDone ? 1.0 : 0.0,
    };

    final newlyCompleted = <QuestData>[];
    for (final quest in dailies) {
      final key = quest.questType;
      if (key == null || !progress.containsKey(key)) continue;
      final value = progress[key]!;
      final wasDone = quest.isCompleted == true;
      if (value >= (quest.targetValue ?? 1) && !wasDone) {
        newlyCompleted.add(quest);
      }
      if ((quest.currentValue ?? 0) != value) {
        await _db.questDAO.updateQuestProgress(quest.id, value);
      }
    }

    final completedToday = progress.values.where((v) => v >= 1).length;
    if (completedToday >= 4) {
      await _recordStreakDay(personId, now);
    }

    return newlyCompleted;
  }

  Future<bool> _hasProjectActivityToday(String personId, DateTime now) async {
    final notes = await (_db.select(_db.projectNotesTable)
          ..where((t) => t.personID.equals(personId)))
        .get();
    for (final n in notes) {
      if (_isSameDay(n.updatedAt, now) || _isSameDay(n.createdAt, now)) {
        return true;
      }
    }

    final goals = await (_db.select(_db.goalsTable)
          ..where((t) => t.personID.equals(personId)))
        .get();
    for (final g in goals) {
      if (_isSameDay(g.updatedAt, now)) return true;
      if (g.completionDate != null && _isSameDay(g.completionDate!, now)) {
        return true;
      }
    }
    return false;
  }

  Future<int> readStreak(String personId) async {
    if (personId.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('daily_loop_streak_$personId') ?? 0;
  }

  Future<void> _recordStreakDay(String personId, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(now);
    final lastKey = prefs.getString('daily_loop_last_all_done_$personId');
    if (lastKey == todayKey) return;

    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
    var streak = prefs.getInt('daily_loop_streak_$personId') ?? 0;
    streak = lastKey == yesterdayKey ? streak + 1 : 1;

    await prefs.setInt('daily_loop_streak_$personId', streak);
    await prefs.setString('daily_loop_last_all_done_$personId', todayKey);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
