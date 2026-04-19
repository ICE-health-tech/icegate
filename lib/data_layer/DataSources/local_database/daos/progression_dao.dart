part of '../Database.dart';

@DriftAccessor(tables: [GoalsTable])
class GoalDAO extends DatabaseAccessor<AppDatabase> with _$GoalDAOMixin {
  GoalDAO(super.db);

  Future<int> insertGoal(GoalsTableCompanion entry) => into(goalsTable).insert(entry);

  Future<bool> updateGoal(GoalData entry) => update(goalsTable).replace(entry);

  Future<int> deleteGoal(String id) =>
      (delete(goalsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<GoalData>> watchAllGoals(String personId) =>
      (select(goalsTable)..where((t) => t.personID.equals(personId))).watch();

  Stream<List<GoalData>> watchGoalsByProject(String projectId) =>
      (select(goalsTable)..where((t) => t.projectID.equals(projectId))).watch();
}

@DriftAccessor(tables: [HabitsTable])
class HabitDAO extends DatabaseAccessor<AppDatabase> with _$HabitDAOMixin {
  HabitDAO(super.db);

  Future<int> insertHabit(HabitsTableCompanion entry) =>
      into(habitsTable).insert(entry);

  Future<bool> updateHabit(HabitData entry) => update(habitsTable).replace(entry);

  Future<int> deleteHabit(String id) =>
      (delete(habitsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<HabitData>> watchAllHabits(String personId) =>
      (select(habitsTable)..where((t) => t.personID.equals(personId))).watch();
}

@DriftAccessor(tables: [QuestsTable])
class QuestDAO extends DatabaseAccessor<AppDatabase> with _$QuestDAOMixin {
  QuestDAO(super.db);

  Future<void> insertQuest(QuestsTableCompanion entry) async {
    var updatedEntry = entry;
    if (entry.category.present) {
      final categoryValue = entry.category.value;
      updatedEntry = entry.copyWith(
        category: Value(categoryValue?.toLowerCase()),
      );
    }
    await into(questsTable).insert(updatedEntry);

    await db.pushToSupabase(
      table: 'quests',
      payload: db.companionToMap(updatedEntry, questsTable),
    );
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(questsTable).insert(
      QuestsTableCompanion(
        id: Value(record['id'] as String),
        tenantID: Value(record['tenant_id'] as String?),
        personID: Value(record['person_id'] as String?),
        title: Value(record['title'] as String?),
        description: Value(record['description'] as String?),
        type: Value(record['type'] as String?),
        targetValue: Value((record['target_value'] as num?)?.toDouble()),
        currentValue: Value((record['current_value'] as num?)?.toDouble()),
        category: Value(record['category'] as String?),
        rewardExp: Value(record['reward_exp'] as int?),
        isCompleted: Value(record['is_completed'] as bool?),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
        penaltyScore: Value(record['penalty_score'] as int?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> updateQuest(QuestData entry) {
    final updatedEntry = entry.copyWith(
      category: Value(entry.category?.toLowerCase()),
    );
    return update(questsTable).replace(updatedEntry);
  }

  Future<int> deleteQuest(String id) async {
    final count = await (delete(
      questsTable,
    )..where((t) => t.id.equals(id))).go();
    if (count > 0) {
      await db.pushToSupabase(
        table: 'quests',
        payload: {'id': id},
        isDelete: true,
      );
    }
    return count;
  }

  Future<int> deleteIncompleteDailyQuestsForPerson(String personId) {
    return (delete(questsTable)..where(
          (t) =>
              t.personID.equals(personId) &
              t.isCompleted.equals(false) &
              t.type.equals('daily'),
        ))
        .go();
  }

  Future<int> deleteSecretQuestsForPerson(String personId) {
    return (delete(questsTable)
          ..where((t) => t.personID.equals(personId) & t.type.equals('secret')))
        .go();
  }

  Stream<List<QuestData>> watchActiveQuests(String personId) {
    return (select(questsTable)..where(
          (t) => t.isCompleted.equals(false) & t.personID.equals(personId),
        ))
        .watch();
  }

  Stream<List<QuestData>> watchAllQuests(String personId) {
    return (select(questsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<QuestData>> getAllQuests(String personId) =>
      (select(questsTable)..where((t) => t.personID.equals(personId))).get();

  Future<void> updateQuestProgress(String id, double value) async {
    final existing = await (select(
      questsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing != null) {
      final newValue = value;
      final target = existing.targetValue ?? 0.0;
      final isNowCompleted = newValue >= target;
      final companion = QuestsTableCompanion(
        id: Value(id),
        currentValue: Value(newValue),
        isCompleted: Value(isNowCompleted),
      );
      await (update(
        questsTable,
      )..where((t) => t.id.equals(id))).write(companion);

      await db.pushToSupabase(
        table: 'quests',
        payload: db.companionToMap(companion, questsTable),
      );
    }
  }
}
