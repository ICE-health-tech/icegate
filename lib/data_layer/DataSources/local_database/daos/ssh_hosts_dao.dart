part of '../Database.dart';

@DriftAccessor(tables: [SSHHostsTable])
class SSHHostsDAO extends DatabaseAccessor<AppDatabase>
    with _$SSHHostsDAOMixin {
  SSHHostsDAO(super.db);

  Future<int> insertSSHHost(SSHHostsTableCompanion entry) =>
      into(sSHHostsTable).insert(entry);

  Future<bool> updateSSHHost(SSHHostData entry) =>
      update(sSHHostsTable).replace(entry);

  Future<int> deleteSSHHost(String id) =>
      (delete(sSHHostsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<SSHHostData>> watchAllSSHHosts() => select(sSHHostsTable).watch();

  Future<SSHHostData?> getSSHHostById(String id) =>
      (select(sSHHostsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
}
