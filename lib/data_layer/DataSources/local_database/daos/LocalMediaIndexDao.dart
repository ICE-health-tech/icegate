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

  Future<void> markSynced({
    required String personId,
    required String relativePath,
    required String remotePath,
    required String device,
    required String subFolder,
    required String fileName,
    int? fileBytes,
    DateTime? lastModifiedAt,
  }) async {
    final now = DateTime.now();
    await upsertMany([
      LocalMediaIndexTableCompanion(
        id: Value(deterministicId(
          personId: personId,
          relativePath: relativePath,
        )),
        personID: Value(personId),
        relativePath: Value(relativePath),
        remotePath: Value(remotePath),
        device: Value(device),
        subFolder: Value(subFolder),
        fileName: Value(fileName),
        fileBytes: Value(fileBytes),
        lastModifiedAt: Value(lastModifiedAt),
        updatedAt: Value(now),
      ),
    ]);
  }
}

