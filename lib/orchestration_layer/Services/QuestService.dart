import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:drift/drift.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

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

  Future<void> _insertQuestFromTemplate(
    String personId,
    _QuestTemplate template,
    String category,
  ) async {
    await _db.questDAO.insertQuest(
      QuestsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: Value(personId),
        title: Value(template.title),
        description: Value(template.description),
        type: const Value('daily'),
        questType: Value(template.questType),
        category: Value(category),
        targetValue: Value(template.targetValue),
        currentValue: const Value(0.0),
        rewardExp: Value(template.rewardExp),
        isCompleted: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _generateNewDailyQuests(String personId) async {
    await _db.questDAO.deleteIncompleteDailyQuestsForPerson(personId);

    
    // Generate 3 random Health Quests
    final healthQuestPool = [
      _QuestTemplate(
        title: "Morning Run",
        description: "Run for 30 minutes to boost your stamina.",
        questType: "running",
        targetValue: 30.0,
        rewardExp: 50,
      ),
      _QuestTemplate(
        title: "Walking Master",
        description: "Walk 10,000 steps today.",
        questType: "walking",
        targetValue: 10000.0,
        rewardExp: 30,
      ),
      _QuestTemplate(
        title: "Swimming Session",
        description: "Swim for 45 minutes to improve full-body strength.",
        questType: "swimming",
        targetValue: 45.0,
        rewardExp: 60,
      ),
      _QuestTemplate(
        title: "Pushup Challenge",
        description: "Complete 50 pushups throughout the day.",
        questType: "pushups",
        targetValue: 50.0,
        rewardExp: 40,
      ),
    ];

    // Shuffle and pick 2
    healthQuestPool.shuffle();
    final selectedHealth = healthQuestPool.take(2).toList();

    for (var template in selectedHealth) {
      await _insertQuestFromTemplate(personId, template, 'health');
    }

    // Generate 1 Finance or Career Quest
    final businessQuestPool = [
      _QuestTemplate(
        title: "Virtual Office Budget",
        description: "Set aside 650,000 VND for your virtual office (Green Office).",
        questType: "budgeting",
        targetValue: 650000.0,
        rewardExp: 40,
      ),
      _QuestTemplate(
        title: "Finance Review",
        description: "Review your transactions for the last 7 days.",
        questType: "review",
        targetValue: 1.0,
        rewardExp: 30,
      ),
      _QuestTemplate(
        title: "Deep Work",
        description: "Complete 2 focus sessions of 25 minutes each.",
        questType: "focus",
        targetValue: 2.0,
        rewardExp: 50,
      ),
    ];

    businessQuestPool.shuffle();
    final selectedBusiness = businessQuestPool.first;
    await _insertQuestFromTemplate(personId, selectedBusiness, 'finance');

  }
}

class _QuestTemplate {
  final String title;
  final String description;
  final String questType;
  final double targetValue;
  final int rewardExp;

  _QuestTemplate({
    required this.title,
    required this.description,
    required this.questType,
    required this.targetValue,
    required this.rewardExp,
  });
}
