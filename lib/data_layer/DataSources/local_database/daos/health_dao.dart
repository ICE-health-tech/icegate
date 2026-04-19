part of '../Database.dart';

@DriftAccessor(
  tables: [
    WaterLogsTable,
    SleepLogsTable,
    ExerciseLogsTable,
    WeightLogsTable,
    FocusSessionsTable,
  ],
)
class HealthLogsDAO extends DatabaseAccessor<AppDatabase>
    with _$HealthLogsDAOMixin {
  HealthLogsDAO(super.db);

  // Water Logs
  Future<void> insertWaterLog(WaterLogsTableCompanion entry) async {
    await into(waterLogsTable).insert(entry);
    await db.pushToSupabase(
      table: 'water_logs',
      payload: db.companionToMap(entry, waterLogsTable),
    );
  }

  Future<void> upsertFromSupabaseWater(Map<String, dynamic> record) async {
    await into(waterLogsTable).insert(
      WaterLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        amount: Value((record['amount'] as num).toInt()),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<List<WaterLogData>> watchDailyWaterLogs(
    String personId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(waterLogsTable)..where(
          (t) =>
              t.personID.equals(personId) &
              t.timestamp.isBetweenValues(start, end),
        ))
        .watch();
  }

  Future<void> deleteWaterLog(String id) async {
    await (delete(waterLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'water_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<int> getDailyWaterTotal(String personId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final logs =
        await (select(waterLogsTable)..where(
              (t) =>
                  t.personID.equals(personId) &
                  t.timestamp.isBetweenValues(start, end),
            ))
            .get();

    return logs.fold<int>(0, (sum, log) => sum + log.amount);
  }

  // Sleep Logs
  Future<void> insertSleepLog(SleepLogsTableCompanion entry) async {
    await into(sleepLogsTable).insert(entry);
    await db.pushToSupabase(
      table: 'sleep_logs',
      payload: db.companionToMap(entry, sleepLogsTable),
    );
  }

  Future<void> upsertFromSupabaseSleep(Map<String, dynamic> record) async {
    await into(sleepLogsTable).insert(
      SleepLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        startTime: Value(DateTime.parse(record['start_time'].toString())),
        endTime: Value(DateTime.parse(record['end_time'].toString())),
        quality: Value((record['quality'] as num?)?.toInt() ?? 3),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteSleepLog(String id) async {
    await (delete(sleepLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'sleep_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Stream<List<SleepLogData>> watchSleepLogs(String personId) {
    return (select(
      sleepLogsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }

  // Exercise Logs
  Future<void> insertExerciseLog(ExerciseLogsTableCompanion entry) async {
    await into(exerciseLogsTable).insert(entry);
    await db.pushToSupabase(
      table: 'exercise_logs',
      payload: db.companionToMap(entry, exerciseLogsTable),
    );
  }

  Future<void> upsertFromSupabaseExercise(Map<String, dynamic> record) async {
    await into(exerciseLogsTable).insert(
      ExerciseLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        type: Value(record['type'] as String),
        durationMinutes: Value((record['duration_minutes'] as num).toInt()),
        intensity: Value(record['intensity'] as String),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
        focusSessionID: Value(record['focus_session_id'] as String?),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteExerciseLog(String id) async {
    await (delete(exerciseLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'exercise_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Stream<List<ExerciseLogData>> watchDailyExerciseLogs(
    String personId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(exerciseLogsTable)..where(
          (t) =>
              t.personID.equals(personId) &
              t.timestamp.isBetweenValues(start, end),
        ))
        .watch();
  }

  Future<int> getDailyExerciseTotal(String personId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final logs =
        await (select(exerciseLogsTable)..where(
              (t) =>
                  t.personID.equals(personId) &
                  t.timestamp.isBetweenValues(start, end),
            ))
            .get();

    return logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
  }

  Future<List<ExerciseWithFocusSession>> getDailyExerciseWithSession(
    String personId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final rows = await customSelect(
      '''
      SELECT
        e.id,
        e.person_id,
        e.type,
        e.duration_minutes,
        e.intensity,
        e.timestamp,
        e.focus_session_id,
        e.health_metric_id,
        f.duration_seconds AS focus_duration_seconds
      FROM exercise_logs e
      LEFT JOIN focus_sessions f ON e.focus_session_id = f.id
      WHERE e.person_id = :personId
        AND e.timestamp >= :start
        AND e.timestamp < :end
      ORDER BY e.timestamp ASC
      ''',
      variables: [
        Variable.withString(personId),
        Variable.withString(start.toIso8601String()),
        Variable.withString(end.toIso8601String()),
      ],
      readsFrom: {exerciseLogsTable, focusSessionsTable},
    ).get();

    return rows.map((row) {
      return ExerciseWithFocusSession(
        id: row.read<String>('id'),
        personId: row.read<String>('person_id'),
        type: row.read<String>('type'),
        durationMinutes: row.readNullable<int>('focus_duration_seconds') != null
            ? (row.read<int>('focus_duration_seconds') ~/ 60)
            : row.read<int>('duration_minutes'),
        exactDurationSeconds: row.readNullable<int>('focus_duration_seconds'),
        intensity: row.read<String>('intensity'),
        timestamp: DateTime.parse(row.read<String>('timestamp')),
        focusSessionId: row.readNullable<String>('focus_session_id'),
      );
    }).toList();
  }

  // Weight Logs
  Future<void> insertWeightLog(WeightLogsTableCompanion entry) async {
    final existing = await (select(
      weightLogsTable,
    )..where((t) => t.id.equals(entry.id.value))).getSingleOrNull();

    if (existing == null) {
      await into(weightLogsTable).insert(entry);
      await db.pushToSupabase(
        table: 'weight_logs',
        payload: db.companionToMap(entry, weightLogsTable),
      );
    }
  }

  Future<void> upsertFromSupabaseWeight(Map<String, dynamic> record) async {
    await into(weightLogsTable).insert(
      WeightLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        weightKg: Value((record['weight_kg'] as num).toDouble()),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<List<WeightLogData>> watchDailyWeightLogs(
    String personId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(weightLogsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.timestamp.isBetweenValues(start, end),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<WeightLogData?> watchLatestWeightLog(String personId) {
    return (select(weightLogsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> deleteWeightLog(String id) async {
    await (delete(weightLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'weight_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }
}

@DataClassName('MealData')
class MealDAO extends DatabaseAccessor<AppDatabase> with _$MealDAOMixin {
  MealDAO(super.db);

  Future<int> insertMeal(MealsTableCompanion entry) {
    return into(mealsTable).insert(entry);
  }

  Future<bool> updateMeal(MealData entry) {
    return update(mealsTable).replace(entry);
  }

  Future<int> deleteMeal(String id) {
    return (delete(mealsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<MealData>> watchAllMeals(String personId) {
    return (select(mealsTable)..where((t) => t.personID.equals(personId))).watch();
  }
}

@DataClassName('DayData')
class DaysDAO extends DatabaseAccessor<AppDatabase> with _$DaysDAOMixin {
  DaysDAO(super.db);

  Future<int> insertDay(DaysTableCompanion entry) {
    return into(daysTable).insert(entry);
  }

  Future<bool> updateDay(DayData entry) {
    return update(daysTable).replace(entry);
  }
}

class ExerciseWithFocusSession {
  final String id;
  final String personId;
  final String type;
  final int durationMinutes;
  final int? exactDurationSeconds;
  final String intensity;
  final DateTime timestamp;
  final String? focusSessionId;

  const ExerciseWithFocusSession({
    required this.id,
    required this.personId,
    required this.type,
    required this.durationMinutes,
    required this.exactDurationSeconds,
    required this.intensity,
    required this.timestamp,
    required this.focusSessionId,
  });

  int get durationSeconds => exactDurationSeconds ?? (durationMinutes * 60);
}
