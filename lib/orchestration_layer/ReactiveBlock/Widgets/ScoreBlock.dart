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
      _score.value = initialScore;
    }
  }

  ScoreData get score => _score.value;
  set score(ScoreData value) => _score.value = value;

  late final averageScore = computed(() {
    final s = _score.value;
    return (s.healthGlobalScore +
            s.socialGlobalScore +
            s.financialGlobalScore +
            s.careerGlobalScore) /
        4;
  });

  /// Raw sum of all scores (Range: 0.0 - 4.0)
  late final totalXP = computed(() {
    final s = _score.value;
    return s.healthGlobalScore +
        s.socialGlobalScore +
        s.financialGlobalScore +
        s.careerGlobalScore;
  });

  /// Global level (Cumulative: Level L requires 50*L*(L+1) pts)
  late final globalLevel = computed(() {
    return GamificationService.getLevel(totalXP.value.toInt());
  });

  /// Percentage progress towards the next level
  late final levelProgress = computed(() {
    return GamificationService.getProgressToNextLevel(totalXP.value.toInt());
  });

  /// Descriptive rank based on Level
  late final rankTitle = computed(() {
    final level = globalLevel.value;
    if (level < 10) return "Novice";
    if (level < 20) return "Protector";
    if (level < 30) return "Guardian";
    if (level < 50) return "Hero";
    if (level < 70) return "Legend";
    if (level < 90) return "Saint";
    return "God";
  });

  void updateScore(ScoreData score) {
    _score.value = score;
  }

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

    // Clear old subscriptions to avoid overlapping updates if init is called again (e.g. on user login)
    for (var s in _subscriptions) {
      s.cancel();
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
        final steps = _healthBlock.totalSteps.value;
        final calories = _healthBlock.todayCaloriesBurned.value;
        final water = _healthBlock.todayWater.value;
        final exercise = _healthBlock.todayExerciseMinutes.value;
        final focus = _healthBlock.todayFocusMinutes.value;
        final meals = _latestMeals.value;

        _triggerHealthUpdate(steps, calories, water, exercise, focus, meals);
      }),
    );
  }

  void _triggerHealthUpdate(
    int totalSteps,
    int caloriesBurned,
    int waterIntake,
    int exerciseMinutes,
    int focusMinutes,
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
    List<DayWithMeal> allMealsWrapper,
  ) async {
    if (_personID.isEmpty) return;

    try {
      // 1. Steps Points
      int stepsPoints = 0;
      if (STEPS_PER_POINT > 0) {
        stepsPoints = (totalSteps / STEPS_PER_POINT).floor();
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
        if (calories > 0 && calories < CALORIE_LIMIT) {
          dietPoints += CALORIE_BONUS_POINTS;
        }
      });

      // 3. Exercise Points
      int exercisePoints = 0;
      if (EXERCISE_PER_POINT > 0) {
        exercisePoints = (exerciseMinutes / EXERCISE_PER_POINT).floor();
      }

      // 4. Focus Points
      int focusPoints = 0;
      if (FOCUS_MINUTES_PER_POINT > 0) {
        focusPoints = (focusMinutes / FOCUS_MINUTES_PER_POINT).floor();
      }

      // 5. Water Points
      int waterPoints = 0;
      if (waterIntake >= WATER_GOAL) {
        waterPoints = WATER_BONUS_POINTS;
      }

      final healthScore =
          (stepsPoints +
                  dietPoints +
                  exercisePoints +
                  focusPoints +
                  waterPoints)
              .toDouble();
      debugPrint(
        "ScoreBlock: Recalculated Health Score: $healthScore (Steps: $stepsPoints, Diet: $dietPoints, Exercise: $exercisePoints, Focus: $focusPoints, Water: $waterPoints)",
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
      } else if (s is Function) {
        s(); // Stop effect
      }
    }
    _healthDebounce?.cancel();
    _financeDebounce?.cancel();
    _socialDebounce?.cancel();
    _score.dispose();
  }
}
