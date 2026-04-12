import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';
import 'package:ice_gate/ui_layer/health_page/models/HealthMetric.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:provider/provider.dart' show ReadContext;
import 'package:ice_gate/l10n/app_localizations.dart';

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
  static List<HealthMetric> getDefaultMetrics(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      HealthMetric(
        id: 'steps',
        name: 'steps',
        value: '8,432',
        icon: Icons.directions_walk,
        color: const Color(0xFF4CAF50),
        unit: 'steps',
        progress: 0.84,
        subtitle: l10n.health_subtitle_goal_steps(STEP_GOAL),
        trend: '+12%',
        trendPositive: true,
        detailPage: '/health/steps',
      ),
      HealthMetric(
        id: 'heart_rate',
        name: 'heart_rate',
        value: '72',
        icon: Icons.favorite,
        color: const Color(0xFFE91E63),
        unit: 'bpm',
        subtitle: l10n.health_heart_resting,
        trend: '-3%',
        trendPositive: true,
        detailPage: '/health/heart_rate',
        isFuture: true,
        availabilityMessage: 'Apple Watch Required',
      ),
      HealthMetric(
        id: 'sleep',
        name: 'sleep',
        value: '7.5',
        icon: Icons.bedtime,
        color: const Color(0xFF673AB7),
        unit: 'hours',
        progress: 0.94,
        subtitle: l10n.health_subtitle_goal_hours(
          SLEEP_GOAL.toStringAsFixed(0),
        ),
        trend: '+0.5h',
        trendPositive: true,
        detailPage: '/health/sleep',
        isFuture: true,
        availabilityMessage: 'Coming Soon',
      ),
      HealthMetric(
        id: 'water',
        name: 'water',
        value: '6',
        icon: Icons.water_drop,
        color: const Color(0xFF2196F3),
        unit: 'glasses',
        progress: 0.75,
        subtitle: l10n.health_subtitle_goal_ml(WATER_GOAL),
        trend: '0%',
        trendPositive: null,
      ),
      HealthMetric(
        id: 'exercise',
        name: 'exercise',
        value: '45',
        icon: Icons.fitness_center,
        color: const Color(0xFFFF5722),
        unit: 'min',
        progress: 0.75,
        subtitle: l10n.health_subtitle_goal_min(EXERCISE_GOAL),
        trend: '+15min',
        trendPositive: true,
        detailPage: '/health/steps',
      ),
      HealthMetric(
        id: 'food',
        name: 'food',
        value: '0',
        icon: Icons.fastfood,
        color: const Color(0xFF9C27B0),
        unit: 'kg',
        subtitle: l10n.health_subtitle_health_first,
        trend: '0kg',
        trendPositive: null,
        detailPage: '/health/food/dashboard',
      ),
      HealthMetric(
        id: 'focus',
        name: 'focus',
        value: '0',
        icon: Icons.timer,
        color: const Color(0xFF3F51B5),
        unit: 'min',
        progress: 0.0,
        subtitle: l10n.health_subtitle_study_time,
        trend: 'New',
        trendPositive: true,
        detailPage: '/health/focus',
      ),
    ];
  }

  static Future<Map<String, HealthMetric>> getMetricsByDay(
    String personId,
    DateTime day,
    BuildContext context,
  ) async {
    // 1. Get the DAOs from the context
    final healthMealDAO = context.read<HealthMealDAO>();
    final healthMetricsDAO = context.read<HealthMetricsDAO>();

    // 2. Fetch data from the database
    final metricsLocal = await healthMetricsDAO.getMetricsForDate(
      personId,
      day,
    );
    double calories = 0;
    print("Day that get fetch calories for: $day");
    try {
      calories = await healthMealDAO.getCaloriesByDate(day);
    } catch (e) {
      debugPrint("Error fetching calories for day: $e");
    }

    // 3. Fetch yesterday's data for trend comparison
    final yesterday = day.subtract(const Duration(days: 1));
    final yesterdayMetrics = await healthMetricsDAO.getMetricsForDate(
      personId,
      yesterday,
    );
    double yesterdayCalories = 0;
    try {
      yesterdayCalories = await healthMealDAO.getCaloriesByDate(yesterday);
    } catch (e) {
      debugPrint("Error fetching yesterday calories: $e");
    }

    // 4. Extract current steps from DB result
    int currentSteps = metricsLocal?.steps ?? 0;

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

    // AppLocalizations must be available — HealthPage._loadHealthData() guards this.
    // If somehow still null (edge case), return empty map gracefully.
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return {};

    // 7. Build metric map
    return {
      'food': HealthMetric(
        id: 'food',
        name: 'food',
        value: calories.round().toString(),
        icon: Icons.fastfood,
        color: const Color.fromARGB(255, 95, 202, 19),
        unit: l10n.health_kcal_label,
        subtitle: l10n.health_subtitle_todays_intake,
        trend: trendStr(calories, yesterdayCalories, '%'),
        trendPositive: null,
        detailPage: '/health/food/consume',
      ),
      'steps': HealthMetric(
        id: 'steps',
        name: 'steps',
        value: currentSteps.toString(),
        icon: Icons.run_circle,
        color: const Color(0xFF9C27B0),
        unit: l10n.health_steps_label,
        progress: (currentSteps / stepGoal).clamp(0.0, 1.0),
        subtitle: l10n.health_subtitle_goal_steps(stepGoal),
        trend: trendStr(currentSteps, ySteps, '%'),
        trendPositive: trendPositive(currentSteps, ySteps),
        detailPage: '/health/steps',
      ),
      'weight': HealthMetric(
        id: 'weight',
        name: 'weight',
        value: (metricsLocal?.weightKg ?? 0.0).toStringAsFixed(1),
        icon: Icons.monitor_weight_rounded,
        color: const Color(0xFF00BCD4),
        unit: l10n.health_kg_label,
        subtitle: l10n.health_subtitle_current_weight,
        trend: null,
        trendPositive: null,
        detailPage: '/health/weight',
      ),
      'water': HealthMetric(
        id: 'water',
        name: 'water',
        value: waterMl.toString(),
        icon: Icons.water_drop,
        color: const Color(0xFF2196F3),
        unit: l10n.health_ml_label,
        progress: (waterMl / waterGoal).clamp(0.0, 1.0),
        subtitle: l10n.health_subtitle_goal_ml(waterGoal),
        trend: trendStr(waterMl, yWater, '%'),
        trendPositive: trendPositive(waterMl, yWater),
        detailPage: '/health/water',
      ),
      'exercise': HealthMetric(
        id: 'exercise',
        name: 'exercise',
        value: exerciseMin.toString(),
        icon: Icons.fitness_center,
        color: const Color(0xFFFF5722),
        unit: l10n.health_min_label,
        progress: (exerciseMin / exerciseGoal).clamp(0.0, 1.0),
        subtitle: l10n.health_subtitle_goal_min(exerciseGoal),
        trend: trendStr(exerciseMin, yExercise, ' ${l10n.health_min_label}'),
        trendPositive: trendPositive(exerciseMin, yExercise),
        detailPage: '/health/exercise',
      ),
      'heart_rate': HealthMetric(
        id: 'heart_rate',
        name: 'heart_rate',
        value: heartRate > 0 ? heartRate.toString() : '--',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFE91E63),
        unit: 'bpm',
        subtitle: heartRate < 60
            ? l10n.health_heart_resting
            : heartRate < 100
            ? l10n.health_heart_normal
            : heartRate < 140
            ? l10n.health_heart_elevated
            : l10n.health_heart_high,
        trend: null,
        trendPositive: null,
        detailPage: '/health/heart_rate',
        isFuture: true,
        availabilityMessage: 'Apple Watch Required',
      ),
      'sleep': HealthMetric(
        id: 'sleep',
        name: 'sleep',
        value: sleepHrs > 0 ? sleepHrs.toStringAsFixed(1) : '--',
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF673AB7),
        unit: l10n.health_hours_label,
        progress: sleepHrs > 0 ? (sleepHrs / sleepGoal).clamp(0.0, 1.0) : null,
        subtitle: l10n.health_subtitle_goal_hours(sleepGoal.toStringAsFixed(0)),
        trend: sleepHrs > 0 ? trendStr(sleepHrs, ySleep, l10n.health_hours_label[0]) : null,
        trendPositive: sleepHrs > 0 ? trendPositive(sleepHrs, ySleep) : null,
        detailPage: '/health/sleep',
        isFuture: true,
        availabilityMessage: 'Coming Soon',
      ),
      'focus': HealthMetric(
        id: 'focus',
        name: 'focus',
        value: focusMin.toString(),
        icon: Icons.timer_outlined,
        color: const Color(0xFF3F51B5),
        unit: l10n.health_min_label,
        progress: (focusMin / 120).clamp(
          0.0,
          1.0,
        ), // Placeholder goal of 2 hours
        subtitle: l10n.health_subtitle_study_time,
        trend: trendStr(focusMin, yFocus, l10n.health_min_label),
        trendPositive: trendPositive(focusMin, yFocus),
        detailPage: '/health/focus',
      ),
    };
  }

  /// Get daily summary statistics
  static Map<String, int> getDailySummary() {
    return {'completed': 0, 'total': 0};
  }
}
