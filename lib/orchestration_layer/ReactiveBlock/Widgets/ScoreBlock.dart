import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart'
    hide ScoreData;
import 'package:ice_shield/initial_layer/CoreLogics/GamificationService.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/Const.dart';
import 'package:signals/signals.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Widgets/ScoreData.dart';

class ScoreBlock {
  final _score = signal<ScoreData>(ScoreData.empty());

  // DAOs stored locally for access in update methods
  late ScoreDAO _dao;
  late FinanceDAO _financeDAO;

  late int _personID;

  // Track subscriptions to cancel them on dispose
  final List<StreamSubscription> _subscriptions = [];

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
    HealthMetricsDAO healthDAO,
    HealthMealDAO mealDAO,
    int personID,
  ) {
    // Clear old subscriptions to avoid overlapping updates if init is called again (e.g. on user login)
    for (var s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();

    _dao = dao;
    _financeDAO = financeDAO;
    _personID = personID;

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

    // Health Watcher
    _subscriptions.add(
      healthDAO.watchAllMetrics(personID).listen(
        (metrics) async {
          final meals = await mealDAO.watchDaysWithMeals().first;
          _updateHealthScore(metrics, meals);
        },
        onError: (e) =>
            debugPrint("ScoreBlock: Error watching health metrics: $e"),
      ),
    );
    _subscriptions.add(
      mealDAO.watchDaysWithMeals().listen((meals) async {
        final metrics = await healthDAO.watchAllMetrics(personID).first;
        _updateHealthScore(metrics, meals);
      }, onError: (e) => debugPrint("ScoreBlock: Error watching meals: $e")),
    );
  }

  Future<void> _updateFinanceScore(
    List<FinancialAccountData> accounts,
    List<AssetData> assets,
  ) async {
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

      // Points calculation using milestone from Const.dart
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
  }

  Future<void> _updateSocialScore(List<SocialContact> contacts) async {
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
  }

  Future<void> _updateHealthScore(
    List<HealthMetricsLocal> allMetrics,
    List<DayWithMeal> allMealsWrapper,
  ) async {
    debugPrint("ScoreBlock: triggering _updateHealthScore...");
    try {
      // 1. Steps
      int stepsPoints = 0;
      debugPrint(
        "ScoreBlock: Processing ${allMetrics.length} health metrics for personID: $_personID",
      );

      int totalSteps = 0;
      for (var m in allMetrics) {
        totalSteps += m.steps;
      }
      debugPrint("ScoreBlock: Total steps sum: $totalSteps");

      if (STEPS_PER_POINT > 0) {
        stepsPoints = (totalSteps / STEPS_PER_POINT).floor();
      }

      // 2. Diet
      int dietPoints = 0;
      final Map<String, double> dailyCalories = {};

      for (var item in allMealsWrapper) {
        // Group by YYYY-MM-DD
        final d = item.meal.eatenAt; // Skip meals without a valid date

        final dateKey = "${d.year}-${d.month}-${d.day}";
        dailyCalories[dateKey] =
            (dailyCalories[dateKey] ?? 0) + item.meal.calories;
      }

      dailyCalories.forEach((_, calories) {
        if (calories > 0 && calories < CALORIE_LIMIT) {
          dietPoints += CALORIE_BONUS_POINTS;
        }
      });
      debugPrint(
        "ScoreBlock: Calculated health metrics — Steps: $stepsPoints, Diet: $dietPoints",
      );

      final healthScore = (stepsPoints + dietPoints).toDouble();
      debugPrint("ScoreBlock: Final Health Global Score: $healthScore");
      // if (_personID != null) {
      await _dao.updateHealthScore(_personID, healthScore);
      // }
    } catch (e, stack) {
      debugPrint("Error updating health score: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  Future<void> persistentCareerIncrement(double points) async {
    await _dao.incrementCareerScore(_personID, points);
  }

  Future<void> persistentHealthIncrement(double points) async {
    await _dao.incrementHealthScore(_personID, points);
  }

  /// Generic method to add points (default to Career/Global)
  void addPoints(double points) {
    persistentCareerIncrement(points);
  }

  void dispose() {
    for (var s in _subscriptions) {
      s.cancel();
    }
    _score.dispose();
  }
}
