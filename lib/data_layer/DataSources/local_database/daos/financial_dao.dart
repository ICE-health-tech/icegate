part of '../Database.dart';

@DriftAccessor(tables: [FinancialAccountsTable])
class FinancialAccountDAO extends DatabaseAccessor<AppDatabase>
    with _$FinancialAccountDAOMixin {
  FinancialAccountDAO(super.db);

  Future<int> insertAccount(FinancialAccountsTableCompanion entry) =>
      into(financialAccountsTable).insert(entry);

  Future<bool> updateAccount(FinancialAccountData entry) =>
      update(financialAccountsTable).replace(entry);

  Future<int> deleteAccount(String id) =>
      (delete(financialAccountsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<FinancialAccountData>> watchAllAccounts(String personId) =>
      (select(financialAccountsTable)..where((t) => t.personID.equals(personId)))
          .watch();

  Future<List<FinancialAccountData>> getAllAccounts(String personId) =>
      (select(financialAccountsTable)..where((t) => t.personID.equals(personId)))
          .get();
}

@DriftAccessor(tables: [AssetsTable])
class AssetDAO extends DatabaseAccessor<AppDatabase> with _$AssetDAOMixin {
  AssetDAO(super.db);

  Future<int> insertAsset(AssetsTableCompanion entry) =>
      into(assetsTable).insert(entry);

  Future<bool> updateAsset(AssetData entry) => update(assetsTable).replace(entry);

  Future<int> deleteAsset(String id) =>
      (delete(assetsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<AssetData>> watchAllAssets(String personId) =>
      (select(assetsTable)..where((t) => t.personID.equals(personId))).watch();
}

@DriftAccessor(tables: [TransactionsTable])
class TransactionDAO extends DatabaseAccessor<AppDatabase>
    with _$TransactionDAOMixin {
  TransactionDAO(super.db);

  Future<int> insertTransaction(TransactionsTableCompanion entry) =>
      into(transactionsTable).insert(entry);

  Future<int> deleteTransaction(String id) =>
      (delete(transactionsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<TransactionData>> watchAllTransactions(String personId) =>
      (select(transactionsTable)..where((t) => t.personID.equals(personId)))
          .watch();

  Stream<List<TransactionData>> watchTransactionsByProject(String projectId) =>
      (select(transactionsTable)..where((t) => t.projectID.equals(projectId)))
          .watch();
}

@DriftAccessor(tables: [SubscriptionsTable])
class SubscriptionDAO extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionDAOMixin {
  SubscriptionDAO(super.db);

  Future<int> insertSubscription(SubscriptionsTableCompanion entry) =>
      into(subscriptionsTable).insert(entry);

  Future<bool> updateSubscription(SubscriptionData entry) =>
      update(subscriptionsTable).replace(entry);

  Future<int> deleteSubscription(String id) =>
      (delete(subscriptionsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<SubscriptionData>> watchAllSubscriptions(String personId) =>
      (select(subscriptionsTable)..where((t) => t.personID.equals(personId)))
          .watch();
}

@DriftAccessor(tables: [FinancialMetricsTable])
class FinancialMetricsDAO extends DatabaseAccessor<AppDatabase>
    with _$FinancialMetricsDAOMixin {
  FinancialMetricsDAO(super.db);

  Future<int> insertMetric(FinancialMetricsTableCompanion entry) =>
      into(financialMetricsTable).insert(entry);

  Future<void> upsertMetric(FinancialMetricsTableCompanion entry) async {
    await into(financialMetricsTable).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Stream<List<FinancialMetricsLocal>> watchMetrics(String personId) =>
      (select(financialMetricsTable)..where((t) => t.personID.equals(personId)))
          .watch();

  Future<FinancialMetricsLocal?> getMetric(String personId, DateTime date, String category) =>
      (select(financialMetricsTable)
            ..where((t) =>
                t.personID.equals(personId) &
                t.date.equals(date) &
                t.category.equals(category)))
          .getSingleOrNull();
}
