import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:intl/intl.dart';

class GamificationService {
  final HealthMetricsDAO _healthMetricsDAO;
  final HealthMealDAO _healthMealDAO;

  GamificationService(this._healthMetricsDAO, this._healthMealDAO);

  Future<int> calculateTotalPoints(String personID) async {
    // 1. Points from Steps: 100 steps = 1 point
    int stepsPoints = 0;
    final allMetrics = await _healthMetricsDAO.watchAllMetrics(personID).first;
    int totalSteps = 0;
    for (var m in allMetrics) {
      totalSteps += m.steps;
    }
    stepsPoints = (totalSteps / 100).floor();

    // 2. Points from Diet: Daily Calories < 1500 = 15 points
    int dietPoints = 0;
    final allMealsWrapper = await _healthMealDAO.watchDaysWithMeals().first;

    // Group by Day
    final Map<String, double> dailyCalories = {};
    for (var item in allMealsWrapper) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.meal.eatenAt);
      dailyCalories[dateKey] =
          (dailyCalories[dateKey] ?? 0) + item.meal.calories;
    }

    // Calculate points
    dailyCalories.forEach((date, calories) {
      if (calories < 1500 && calories > 0) {
        // Assuming > 0 to count as "tracking"
        dietPoints += 15;
      }
    });

    return stepsPoints + dietPoints;
  }

  int getLevel(int points) {
    if (points == 0) return 0;
    // LV 1 = 100 points.
    // If linear: Level = Points / 100.
    return (points / 100).floor();
  }

  double getProgressToNextLevel(int points) {
    int currentLevel = getLevel(points);
    int currentLevelPoints = currentLevel * 100;

    return (points - currentLevelPoints) / 100;
  }
}
