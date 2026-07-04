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
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceAssetPillars.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceInflowPillars.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/utils/QuantMath.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceBlock {
  final activeTab = signal(0);
  final accounts = listSignal<FinancialAccountProtocol>([]);
  final assets = listSignal<AssetProtocol>([]);
  final transactions = listSignal<TransactionData>([]);
  final subscriptions = listSignal<SubscriptionData>([]);
  final recurringIncomes = listSignal<RecurringIncomeData>([]);
  final jobPositions = listSignal<JobPositionData>([]);
  final isSyncing = signal(false);

  StreamSubscription? _accountsSubscription;
  StreamSubscription? _assetsSubscription;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _subscriptionsSubscription;
  StreamSubscription? _recurringIncomesSubscription;
  StreamSubscription? _jobPositionsSubscription;

  late FinanceDAO _dao;
  late PortfolioSnapshotsDAO _snapshotDao;
  String _personId = '';
  String? _lastSourceAccountId;

  static String _lastSourceAccountKey(String personId) =>
      'finance_last_source_account_$personId';

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

  /// Savings recorded in the current month.
  late final monthlySavings = computed(() {
    final now = DateTime.now();
    return transactions.value
        .where(
          (t) =>
              t.type == 'savings' &&
              t.transactionDate.month == now.month &&
              t.transactionDate.year == now.year,
        )
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

  /// One-time money (bonus/contract) — never part of monthly recurring math.
  /// STORY: Category is the user's intent, interval is derived — trust either
  /// signal so a row with a dirty interval still classifies correctly.
  static bool isOneTimeIncome(RecurringIncomeData item) =>
      item.interval == 'once' ||
      item.category == 'bonus' ||
      item.category == 'contract';

  /// Sum of active fixed/recurring incomes normalized to a monthly amount.
  /// Excludes one-time bonus/contract entries.
  late final monthlyFixedIncome = computed(() {
    return recurringIncomes.value.fold(0.0, (sum, item) {
      if (isOneTimeIncome(item)) return sum;
      return sum + _recurringToMonthly(item.amount, item.interval);
    });
  });

  /// Imputed earning power (category human_capital only — not cash).
  late final monthlyHumanCapitalCapacity = computed(() {
    var sum = 0.0;
    for (final item in recurringIncomes.value) {
      if (item.category == 'human_capital') {
        sum += _recurringToMonthly(item.amount, item.interval);
      }
    }
    final now = DateTime.now();
    for (final t in transactions.value) {
      if (t.type == 'income' &&
       
          t.transactionDate.month == now.month &&
          t.transactionDate.year == now.year) {
        sum += t.amount;
      }
    }
    return sum;
  });

  /// Cash from work (salary, freelance, bonus).
  late final monthlyHumanCapitalRealized = computed(() {
    const realized = {'salary', 'freelance', 'bonus'};
    var sum = 0.0;
    for (final item in recurringIncomes.value) {
      if (realized.contains(item.category)) {
        sum += _recurringToMonthly(item.amount, item.interval);
      }
    }
    final now = DateTime.now();
    for (final t in transactions.value) {
      if (t.type == 'income' &&
          realized.contains(t.category) &&
          t.transactionDate.month == now.month &&
          t.transactionDate.year == now.year) {
        sum += t.amount;
      }
    }
    return sum;
  });

  /// Monthly cash inflow by pillar.
  late final monthlyInflowByPillar = computed(() {
    final map = {for (final p in FinanceInflowPillar.ordered) p: 0.0};
    for (final item in recurringIncomes.value) {
      final pillar = FinanceInflowPillar.pillarForCategory(item.category);
      if (pillar != null) {
        map[pillar] =
            (map[pillar] ?? 0) + _recurringToMonthly(item.amount, item.interval);
      }
    }
    final now = DateTime.now();
    for (final t in transactions.value) {
      if (t.type != 'income' ||
          t.transactionDate.month != now.month ||
          t.transactionDate.year != now.year) {
        continue;
      }
      final pillar = FinanceInflowPillar.pillarForCategory(t.category);
      if (pillar != null) {
        map[pillar] = (map[pillar] ?? 0) + t.amount;
      }
    }
    return map;
  });

  /// Net worth split by asset pillar (accounts + holdings).
  late final netWorthByAssetPillar = computed(() {
    return FinanceAssetPillar.sumByPillar(
      accounts: accounts.value,
      assets: assets.value,
    );
  });

  static double _recurringToMonthly(double amount, String interval) {
    switch (interval) {
      case 'weekly':
        return amount * 52 / 12;
      case 'yearly':
        return amount / 12;
      case 'once':
        return 0; // one-offs have no monthly equivalent
      case 'monthly':
      default:
        return amount;
    }
  }

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

  /// Savings rate — this month's savings vs this month's income.
  /// STORY: Both numbers must cover the same period; all-time savings over
  /// one month's income inflates the rate (4M lifetime / 500k month = 800%).
  late final savingsRate = computed(() {
    final inc = monthlyIncome.value;
    if (inc <= 0) return 0.0;
    return (monthlySavings.value / inc) * 100;
  });

  /// Spending Efficiency (1 - Expense / Income)
  late final spendingEfficiency = computed(() {
    final inc = monthlyIncome.value;
    if (inc <= 0) return 0.0;
    final exp = monthlySpending.value;
    return (1 - (exp / inc)).clamp(0.0, 1.0) * 100;
  });

  /// Budget limit as the user entered it — per week or per month
  /// ([budgetLimitPeriod]). Persisted per person in SharedPreferences.
  final monthlyBudgetLimit = signal<double>(1500.0);

  /// 'week' | 'month'. STORY: First we keep the number exactly as typed with
  /// its period. Then [monthlyLimitEquivalent] converts once. So every
  /// consumer keeps comparing against a monthly amount without knowing weeks
  /// exist.
  final budgetLimitPeriod = signal<String>('month');

  /// Average weeks per month (52 weeks / 12 months).
  static const double _weeksPerMonth = 52 / 12;

  /// The limit normalized to one month — all budget math uses this.
  late final monthlyLimitEquivalent = computed(() {
    final raw = monthlyBudgetLimit.value;
    return budgetLimitPeriod.value == 'week' ? raw * _weeksPerMonth : raw;
  });

  static String _budgetLimitKey(String personId) =>
      'finance_monthly_budget_limit_$personId';

  static String _budgetLimitPeriodKey(String personId) =>
      'finance_budget_limit_period_$personId';

  Future<void> loadBudgetLimit() async {
    if (_personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_budgetLimitKey(_personId));
    if (saved != null) monthlyBudgetLimit.value = saved;
    final period = prefs.getString(_budgetLimitPeriodKey(_personId));
    if (period == 'week' || period == 'month') {
      budgetLimitPeriod.value = period!;
    }
  }

  Future<void> setBudgetLimit(double limit, {String? period}) async {
    monthlyBudgetLimit.value = limit;
    if (period == 'week' || period == 'month') {
      budgetLimitPeriod.value = period!;
    }
    if (_personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetLimitKey(_personId), limit);
    await prefs.setString(
      _budgetLimitPeriodKey(_personId),
      budgetLimitPeriod.value,
    );
  }

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
    return (monthlyLimitEquivalent.value - totalSubscriptionsBilling.value)
        .clamp(0.0, double.infinity);
  });

  /// Budget usage %: active **subscriptions** burn rate vs the monthly
  /// equivalent of the limit (same base currency as DB).
  late final budgetUsagePercent = computed(() {
    if (monthlyLimitEquivalent.value <= 0) return 0.0;
    return (monthlyBurnRate.value / monthlyLimitEquivalent.value) * 100;
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
    await _loadLastSourceAccount();
    await loadBudgetLimit();

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
                        financialAccountID: e.id,
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
    _jobPositionsSubscription?.cancel();
    _jobPositionsSubscription =
        dao.watchJobPositions(personId).listen((data) {
      Timer(Duration.zero, () {
        untracked(() {
          jobPositions.value = data;
        });
      });
    });
    unawaited(_reloadSubscriptionsFromDb());
    unawaited(_reloadRecurringIncomesFromDb());
    unawaited(_reloadJobPositionsFromDb());
    unawaited(_startupIncomeProcessing());
  }

  Future<void> _startupIncomeProcessing() async {
    await cleanupDuplicateIncomes();
    await _cleanupDuplicateRecurringIncomes();
    await processDueRecurringIncomes();
    try {
      await _dao.pushAllRecurringIncomesToCloud(_personId);
    } catch (e) {
      debugPrint('🔄 Recurring-income push-up failed: $e');
    }
  }

  Future<void> _cleanupDuplicateRecurringIncomes() async {
    if (_personId.isEmpty) return;
    final removed = await _dao.deduplicateRecurringIncomes(_personId);
    if (removed > 0) {
      debugPrint('🧹 Removed $removed duplicate recurring income(s)');
      await _reloadRecurringIncomesFromDb();
    }
  }

  static DateTime advanceRecurringDue(DateTime from, String interval) {
    switch (interval) {
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      case 'once':
        return DateTime(2099, 12, 31);
      case 'monthly':
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  bool _postingDueIncomes = false;

  /// Posts income transactions for any recurring schedules that are due.
  /// Skips posting if a matching transaction already exists for that day
  /// (guards against duplicates from stale sync-down overwrites).
  Future<void> processDueRecurringIncomes() async {
    if (_personId.isEmpty || _postingDueIncomes) return;
    _postingDueIncomes = true;
    try {
      final now = DateTime.now();
      final due = await _dao.getDueRecurringIncomes(_personId, now);
      for (final schedule in due) {
        var next = schedule.nextDueAt;
        while (!next.isAfter(now)) {
          final alreadyExists = await _dao.incomeTransactionExists(
            personId: _personId,
            category: schedule.category,
            amount: schedule.amount,
            date: next,
            description: schedule.description,
          );
          if (!alreadyExists) {
            await addTransaction(
              category: schedule.category,
              type: 'income',
              amount: schedule.amount,
              description: schedule.description,
              date: next,
            );
          }
          next = advanceRecurringDue(next, schedule.interval);
        }
        await _dao.updateRecurringIncomeNextDue(
          id: schedule.id,
          nextDueAt: next,
        );
      }
    } finally {
      _postingDueIncomes = false;
    }
  }

  /// Removes duplicate income transactions caused by previous sync bugs.
  /// Safe to call on every startup — it's a no-op when there are no dupes.
  Future<void> cleanupDuplicateIncomes() async {
    if (_personId.isEmpty) return;
    final removed = await _dao.deduplicateIncomeTransactions(_personId);
    if (removed > 0) {
      debugPrint('🧹 Removed $removed duplicate income transaction(s)');
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

  /// Creates or updates the monthly salary income linked to a job position.
  /// Returns the recurring income id (existing or newly created).
  Future<String> upsertJobSalaryIncome({
    String? existingIncomeId,
    required double amount,
    required String label,
    String category = 'salary',
    String? jobPositionId,
  }) async {
    if (_personId.isEmpty) return '';
    if (existingIncomeId != null && existingIncomeId.isNotEmpty) {
      await _dao.updateRecurringIncomeAmount(
        id: existingIncomeId,
        amount: amount,
        description: label,
        category: category,
      );
      await _reloadRecurringIncomesFromDb();
      return existingIncomeId;
    }
    final id = IDGen.UUIDV7();
    final anchor = DateTime.now();
    final interval = (category == 'contract' || category == 'bonus') ? 'once' : 'monthly';
    await _dao.insertRecurringIncome(
      RecurringIncomesTableCompanion.insert(
        id: id,
        personID: _personId,
        category: category,
        amount: amount,
        description: Value(label),
        interval: Value(interval),
        nextDueAt: advanceRecurringDue(anchor, interval),
        jobPositionId: Value(jobPositionId),
        createdAt: Value(anchor),
      ),
    );
    await _reloadRecurringIncomesFromDb();
    return id;
  }

  List<RecurringIncomeData> incomesForJob(String jobId) {
    return recurringIncomes.peek().where((i) => i.jobPositionId == jobId).toList();
  }

  Future<void> _reloadRecurringIncomesFromDb() async {
    if (_personId.isEmpty) return;
    // Repair legacy rows saved as bonus/contract with a monthly interval —
    // otherwise processDueRecurringIncomes would re-post them every month.
    await (_dao.update(_dao.recurringIncomesTable)
          ..where(
            (t) =>
                t.category.isIn(const ['bonus', 'contract']) &
                t.interval.equals('once').not(),
          ))
        .write(
      RecurringIncomesTableCompanion(
        interval: const Value('once'),
        nextDueAt: Value(DateTime(2099, 12, 31)),
      ),
    );
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

  // ─── Job Positions ───────────────────────────────────────────────

  /// Current job = first position where end_date is null.
  late final currentJob = computed<JobPositionData?>(() {
    for (final job in jobPositions.value) {
      if (job.endDate == null) return job;
    }
    return null;
  });

  /// Tenure in months of the current job (0 if none).
  late final currentJobTenureMonths = computed<int>(() {
    final job = currentJob.value;
    if (job == null) return 0;
    final now = DateTime.now();
    return (now.year - job.startDate.year) * 12 +
        (now.month - job.startDate.month);
  });

  Future<String> addJobPosition({
    required String employer,
    required String jobTitle,
    required DateTime startDate,
    DateTime? endDate,
    String contractType = 'full_time',
    String? linkedIncomeId,
    String? linkedProjectId,
    String notes = '',
  }) async {
    final id = IDGen.generateUuid();
    final companion = JobPositionsTableCompanion.insert(
      id: id,
      personID: _personId,
      employer: Value(employer),
      jobTitle: Value(jobTitle),
      contractType: Value(contractType),
      startDate: startDate,
      endDate: Value(endDate),
      linkedIncomeId: Value(linkedIncomeId),
      linkedProjectId: Value(linkedProjectId),
      notes: Value(notes),
    );
    await _dao.insertJobPosition(companion);
    await _reloadJobPositionsFromDb();
    return id;
  }

  Future<void> updateJobPosition({
    required String id,
    String? employer,
    String? jobTitle,
    DateTime? startDate,
    DateTime? endDate,
    String? contractType,
    String? linkedIncomeId,
    String? linkedProjectId,
    String? notes,
    bool clearEndDate = false,
  }) async {
    final companion = JobPositionsTableCompanion(
      id: Value(id),
      employer: employer != null ? Value(employer) : const Value.absent(),
      jobTitle: jobTitle != null ? Value(jobTitle) : const Value.absent(),
      startDate: startDate != null ? Value(startDate) : const Value.absent(),
      endDate: clearEndDate ? const Value(null) : (endDate != null ? Value(endDate) : const Value.absent()),
      contractType:
          contractType != null ? Value(contractType) : const Value.absent(),
      linkedIncomeId:
          linkedIncomeId != null ? Value(linkedIncomeId) : const Value.absent(),
      linkedProjectId: linkedProjectId != null
          ? Value(linkedProjectId)
          : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
    );
    await _dao.updateJobPosition(companion);

    // STORY: First the job row is saved. Then we check if the job just
    // ended (endDate set) or became current again (endDate cleared).
    // So the linked salary income switches off when the job ends and
    // switches back on when the job is current — monthly income totals
    // never count salary from a job that already ended.
    final salaryId = linkedIncomeId ?? _linkedIncomeIdFor(id);
    if (salaryId != null && salaryId.isNotEmpty) {
      if (endDate != null) {
        await _dao.setRecurringIncomeActive(id: salaryId, isActive: false);
        await _reloadRecurringIncomesFromDb();
      } else if (clearEndDate) {
        await _dao.setRecurringIncomeActive(id: salaryId, isActive: true);
        await _reloadRecurringIncomesFromDb();
      }
    }

    await _reloadJobPositionsFromDb();
  }

  Future<void> endJobPosition(String id, {DateTime? endDate}) async {
    await updateJobPosition(id: id, endDate: endDate ?? DateTime.now());
  }

  Future<void> deleteJobPosition(String id) async {
    // STORY: First find the salary income tied to this job. Then delete
    // the job and deactivate that income. So a deleted job never leaves
    // a ghost salary inflating the monthly income numbers.
    final salaryId = _linkedIncomeIdFor(id);
    await _dao.deleteJobPosition(id);
    if (salaryId != null && salaryId.isNotEmpty) {
      await _dao.setRecurringIncomeActive(id: salaryId, isActive: false);
      await _reloadRecurringIncomesFromDb();
    }
    await _reloadJobPositionsFromDb();
  }

  String? _linkedIncomeIdFor(String jobId) {
    for (final job in jobPositions.peek()) {
      if (job.id == jobId) return job.linkedIncomeId;
    }
    return null;
  }

  Future<void> _reloadJobPositionsFromDb() async {
    if (_personId.isEmpty) return;
    final rows = await (_dao.select(_dao.jobPositionsTable)
          ..where((t) => t.personID.equals(_personId))
          ..orderBy([(t) => OrderingTerm(expression: t.endDate)]))
        .get();
    Timer(Duration.zero, () {
      untracked(() {
        jobPositions.value = rows;
      });
    });
  }

  Future<void> refreshJobPositions() => _reloadJobPositionsFromDb();

  // ─────────────────────────────────────────────────────────────────

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
                    financialAccountID: e.id,
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
      await _dao.pushAllTransactionsToCloud(_personId);
      await _dao.pushAllRecurringIncomesToCloud(_personId);
      await _dao.pushAllJobPositionsToCloud(_personId);
      await _dao.pushAllBonusesToCloud(_personId);
      await _dao.db.syncTableDown('transactions', _personId);
      await _dao.db.syncTableDown('subscriptions', _personId);
      await _dao.db.syncTableDown('recurring_incomes', _personId);
      await _dao.db.syncTableDown('job_positions', _personId);
      await _reloadSubscriptionsFromDb();
      await _reloadRecurringIncomesFromDb();
      await _reloadJobPositionsFromDb();
    } catch (e) {
      debugPrint("FinanceBlock: Sync failed: $e");
    } finally {
      isSyncing.value = false;
    }
  }

  TransactionData? _transactionById(String id) {
    for (final t in transactions.value) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _loadLastSourceAccount() async {
    if (_personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _lastSourceAccountId = prefs.getString(_lastSourceAccountKey(_personId));
  }

  Future<void> _persistLastSourceAccount(String? id) async {
    if (_personId.isEmpty) return;
    _lastSourceAccountId = id;
    final prefs = await SharedPreferences.getInstance();
    final key = _lastSourceAccountKey(_personId);
    if (id == null || id.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, id);
    }
  }

  /// Default wallet for a new expense/savings log (last used → primary → liquidity).
  String? suggestSourceAccountId() {
    if (_lastSourceAccountId != null &&
        accountById(_lastSourceAccountId) != null) {
      return _lastSourceAccountId;
    }
    FinancialAccountProtocol? primary;
    FinancialAccountProtocol? firstLiquidity;
    for (final a in accounts.value) {
      if (!a.isActive) continue;
      if (a.isPrimary) primary = a;
      if (firstLiquidity == null &&
          FinanceAssetPillar.pillarForAccountType(a.accountType) ==
              FinanceAssetPillar.liquidity) {
        firstLiquidity = a;
      }
    }
    return primary?.financialAccountID ??
        firstLiquidity?.financialAccountID ??
        (accounts.value.where((a) => a.isActive).isNotEmpty
            ? accounts.value.firstWhere((a) => a.isActive).financialAccountID
            : null);
  }

  bool get hasActiveAccounts =>
      accounts.value.any((a) => a.isActive);

  FinancialAccountProtocol? accountById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final a in accounts.value) {
      if (a.financialAccountID == id && a.isActive) return a;
    }
    return null;
  }

  String? accountDisplayName(String? accountId) =>
      accountById(accountId)?.accountName;

  CurrencyType _currencyFromName(String name) {
    return CurrencyType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => CurrencyType.USD,
    );
  }

  /// Balance delta when money leaves [accountId] (expense / savings).
  double _outflowDelta(String type, double amount, {bool reverse = false}) {
    if (type != 'expense' && type != 'savings') return 0;
    final delta = -amount;
    return reverse ? -delta : delta;
  }

  Future<void> _adjustAccountBalance(String accountId, double delta) async {
    if (delta == 0) return;
    final acc = accountById(accountId);
    if (acc == null) return;
    await updateAccount(
      id: acc.financialAccountID,
      accountName: acc.accountName,
      accountType: acc.accountType,
      balance: acc.balance + delta,
      currency: _currencyFromName(acc.currency),
    );
  }

  Future<void> _revertTransactionAccountEffect(TransactionData txn) async {
    final id = txn.sourceAccountId;
    if (id == null || id.isEmpty) return;
    await _adjustAccountBalance(
      id,
      _outflowDelta(txn.type, txn.amount, reverse: true),
    );
  }

  Future<void> _applyTransactionAccountEffect({
    required String type,
    required double amount,
    String? sourceAccountId,
  }) async {
    if (sourceAccountId == null || sourceAccountId.isEmpty) return;
    await _adjustAccountBalance(
      sourceAccountId,
      _outflowDelta(type, amount),
    );
  }

  Future<void> addTransaction({
    required String category,
    required String type,
    required double amount,
    String? description,
    DateTime? date,
    String? projectID,
    int? moodScore,
    String? sourceAccountId,
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
        sourceAccountId: Value(sourceAccountId),
      ),
    );
    await _applyTransactionAccountEffect(
      type: type,
      amount: amount,
      sourceAccountId: sourceAccountId,
    );
    if (sourceAccountId != null &&
        sourceAccountId.isNotEmpty &&
        (type == 'expense' || type == 'savings')) {
      await _persistLastSourceAccount(sourceAccountId);
    }
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
    String? sourceAccountId,
  }) async {
    if (_personId.isEmpty) return;
    final previous = _transactionById(id);
    if (previous != null) {
      await _revertTransactionAccountEffect(previous);
    }
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
        sourceAccountId: Value(sourceAccountId),
      ),
    );
    await _applyTransactionAccountEffect(
      type: type,
      amount: amount,
      sourceAccountId: sourceAccountId,
    );
    if (sourceAccountId != null &&
        sourceAccountId.isNotEmpty &&
        (type == 'expense' || type == 'savings')) {
      await _persistLastSourceAccount(sourceAccountId);
    }
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
    final previous = _transactionById(id);
    if (previous != null) {
      await _revertTransactionAccountEffect(previous);
    }
    await _dao.deleteTransaction(id);
  }

  Future<void> updateAccount({
    required String id,
    required String accountName,
    required String accountType,
    required double balance,
    required CurrencyType currency,
  }) async {
    if (_personId.isEmpty) return;
    await _dao.updateFinancialAccount(
      FinancialAccountsTableCompanion(
        id: Value(id),
        personID: Value(_personId),
        accountName: Value(accountName),
        accountType: Value(accountType),
        balance: Value(balance),
        currency: Value(currency),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await refreshFromLocalDatabase();
  }

  Future<void> deleteAccount(String id) async {
    await _dao.deleteAccount(id);
    await refreshFromLocalDatabase();
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
