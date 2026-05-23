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
  }
}
