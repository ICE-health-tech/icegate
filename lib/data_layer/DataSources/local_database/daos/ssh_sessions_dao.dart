part of '../Database.dart';

@DriftAccessor(tables: [SSHSessionsTable])
class SSHSessionsDAO extends DatabaseAccessor<AppDatabase>
    with _$SSHSessionsDAOMixin {
  SSHSessionsDAO(super.db);

  Future<int> insertSSHSession(SSHSessionsTableCompanion entry) async {
    final res = await into(sSHSessionsTable).insert(entry);
    
    // Sync to Supabase
    await attachedDatabase.pushToSupabase(
      table: 'ssh_sessions',
      payload: attachedDatabase.companionToMap(entry, sSHSessionsTable),
    );
    
    return res;
  }

  Future<bool> updateSSHSession(SSHSessionData entry) async {
    final res = await update(sSHSessionsTable).replace(entry);
    
    // Sync to Supabase
    await attachedDatabase.pushToSupabase(
      table: 'ssh_sessions',
      payload: entry.toJson(),
    );
    
    return res;
  }

  Future<int> deleteSSHSession(String id) async {
    final res = await (delete(sSHSessionsTable)..where((t) => t.id.equals(id))).go();
    
    // Sync to Supabase
    await attachedDatabase.pushToSupabase(
      table: 'ssh_sessions',
      payload: {'id': id},
      isDelete: true,
    );
    
    return res;
  }

  Future<int> markSessionAsDeleted(String id) async {
    final companion = const SSHSessionsTableCompanion(isActive: Value(false));
    final res = await (update(sSHSessionsTable)..where((t) => t.id.equals(id))).write(companion);
    
    // Sync to Supabase
    await attachedDatabase.pushToSupabase(
      table: 'ssh_sessions',
      payload: {'id': id, 'is_active': false},
    );
    
    return res;
  }

  Stream<List<SSHSessionData>> watchActiveSessions() =>
      (select(sSHSessionsTable)..where((t) => t.isActive.equals(true))).watch();

  Future<SSHSessionData?> getSessionById(String id) => (select(
    sSHSessionsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> deleteSessionsByIp(String ip) async {
    // Get IDs first to sync deletes
    final sessions = await (select(sSHSessionsTable)..where((t) => t.ipAddress.equals(ip))).get();
    final res = await (delete(sSHSessionsTable)..where((t) => t.ipAddress.equals(ip))).go();
    
    // Sync to Supabase
    for (final session in sessions) {
      await attachedDatabase.pushToSupabase(
        table: 'ssh_sessions',
        payload: {'id': session.id},
        isDelete: true,
      );
    }
    
    return res;
  }

  Future<int> updateAiModelByIp(String ip, String aiModel) async {
    final companion = SSHSessionsTableCompanion(aiModel: Value(aiModel));
    final res = await (update(sSHSessionsTable)..where((t) => t.ipAddress.equals(ip))).write(companion);
    
    // Get sessions to sync to Supabase
    final sessions = await (select(sSHSessionsTable)..where((t) => t.ipAddress.equals(ip))).get();
    for (final session in sessions) {
      await attachedDatabase.pushToSupabase(
        table: 'ssh_sessions',
        payload: {'id': session.id, 'ai_model': aiModel},
      );
    }
    
    return res;
  }
}
