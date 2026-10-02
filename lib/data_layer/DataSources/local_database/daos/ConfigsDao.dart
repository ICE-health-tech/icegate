part of '../Database.dart';

@DriftAccessor(tables: [ConfigsTable])
class ConfigsDAO extends DatabaseAccessor<AppDatabase> with _$ConfigsDAOMixin {
  ConfigsDAO(super.db);

  Future<ConfigData?> getConfig(String personID, String key) {
    return (select(configsTable)
          ..where((t) => t.personID.equals(personID) & t.configKey.equals(key)))
        .getSingleOrNull();
  }

  Future<int> setConfig(String personID, String key, String value) async {
    final existing = await getConfig(personID, key);
    if (existing != null) {
      final companion = ConfigsTableCompanion(
        configValue: Value(value),
        updatedAt: Value(DateTime.now()),
      );
      final res = await (update(configsTable)..where(
            (t) => t.personID.equals(personID) & t.configKey.equals(key),
          ))
          .write(companion);
      
      // Sync to Supabase
      await attachedDatabase.pushToSupabase(
        table: 'themes_config',
        payload: {
          'id': existing.id,
          'config_value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      
      return res;
    } else {
      final id = IDGen.UUIDV7();
      final companion = ConfigsTableCompanion.insert(
        id: id,
        personID: Value(personID),
        configKey: key,
        configValue: value,
        updatedAt: Value(DateTime.now()),
      );
      final res = await into(configsTable).insert(companion);
      
      // Sync to Supabase
      await attachedDatabase.pushToSupabase(
        table: 'themes_config',
        payload: attachedDatabase.companionToMap(companion, configsTable),
      );
      
      return res;
    }
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(configsTable).insert(
      ConfigsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String),
        configKey: Value(record['config_key'] as String),
        configValue: Value(record['config_value'] as String),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}
