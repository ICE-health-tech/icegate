import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:ice_shield/data_layer/Protocol/User/FinanceProtocols.dart';

class FinanceBlock {
  final accounts = listSignal<FinancialAccountProtocol>([]);
  final assets = listSignal<AssetProtocol>([]);
  final transactions = listSignal<TransactionData>([]);

  StreamSubscription? _accountsSubscription;
  StreamSubscription? _assetsSubscription;
  StreamSubscription? _transactionsSubscription;

  late FinanceDAO _dao;
  late String _personId;

  void updateAccounts(List<FinancialAccountProtocol> data) {
    accounts.value = data;
  }

  void updateAssets(List<AssetProtocol> data) {
    assets.value = data;
  }

  /// Total Net Worth (Accounts + Assets + Net Income)
  late final totalBalance = computed(() {
    final accSum = accounts.value.fold(0.0, (sum, acc) => sum + acc.balance);
    final assetSum = assets.value.fold(
      0.0,
      (sum, asset) => sum + (asset.currentEstimatedValue ?? 0.0),
    );

    final txs = transactions.value;
    final income = txs
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = txs
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final investment = txs
        .where((t) => t.type == 'investment')
        .fold(0.0, (sum, t) => sum + t.amount);

    final savings = txs
        .where((t) => t.type == 'savings')
        .fold(0.0, (sum, t) => sum + t.amount);

    return accSum + assetSum + (income + savings - expense - investment);
  });

  /// Total savings amount
  late final totalSavings = computed(() {
    return transactions.value
        .where((t) => t.type == 'savings')
        .fold(0.0, (sum, t) => sum + t.amount);
  });

  /// Monthly spending for the current month
  late final monthlySpending = computed(() {
    final now = DateTime.now();
    return transactions.value
        .where(
          (t) =>
              t.type == 'expense' &&
              t.transactionDate.month == now.month &&
              t.transactionDate.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  });

  /// Monthly income for the current month
  late final monthlyIncome = computed(() {
    final now = DateTime.now();
    return transactions.value
        .where(
          (t) =>
              t.type == 'income' &&
              t.transactionDate.month == now.month &&
              t.transactionDate.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  });

  /// Monthly net change (Income + Savings - Expenses - Investment)
  late final monthlyNetChange = computed(() {
    final now = DateTime.now();
    final txs = transactions.value.where(
      (t) =>
          t.transactionDate.month == now.month &&
          t.transactionDate.year == now.year,
    );

    final income = txs
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = txs
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final investment = txs
        .where((t) => t.type == 'investment')
        .fold(0.0, (sum, t) => sum + t.amount);
    final savings = txs
        .where((t) => t.type == 'savings')
        .fold(0.0, (sum, t) => sum + t.amount);

    return income + savings - expense - investment;
  });

  /// Percentage of net change relative to previous balance
  late final netChangePercent = computed(() {
    final change = monthlyNetChange.value;
    final total = totalBalance.value;
    final previousBalance = total - change;

    if (previousBalance <= 0) return 0.0;
    return (change / previousBalance) * 100;
  });

  /// Spending grouped by category this month
  late final spendingByCategory = computed(() {
    final now = DateTime.now();
    final monthExpenses = transactions.value.where(
      (t) =>
          t.type == 'expense' &&
          t.transactionDate.month == now.month &&
          t.transactionDate.year == now.year,
    );
    final Map<String, double> map = {};
    for (final t in monthExpenses) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  });

  void init(FinanceDAO dao, String personId) {
    if (personId.isEmpty) {
      debugPrint("FinanceBlock: Skipping init, personId is empty.");
      return;
    }
    _dao = dao;
    _personId = personId;

    _accountsSubscription?.cancel();
    _accountsSubscription = dao.watchAccounts(personId).listen((data) {
      final protocols = data
          .map(
            (e) => FinancialAccountProtocol(
              financialAccountID: e.accountID ?? "",
              personID: e.personID,
              accountName: e.accountName,
              accountType: e.accountType,
              balance: e.balance,
              currency: e.currency.name,
              isPrimary: e.isPrimary,
              isActive: e.isActive,
            ),
          )
          .toList();
      updateAccounts(protocols);
    });

    _assetsSubscription?.cancel();
    _assetsSubscription = dao.watchAssets(personId).listen((data) {
      final protocols = data
          .map(
            (e) => AssetProtocol(
              id: e.assetID ?? "",
              personId: e.personID,
              assetName: e.assetName,
              assetCategory: e.assetCategory,
              purchaseDate: e.purchaseDate,
              purchasePrice: e.purchasePrice,
              currentEstimatedValue: e.currentEstimatedValue,
              currency: e.currency.name,
              condition: e.condition,
              location: e.location,
              notes: e.notes,
              isInsured: e.isInsured,
            ),
          )
          .toList();
      updateAssets(protocols);
    });

    _transactionsSubscription?.cancel();
    _transactionsSubscription = dao.watchAllTransactions(personId).listen((
      data,
    ) {
      transactions.value = data;
    });
  }

  Future<void> addTransaction({
    required String category,
    required String type,
    required double amount,
    String? description,
    DateTime? date,
    String? projectID,
  }) async {
    if (_personId.isEmpty) return;
    await _dao.insertTransaction(
      TransactionsTableCompanion.insert(
        id: IDGen.generateUuid(),
        personID: _personId,
        category: category,
        type: type,
        amount: amount,
        description: Value(description),
        transactionDate: Value(date ?? DateTime.now()),
        projectID: Value(projectID),
      ),
    );
  }

  Future<void> deleteTransaction(String id) async {
    await _dao.deleteTransaction(id);
  }

  void dispose() {
    _accountsSubscription?.cancel();
    _assetsSubscription?.cancel();
    _transactionsSubscription?.cancel();
  }
}
