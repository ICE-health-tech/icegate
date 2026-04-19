part of '../Database.dart';

@DriftAccessor(tables: [AchievementsTable])
class AchievementsDAO extends DatabaseAccessor<AppDatabase>
    with _$AchievementsDAOMixin {
  AchievementsDAO(super.db);

  Future<int> insertAchievement(AchievementsTableCompanion entry) {
    return into(achievementsTable).insert(entry);
  }

  Stream<List<AchievementData>> watchAchievementsByPerson(String personId) {
    return (select(achievementsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }
}

@DriftAccessor(tables: [MindLogsTable])
class MindLogsDAO extends DatabaseAccessor<AppDatabase>
    with _$MindLogsDAOMixin {
  MindLogsDAO(super.db);

  Future<int> insertMindLog(MindLogsTableCompanion entry) {
    return into(mindLogsTable).insert(entry);
  }

  Stream<List<MindLogData>> watchMindLogsByPerson(String personId) {
    return (select(mindLogsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.logDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(mindLogsTable).insert(
      MindLogsTableCompanion(
        id: Value(record['id'] as String),
        tenantID: Value(record['tenant_id'] as String?),
        personID: Value(record['person_id'] as String?),
        moodScore: Value(record['mood_score'] as int),
        moodEmoji: Value(record['mood_emoji'] as String?),
        activities: Value(record['activities'] as String),
        note: Value(record['note'] as String?),
        logDate: Value(DateTime.parse(record['log_date'] as String)),
        createdAt: Value(DateTime.parse(record['created_at'] as String)),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}
