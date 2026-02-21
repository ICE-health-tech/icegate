import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';
import 'package:ice_shield/ui_layer/health_page/models/HealthMetric.dart';
import 'package:ice_shield/ui_layer/health_page/services/HealthService.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/Const.dart';
import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart' show ReadContext;

/// Protocol for managing health metrics data
abstract class HealthMetricsProtocol {
  /// Get the current health metrics
  HealthMetrics? getHealthMetrics();

  /// Update health metrics
  Future<bool> updateHealthMetrics(HealthMetrics metrics);

  /// Update specific metric value
  Future<bool> updateMetric(String metricId, dynamic value);

  /// Get metric by ID
  dynamic getMetric(String metricId);

  /// Validate health metrics
  Map<String, String?> validateHealthMetrics(HealthMetrics metrics);
}

/// Default implementation of HealthMetricsProtocol
class HealthMetricsService implements HealthMetricsProtocol {
  HealthMetrics? _currentMetrics;

  HealthMetricsService({HealthMetrics? initialMetrics})
    : _currentMetrics = initialMetrics;

  @override
  HealthMetrics? getHealthMetrics() {
    return _currentMetrics;
  }

  @override
  Future<bool> updateHealthMetrics(HealthMetrics metrics) async {
    // Validate before updating
    final errors = validateHealthMetrics(metrics);
    if (errors.values.any((error) => error != null)) {
      return false;
    }

    // Simulate async operation (e.g., API call or database update)
    await Future.delayed(const Duration(milliseconds: 300));
    _currentMetrics = metrics;
    return true;
  }

  @override
  Future<bool> updateMetric(String metricId, dynamic value) async {
    if (_currentMetrics == null) return false;

    try {
      HealthMetrics updatedMetrics;

      switch (metricId) {
        case 'steps':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(todaySteps: value);
          break;
        case 'caloriesConsumed':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(caloriesConsumed: value);
          break;
        case 'caloriesBurned':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(caloriesBurned: value);
          break;
        case 'sleepHours':
          if (value is! double) return false;
          updatedMetrics = _currentMetrics!.copyWith(sleepHours: value);
          break;
        case 'heartRate':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(heartRate: value);
          break;
        default:
          return false;
      }

      return await updateHealthMetrics(updatedMetrics);
    } catch (e) {
      return false;
    }
  }

  @override
  dynamic getMetric(String metricId) {
    if (_currentMetrics == null) return null;

    switch (metricId) {
      case 'steps':
        return _currentMetrics!.todaySteps;
      case 'caloriesConsumed':
        return _currentMetrics!.caloriesConsumed;
      case 'caloriesBurned':
        return _currentMetrics!.caloriesBurned;
      case 'sleepHours':
        return _currentMetrics!.sleepHours;
      case 'heartRate':
        return _currentMetrics!.heartRate;
      case 'netCalories':
        return _currentMetrics!.netCalories;
      default:
        return null;
    }
  }

  @override
  Map<String, String?> validateHealthMetrics(HealthMetrics metrics) {
    final errors = <String, String?>{};

    // Validate steps (should be non-negative and reasonable)
    if (metrics.todaySteps < 0) {
      errors['todaySteps'] = 'Steps cannot be negative';
    } else if (metrics.todaySteps > 100000) {
      errors['todaySteps'] = 'Steps value seems unrealistic';
    }

    // Validate calories consumed (should be positive and reasonable)
    if (metrics.caloriesConsumed < 0) {
      errors['caloriesConsumed'] = 'Calories consumed cannot be negative';
    } else if (metrics.caloriesConsumed > 10000) {
      errors['caloriesConsumed'] = 'Calories consumed seems too high';
    }

    // Validate calories burned (should be non-negative and reasonable)
    if (metrics.caloriesBurned < 0) {
      errors['caloriesBurned'] = 'Calories burned cannot be negative';
    } else if (metrics.caloriesBurned > 5000) {
      errors['caloriesBurned'] = 'Calories burned seems too high';
    }

    // Validate sleep hours (should be between 0 and 24)
    if (metrics.sleepHours < 0) {
      errors['sleepHours'] = 'Sleep hours cannot be negative';
    } else if (metrics.sleepHours > 24) {
      errors['sleepHours'] = 'Sleep hours cannot exceed 24';
    }

    // Validate heart rate (should be reasonable)
    if (metrics.heartRate < 30) {
      errors['heartRate'] = 'Heart rate seems too low';
    } else if (metrics.heartRate > 220) {
      errors['heartRate'] = 'Heart rate seems too high';
    }

    return errors;
  }
}

