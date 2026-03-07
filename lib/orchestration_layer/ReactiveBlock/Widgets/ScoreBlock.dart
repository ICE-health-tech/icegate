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

  final _latestMeals = signal<List<DayWithMeal>>([]);

  // Track subscriptions and effect cleanups to cancel them on dispose
  final List<dynamic> _subscriptions = [];

  // Monotonic Correction Tracking

  ScoreBlock({ScoreData? initialScore}) {
    if (initialScore != null) {
      updateScore(initialScore);
    } else {
      updateScore(ScoreData.empty());
    }
  }

  ScoreData get score => _score.value;
  set score(ScoreData value) => _score.value = value;

  final averageScore = signal<double>(0);
  final totalXP = signal<double>(0);
  final globalLevel = signal<int>(1);
  final levelProgress = signal<double>(0);
  final rankTitle = signal<String>("Novice");

  // Breakdown Signals
  final healthBreakdown = signal<Map<String, double>>({});
  final socialBreakdown = signal<Map<String, double>>({});
  final financeBreakdown = signal<Map<String, double>>({});
  final projectsBreakdown = signal<Map<String, double>>({});

  void updateScore(ScoreData scoreValue) {
    batch(() {
      _score.value = scoreValue;

      final avg =
          (scoreValue.healthGlobalScore +
              scoreValue.socialGlobalScore +
              scoreValue.financialGlobalScore +
              scoreValue.careerGlobalScore) /
          4;
      averageScore.value = avg;

      final xp =
          scoreValue.healthGlobalScore +
          scoreValue.socialGlobalScore +
          scoreValue.financialGlobalScore +
          scoreValue.careerGlobalScore;
      totalXP.value = xp;

      final level = GamificationService.getLevel(xp.toInt());
      globalLevel.value = level;

      levelProgress.value = GamificationService.getProgressToNextLevel(
        xp.toInt(),
      );

      if (level < 10)
        rankTitle.value = "Novice";
      else if (level < 20)
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
    String personID,
  ) async {
    if (personID.isEmpty) {
      debugPrint("ScoreBlock: Skipping init, personID is empty.");
      return;
    }

    if (_initializedPersonID == personID) {
      debugPrint("ScoreBlock: ℹ️ Already initialized for $personID");
      return;
    }

    isReady.value = false;
    debugPrint("ScoreBlock: 🚀 Initializing for personID: $personID");
    _initializedPersonID = personID;

    // Clear old subscriptions safely
    for (var s in _subscriptions) {
      if (s is StreamSubscription) {
        s.cancel();
      } else if (s is void Function()) {
        s(); // Effect cleanup
      }
    }
    _subscriptions.clear();

    // 3. DAOs Initialization

    _dao = dao;
    _financeDAO = financeDAO;
    _personID = personID;
    _healthBlock = healthBlock;
    _metricsDAO = metricsDAO;

    _subscriptions.add(
      dao.watchScoreByPersonID(personID).listen((data) {
        if (!isReady.value) return;
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
      }, onError: (e) => debugPrint("ScoreBlock: Error watching score: $e")),
    );

    _subscriptions.add(
      _metricsDAO.watchTotalHealthQuestPoints(personID).listen((pts) {
        if (!isReady.value) return;
        _totalHealthQuestPoints.value = pts;
      }),
    );
    _subscriptions.add(
      _metricsDAO.watchTotalSocialQuestPoints(personID).listen((pts) {
        if (!isReady.value) return;
        _totalSocialQuestPoints.value = pts;
      }),
    );
    _subscriptions.add(
      _metricsDAO.watchTotalProjectQuestPoints(personID).listen((pts) {
        if (!isReady.value) return;
        _totalProjectQuestPoints.value = pts;
      }),
    );
    _subscriptions.add(
      _metricsDAO.watchTotalFinancialQuestPoints(personID).listen((pts) {
        if (!isReady.value) return;
        _totalFinancialQuestPoints.value = pts;
      }),
    );

    _subscriptions.add(
      _metricsDAO.watchHistoricalHealthMetricPoints(personID).listen((pts) {
        if (!isReady.value) return;
        _historicalHealthMetricPoints.value = pts;
      }),
    );

    // 2. Auto-Update Logic (write)

    // Finance Watcher
    _subscriptions.add(
      financeDAO.watchAccounts(personID).listen((accounts) async {
        if (!isReady.value) return;
        final assets = await _financeDAO.watchAssets(personID).first;
        _updateFinanceScore(accounts, assets);
      }, onError: (e) => debugPrint("ScoreBlock: Error watching accounts: $e")),
    );
    _subscriptions.add(
      financeDAO.watchAssets(personID).listen((assets) async {
        if (!isReady.value) return;
        final accounts = await _financeDAO.watchAccounts(personID).first;
        _updateFinanceScore(accounts, assets);
      }, onError: (e) => debugPrint("ScoreBlock: Error watching assets: $e")),
    );

    // Social Watcher
    _subscriptions.add(
      personDAO.getAllContacts().listen((contacts) {
        if (!isReady.value) return;
        _updateSocialScore(contacts);
      }, onError: (e) => debugPrint("ScoreBlock: Error watching contacts: $e")),
    );

    // Meal Watcher (Update signal)
    _subscriptions.add(
      mealDAO.watchDaysWithMeals().listen((meals) {
        if (!isReady.value) return;
        _latestMeals.value = meals;
      }, onError: (e) => debugPrint("ScoreBlock: Error watching meals: $e")),
    );

    // Health Watcher (Reactive to Signals)
    _subscriptions.add(
      effect(() {
        if (!isReady.value) return;
        if (!_healthBlock.hasInitialSync.value) {
          debugPrint(
            "ScoreBlock: Skipping health update, initial sync pending.",
          );
          return;
        }

        final steps = _healthBlock.totalSteps.value;
        final calories = _healthBlock.todayCaloriesBurned.value;
        final water = _healthBlock.todayWater.value;
        final exercise = _healthBlock.todayExerciseMinutes.value;
        final focus = _healthBlock.todayFocusMinutes.value;
        final sleep = _healthBlock.todaySleep.value;
        final meals = _latestMeals.value;

        _triggerHealthUpdate(
          steps,
          calories,
          water,
          exercise,
          focus,
          sleep,
          meals,
        );
      }),
    );

    // 3. Initial Bootstrapping (Force calculation once)
    Future.microtask(() async {
      try {
        final accounts = await _financeDAO.watchAccounts(_personID).first;
        final assets = await _financeDAO.watchAssets(_personID).first;
        _updateFinanceScore(accounts, assets);

        final contacts = await personDAO.getAllContacts().first;
        _updateSocialScore(contacts);

        // Cleanup any old migration artifacts
        await _metricsDAO.cleanupGenesisRecords(_personID);

        // Now we are ready
        isReady.value = true;
        debugPrint(
          "ScoreBlock: ✅ Initialization complete. Scoring is now fully deterministic.",
        );
      } catch (e) {
        debugPrint("ScoreBlock: Error during initial bootstrap: $e");
      }
    });
  }

  void _triggerHealthUpdate(
    int totalSteps,
    int caloriesBurned,
    int waterIntake,
    int exerciseMinutes,
    int focusMinutes,
    double sleepHours,
    List<DayWithMeal> meals,
  ) {
    _healthDebounce?.cancel();
    _healthDebounce = Timer(const Duration(milliseconds: 500), () async {
      _updateHealthScore(
        totalSteps,
        caloriesBurned,
        waterIntake,
        exerciseMinutes,
        focusMinutes,
        sleepHours,
        meals,
      );
    });
  }

  Timer? _healthDebounce;
  Timer? _financeDebounce;
  Timer? _socialDebounce;

  void _updateFinanceScore(
    List<FinancialAccountData> accounts,
    List<AssetData> assets,
  ) {
    _financeDebounce?.cancel();
    _financeDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (_personID.isEmpty) return;
      try {
        double accountWorth = 0;
        for (var acc in accounts) {
          accountWorth += acc.balance;
        }
        double assetWorth = 0;
        for (var asset in assets) {
          assetWorth += (asset.currentEstimatedValue ?? 0.0);
        }

        double accountScore = 0;
        double assetScore = 0;

        if (FINANCE_SAVINGS_MILESTONE > 0) {
          accountScore =
              (accountWorth / FINANCE_SAVINGS_MILESTONE) *
              FINANCE_SAVINGS_POINTS;
          assetScore =
              (assetWorth / FINANCE_SAVINGS_MILESTONE) * FINANCE_SAVINGS_POINTS;
        }

        final questXP = _totalFinancialQuestPoints.value;
        final finalScore = accountScore + assetScore + questXP;

        financeBreakdown.value = {
          'Accounts': accountScore,
          'Assets': assetScore,
          if (questXP > 0) 'Quests': questXP,
        };

        debugPrint(
          "ScoreBlock: Finance Score — base: ${accountScore + assetScore}, totalQuestXP: $questXP, final: $finalScore",
        );

        await _dao.updateFinancialScore(_personID, finalScore);
      } catch (e) {
        debugPrint("Error updating finance score: $e");
      }
    });
  }

  void _updateSocialScore(List<SocialContact> contacts) {
    _socialDebounce?.cancel();
    _socialDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (_personID.isEmpty) return;
      try {
        int totalAffection = 0;
        for (var contact in contacts) {
          totalAffection += contact.affection;
        }

        final contactPoints = (contacts.length * CONTACT_POINTS).toDouble();
        final affectionPoints =
            ((totalAffection ~/ AFFECTION_PER_UNIT) * AFFECTION_POINTS)
                .toDouble();

        final questXP = _totalSocialQuestPoints.value;
        final finalScore = contactPoints + affectionPoints + questXP;

        socialBreakdown.value = {
          'Contacts': contactPoints,
          'Affection': affectionPoints,
          if (questXP > 0) 'Quests': questXP,
        };

        debugPrint(
          "ScoreBlock: Social Score — base: ${contactPoints + affectionPoints}, totalQuestXP: $questXP, final: $finalScore",
        );

        await _dao.updateSocialScore(_personID, finalScore);
      } catch (e) {
        debugPrint("Error updating social score: $e");
      }
    });
  }

  Future<void> _updateHealthScore(
    int totalSteps,
    int caloriesBurned,
    int waterIntake,
    int exerciseMinutes,
    int focusMinutes,
    double sleepHours,
    List<DayWithMeal> allMealsWrapper,
  ) async {
    if (_personID.isEmpty) return;

    try {
      // 1. Steps Points (500 steps = 1 point)
      double stepsPoints = 0;
      if (STEPS_PER_POINT > 0) {
        stepsPoints = (totalSteps / STEPS_PER_POINT);
      }

      // 2. Diet Points (Bonus if < 1500 kcal)
      double dietPoints = 0;
      final Map<String, double> dailyCalories = {};
      for (var item in allMealsWrapper) {
        final d = item.meal.eatenAt;
        final dateKey = "${d.year}-${d.month}-${d.day}";
        dailyCalories[dateKey] =
            (dailyCalories[dateKey] ?? 0) + item.meal.calories;
      }

      // Check TODAY's calories specifically for the manual rule
      final todayDate = DateTime.now();
      final todayKey = "${todayDate.year}-${todayDate.month}-${todayDate.day}";
      final todayKcal = dailyCalories[todayKey] ?? 0.0;
      if (todayKcal > 0 && todayKcal < CALORIE_LIMIT) {
        dietPoints += CALORIE_LIMIT_BONUS;
      }

      // 3. Exercise Points (5 min = 1 point)
      double exercisePoints = 0;
      if (EXERCISE_PER_POINT > 0) {
        exercisePoints = (exerciseMinutes / EXERCISE_PER_POINT);
      }

      // 4. Focus Points
      double focusPoints = 0;
      if (FOCUS_MINUTES_PER_POINT > 0) {
        focusPoints = (focusMinutes / FOCUS_MINUTES_PER_POINT);
      }

      // 5. Water Points (Goal >= 2000ml = +10)
      double waterPoints = 0;
      if (waterIntake >= WATER_GOAL) {
        waterPoints += WATER_BONUS_POINTS;
      }

      // 6. Sleep Points (2 points per hour)
      double sleepPoints = (sleepHours * SLEEP_POINTS_PER_HOUR);

      // 7. Weight Points (Placeholder for now, implementation depends on HealthBlock startWeight)
      double weightPoints = 0;
      // if (hasMetWeightGoalToday) weightPoints += (weightDelta * 100);

      final baseHealthScore =
          stepsPoints +
          dietPoints +
          exercisePoints +
          focusPoints +
          waterPoints +
          sleepPoints +
          weightPoints;

      final questXP = _totalHealthQuestPoints.value;
      final historicalXP = _historicalHealthMetricPoints.value;
      final derivedScore = baseHealthScore + questXP + historicalXP;

      final finalScore = derivedScore;

      healthBreakdown.value = {
        'Steps': stepsPoints,
        if (dietPoints > 0) 'Diet': dietPoints,
        'Exercise': exercisePoints,
        if (focusPoints > 0) 'Focus': focusPoints,
        if (waterPoints > 0) 'Water': waterPoints,
        'Sleep': sleepPoints,
        if (weightPoints > 0) 'Weight': weightPoints,
        if (questXP > 0) 'Quests': questXP,
        if (historicalXP > 0) 'Legacy': historicalXP,
      };

      debugPrint(
        "ScoreBlock: Health Score — current_base: $baseHealthScore, totalQuestXP: $questXP, historicalMetricXP: $historicalXP, final: $finalScore",
      );
      await _dao.updateHealthScore(_personID, finalScore);
    } catch (e, stack) {
      debugPrint("Error updating health score: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Future<void> manualSocialIncrement(double points) async {
    if (_personID.isEmpty) return;
    await _metricsDAO.incrementSocialQuestPoints(_personID, points);
  }

  Future<void> persistentCareerIncrement(double points, {String? label}) async {
    if (_personID.isEmpty) return;

    final current = Map<String, double>.from(projectsBreakdown.value);
    String finalLabel = label ?? (points >= 50.0 ? 'Projects' : 'Tasks');
    current[finalLabel] = (current[finalLabel] ?? 0) + points;
    projectsBreakdown.value = current;

    await _metricsDAO.incrementProjectQuestPoints(_personID, points);
  }

  Future<void> persistentHealthIncrement(double points, {String? label}) async {
    if (_personID.isEmpty) return;

    final current = Map<String, double>.from(healthBreakdown.value);
    final key = label ?? 'Quests';
    current[key] = (current[key] ?? 0) + points;
    healthBreakdown.value = current;

    await _metricsDAO.incrementHealthQuestPoints(_personID, points);
  }

  /// Generic method to add points (default to Career/Global)
  void addPoints(double points, {String? label}) {
    persistentCareerIncrement(points, label: label);
  }

  void dispose() {
    for (var s in _subscriptions) {
      if (s is StreamSubscription) {
        s.cancel();
      } else if (s is void Function()) {
        s(); // Effect cleanup
      }
    }
    _subscriptions.clear();
    _healthDebounce?.cancel();
    _financeDebounce?.cancel();
    _socialDebounce?.cancel();
    _score.dispose();
    averageScore.dispose();
    totalXP.dispose();
    globalLevel.dispose();
    levelProgress.dispose();
    rankTitle.dispose();
    _latestMeals.dispose();
    _totalHealthQuestPoints.dispose();
    _totalSocialQuestPoints.dispose();
    _totalProjectQuestPoints.dispose();
    _totalFinancialQuestPoints.dispose();
    _historicalHealthMetricPoints.dispose();
  }

  // Internal Quest XP signals (watching DB)
  final _totalHealthQuestPoints = signal<double>(0);
  final _totalSocialQuestPoints = signal<double>(0);
  final _totalProjectQuestPoints = signal<double>(0);
  final _totalFinancialQuestPoints = signal<double>(0);
  final _historicalHealthMetricPoints = signal<double>(0);
}
