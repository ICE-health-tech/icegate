part of '../Database.dart';

@DriftAccessor(tables: [HourlyActivityLogTable])
class HourlyActivityLogDAO extends DatabaseAccessor<AppDatabase>
    with _$HourlyActivityLogDAOMixin {
  HourlyActivityLogDAO(super.db);

  Future<int> insertActivity(HourlyActivityLogTableCompanion entry) {
    return into(hourlyActivityLogTable).insert(entry);
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(hourlyActivityLogTable).insert(
      HourlyActivityLogTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String),
        startTime: Value(DateTime.parse(record['start_time'].toString())),
        endTime: Value(record['end_time'] != null
            ? DateTime.parse(record['end_time'].toString())
            : null),
        logDate: Value(DateTime.parse(record['log_date'].toString())),
        stepsCount: Value(record['steps_count'] as int),
        distanceKm: Value((record['distance_km'] as num).toDouble()),
        caloriesBurned: Value(record['calories_burned'] as int),
        createdAt: Value(record['created_at'] != null
            ? DateTime.parse(record['created_at'].toString())
            : DateTime.now()),
        updatedAt: Value(record['updated_at'] != null
            ? DateTime.parse(record['updated_at'].toString())
            : DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<List<HourlyActivityLogData>> watchLogsByDay(
      String personId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(hourlyActivityLogTable)
          ..where((t) =>
              t.personID.equals(personId) & t.logDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .watch();
  }

  Future<List<HourlyActivityLogData>> getLogsByDay(
      String personId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(hourlyActivityLogTable)
          ..where((t) =>
              t.personID.equals(personId) & t.logDate.isBetweenValues(start, end)))
        .get();
  }
}
