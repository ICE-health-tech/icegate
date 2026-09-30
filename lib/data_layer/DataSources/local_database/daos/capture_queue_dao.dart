part of '../database.dart';

/// Local queue of screen captures pending upload + extraction.
/// The daily capture budget is enforced by COUNTing rows rather than keeping
/// an in-memory counter, so an app restart cannot silently exceed the cap.
@DriftAccessor(tables: [CaptureQueueTable])
class CaptureQueueDAO extends DatabaseAccessor<AppDatabase>
    with _$CaptureQueueDAOMixin {
  CaptureQueueDAO(super.db);

  Future<void> enqueue(CaptureQueueTableCompanion entry) async {
    await into(captureQueueTable).insert(entry);
  }

  /// Row count for the calendar day, used for budget enforcement.
  Future<int> countCreatedToday(String personId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final count = countQuery(captureQueueTable)
      ..where(
        (t) =>
            t.personID.equals(personId) &
            t.createdAt.isBiggerOrEqualValue(startOfToday),
      );
    return await count.getSingle();
  }

  /// Pending rows, oldest first, so the queue drains in capture order.
  Future<List<CaptureQueueData>> getPending(String personId, {int limit = 10}) {
    return (select(captureQueueTable)
          ..where((t) => t.personID.equals(personId) & t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<CaptureQueueData>> watchQueue(String personId) {
    return (select(captureQueueTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> updateRow(String id, CaptureQueueTableCompanion companion) async {
    await (update(captureQueueTable)..where((t) => t.id.equals(id))).write(
      companion.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  /// Marks a row failed. Stays visible in the review UI rather than being
  /// dropped, so a failed capture is never silently lost.
  Future<void> markFailed(String id, String error) async {
    final row = await (select(
      captureQueueTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await updateRow(
      id,
      CaptureQueueTableCompanion(
        status: const Value('failed'),
        error: Value(error),
        attempts: Value(row.attempts + 1),
      ),
    );
  }

  Future<void> deleteRow(String id) async {
    await (delete(captureQueueTable)..where((t) => t.id.equals(id))).go();
  }

  /// Clears all captures and their uploaded images. Backs the "delete all
  /// captures" control — a consent requirement for this feature.
  Future<void> deleteAllForPerson(String personId) async {
    await (delete(
      captureQueueTable,
    )..where((t) => t.personID.equals(personId))).go();
  }

  /// Clears transient failure state on startup so a crash loop cannot
  /// permanently poison rows.
  Future<void> resetStaleInFlight() async {
    await update(captureQueueTable).write(
      const CaptureQueueTableCompanion(
        status: Value('pending'),
        error: Value(null),
        attempts: Value(0),
      ),
    );
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(captureQueueTable).insert(
      CaptureQueueTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String),
        sourceKind: Value(record['source_kind'] as String),
        appLabel: Value(record['app_label'] as String),
        route: Value(record['route'] as String?),
        imageUrl: Value(record['image_url'] as String?),
        score: Value(
          record['score'] == null ? 0.0 : (record['score'] as num).toDouble(),
        ),
        scoreReasons: Value(record['score_reasons'] as String?),
        status: Value(record['status'] as String? ?? 'pending'),
        attempts: Value(record['attempts'] as int? ?? 0),
        error: Value(record['error'] as String?),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : null,
        ),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : null,
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}
