import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/ui_layer/finance_page/utils/QuantMath.dart';
import 'package:intl/intl.dart';

class FinanceBlock {
  final accounts = listSignal<FinancialAccountProtocol>([]);
  final assets = listSignal<AssetProtocol>([]);
  final transactions = listSignal<TransactionData>([]);

  StreamSubscription? _accountsSubscription;
  StreamSubscription? _assetsSubscription;
  StreamSubscription? _transactionsSubscription;

  late FinanceDAO _dao;
  late PortfolioSnapshotsDAO _snapshotDao;
  late String _personId;

  final _persistedAth = signal<double>(0.0);

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

  /// Calculate points based on total net worth
  /// Rule: +2 points for every $10 = +0.2 points per $1
  late final financePoints = computed(() {
    if (FINANCE_NET_WORTH_PER_POINT <= 0) return 0.0;
    // Points = Total Net Worth / 5 (since 10/2 = 5)
    return totalBalance.value / FINANCE_NET_WORTH_PER_POINT;
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

  /// All-Time High Net Worth (Persisted)
  late final athBalance = computed(() {
    final current = totalBalance.value;
    final persisted = _persistedAth.value;
    return current > persisted ? current : persisted;
  });

  /// Daily Delta (Net change today)
  late final dailyDelta = computed(() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final txs = transactions.value;

    final todayNet = txs
        .where((t) => t.transactionDate.isAfter(todayStart))
        .fold(0.0, (sum, t) {
      if (t.type == 'income' || t.type == 'savings') return sum + t.amount;
      if (t.type == 'expense' || t.type == 'investment') return sum - t.amount;
      return sum;
    });

    return todayNet;
  });

  /// Portfolio Sharpe Ratio
  late final sharpeRatio = computed(() {
    final history = historicalNetWorth.value;
    if (history.length < 5) return 0.0;
    
    final returns = <double>[];
    for (int i = 1; i < history.length; i++) {
      if (history[i - 1] > 0) {
        returns.add((history[i] - history[i - 1]) / history[i - 1]);
      }
    }
    return QuantMath.calculateSharpeRatio(returns);
  });

  /// Current Drawdown from ATH
  late final drawdown = computed(() {
    final current = totalBalance.value;
    final ath = athBalance.value;
    return QuantMath.calculateDrawdown(current, ath);
  });

  /// 30-day Historical Net Worth series
  late final historicalNetWorth = computed(() {
    final List<double> series = [];
    final now = DateTime.now();
    final currentNW = totalBalance.value;
    final txs = transactions.value;

    for (int i = 0; i < 30; i++) {
      final dateThreshold = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final futureTxs = txs.where((t) => t.transactionDate.isAfter(dateThreshold)).fold(0.0, (sum, t) {
        if (t.type == 'income' || t.type == 'savings') return sum + t.amount;
        if (t.type == 'expense' || t.type == 'investment') return sum - t.amount;
        return sum;
      });
      series.add(currentNW - futureTxs);
    }
    return series.reversed.toList();
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

  /// Savings rate (Savings / Income)
  late final savingsRate = computed(() {
    final inc = monthlyIncome.value;
    if (inc <= 0) return 0.0;
    return (totalSavings.value / inc) * 100;
  });

  /// Spending Efficiency (1 - Expense / Income)
  late final spendingEfficiency = computed(() {
    final inc = monthlyIncome.value;
    if (inc <= 0) return 0.0;
    final exp = monthlySpending.value;
    return (1 - (exp / inc)).clamp(0.0, 1.0) * 100;
  });

  /// Next major milestone (next $5000 or $10000 depending on current balance)
  late final nextMilestone = computed(() {
    final balance = totalBalance.value;
    if (balance < 1000) return 1000.0;
    if (balance < 5000) return 5000.0;
    if (balance < 10000) return 10000.0;
    // Round up to nearest $10k
    return ((balance / 10000).floor() + 1) * 10000.0;
  });

  /// Progress to next milestone (0.0 to 1.0)
  late final milestoneProgress = computed(() {
    final total = totalBalance.value;
    final target = nextMilestone.value;
    if (target <= 0) return 0.0;

    // We calculate progress relative to the previous "step"
    double start = 0;
    if (target == 1000) {
      start = 0;
    } else if (target == 5000) start = 1000;
    else if (target == 10000) start = 5000;
    else start = target - 10000;

    final range = target - start;
    if (range <= 0) return 1.0;
    return ((total - start) / range).clamp(0.0, 1.0);
  });

  /// Currency toggle (true for VND, false for USD)
  late final useVnd = computed(() => _configBlock?.currency.value == 'VND');

  ConfigBlock? _configBlock;
  void Function()? _snapshotDisposer;

  void init(
    FinanceDAO dao,
    PortfolioSnapshotsDAO snapshotDao,
    String personId, {
    ConfigBlock? configBlock,
  }) async {
    if (personId.isEmpty) {
      debugPrint("FinanceBlock: Skipping init, personId is empty.");
      return;
    }
    _dao = dao;
    _snapshotDao = snapshotDao;
    _personId = personId;
    _configBlock = configBlock;

    // Load persistent ATH
    final latest = await snapshotDao.getLatestSnapshot(personId);
    if (latest != null) {
      _persistedAth.value = latest.athAtTime;
    }

    _snapshotDisposer?.call();
    _snapshotDisposer = effect(() {
      final currentNW = totalBalance.value;
      if (currentNW > _persistedAth.value) {
        _persistedAth.value = currentNW;
        _saveSnapshot();
      }
    });

    _accountsSubscription?.cancel();
    _accountsSubscription = dao.watchAccounts(personId).listen((data) {
      final protocols = data
          .map(
            (e) => FinancialAccountProtocol(
              financialAccountID: e.accountID ?? "",
              personID: e.personID ?? "",
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
              personId: e.personID ?? "",
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
        id: IDGen.UUIDV7(),
        personID: Value(_personId),
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

  Future<void> toggleCurrency() async {
    await _configBlock?.toggleCurrency();
  }

  static final NumberFormat _usdFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 1,
  );
  static final NumberFormat _vndFormat = NumberFormat.currency(
    symbol: '₫',
    decimalDigits: 0,
    locale: 'vi_VN',
  );

  String formatCurrency(double amount) {
    if (useVnd.value) {
      return _vndFormat.format(amount * USD_TO_VND_RATE);
    }
    return _usdFormat.format(amount);
  }

  Future<void> _saveSnapshot() async {
    if (_personId.isEmpty) return;
    try {
      await _snapshotDao.insertSnapshot(
        PortfolioSnapshotsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: Value(_personId),
          totalNetWorth: totalBalance.value,
          athAtTime: athBalance.value,
          timestamp: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      debugPrint("FinanceBlock: Failed to save snapshot: $e");
    }
  }

  void dispose() {
    _accountsSubscription?.cancel();
    _assetsSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _snapshotDisposer?.call();
  }
}
