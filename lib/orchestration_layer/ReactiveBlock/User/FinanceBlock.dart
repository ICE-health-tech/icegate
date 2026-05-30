import 'dart:async';
import 'package:ice_gate/orchestration_layer/Constraint/FinanceConstraint.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
// import 'package:ice_gate/orchestration_layer/Services/PowerPoint/GameConst.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/utils/QuantMath.dart';
import 'package:intl/intl.dart';

class FinanceBlock {
  final activeTab = signal(0);
  final accounts = listSignal<FinancialAccountProtocol>([]);
  final assets = listSignal<AssetProtocol>([]);
  final transactions = listSignal<TransactionData>([]);
  final subscriptions = listSignal<SubscriptionData>([]);
  final recurringIncomes = listSignal<RecurringIncomeData>([]);
  final isSyncing = signal(false);

  StreamSubscription? _accountsSubscription;
  StreamSubscription? _assetsSubscription;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _subscriptionsSubscription;
  StreamSubscription? _recurringIncomesSubscription;

  late FinanceDAO _dao;
  late PortfolioSnapshotsDAO _snapshotDao;
  String _personId = '';

  /// Logged-in person; empty before [init] or when unauthenticated.
  String get personId => _personId;

  final _persistedAth = signal<double>(0.0);

  void updateAccounts(List<FinancialAccountProtocol> data) {
    accounts.value = data;
  }

  void updateAssets(List<AssetProtocol> data) {
    assets.value = data;
  }

  /// Total Net Worth (Accounts + Assets)
  late final totalBalance = computed(() {
    final accSum = accounts.value.fold(0.0, (sum, acc) => sum + acc.balance);
    final assetSum = assets.value.fold(
      0.0,
      (sum, asset) => sum + (asset.currentEstimatedValue ?? 0.0),
    );

    return accSum + assetSum;
  });

  /// Calculate points based on total net worth

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

