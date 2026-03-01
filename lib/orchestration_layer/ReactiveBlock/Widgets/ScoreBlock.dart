import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/initial_layer/CoreLogics/GamificationService.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:signals/signals.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Widgets/ScoreData.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';

class ScoreBlock {
  final _score = signal<ScoreData>(ScoreData.empty());

  // DAOs stored locally for access in update methods
  late ScoreDAO _dao;
  late FinanceDAO _financeDAO;
  late HealthBlock _healthBlock;

  late String _personID;

  final _latestMeals = signal<List<DayWithMeal>>([]);

  // Track subscriptions and effect cleanups to cancel them on dispose
  final List<dynamic> _subscriptions = [];

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

  void init(
    ScoreDAO dao,
    PersonManagementDAO personDAO,
    FinanceDAO financeDAO,
    HealthBlock healthBlock,
    HealthMealDAO mealDAO,
    String personID,
  ) {
    if (personID.isEmpty) {
      debugPrint("ScoreBlock: Skipping init, personID is empty.");
      return;
    }

    if (_initializedPersonID == personID) {
      debugPrint("ScoreBlock: ℹ️ Already initialized for $personID");
      return;
    }

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

    _dao = dao;
    _financeDAO = financeDAO;
    _personID = personID;
    _healthBlock = healthBlock;

    // 1. Listen to Score changes (read)
    _subscriptions.add(
      dao.watchScoreByPersonID(personID).listen((data) {
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

    // 2. Auto-Update Logic (write)

    // Finance Watcher
    _subscriptions.add(
      financeDAO.watchAccounts(personID).listen((accounts) async {
        final assets = await _financeDAO.watchAssets(personID).first;
        _updateFinanceScore(accounts, assets);
      }, onError: (e) => debugPrint("ScoreBlock: Error watching accounts: $e")),
    );
    _subscriptions.add(
      financeDAO.watchAssets(personID).listen((assets) async {
        final accounts = await _financeDAO.watchAccounts(personID).first;
        _updateFinanceScore(accounts, assets);
      }, onError: (e) => debugPrint("ScoreBlock: Error watching assets: $e")),
    );

    // Social Watcher
    _subscriptions.add(
      personDAO.getAllContacts().listen(
        (contacts) => _updateSocialScore(contacts),
        onError: (e) => debugPrint("ScoreBlock: Error watching contacts: $e"),
      ),
    );

    // Meal Watcher (Update signal)
    _subscriptions.add(
      mealDAO.watchDaysWithMeals().listen((meals) {
        _latestMeals.value = meals;
      }, onError: (e) => debugPrint("ScoreBlock: Error watching meals: $e")),
    );

    // Health Watcher (Reactive to Signals)
    _subscriptions.add(
      effect(() {
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
      debugPrint("ScoreBlock: triggering _updateFinanceScore...");
      try {
        double totalNetWorth = 0;
        for (var acc in accounts) {
          totalNetWorth += acc.balance;
        }
        for (var asset in assets) {
          totalNetWorth += (asset.currentEstimatedValue ?? 0.0);
        }
        debugPrint("ScoreBlock: Total net worth: $totalNetWorth");

        double financeScore = 0;
        if (FINANCE_SAVINGS_MILESTONE > 0) {
          financeScore =
              (totalNetWorth / FINANCE_SAVINGS_MILESTONE) *
              FINANCE_SAVINGS_POINTS;
        }

        debugPrint("ScoreBlock: Final Finance Global Score: $financeScore");
        await _dao.updateFinancialScore(_personID, financeScore);
      } catch (e) {
        debugPrint("Error updating finance score: $e");
      }
    });
  }

  void _updateSocialScore(List<SocialContact> contacts) {
    _socialDebounce?.cancel();
    _socialDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (_personID.isEmpty) return;
      debugPrint("ScoreBlock: triggering _updateSocialScore...");
      try {
        int totalAffection = 0;
        for (var contact in contacts) {
          totalAffection += contact.affection;
        }

        final socialScore =
            (contacts.length * CONTACT_POINTS) +
            ((totalAffection ~/ AFFECTION_PER_UNIT) * AFFECTION_POINTS);

        debugPrint(
          "ScoreBlock: Final Social Global Score: ${socialScore.toDouble()}",
        );
        await _dao.updateSocialScore(_personID, socialScore.toDouble());
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
      // 1. Steps Points
      int stepsPoints = 0;
      if (STEPS_PER_POINT > 0) {
        stepsPoints = (totalSteps / STEPS_PER_POINT).floor();
      }
      if (totalSteps >= _healthBlock.dailyStepGoal.value) {
        stepsPoints += STEP_GOAL_BONUS.toInt();
      }

      // 2. Nutrition Points
      int dietPoints = 0;
      final Map<String, double> dailyCalories = {};
      for (var item in allMealsWrapper) {
        final d = item.meal.eatenAt;
        final dateKey = "${d.year}-${d.month}-${d.day}";
        dailyCalories[dateKey] =
            (dailyCalories[dateKey] ?? 0) + item.meal.calories;
      }
      dailyCalories.forEach((_, calories) {
        if (calories > 0 && calories < _healthBlock.dailyKcalGoal.value) {
          dietPoints += CALORIE_LIMIT_BONUS.toInt();
        }
      });

      // 3. Exercise Points
      int exercisePoints = 0;
      if (EXERCISE_PER_POINT > 0) {
        exercisePoints = (exerciseMinutes / EXERCISE_PER_POINT).floor();
      }
      if (exerciseMinutes >= _healthBlock.dailyExerciseGoal.value) {
        exercisePoints += EXERCISE_GOAL_BONUS.toInt();
      }

      // 4. Focus Points
      int focusPoints = 0;
      if (FOCUS_MINUTES_PER_POINT > 0) {
        focusPoints = (focusMinutes / FOCUS_MINUTES_PER_POINT).floor();
      }
      if (focusMinutes >= _healthBlock.dailyFocusGoal.value) {
        focusPoints += FOCUS_GOAL_BONUS.toInt();
      }

      // 5. Water Points
      int waterPoints = 0;
      if (waterIntake >= _healthBlock.dailyWaterGoal.value) {
        waterPoints = WATER_GOAL_BONUS.toInt();
      }

      // 6. Sleep Points
      int sleepPoints = 0;
      if (sleepHours >= _healthBlock.dailySleepGoal.value) {
        sleepPoints = SLEEP_GOAL_BONUS.toInt();
      }

      final healthScore =
          (stepsPoints +
                  dietPoints +
                  exercisePoints +
                  focusPoints +
                  waterPoints +
                  sleepPoints)
              .toDouble();
      debugPrint(
        "ScoreBlock: Recalculated Health Score: $healthScore (Steps: $stepsPoints, Diet: $dietPoints, Exercise: $exercisePoints, Focus: $focusPoints, Water: $waterPoints, Sleep: $sleepPoints)",
      );
      await _dao.updateHealthScore(_personID, healthScore);
    } catch (e, stack) {
      debugPrint("Error updating health score: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Future<void> persistentCareerIncrement(double points) async {
    if (_personID.isEmpty) return;
    await _dao.incrementCareerScore(_personID, points);
  }

  Future<void> persistentHealthIncrement(double points) async {
    if (_personID.isEmpty) return;
    await _dao.incrementHealthScore(_personID, points);
  }

  /// Generic method to add points (default to Career/Global)
  void addPoints(double points) {
    persistentCareerIncrement(points);
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
  }
}
