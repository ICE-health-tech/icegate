import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/Const.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class GamificationService {
  final HealthMetricsDAO _healthMetricsDAO;
  final HealthMealDAO _healthMealDAO;
  final PersonManagementDAO _personDAO;
  final FinanceDAO _financeDAO;

  GamificationService(
    this._healthMetricsDAO,
    this._healthMealDAO,
    this._personDAO,
    this._financeDAO,
  );

  Future<int> calculateTotalPoints(String personID) async {
    // 1. Points from Steps: STEPS_PER_POINT steps = 1 point
    int stepsPoints = 0;
    try {
      final allMetrics = await _healthMetricsDAO
          .watchAllMetrics(personID)
          .first;
      int totalSteps = 0;
      for (var m in allMetrics) {
        totalSteps += m.steps;
      }
      stepsPoints = (totalSteps / STEPS_PER_POINT).floor();
    } catch (e) {
      stepsPoints = 0;
    }

    // 2. Points from Diet: Daily Calories < CALORIE_LIMIT = CALORIE_BONUS_POINTS
    int dietPoints = 0;
    try {
      final allMealsWrapper = await _healthMealDAO.watchDaysWithMeals().first;

      // Group by Day
      final Map<String, double> dailyCalories = {};
      for (var item in allMealsWrapper) {
        final date = item.meal.eatenAt; // Skip meals without a valid date

        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        dailyCalories[dateKey] =
            (dailyCalories[dateKey] ?? 0) + item.meal.calories;
      }

      // Calculate points
      dailyCalories.forEach((date, calories) {
        if (calories > 0 && calories < CALORIE_LIMIT) {
          dietPoints += CALORIE_BONUS_POINTS;
        }
      });
    } catch (e) {
      dietPoints = 0;
    }

    // 3. Points from Social: CONTACT_POINTS per contact, AFFECTION_POINTS per AFFECTION_PER_UNIT affection
    int socialPoints = 0;
    try {
      final contacts = await _personDAO.getAllContacts().first;
      int totalAffection = 0;
      for (var contact in contacts) {
        totalAffection += contact.affection;
      }
      socialPoints =
          (contacts.length * CONTACT_POINTS) +
          ((totalAffection ~/ AFFECTION_PER_UNIT) * AFFECTION_POINTS);
    } catch (e) {
      socialPoints = 0;
    }

    // 4. Points from Finance: Net Worth / FINANCE_SAVINGS_MILESTONE * FINANCE_SAVINGS_POINTS
    int financePoints = 0;
    try {
      final accounts = await _financeDAO.watchAccounts(personID).first;
      final assets = await _financeDAO.watchAssets(personID).first;

      double totalNetWorth = 0;
      for (var acc in accounts) {
        totalNetWorth += acc.balance;
      }
      for (var asset in assets) {
        totalNetWorth += (asset.currentEstimatedValue ?? 0.0);
      }

      financePoints =
          ((totalNetWorth / FINANCE_SAVINGS_MILESTONE) * FINANCE_SAVINGS_POINTS)
              .floor();
    } catch (e) {
      financePoints = 0;
    }

    return stepsPoints + dietPoints + socialPoints + financePoints;
  }

  Future<Map<String, int>> getPointsBreakdown(String personID) async {
    // 1. Steps
    int stepsPoints = 0;
    try {
      final allMetrics = await _healthMetricsDAO
          .watchAllMetrics(personID)
          .first;
      int totalSteps = 0;
      for (var m in allMetrics) {
        totalSteps += m.steps;
      }
      stepsPoints = (totalSteps / STEPS_PER_POINT).floor();
    } catch (_) {}

    // 2. Diet
    int dietPoints = 0;
    try {
      final allMealsWrapper = await _healthMealDAO.watchDaysWithMeals().first;
      final Map<String, double> dailyCalories = {};
      for (var item in allMealsWrapper) {
        final dateKey = DateFormat('yyyy-MM-dd').format(item.meal.eatenAt);
        dailyCalories[dateKey] =
            (dailyCalories[dateKey] ?? 0) + item.meal.calories;
      }
      dailyCalories.forEach((date, calories) {
        if (calories > 0 && calories < CALORIE_LIMIT) {
          dietPoints += CALORIE_BONUS_POINTS;
        }
      });
    } catch (_) {}

    // 3. Social
    int socialPoints = 0;
    try {
      final contacts = await _personDAO.getAllContacts().first;
      int totalAffection = 0;
      for (var contact in contacts) {
        totalAffection += contact.affection;
      }
      socialPoints =
          (contacts.length * CONTACT_POINTS) +
          ((totalAffection ~/ AFFECTION_PER_UNIT) * AFFECTION_POINTS);
    } catch (_) {}

    // 4. Finance
    int financePoints = 0;
    try {
      final accounts = await _financeDAO.watchAccounts(personID).first;
      final assets = await _financeDAO.watchAssets(personID).first;
      double totalNetWorth = 0;
      for (var acc in accounts) {
        totalNetWorth += acc.balance;
      }
      for (var asset in assets) {
        totalNetWorth += (asset.currentEstimatedValue ?? 0.0);
      }
      financePoints =
          ((totalNetWorth / FINANCE_SAVINGS_MILESTONE) * FINANCE_SAVINGS_POINTS)
              .floor();
    } catch (_) {}

    return {
      'Steps': stepsPoints,
      'Diet': dietPoints,
      'Social': socialPoints,
      'Finance': financePoints,
    };
  }

  static int getLevel(int points) {
    if (points < 0) return 0;
    // Formula derived from P = 50 * L * (L + 1)
    return ((-1 + sqrt(1 + 0.08 * points)) / 2).floor();
  }

  static double getProgressToNextLevel(int points) {
    if (points < 0) return 0.0;

    int currentLevel = getLevel(points);
    // Base points for current level L: 50 * L * (L + 1)
    int basePoints = (50 * currentLevel * (currentLevel + 1)).toInt();

    // Points needed for next level (L+1) is simply (L+1) * 100
    int pointsNeedForNextLevel = (currentLevel + 1) * 100;

    return (points - basePoints) / pointsNeedForNextLevel;
  }
}
