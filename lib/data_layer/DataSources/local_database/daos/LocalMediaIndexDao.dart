part of '../Database.dart';

@DriftAccessor(tables: [LocalMediaIndexTable])
class LocalMediaIndexDAO extends DatabaseAccessor<AppDatabase>
    with _$LocalMediaIndexDAOMixin {
  LocalMediaIndexDAO(super.db);

  static String deterministicId({
    required String personId,
    required String relativePath,
  }) {
    return sha1.convert(utf8.encode('$personId|$relativePath')).toString();
  }

  Future<void> upsertMany(List<LocalMediaIndexTableCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localMediaIndexTable, rows);
    });
  }

  Stream<List<LocalMediaIndexData>> watchByPerson(String personId) {
    return (select(localMediaIndexTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<List<LocalMediaIndexData>> getAllByPerson(String personId) {
    return (select(localMediaIndexTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }
}

