import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/initial_layer/CoreLogics/GamificationService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreData.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';

class ScoreBlock {
  final _score = signal<ScoreData>(ScoreData.empty());
  final isReady = signal<bool>(false);

  // DAOs stored locally for access in update methods
  late ScoreDAO _dao;
  late FinanceDAO _financeDAO;
  late HealthBlock _healthBlock;
  late MetricsDAO _metricsDAO;

  late String _personID;
  String? _tenantID;

  final _latestMeals = signal<List<DayWithMeal>>([]);
  final _latestContacts = signal<List<SocialContact>>([]);
  final _latestAccounts = signal<List<FinancialAccountData>>([]);
  final _latestAssets = signal<List<AssetData>>([]);
  final _latestTransactions = signal<List<TransactionData>>([]);

  // Track subscriptions and effect cleanups to cancel them on dispose
  final List<dynamic> _subscriptions = [];

  // Reactive Streams (Database totals)
  final _totalHealthQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalHealthQuestPoints',
  );
  final _totalSocialQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalSocialQuestPoints',
  );
  final _totalFinanceQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalFinanceQuestPoints',
  );
  final _totalProjectQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalProjectQuestPoints',
  );
  final _historicalHealthMetricPoints = signal<double>(
    0.0,
    debugLabel: 'historicalHealthMetricPoints',
  );
  
  // Today's Points Signals
  final todayHealthPoints = signal<double>(0.0, debugLabel: 'todayHealthPoints');
  final todaySocialPoints = signal<double>(0.0, debugLabel: 'todaySocialPoints');
  final todayFinancePoints = signal<double>(0.0, debugLabel: 'todayFinancePoints');
  final todayProjectPoints = signal<double>(0.0, debugLabel: 'todayProjectPoints');

  // Breakdown Signals (Synced from DB categorical metrics)
  final projectsBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'projectsBreakdown',
  );
  final healthBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'healthBreakdown',
  );
  final socialBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'socialBreakdown',
  );
  final financeBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'financeBreakdown',
  );

  final averageScore = signal<double>(0);
  final totalXP = signal<double>(0);
  final globalLevel = signal<int>(1);
  final levelProgress = signal<double>(0);
  final rankTitle = signal<String>("Novice");

  ScoreBlock({ScoreData? initialScore}) {
    if (initialScore != null) {
      updateScore(initialScore);
    } else {
      updateScore(ScoreData.empty());
    }
  }

  ScoreData get score => _score.value;

  void updateScore(ScoreData scoreValue) {
    batch(() {
      _score.value = scoreValue;

      final xp =
          scoreValue.healthGlobalScore +
          scoreValue.socialGlobalScore +
          scoreValue.financialGlobalScore +
          scoreValue.careerGlobalScore;
      totalXP.value = xp;

      final avg = xp / 4;
      averageScore.value = avg;

      final level = GamificationService.getLevel(xp.toInt());
      globalLevel.value = level;

      levelProgress.value = GamificationService.getProgressToNextLevel(
        xp.toInt(),
      );

      if (level < 10) {
        rankTitle.value = "Novice";
      } else if (level < 20)
        rankTitle.value = "Protector";
      else if (level < 30)
        rankTitle.value = "Guardian";
      else if (level < 50)
        rankTitle.value = "Hero";
      else if (level < 70)
        rankTitle.value = "Legend";
      else if (level < 90)
        rankTitle.value = "Saint";
      else
        rankTitle.value = "God";
    });
  }

  String? _initializedPersonID;

  Future<void> init(
    ScoreDAO dao,
    PersonManagementDAO personDAO,
    FinanceDAO financeDAO,
    HealthBlock healthBlock,
    HealthMealDAO mealDAO,
    MetricsDAO metricsDAO,
    String personID, {
    String? tenantID,
  }) async {
    if (personID.isEmpty) return;

    if (_initializedPersonID == personID) {
      debugPrint("ScoreBlock: ℹ️ Already initialized for $personID");
      return;
    }

    isReady.value = false;
    debugPrint("ScoreBlock: 🚀 Initializing for personID: $personID");
    _initializedPersonID = personID;

    // Clear old subscriptions
    for (var s in _subscriptions) {
      if (s is StreamSubscription) {
        s.cancel();
      } else if (s is void Function())
        s();
    }
    _subscriptions.clear();

    _dao = dao;
    _financeDAO = financeDAO;
    _personID = personID;
    _healthBlock = healthBlock;
    _metricsDAO = metricsDAO;
    _tenantID = tenantID;

    // 1. Total Point Watchers
    _subscriptions.add(
      _metricsDAO
          .watchTotalHealthQuestPoints(personID)
          .listen((pts) => _totalHealthQuestPoints.value = pts),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTotalSocialQuestPoints(personID)
          .listen((pts) => _totalSocialQuestPoints.value = pts),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTotalProjectQuestPoints(personID)
          .listen((pts) => _totalProjectQuestPoints.value = pts),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTotalFinancialQuestPoints(personID)
          .listen((pts) => _totalFinanceQuestPoints.value = pts),
    );
    _subscriptions.add(
      _metricsDAO
          .watchHistoricalHealthMetricPoints(personID)
          .listen((pts) => _historicalHealthMetricPoints.value = pts),
    );
    
    // Today's Points Watchers
    _subscriptions.add(
      _metricsDAO
          .watchTodayHealthQuestPoints(personID)
          .listen((pts) => todayHealthPoints.value = pts),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTodaySocialQuestPoints(personID)
          .listen((pts) => todaySocialPoints.value = pts),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTodayProjectQuestPoints(personID)
          .listen((pts) => todayProjectPoints.value = pts),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTodayFinancialQuestPoints(personID)
          .listen((pts) => todayFinancePoints.value = pts),
    );

    // 2. Breakdown Watchers (Source of Truth)
    _subscriptions.add(
      _metricsDAO
          .watchProjectBreakdown(personID)
          .listen((data) => projectsBreakdown.value = data),
    );
    _subscriptions.add(
      _metricsDAO
          .watchHealthBreakdown(personID)
          .listen((data) => healthBreakdown.value = data),
    );
    _subscriptions.add(
      _metricsDAO
          .watchSocialBreakdown(personID)
          .listen((data) => socialBreakdown.value = data),
    );
    _subscriptions.add(
      _metricsDAO
          .watchFinancialBreakdown(personID)
          .listen((data) => financeBreakdown.value = data),
    );

    // 3. Other Data Watchers
    _subscriptions.add(
      _dao.watchScoreByPersonID(personID).listen((data) {
        if (data != null) {
          updateScore(
            ScoreData(
              healthGlobalScore: data.healthGlobalScore ?? 0.0,
              socialGlobalScore: data.socialGlobalScore ?? 0.0,
              financialGlobalScore: data.financialGlobalScore ?? 0.0,
              careerGlobalScore: data.careerGlobalScore ?? 0.0,
            ),
          );
        }
      }),
    );

    _subscriptions.add(
      financeDAO.watchAccounts(personID).listen((accounts) {
        _latestAccounts.value = accounts;
        _triggerFinanceUpdate();
      }),
    );
    _subscriptions.add(
      financeDAO.watchAssets(personID).listen((assets) {
        _latestAssets.value = assets;
        _triggerFinanceUpdate();
      }),
    );
    _subscriptions.add(
      financeDAO.watchAllTransactions(personID).listen((txs) {
        _latestTransactions.value = txs;
        _triggerFinanceUpdate();
      }),
    );
    _subscriptions.add(
      personDAO.getAllContacts().listen(
        (contacts) => _latestContacts.value = contacts,
      ),
    );
    _subscriptions.add(
      mealDAO.watchDaysWithMeals(personID).listen(
        (meals) => _latestMeals.value = meals,
      ),
    );

    // 4. Reactive Effects (Calculations)
    _subscriptions.add(
      effect(() {
        if (!isReady.value) return;
        if (!_healthBlock.hasInitialSync.value) return;
        _triggerHealthUpdate(
          _healthBlock.totalSteps.value,
          _healthBlock.todayCaloriesBurned.value,
          _healthBlock.todayWater.value,
          _healthBlock.todayExerciseMinutes.value,
          _healthBlock.todayFocusMinutes.value,
          _healthBlock.todaySleep.value,
          _latestMeals.value,
        );
      }),
    );

    _subscriptions.add(
      effect(() {
        if (!isReady.value) return;
        _triggerCareerUpdate(_totalProjectQuestPoints.value);
      }),
    );

    _subscriptions.add(
      effect(() {
        if (!isReady.value) return;
        _triggerSocialUpdate(
          _latestContacts.value,
          _totalSocialQuestPoints.value,
        );
      }),
    );

    // 5. Initial Bootstrapping
    Future.microtask(() async {
      try {
        final accounts = await _financeDAO
            .watchAccounts(_personID)
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
        _latestAccounts.value = accounts;

        final assets = await _financeDAO
            .watchAssets(_personID)
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
        _latestAssets.value = assets;

        final txs = await _financeDAO
            .watchAllTransactions(_personID)
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
        _latestTransactions.value = txs;

        _updateFinanceScore(isBootstrap: true);

        final contacts = await personDAO.getAllContacts().first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => [],
        );
        _updateSocialScore(
          contacts,
          _totalSocialQuestPoints.value,
          isBootstrap: true,
        );

        await _updateCareerScore(
          _totalProjectQuestPoints.value,
          isBootstrap: true,
        );

        await _metricsDAO.cleanupGenesisRecords(_personID);
        isReady.value = true;
        debugPrint("ScoreBlock: ✅ Initialization complete.");
      } catch (e) {
        debugPrint("ScoreBlock: Error during bootstrap: $e");
      }
    });
  }

  void _triggerHealthUpdate(
    int steps,
    int kcal,
    int water,
    int exercise,
    int focus,
    double sleep,
    List<DayWithMeal> meals,
  ) {
    _healthDebounce?.cancel();
    _healthDebounce = Timer(
      const Duration(milliseconds: 500),
      () =>
          _updateHealthScore(steps, kcal, water, exercise, focus, sleep, meals),
    );
  }

  void _triggerCareerUpdate(double questXP) {
    _careerDebounce?.cancel();
    _careerDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _updateCareerScore(questXP),
    );
  }

  void _triggerFinanceUpdate() {
    if (!isReady.value) return;
    _financeDebounce?.cancel();
    _financeDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _updateFinanceScore(),
    );
  }

  void _triggerSocialUpdate(List<SocialContact> contacts, double questXP) {
    if (!isReady.value) return;
    _socialDebounce?.cancel();
    _socialDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _updateSocialScore(contacts, questXP),
    );
  }

  Timer? _healthDebounce, _financeDebounce, _socialDebounce, _careerDebounce;

  void _updateFinanceScore({
    bool isBootstrap = false,
  }) {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;

    final accounts = _latestAccounts.value;
    final assets = _latestAssets.value;
    final txs = _latestTransactions.value;

    double accountWorth = 0;
    for (var acc in accounts) {
      accountWorth += acc.balance;
    }
    double assetWorth = 0;
    for (var asset in assets) {
      assetWorth += (asset.currentEstimatedValue ?? 0.0);
    }

    // Logic aligned with FinanceBlock.totalBalance
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

    final totalNetWorth =
        accountWorth + assetWorth + (income + savings - expense - investment);

    double finalScore = 0;
    if (FINANCE_NET_WORTH_PER_POINT > 0) {
      // Linear Point Calculation: +2 points for every $10
      finalScore = totalNetWorth / FINANCE_NET_WORTH_PER_POINT;
    }

    final questXP = _totalFinanceQuestPoints.value;
    finalScore += questXP;

    _dao.updateFinancialScore(_personID, finalScore);
  }

  Future<void> _updateSocialScore(
    List<SocialContact> contacts,
    double questXP, {
    bool isBootstrap = false,
  }) async {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;

    int totalAffection = 0;
    for (var contact in contacts) {
      totalAffection += contact.affection;
    }

    final contactPoints = (contacts.length * CONTACT_POINTS).toDouble();
    final affectionPoints =
        ((totalAffection ~/ AFFECTION_PER_UNIT) * AFFECTION_POINTS).toDouble();
    final finalScore = contactPoints + affectionPoints + questXP;

    await _dao.updateSocialScore(_personID, finalScore);
  }

  Future<void> _updateHealthScore(
    int totalSteps,
    int caloriesBurned,
    int waterIntake,
    int exerciseMinutes,
    int focusMinutes,
    double sleepHours,
    List<DayWithMeal> meals, {
    bool isBootstrap = false,
  }) async {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;

    double stepsPoints = 0;
    if (STEPS_PER_POINT > 0) stepsPoints = (totalSteps / STEPS_PER_POINT);

    double dietPoints = 0;
    final todayDate = DateTime.now();
    double todayKcal = 0;
    for (var item in meals) {
      final d = item.meal.eatenAt;
      if (d.year == todayDate.year &&
          d.month == todayDate.month &&
          d.day == todayDate.day) {
        todayKcal += item.meal.calories;
      }
    }
    if (todayKcal > 0 && todayKcal < CALORIE_LIMIT) {
      dietPoints += CALORIE_LIMIT_BONUS;
    }

    double exercisePoints = 0;
    if (EXERCISE_PER_POINT > 0) {
      exercisePoints = (exerciseMinutes / EXERCISE_PER_POINT);
    }

    double focusPoints = 0;
    if (FOCUS_MINUTES_PER_POINT > 0) {
      focusPoints = (focusMinutes / FOCUS_MINUTES_PER_POINT);
    }

    double waterPoints = 0;
    if (waterIntake >= WATER_GOAL) waterPoints += WATER_BONUS_POINTS;

    double sleepPoints = (sleepHours * SLEEP_POINTS_PER_HOUR);

    final baseHealthScore =
        stepsPoints +
        dietPoints +
        exercisePoints +
        focusPoints +
        waterPoints +
        sleepPoints;
    final questXP = _totalHealthQuestPoints.value;
    final historicalXP = _historicalHealthMetricPoints.value;
    final finalScore = baseHealthScore + questXP + historicalXP;

    await _dao.updateHealthScore(_personID, finalScore);
  }

  Future<void> manualSocialIncrement(double points, {String? label}) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementSocialQuestPoints(
      _personID,
      points,
      category: label ?? 'General',
      tenantId: _tenantID,
    );
  }

  Future<void> persistentCareerIncrement(double points, {String? label}) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementProjectQuestPoints(
      _personID,
      points,
      category: label ?? (points >= 50.0 ? 'Projects' : 'Tasks'),
      tenantId: _tenantID,
    );
  }

  Future<void> persistentHealthIncrement(double points, {String? label}) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementHealthQuestPoints(
      _personID,
      points,
      category: label ?? 'Quests',
      tenantId: _tenantID,
    );
  }

  void addPoints(double points, {String? label}) {
    persistentCareerIncrement(points, label: label);
  }

  Future<void> _updateCareerScore(
    double questXP, {
    bool isBootstrap = false,
  }) async {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;
    // FIX: questXP is already the sum of all categorized points in DB.
    await _dao.updateCareerScore(_personID, questXP);
  }

  void dispose() {
    for (var s in _subscriptions) {
      if (s is StreamSubscription) {
        s.cancel();
      } else if (s is void Function())
        s();
    }
    _subscriptions.clear();
    _healthDebounce?.cancel();
    _financeDebounce?.cancel();
    _socialDebounce?.cancel();
    _careerDebounce?.cancel();
    _score.dispose();
    averageScore.dispose();
    totalXP.dispose();
    globalLevel.dispose();
    levelProgress.dispose();
    rankTitle.dispose();
    _latestMeals.dispose();
    _latestContacts.dispose();
    _totalHealthQuestPoints.dispose();
    _totalSocialQuestPoints.dispose();
    _totalProjectQuestPoints.dispose();
    _totalFinanceQuestPoints.dispose();
    _historicalHealthMetricPoints.dispose();
    todayHealthPoints.dispose();
    todaySocialPoints.dispose();
    todayFinancePoints.dispose();
    todayProjectPoints.dispose();
    _latestAccounts.dispose();
    _latestAssets.dispose();
    _latestTransactions.dispose();
  }
}