/// Utility class for health metrics data and default values
class HealthMetricsData {
  /// Get default health metrics for display
  static List<HealthMetric> getDefaultMetrics() {
    return [
      const HealthMetric(
        id: 'steps',
        name: 'Steps',
        value: '8,432',
        icon: Icons.directions_walk,
        color: Color(0xFF4CAF50),
        unit: 'steps',
        progress:
            0.84, // This should ideally be dynamic too, but keeping as placeholder for default
        subtitle: 'Goal: $STEP_GOAL',
        trend: '+12%',
        trendPositive: true,
        detailPage: '/health/steps',
      ),
      const HealthMetric(
        id: 'heart_rate',
        name: 'Heart Rate',
        value: '72',
        icon: Icons.favorite,
        color: Color(0xFFE91E63),
        unit: 'bpm',
        subtitle: 'Resting',
        trend: '-3%',
        trendPositive: true,
        detailPage: '/health/heart_rate',
      ),
      const HealthMetric(
        id: 'sleep',
        name: 'Sleep',
        value: '7.5',
        icon: Icons.bedtime,
        color: Color(0xFF673AB7),
        unit: 'hours',
        progress: 0.94,
        subtitle: 'Goal: $SLEEP_GOAL hours',
        trend: '+0.5h',
        trendPositive: true,
        detailPage: '/health/sleep',
      ),
      const HealthMetric(
        id: 'water',
        name: 'Water',
        value: '6',
        icon: Icons.water_drop,
        color: Color(0xFF2196F3),
        unit: 'glasses',
        progress: 0.75, // Placeholder
        subtitle: 'Goal: $WATER_GOAL ml',
        trend: '0%',
        trendPositive: null,
      ),
      const HealthMetric(
        id: 'exercise',
        name: 'Exercise',
        value: '45',
        icon: Icons.fitness_center,
        color: Color(0xFFFF5722),
        unit: 'min',
        progress: 0.75,
        subtitle: 'Goal: $EXERCISE_GOAL min',
        trend: '+15min',
        trendPositive: true,
        detailPage: '/health/steps',
      ),
      const HealthMetric(
        id: 'food',
        name: 'Food',
        value: '0',
        icon: Icons.fastfood,
        color: Color(0xFF9C27B0),
        unit: 'kg',
        subtitle: 'Health first',
        trend: '0kg',
        trendPositive: null,
        detailPage: '/health/food/dashboard',
      ),
      const HealthMetric(
        id: 'focus',
        name: 'Focus',
        value: '0',
        icon: Icons.timer,
        color: Color(0xFF3F51B5),
        unit: 'min',
        progress: 0.0,
        subtitle: 'Study Time',
        trend: 'New',
        trendPositive: true,
        detailPage: '/health/focus',
      ),
    ];
  }