  /// Sum of active fixed/recurring incomes normalized to a monthly amount.
  late final monthlyFixedIncome = computed(() {
    return recurringIncomes.value.fold(0.0, (sum, item) {
      switch (item.interval) {
        case 'weekly':
          return sum + (item.amount * 52 / 12);
        case 'yearly':
          return sum + (item.amount / 12);
        case 'monthly':
        default:
          return sum + item.amount;
      }
    });
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

  /// Monthly net cash flow (Income - Expenses)
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

    return income - expense;
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
          if (t.type == 'income') return sum + t.amount;
          if (t.type == 'expense') {
            return sum - t.amount;
          }
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
      final dateThreshold = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final futureTxs = txs
          .where((t) => t.transactionDate.isAfter(dateThreshold))
          .fold(0.0, (sum, t) {
            if (t.type == 'income' || t.type == 'savings') {
              return sum + t.amount;
            }
            if (t.type == 'expense' || t.type == 'investment') {
              return sum - t.amount;
            }
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

  /// Monthly budget limit (Default $1500)
  final monthlyBudgetLimit = signal<double>(1500.0);

  /// Total billing for subscriptions and bills this month
  late final totalSubscriptionsBilling = computed(() {
    final now = DateTime.now();

    // Sum from recorded transactions (actual payments)
    final actualPayments = transactions.value
        .where(
          (t) =>
              (t.category == 'subscriptions' || t.category == 'bills') &&
              t.type == 'expense' &&
              t.transactionDate.month == now.month &&
              t.transactionDate.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    // Also include active subscriptions that might not have been paid yet this month
    // if we want a "Burn Rate" view. For now, let's keep it to actual payments
    // but the user might want to see the "Total Committed" amount.
    return actualPayments;
  });

  /// Monthly Burn Rate (Total of all active subscriptions)
  late final monthlyBurnRate = computed(() {
    return subscriptions.value
        .where((s) => s.isActive)
        .fold(0.0, (sum, s) => sum + s.amount);
  });

  /// Remaining budget for the month
  late final remainingBudget = computed(() {
    return (monthlyBudgetLimit.value - totalSubscriptionsBilling.value).clamp(
      0.0,
      double.infinity,
    );
  });

  /// Budget usage %: active **subscriptions** burn rate vs [monthlyBudgetLimit] (same base currency as DB).
  late final budgetUsagePercent = computed(() {
    if (monthlyBudgetLimit.value <= 0) return 0.0;
    return (monthlyBurnRate.value / monthlyBudgetLimit.value) * 100;
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
    } else if (target == 5000)
      start = 1000;
    else if (target == 10000)
      start = 5000;
    else
      start = target - 10000;

    final range = target - start;
    if (range <= 0) return 1.0;
    return ((total - start) / range).clamp(0.0, 1.0);
  });

  /// Currency toggle (true for VND, false for USD)
  late final useVnd = computed(
    () => _configBlock.value?.currency.value == 'VND',
  );

  late final subscriptionPlanSkips = computed(
    () => _configBlock.value?.subscriptionPlanSkips.value ?? const <String>{},
  );

  final _configBlock = signal<ConfigBlock?>(null);
  void Function()? _snapshotDisposer;

  void init(
    FinanceDAO dao,
    PortfolioSnapshotsDAO snapshotDao,
    String personId, {
    ConfigBlock? configBlock,
  }) async {
    _personId = personId;
    if (personId.isEmpty) {
      debugPrint("FinanceBlock: Skipping init, personId is empty.");
      return;
    }
    _dao = dao;
    _snapshotDao = snapshotDao;
    _configBlock.value = configBlock;

    // Load persistent ATH and latest timestamp
    DateTime? lastSnapshotTime;
    final latest = await snapshotDao.getLatestSnapshot(personId);
    if (latest != null) {
      _persistedAth.value = latest.athAtTime;
      lastSnapshotTime = latest.timestamp;
    }

    _snapshotDisposer?.call();
    _snapshotDisposer = effect(() {
      final currentNW = totalBalance.value;
      if (currentNW == 0) return; // Wait for initial data load

      untracked(() {
        bool shouldSave = false;

        // Rule 1: All-Time High
        if (currentNW > _persistedAth.value) {
          Timer(Duration.zero, () {
            _persistedAth.value = currentNW;
          });
          shouldSave = true;
        }

        // Rule 2: Daily Snapshot
        if (lastSnapshotTime == null ||
            DateTime.now().difference(lastSnapshotTime!).inDays >= 1) {
          shouldSave = true;
        }

        if (shouldSave) {
          _saveSnapshot();
          lastSnapshotTime = DateTime.now();
        }
      });
    });

    _accountsSubscription?.cancel();
    _accountsSubscription = dao.watchAccounts(personId).listen((data) {
          Timer(Duration.zero, () {
            untracked(() {
              batch(() {
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
            });
          });
        });

    _assetsSubscription?.cancel();
    _assetsSubscription = dao.watchAssets(personId).listen((data) {
          Timer(Duration.zero, () {
            untracked(() {
              batch(() {
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
            });
          });
        });

    _transactionsSubscription?.cancel();
    _transactionsSubscription = dao.watchAllTransactions(personId).listen((data) {
          Timer(Duration.zero, () {
            untracked(() {
              transactions.value = data;
            });
          });
        });

    _subscriptionsSubscription?.cancel();
    _subscriptionsSubscription = dao.watchSubscriptions(personId).listen((data) {
      Timer(Duration.zero, () {
        untracked(() {
          subscriptions.value = data;
        });
      });
    });
    _recurringIncomesSubscription?.cancel();
    _recurringIncomesSubscription =
        dao.watchRecurringIncomes(personId).listen((data) {
      Timer(Duration.zero, () {
        untracked(() {
          recurringIncomes.value = data;
        });
      });
    });
    unawaited(_reloadSubscriptionsFromDb());
    unawaited(_reloadRecurringIncomesFromDb());
    unawaited(processDueRecurringIncomes());
  }

  static DateTime advanceRecurringDue(DateTime from, String interval) {
    switch (interval) {
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      case 'monthly':
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  /// Posts income transactions for any recurring schedules that are due.
  Future<void> processDueRecurringIncomes() async {
    if (_personId.isEmpty) return;
    final now = DateTime.now();
    final due = await _dao.getDueRecurringIncomes(_personId, now);
    for (final schedule in due) {
      var next = schedule.nextDueAt;
      while (!next.isAfter(now)) {
        await addTransaction(
          category: schedule.category,
          type: 'income',
          amount: schedule.amount,
          description: schedule.description,
          date: next,
        );
        next = advanceRecurringDue(next, schedule.interval);
      }
      await _dao.updateRecurringIncomeNextDue(
        id: schedule.id,
        nextDueAt: next,
      );
    }
  }

  Future<void> addRecurringIncome({
    required String category,
    required double amount,
    String? description,
    String interval = 'monthly',
  }) async {
    if (_personId.isEmpty) return;
    final anchor = DateTime.now();
    await _dao.insertRecurringIncome(
      RecurringIncomesTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: _personId,
        category: category,
        amount: amount,
        description: Value(description),
        interval: Value(interval),
        nextDueAt: advanceRecurringDue(anchor, interval),
        createdAt: Value(anchor),
      ),
    );
    await _reloadRecurringIncomesFromDb();
    await processDueRecurringIncomes();
  }

  Future<void> deleteRecurringIncome(String id) async {
    if (_personId.isEmpty) return;
    await _dao.deleteRecurringIncome(id);
    await _reloadRecurringIncomesFromDb();
  }

  Future<void> _reloadRecurringIncomesFromDb() async {
    if (_personId.isEmpty) return;
    final rows = await (_dao.select(_dao.recurringIncomesTable)
          ..where(
            (t) => t.personID.equals(_personId) & t.isActive.equals(true),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.nextDueAt)]))
        .get();
    Timer(Duration.zero, () {
      untracked(() {
        recurringIncomes.value = rows;
      });
    });
  }

  Future<void> refreshRecurringIncomes() => _reloadRecurringIncomesFromDb();

  /// One-shot load + call after local writes so the list updates even if table [watch] lags (e.g. sync/replication).
  Future<void> _reloadSubscriptionsFromDb() async {
    if (_personId.isEmpty) return;
    final rows = await (_dao.select(_dao.subscriptionsTable)
          ..where((t) => t.personID.equals(_personId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
    Timer(Duration.zero, () {
      untracked(() {
        subscriptions.value = rows;
      });
    });
  }

  /// Re-query local Drift `subscriptions` for the current person (open Billing tab, pull-to-refresh, etc.).
  Future<void> refreshSubscriptions() => _reloadSubscriptionsFromDb();

  /// Reload accounts, assets, transactions, and subscriptions from Drift (home finance card, cold start).
  Future<void> refreshFromLocalDatabase() async {
    if (_personId.isEmpty) return;
    final accRows = await (_dao.select(_dao.financialAccountsTable)
          ..where((t) => t.personID.equals(_personId)))
        .get();
    final assetRows =
        await (_dao.select(_dao.assetsTable)
              ..where((t) => t.personID.equals(_personId)))
            .get();
    final txnRows = await (_dao.select(_dao.transactionsTable)
          ..where((t) => t.personID.equals(_personId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();

    untracked(() {
      batch(() {
        updateAccounts(
            accRows
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
                .toList(),
          );
          updateAssets(
            assetRows
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
                .toList(),
          );
        transactions.value = txnRows;
      });
    });
    await _reloadSubscriptionsFromDb();
  }

  Future<void> sync() async {
    if (_personId.isEmpty) return;
    isSyncing.value = true;
    try {
      // Access the SupabaseService via the database's reference if available,
      // but in this architecture, we usually call it directly if we have the reference.
      // Looking at main.dart or SupabaseService usage, we can see how it's wired.
      // For now, I'll call the DAOs if they have sync methods or the db directly.
      await _dao.db.syncTableDown('transactions', _personId);
      await _dao.db.syncTableDown('subscriptions', _personId);
      await _reloadSubscriptionsFromDb();
    } catch (e) {
      debugPrint("FinanceBlock: Sync failed: $e");
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> addTransaction({
    required String category,
    required String type,
    required double amount,
    String? description,
    DateTime? date,
    String? projectID,
    int? moodScore,
  }) async {
    if (_personId.isEmpty) return;
    await _dao.insertTransaction(
      TransactionsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: Value(_personId),
        category: category,
        type: type,
        amount: amount,
        moodScore: moodScore != null
            ? Value(moodScore)
            : const Value.absent(),
        description: Value(description),
        transactionDate: Value(date ?? DateTime.now()),
        projectID: Value(projectID),
      ),
    );
  }

  Future<void> updateTransaction({
    required String id,
    required String category,
    required String type,
    required double amount,
    String? description,
    DateTime? date,
    String? projectID,
    int? moodScore,
  }) async {
    if (_personId.isEmpty) return;
    await _dao.updateTransaction(
      TransactionsTableCompanion(
        id: Value(id),
        personID: Value(_personId),
        category: Value(category),
        type: Value(type),
        amount: Value(amount),
        moodScore: Value(moodScore),
        description: Value(description),
        transactionDate: Value(date ?? DateTime.now()),
        projectID: Value(projectID),
      ),
    );
  }

  Future<void> addSubscription({
    required String name,
    required double amount,
    required int billingDay,
    String category = 'subscriptions',
    String billingCycle = 'monthly',
  }) async {
    if (_personId.isEmpty) return;
    await _dao.insertSubscription(
      SubscriptionsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: _personId,
        name: name,
        amount: amount,
        billingDay: billingDay,
        category: Value(category),
        isActive: const Value(true),
        billingCycle: Value(billingCycle),
        createdAt: Value(DateTime.now()),
      ),
    );
    await _reloadSubscriptionsFromDb();
  }

  Future<void> updateSubscription({
    required String id,
    required String name,
    required double amount,
    required int billingDay,
    String category = 'subscriptions',
    String billingCycle = 'monthly',
    bool isActive = true,
  }) async {
    if (_personId.isEmpty) return;
    final existing =
        await (_dao.select(_dao.subscriptionsTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (existing == null) return;
    await _dao.updateSubscription(
      SubscriptionsTableCompanion(
        id: Value(existing.id),
        tenantID: Value(existing.tenantID),
        personID: Value(existing.personID),
        name: Value(name),
        amount: Value(amount),
        billingDay: Value(billingDay),
        category: Value(category),
        isActive: Value(isActive),
        billingCycle: Value(billingCycle),
        createdAt: Value(existing.createdAt),
      ),
    );
    await _reloadSubscriptionsFromDb();
  }

  Future<void> deleteSubscription(String id) async {
    await _dao.deleteSubscription(id);
    await _reloadSubscriptionsFromDb();
  }

  /// Hides one billing from the future-month plan; does not delete the subscription.
  Future<void> skipSubscriptionInPlanMonth(
    String subId,
    int year,
    int month,
  ) async {
    await _configBlock.value?.skipSubscriptionForPlanMonth(subId, year, month);
  }

  bool isSubscriptionSkippedInPlanMonth(
    String subId,
    int year,
    int month,
  ) {
    return _configBlock.value?.isSubscriptionSkippedForPlanMonth(
          subId,
          year,
          month,
        ) ??
        false;
  }

  Future<void> deleteTransaction(String id) async {
    await _dao.deleteTransaction(id);
  }

  Future<void> toggleCurrency() async {
    await _configBlock.value?.toggleCurrency();
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

  /// Converts a base amount (USD) to the current display currency (VND or USD).
  double convertToDisplay(double amount) {
    if (useVnd.value) {
      return amount * USD_TO_VND_RATE;
    }
    return amount;
  }

  /// Converts a display amount (VND or USD) back to the base currency (USD).
  double convertToBase(double amount) {
    if (useVnd.value) {
      return amount / USD_TO_VND_RATE;
    }
    return amount;
  }

  String formatCurrency(double amount, {bool compact = false}) {
    final displayAmount = convertToDisplay(amount);
    final absDisplayAmount = displayAmount.abs();
    final sign = displayAmount < 0 ? '-' : '';

    if (useVnd.value) {
      if (compact) {
        if (absDisplayAmount >= 1000000000) {
          return '$sign${(absDisplayAmount / 1000000000).toStringAsFixed(1)} Tỉ ₫';
        } else if (absDisplayAmount >= 1000000) {
          return '$sign${(absDisplayAmount / 1000000).toStringAsFixed(1)} Tr ₫';
        } else if (absDisplayAmount >= 1000) {
          return '$sign${(absDisplayAmount / 1000).toStringAsFixed(1)}k ₫';
        }
      }
      return _vndFormat.format(displayAmount);
    } else {
      if (compact) {
        if (absDisplayAmount >= 1000000000) {
          return '$sign\$${(absDisplayAmount / 1000000000).toStringAsFixed(1)}B';
        } else if (absDisplayAmount >= 1000000) {
          return '$sign\$${(absDisplayAmount / 1000000).toStringAsFixed(1)}M';
        } else if (absDisplayAmount >= 1000) {
          return '$sign\$${(absDisplayAmount / 1000).toStringAsFixed(1)}k';
        }
      }
      return _usdFormat.format(displayAmount);
    }
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
    _subscriptionsSubscription?.cancel();
    _recurringIncomesSubscription?.cancel();
    _snapshotDisposer?.call();
  }
}
