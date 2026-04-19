part of '../Database.dart';

@DriftAccessor(tables: [ScoresTable])
class ScoreDAO extends DatabaseAccessor<AppDatabase> with _$ScoreDAOMixin {
  ScoreDAO(super.db);

  Future<int> insertScore(ScoresTableCompanion entry) => into(scoresTable).insert(entry);

  Future<bool> updateScore(ScoreData entry) => update(scoresTable).replace(entry);

  Stream<ScoreLocalData?> watchScoreByPerson(String personId) =>
      (select(scoresTable)..where((t) => t.personID.equals(personId)))
          .watchSingleOrNull();

  Future<ScoreLocalData?> getScoreByPerson(String personId) =>
      (select(scoresTable)..where((t) => t.personID.equals(personId)))
          .getSingleOrNull();
  
  Future<void> upsertScore(ScoresTableCompanion entry) async {
    await into(scoresTable).insert(entry, mode: InsertMode.insertOrReplace);
  }
}

@DriftAccessor(tables: [HealthMetricsTable])
class HealthMetricsDAO extends DatabaseAccessor<AppDatabase>
    with _$HealthMetricsDAOMixin {
  HealthMetricsDAO(super.db);

  Future<int> insertMetric(HealthMetricsTableCompanion entry) =>
      into(healthMetricsTable).insert(entry);

  Future<void> upsertMetric(HealthMetricsTableCompanion entry) async {
    await into(healthMetricsTable).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Stream<List<HealthMetricsLocal>> watchMetrics(String personId) =>
      (select(healthMetricsTable)..where((t) => t.personID.equals(personId)))
          .watch();

  Future<HealthMetricsLocal?> getMetric(String personId, DateTime date, String category) =>
      (select(healthMetricsTable)
            ..where((t) =>
                t.personID.equals(personId) &
                t.date.equals(date) &
                t.category.equals(category)))
          .getSingleOrNull();
}

@DriftAccessor(tables: [ProjectMetricsTable])
class ProjectMetricsDAO extends DatabaseAccessor<AppDatabase>
    with _$ProjectMetricsDAOMixin {
  ProjectMetricsDAO(super.db);

  Future<int> insertMetric(ProjectMetricsTableCompanion entry) =>
      into(projectMetricsTable).insert(entry);

  Future<void> upsertMetric(ProjectMetricsTableCompanion entry) async {
    await into(projectMetricsTable).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Stream<List<ProjectMetricsLocal>> watchMetrics(String personId) =>
      (select(projectMetricsTable)..where((t) => t.personID.equals(personId)))
          .watch();

  Future<ProjectMetricsLocal?> getMetric(String personId, DateTime date, String category) =>
      (select(projectMetricsTable)
            ..where((t) =>
                t.personID.equals(personId) &
                t.date.equals(date) &
                t.category.equals(category)))
          .getSingleOrNull();
}

@DriftAccessor(tables: [SocialMetricsTable])
class SocialMetricsDAO extends DatabaseAccessor<AppDatabase>
    with _$SocialMetricsDAOMixin {
  SocialMetricsDAO(super.db);

  Future<int> insertMetric(SocialMetricsTableCompanion entry) =>
      into(socialMetricsTable).insert(entry);

  Future<void> upsertMetric(SocialMetricsTableCompanion entry) async {
    await into(socialMetricsTable).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Stream<List<SocialMetricsLocal>> watchMetrics(String personId) =>
      (select(socialMetricsTable)..where((t) => t.personID.equals(personId)))
          .watch();

  Future<SocialMetricsLocal?> getMetric(String personId, DateTime date, String category) =>
      (select(socialMetricsTable)
            ..where((t) =>
                t.personID.equals(personId) &
                t.date.equals(date) &
                t.category.equals(category)))
          .getSingleOrNull();
}
