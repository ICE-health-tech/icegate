part of '../Database.dart';

@DriftAccessor(tables: [GratitudeEntriesTable])
class GratitudeDAO extends DatabaseAccessor<AppDatabase>
    with _$GratitudeDAOMixin {
  GratitudeDAO(super.db);

  Stream<List<GratitudeEntryData>> watchForPerson(String personId) {
    return (select(gratitudeEntriesTable)
          ..where((t) => t.personId.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<GratitudeEntryData?> entryById(String id) {
    return (select(gratitudeEntriesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertEntry({
    required String id,
    required String personId,
    required String name,
    String kind = 'person',
    String? note,
    String? facebookUrl,
    String? avatarLocalPath,
  }) async {
    final now = DateTime.now().toUtc();
    await into(gratitudeEntriesTable).insert(
      GratitudeEntriesTableCompanion.insert(
        id: id,
        personId: personId,
        name: name,
        kind: Value(kind),
        note: Value(note),
        facebookUrl: Value(facebookUrl),
        avatarLocalPath: Value(avatarLocalPath),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await _pushEntry(
      id: id,
      personId: personId,
      name: name,
      kind: kind,
      note: note,
      facebookUrl: facebookUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateEntry({
    required String id,
    required String name,
    required String kind,
    String? note,
    String? facebookUrl,
    String? avatarLocalPath,
  }) async {
    final row = await entryById(id);
    if (row == null) return;
    final now = DateTime.now().toUtc();
    await (update(gratitudeEntriesTable)..where((t) => t.id.equals(id))).write(
      GratitudeEntriesTableCompanion(
        name: Value(name),
        kind: Value(kind),
        note: Value(note),
        facebookUrl: Value(facebookUrl),
        avatarLocalPath: avatarLocalPath != null
            ? Value(avatarLocalPath)
            : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
    await _pushEntry(
      id: row.id,
      personId: row.personId,
      name: name,
      kind: kind,
      note: note,
      facebookUrl: facebookUrl,
      createdAt: row.createdAt.toUtc(),
      updatedAt: now,
    );
  }

  Future<void> updateAvatar({
    required String id,
    required String avatarLocalPath,
  }) async {
    final row = await entryById(id);
    if (row == null) return;
    final now = DateTime.now().toUtc();
    await (update(gratitudeEntriesTable)..where((t) => t.id.equals(id))).write(
      GratitudeEntriesTableCompanion(
        avatarLocalPath: Value(avatarLocalPath),
        updatedAt: Value(now),
      ),
    );
    await _pushEntry(
      id: row.id,
      personId: row.personId,
      name: row.name,
      kind: row.kind,
      note: row.note,
      facebookUrl: row.facebookUrl,
      createdAt: row.createdAt.toUtc(),
      updatedAt: now,
    );
  }

  Future<void> deleteEntry(String id) async {
    await (delete(gratitudeEntriesTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'gratitude_entries',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> pushAllToCloud(String personId) async {
    if (personId.isEmpty) return;
    final rows = await (select(gratitudeEntriesTable)
          ..where((t) => t.personId.equals(personId)))
        .get();
    for (final row in rows) {
      await _pushEntry(
        id: row.id,
        personId: row.personId,
        name: row.name,
        kind: row.kind,
        note: row.note,
        facebookUrl: row.facebookUrl,
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );
    }
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final existing = await entryById(r['id'] as String);
    await into(gratitudeEntriesTable).insert(
      GratitudeEntriesTableCompanion(
        id: Value(r['id'] as String),
        personId: Value(r['person_id'] as String),
        name: Value(r['name'] as String),
        kind: Value((r['kind'] as String?) ?? 'person'),
        note: Value(r['note'] as String?),
        facebookUrl: Value(r['facebook_url'] as String?),
        avatarLocalPath: existing?.avatarLocalPath != null
            ? Value(existing!.avatarLocalPath)
            : const Value.absent(),
        createdAt: Value(DateTime.parse(r['created_at'] as String)),
        updatedAt: Value(DateTime.parse(r['updated_at'] as String)),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> _pushEntry({
    required String id,
    required String personId,
    required String name,
    required String kind,
    String? note,
    String? facebookUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    await db.pushToSupabase(
      table: 'gratitude_entries',
      payload: {
        'id': id,
        'person_id': personId,
        'name': name,
        'kind': kind,
        'note': note,
        'facebook_url': facebookUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      },
    );
  }
}
