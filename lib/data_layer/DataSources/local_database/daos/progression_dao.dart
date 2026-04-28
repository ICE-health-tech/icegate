part of '../database.dart';

@DriftAccessor(tables: [QuestsTable])
class QuestDAO extends DatabaseAccessor<AppDatabase> with _$QuestDAOMixin {
  QuestDAO(super.db);

  Future<void> insertQuest(QuestsTableCompanion entry) async {
    // Force category to lowercase if present
    var updatedEntry = entry;
    if (entry.category.present) {
      final categoryValue = entry.category.value;
      updatedEntry = entry.copyWith(
        category: Value(categoryValue?.toLowerCase()),
      );
    }
    await into(questsTable).insert(updatedEntry);

    // Direct push to Supabase using shared helper
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

  /// Clears stale auto-generated dailies before inserting a new day's batch.
  Future<void> deleteIncompleteDailyQuestsForPerson(String personId) async {
    final toDelete =
        await (select(questsTable)..where(
              (t) =>
                  t.personID.equals(personId) &
                  t.isCompleted.equals(false) &
                  t.type.equals('daily'),
            ))
            .get();

    await (delete(questsTable)..where(
          (t) =>
              t.personID.equals(personId) &
              t.isCompleted.equals(false) &
              t.type.equals('daily'),
        ))
        .go();

    for (final q in toDelete) {
      await db.pushToSupabase(
        table: 'quests',
        payload: {'id': q.id},
        isDelete: true,
      );
    }
  }

  /// Permanently removes all quests for a person (both active and completed).
  Future<void> deleteAllQuestsForPerson(String personId) async {
    // 1. Get all local quests for this person first to sync deletion
    final localQuests = await (select(
      questsTable,
    )..where((t) => t.personID.equals(personId))).get();

    // 2. Delete locally
    await (delete(questsTable)..where((t) => t.personID.equals(personId))).go();

    // 3. Sync deletions to Supabase
    for (final quest in localQuests) {
      await db.pushToSupabase(
        table: 'quests',
        payload: {'id': quest.id},
        isDelete: true,
      );
    }
  }

  /// Removes all secret quests for a person. Used to clean up mock mysterious quests.
  Future<void> deleteSecretQuestsForPerson(String personId) async {
    final toDelete =
        await (select(questsTable)..where(
              (t) => t.personID.equals(personId) & t.type.equals('secret'),
            ))
            .get();

    await (delete(questsTable)
          ..where((t) => t.personID.equals(personId) & t.type.equals('secret')))
        .go();

    for (final q in toDelete) {
      await db.pushToSupabase(
        table: 'quests',
        payload: {'id': q.id},
        isDelete: true,
      );
    }
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

  Stream<List<QuestData>> watchQuestsByPerson(String personId) {
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
