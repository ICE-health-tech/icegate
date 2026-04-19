part of '../Database.dart';

@DriftAccessor(tables: [SSHSessionsTable])
class SSHSessionDAO extends DatabaseAccessor<AppDatabase>
    with _$SSHSessionDAOMixin {
  SSHSessionDAO(super.db);

  Future<int> insertSession(SSHSessionsTableCompanion entry) =>
      into(sSHSessionsTable).insert(entry);

  Future<bool> updateSession(SSHSessionData entry) =>
      update(sSHSessionsTable).replace(entry);

  Future<int> deleteSession(String id) =>
      (delete(sSHSessionsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<SSHSessionData>> watchAllSessions() =>
      select(sSHSessionsTable).watch();

  Future<SSHSessionData?> getSessionById(String id) =>
      (select(sSHSessionsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Stream<List<SSHSessionData>> watchActiveSessions() {
    return (select(sSHSessionsTable)..where((t) => t.isActive.equals(true)))
        .watch();
  }
}
