part of '../database.dart';

@DriftAccessor(tables: [PortfolioSnapshotsTable])
class PortfolioSnapshotsDAO extends DatabaseAccessor<AppDatabase>
    with _$PortfolioSnapshotsDAOMixin {
  PortfolioSnapshotsDAO(super.db);

  Future<void> insertSnapshot(PortfolioSnapshotsTableCompanion snapshot) async {
    await into(portfolioSnapshotsTable).insert(snapshot);

    // Map to Supabase
    final Map<String, dynamic> payload = {};
    for (final col in portfolioSnapshotsTable.$columns) {
      final value = snapshot.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }
    await db.pushToSupabase(table: 'portfolio_snapshots', payload: payload);
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    final id = record['id'] as String;
    final personId = record['person_id'] as String;

    await into(portfolioSnapshotsTable).insert(
      PortfolioSnapshotsTableCompanion(
        id: Value(id),
        personID: Value(personId),
        totalNetWorth: Value((record['total_net_worth'] as num).toDouble()),
        athAtTime: Value((record['ath_at_time'] as num).toDouble()),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<PortfolioSnapshotData?> watchLatestSnapshot(String personId) {
    return (select(portfolioSnapshotsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<PortfolioSnapshotData?> getLatestSnapshot(String personId) {
    return (select(portfolioSnapshotsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }
}
