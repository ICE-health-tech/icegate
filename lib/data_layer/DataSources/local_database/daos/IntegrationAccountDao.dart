part of '../Database.dart';

@DriftAccessor(tables: [IntegrationAccountsTable])
class IntegrationAccountDAO extends DatabaseAccessor<AppDatabase>
    with _$IntegrationAccountDAOMixin {
  IntegrationAccountDAO(super.db);

  Future<List<IntegrationAccountData>> listForPerson(String personId) {
    return (select(integrationAccountsTable)
          ..where((t) => t.personId.equals(personId))
          ..orderBy([(t) => OrderingTerm.asc(t.domain)]))
        .get();
  }

  Future<IntegrationAccountData?> getForProvider(
    String personId,
    String domain,
    String provider,
  ) {
    return (select(integrationAccountsTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.domain.equals(domain) &
                t.provider.equals(provider),
          ))
        .getSingleOrNull();
  }

  Future<void> upsert(IntegrationAccountsTableCompanion companion) async {
    await into(integrationAccountsTable).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
    final id = companion.id.value;
    final row = await (select(integrationAccountsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await db.pushToSupabase(
      table: 'integration_accounts',
      payload: _integrationAccountPayload(row),
    );
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(integrationAccountsTable).insert(
      IntegrationAccountsTableCompanion(
        id: Value(record['id'] as String),
        personId: Value(record['person_id'] as String),
        domain: Value(record['domain'] as String),
        provider: Value(record['provider'] as String),
        status: Value(record['status'] as String? ?? 'disconnected'),
        displayName: Value(record['display_name'] as String? ?? ''),
        externalAccountId: Value(record['external_account_id'] as String?),
        configJson: Value(record['config_json'] as String?),
        lastSyncAt: Value(
          record['last_sync_at'] != null
              ? DateTime.parse(record['last_sync_at'].toString())
              : null,
        ),
        lastError: Value(record['last_error'] as String?),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  static Map<String, dynamic> _integrationAccountPayload(
    IntegrationAccountData row,
  ) {
    return {
      'id': row.id,
      'person_id': row.personId,
      'domain': row.domain,
      'provider': row.provider,
      'status': row.status,
      'display_name': row.displayName,
      'external_account_id': row.externalAccountId,
      'config_json': row.configJson,
      'last_sync_at': row.lastSyncAt?.toIso8601String(),
      'last_error': row.lastError,
      'created_at': row.createdAt.toIso8601String(),
      'updated_at': row.updatedAt.toIso8601String(),
    };
  }
}
