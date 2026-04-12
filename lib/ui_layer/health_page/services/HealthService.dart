import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final Health health = Health();
  static bool _isAuthorized = false;

  /// Requests permission to access health data.
  static Future<bool> requestPermissions() async {
    // Platform check: HealthKit/Google Fit only supported on mobile
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      debugPrint(
        "HealthService: Skipping authorization on ${defaultTargetPlatform.name}",
      );
      return false;
    }

    if (_isAuthorized) return true;

    // Check motion permission first (needed for some data types on iOS)
    try {
      debugPrint("HealthService: Requesting motion sensors permission...");
      await Permission.sensors.request();
    } catch (e) {
      debugPrint(
        "HealthService: Motion sensors permission failed (possibly missing plugin): $e",
      );
    }

    final types = [
      HealthDataType.STEPS,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.WEIGHT,
    ];
    final permissions = List.filled(types.length, HealthDataAccess.READ);

    try {
      debugPrint("HealthService: Requesting health authorization...");
      _isAuthorized = await health.requestAuthorization(
        types,
        permissions: permissions,
      );
      debugPrint("HealthService: Authorization status: $_isAuthorized");
      return _isAuthorized;
    } catch (e) {
      debugPrint("HealthService: Authorization error: $e");
      return false;
    }
  }

  /// Fetches today's step count from Apple Health/Google Fit.
  static Future<int> fetchStepCount() async {
    final authorized = await requestPermissions();
    if (!authorized) return 0;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      debugPrint("HealthService: [iPhone Sync] Requesting total steps for interval: $midnight to $now");
      final steps = await health.getTotalStepsInInterval(midnight, now);
      debugPrint(
        "HealthService: [iPhone Sync] Result from getTotalStepsInInterval: $steps",
      );

      // Fallback: Get raw points if getTotalStepsInInterval returns 0 or null
      if (steps == null || steps == 0) {
        debugPrint("HealthService: [iPhone Sync] Steps is null/0. Attempting raw points fallback...");
        final rawSteps = await health.getHealthDataFromTypes(
          startTime: midnight,
          endTime: now,
          types: [HealthDataType.STEPS],
        );
        debugPrint(
          "HealthService: [iPhone Sync] Raw Points Check: ${rawSteps.length} points found.",
        );

        int sumRaw = 0;
        for (var p in rawSteps) {
          final v = p.value;
          if (v is NumericHealthValue) {
            sumRaw += v.numericValue.toInt();
          }
        }
        if (sumRaw > 0) {
          debugPrint(
            "HealthService: [iPhone Sync] Fallback Success: Summed $sumRaw steps from raw points.",
          );
          return sumRaw;
        } else {
          debugPrint("HealthService: [iPhone Sync] Fallback failed. No raw step data found for today.");
        }
      }

      return steps ?? 0;
    } catch (e, stack) {
      debugPrint("HealthService: Error fetching steps: $e\n$stack");
      return 0;
    }
  }

  /// Fetches the latest heart rate reading from Apple Health/Google Fit.
  static Future<int> fetchLatestHeartRate() async {
    final authorized = await requestPermissions();
    if (!authorized) return 0;

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    try {
      final types = [HealthDataType.HEART_RATE];
      final healthData = await health.getHealthDataFromTypes(
        startTime: oneHourAgo,
        endTime: now,
        types: types,
      );

      if (healthData.isEmpty) return 0;

      // Sort by date to get the LATEST
      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latestValue = healthData.first.value;

      if (latestValue is NumericHealthValue) {
        final bpm = latestValue.numericValue.round();
        debugPrint("HealthService: Fetched latest heart rate: $bpm bpm");
        return bpm;
      }
      return 0;
    } catch (e) {
      debugPrint("HealthService: Error fetching heart rate: $e");
      return 0;
    }
  }

  /// Fetches sleep data for the last 24 hours and returns total hours.
  static Future<double> fetchSleepData() async {
    final authorized = await requestPermissions();
    if (!authorized) return 0.0;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    try {
      final types = [HealthDataType.SLEEP_ASLEEP];
      final healthData = await health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: types,
      );

      double totalMinutes = 0;
      for (var data in healthData) {
        // For sleep, the value is often the numeric representation of the category,
        // but we want the duration. Health package provides 'value' which for sleep
        // data points is usually the category. We need to calculate duration
        // between data.dateFrom and data.dateTo.
        final startTime = data.dateFrom;
        final endTime = data.dateTo;
        final duration = endTime.difference(startTime).inMinutes;
        totalMinutes += duration;
      }

      final totalHours = totalMinutes / 60.0;
      debugPrint("HealthService: Fetched sleep duration: $totalHours hours");
      return totalHours;
    } catch (e) {
      debugPrint("HealthService: Error fetching sleep data: $e");
      return 0.0;
    }
  }

  /// Fetches step count for a specific day.
  static Future<int> fetchStepsForDay(DateTime day) async {
    final authorized = await requestPermissions();
    if (!authorized) return 0;

    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    final start = DateTime(day.year, day.month, day.day);
    final end = isToday ? now : start.add(const Duration(days: 1));

    try {
      final steps = await health.getTotalStepsInInterval(start, end);
      debugPrint(
        "HealthService: fetchStepsForDay for $start to $end returned $steps",
      );
      if (steps == null || steps == 0) {
        final rawSteps = await health.getHealthDataFromTypes(
          startTime: start,
          endTime: end,
          types: [HealthDataType.STEPS],
        );
        debugPrint(
          "HealthService: Raw points count for same interval: ${rawSteps.length}",
        );
        int sumRaw = 0;
        for (var p in rawSteps) {
          final v = p.value;
          if (v is NumericHealthValue) sumRaw += v.numericValue.toInt();
        }
        debugPrint("HealthService: Sum of raw points: $sumRaw");
        return sumRaw;
      }
      return steps;
    } catch (e) {
      debugPrint("HealthService: Error fetching steps for $day: $e");
      return 0;
    }
  }

  /// Fetches step count for each hour of a specific day.
  /// Returns a map where key is hour (0-23) and value is step count.
  static Future<Map<int, int>> fetchHourlyStepsForDay(DateTime day) async {
    final authorized = await requestPermissions();
    if (!authorized) return {};

    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    final start = DateTime(day.year, day.month, day.day);
    final end = isToday ? now : start.add(const Duration(days: 1));

    try {
      final healthData = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.STEPS],
      );

      final Map<int, int> hourlySteps = {
        for (var i = 0; i < 24; i++) i: 0
      };

      for (var data in healthData) {
        final value = data.value;
        if (value is NumericHealthValue) {
          final hour = data.dateFrom.hour;
          hourlySteps[hour] = (hourlySteps[hour] ?? 0) + value.numericValue.toInt();
        }
      }

      debugPrint("HealthService: Fetched hourly steps for $start: $hourlySteps");
      return hourlySteps;
    } catch (e) {
      debugPrint("HealthService: Error fetching hourly steps for $day: $e");
      return {};
    }
  }

  /// Fetches calories burned for a specific day.
  static Future<double> fetchCaloriesForDay(DateTime day) async {
    final authorized = await requestPermissions();
    if (!authorized) return 0.0;

    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    final start = DateTime(day.year, day.month, day.day);
    final end = isToday ? now : start.add(const Duration(days: 1));

    try {
      final healthData = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      double totalCalories = 0.0;
      for (var data in healthData) {
        final value = data.value;
        if (value is NumericHealthValue) totalCalories += value.numericValue;
      }
      return totalCalories;
    } catch (e) {
      debugPrint("HealthService: Error fetching calories for $day: $e");
      return 0.0;
    }
  }


  /// Fetches the latest weight reading.
  static Future<double> fetchLatestWeight() async {
    final authorized = await requestPermissions();
    if (!authorized) return 0.0;

    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    try {
      final types = [HealthDataType.WEIGHT];
      final healthData = await health.getHealthDataFromTypes(
        startTime: oneMonthAgo,
        endTime: now,
        types: types,
      );

      if (healthData.isEmpty) return 0.0;

      // Sort by date to get the LATEST
      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latestValue = healthData.first.value;

      if (latestValue is NumericHealthValue) {
        return latestValue.numericValue.toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint("HealthService: Error fetching latest weight: $e");
      return 0.0;
    }
  }

  /// Fetches weight for a specific day.
  static Future<double> fetchWeightForDay(DateTime day) async {
    final authorized = await requestPermissions();
    if (!authorized) return 0.0;

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    try {
      final healthData = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.WEIGHT],
      );

      if (healthData.isEmpty) return 0.0;

      // Usually weight is a single reading per day, take the latest for that day
      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = healthData.first.value;

      if (value is NumericHealthValue) return value.numericValue.toDouble();
      return 0.0;
    } catch (e) {
      debugPrint("HealthService: Error fetching weight for $day: $e");
      return 0.0;
    }
  }
}