  static Future<Map<String, HealthMetric>> getMetricsByDay(
    DateTime day,
    BuildContext context,
  ) async {
    // 1. Get the DAOs from the context
    final healthMealDAO = context.read<HealthMealDAO>();
    final healthMetricsDAO = context.read<HealthMetricsDAO>();

    // 2. Fetch data from the database
    final metricsLocal = await healthMetricsDAO.getMetricsForDate(1, day);
    final calories = await healthMealDAO.getCaloriesByDate(day);

    // 3. Fetch yesterday's data for trend comparison
    final yesterday = day.subtract(const Duration(days: 1));
    final yesterdayMetrics = await healthMetricsDAO.getMetricsForDate(
      1,
      yesterday,
    );
    final yesterdayCalories = await healthMealDAO.getCaloriesByDate(yesterday);

    // 4. Fetch live steps from HealthService (Pedometer)
    int currentSteps = metricsLocal?.steps ?? 0;

    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    if (isToday) {
      try {
        // Sync Steps
        final liveSteps = await HealthService.fetchStepCount();
        if (liveSteps > currentSteps) {
          currentSteps = liveSteps;

          // Sync back to DB
          if (metricsLocal != null) {
            await healthMetricsDAO.insertOrUpdateMetrics(
              metricsLocal.toCompanion(true).copyWith(steps: Value(liveSteps)),
            );
          } else {
            await healthMetricsDAO.insertOrUpdateMetrics(
              HealthMetricsTableCompanion.insert(
                personID: 1,
                date: day,
                steps: Value(liveSteps),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }

        // Sync Sleep
        final liveSleep = await HealthService.fetchSleepData();
        if (liveSleep > (metricsLocal?.sleepHours ?? 0.0)) {
          // Sync back to DB
          if (metricsLocal != null) {
            await healthMetricsDAO.insertOrUpdateMetrics(
              metricsLocal
                  .toCompanion(true)
                  .copyWith(sleepHours: Value(liveSleep)),
            );
          } else {
            await healthMetricsDAO.insertOrUpdateMetrics(
              HealthMetricsTableCompanion.insert(
                personID: 1,
                date: day,
                sleepHours: Value(liveSleep),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }

        // Sync Heart Rate
        final liveHeartRate = await HealthService.fetchLatestHeartRate();
        if (liveHeartRate > 0) {
          // Sync back to DB
          if (metricsLocal != null) {
            await healthMetricsDAO.insertOrUpdateMetrics(
              metricsLocal
                  .toCompanion(true)
                  .copyWith(heartRate: Value(liveHeartRate)),
            );
          } else {
            await healthMetricsDAO.insertOrUpdateMetrics(
              HealthMetricsTableCompanion.insert(
                personID: 1,
                date: day,
                heartRate: Value(liveHeartRate),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Error syncing live health data: $e");
      }
    }

    // 5. Helper for trend calculation
    String trendStr(num today, num yesterday, String unit) {
      final diff = today - yesterday;
      if (diff == 0) return '0$unit';
      final sign = diff > 0 ? '+' : '';
      if (unit == '%') {
        if (yesterday == 0) return today > 0 ? '+100%' : '0%';
        final pct = ((diff / yesterday) * 100).round();
        return '$sign$pct%';
      }
      return '$sign${diff is double ? diff.toStringAsFixed(1) : diff}$unit';
    }

    bool? trendPositive(
      num today,
      num yesterday, {
      bool higherIsBetter = true,
    }) {
      if (today == yesterday) return null;
      return higherIsBetter ? today > yesterday : today < yesterday;
    }

    // 6. Extract values
    final waterMl = metricsLocal?.waterGlasses ?? 0;
    final exerciseMin = metricsLocal?.exerciseMinutes ?? 0;
    final focusMin = metricsLocal?.focusMinutes ?? 0;
    final sleepHrs = metricsLocal?.sleepHours ?? 0.0;
    final heartRate = metricsLocal?.heartRate ?? 0;

    final yWater = yesterdayMetrics?.waterGlasses ?? 0;
    final yExercise = yesterdayMetrics?.exerciseMinutes ?? 0;
    final ySleep = yesterdayMetrics?.sleepHours ?? 0.0;
    final ySteps = yesterdayMetrics?.steps ?? 0;
    final yFocus = yesterdayMetrics?.focusMinutes ?? 0;

    // Goals
    const stepGoal = STEP_GOAL;
    const waterGoal = WATER_GOAL; // ml
    const exerciseGoal = EXERCISE_GOAL; // min
    const sleepGoal = SLEEP_GOAL; // hours

    // 7. Build metric map
    return {
      'food': HealthMetric(
        id: 'food',
        name: 'Food',
        value: calories.round().toString(),
        icon: Icons.fastfood,
        color: const Color.fromARGB(255, 95, 202, 19),
        unit: 'kcal',
        subtitle: 'Today\'s intake',
        trend: trendStr(calories, yesterdayCalories, '%'),
        trendPositive: null,
        detailPage: '/health/food/dashboard',
      ),
      'steps': HealthMetric(
        id: 'steps',
        name: 'Steps',
        value: currentSteps.toString(),
        icon: Icons.run_circle,
        color: const Color(0xFF9C27B0),
        unit: 'steps',
        progress: (currentSteps / stepGoal).clamp(0.0, 1.0),
        subtitle: 'Goal: $stepGoal',
        trend: trendStr(currentSteps, ySteps, '%'),
        trendPositive: trendPositive(currentSteps, ySteps),
        detailPage: '/health/steps',
      ),
      'water': HealthMetric(
        id: 'water',
        name: 'Water',
        value: waterMl.toString(),
        icon: Icons.water_drop,
        color: const Color(0xFF2196F3),
        unit: 'ml',
        progress: (waterMl / waterGoal).clamp(0.0, 1.0),
        subtitle: 'Goal: $waterGoal ml',
        trend: trendStr(waterMl, yWater, '%'),
        trendPositive: trendPositive(waterMl, yWater),
        detailPage: '/health/water',
      ),
      'exercise': HealthMetric(
        id: 'exercise',
        name: 'Exercise',
        value: exerciseMin.toString(),
        icon: Icons.fitness_center,
        color: const Color(0xFFFF5722),
        unit: 'min',
        progress: (exerciseMin / exerciseGoal).clamp(0.0, 1.0),
        subtitle: 'Goal: $exerciseGoal min',
        trend: trendStr(exerciseMin, yExercise, ' min'),
        trendPositive: trendPositive(exerciseMin, yExercise),
        detailPage: '/health/exercise',
      ),
      'heart_rate': HealthMetric(
        id: 'heart_rate',
        name: 'Heart Rate',
        value: heartRate > 0 ? heartRate.toString() : '--',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFE91E63),
        unit: 'bpm',
        subtitle: heartRate < 60
            ? 'Resting'
            : heartRate < 100
            ? 'Normal'
            : heartRate < 140
            ? 'Elevated'
            : 'High',
        trend: null,
        trendPositive: null,
        detailPage: '/health/heart_rate',
      ),
      'sleep': HealthMetric(
        id: 'sleep',
        name: 'Sleep',
        value: sleepHrs > 0 ? sleepHrs.toStringAsFixed(1) : '--',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF673AB7),
        unit: 'hours',
        progress: sleepHrs > 0 ? (sleepHrs / sleepGoal).clamp(0.0, 1.0) : null,
        subtitle: 'Goal: ${sleepGoal.toStringAsFixed(0)} hours',
        trend: sleepHrs > 0 ? trendStr(sleepHrs, ySleep, 'h') : null,
        trendPositive: sleepHrs > 0 ? trendPositive(sleepHrs, ySleep) : null,
        detailPage: '/health/sleep',
      ),
      'focus': HealthMetric(
        id: 'focus',
        name: 'Focus',
        value: focusMin.toString(),
        icon: Icons.timer_outlined,
        color: const Color(0xFF3F51B5),
        unit: 'min',
        progress: (focusMin / 120).clamp(
          0.0,
          1.0,
        ), // Placeholder goal of 2 hours
        subtitle: 'Study Time',
        trend: trendStr(focusMin, yFocus, 'min'),
        trendPositive: trendPositive(focusMin, yFocus),
        detailPage: '/health/focus',
      ),
    };
  }

  /// Get daily summary statistics
  static Map<String, int> getDailySummary() {
    final metrics = getDefaultMetrics();
    int completed = 0;
    int total = 0;

    for (var metric in metrics) {
      if (metric.progress != null) {
        total++;
        if (metric.progress! >= 1.0) {
          completed++;
        }
      }
    }

    return {'completed': completed, 'total': total};
  }
}
