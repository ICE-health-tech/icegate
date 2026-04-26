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
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.WEIGHT,
      HealthDataType.WORKOUT,
    ];
    final permissions = [
      HealthDataAccess.READ, // STEPS
      HealthDataAccess.READ, // SLEEP_ASLEEP
      HealthDataAccess.READ, // SLEEP_IN_BED
      HealthDataAccess.READ, // SLEEP_AWAKE
      HealthDataAccess.READ, // SLEEP_DEEP
      HealthDataAccess.READ, // SLEEP_REM
      HealthDataAccess.READ, // SLEEP_LIGHT
      HealthDataAccess.READ, // HEART_RATE
      HealthDataAccess.READ, // BLOOD_OXYGEN
      HealthDataAccess.READ_WRITE, // ACTIVE_ENERGY_BURNED (Allow writing burned calories)
      HealthDataAccess.READ, // WEIGHT
      HealthDataAccess.READ_WRITE, // WORKOUT (Allow writing exercise logs)
    ];

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

  /// Fetches the latest oxygen saturation (SpO2) reading.
  static Future<double> fetchLatestOxygenSaturation() async {
    final authorized = await requestPermissions();
    if (!authorized) return 0.0;

    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));

    try {
      final types = [HealthDataType.BLOOD_OXYGEN];
      final healthData = await health.getHealthDataFromTypes(
        startTime: oneDayAgo,
        endTime: now,
        types: types,
      );

      if (healthData.isEmpty) return 0.0;

      // Sort by date to get the LATEST
      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latestValue = healthData.first.value;

      if (latestValue is NumericHealthValue) {
        // SpO2 is often represented as a fraction (e.g., 0.98) or percentage (98)
        double value = latestValue.numericValue.toDouble();
        // If value is between 0 and 1, it's a fraction (0.98 -> 98%)
        if (value <= 1.0 && value > 0) value *= 100.0;
        debugPrint("HealthService: [RAW] Latest SpO2: ${latestValue.numericValue}, Normalized: $value%");
        return value;
      }
      return 0.0;
    } catch (e) {
      debugPrint("HealthService: Error fetching oxygen saturation: $e");
      return 0.0;
    }
  }

  /// Fetches sleep data for the last 24 hours and returns total hours.
  static Future<double> fetchSleepData() async {
    final authorized = await requestPermissions();
    if (!authorized) return 0.0;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    try {
      final types = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
      ];
      final healthData = await health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: types,
      );

      double totalMinutes = 0;
      for (var data in healthData) {
        // Only count actual sleep time, avoid double counting if multiple types overlap
        // but for now simple sum is common for duration overview
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

  /// Fetches individual sleep sessions for a specific day
  static Future<List<Map<String, dynamic>>> fetchSleepSessions(DateTime day) async {
    final authorized = await requestPermissions();
    if (!authorized) return [];

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    try {
      final types = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
      ];
      final healthData = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      return healthData.map((data) => {
        'startTime': data.dateFrom,
        'endTime': data.dateTo,
        'type': data.typeString,
        'sourceName': data.sourceName,
        'sourceId': data.sourceId,
      }).toList();
    } catch (e) {
      debugPrint("HealthService: Error fetching sleep sessions: $e");
      return [];
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
  /// Fetches heart rate samples for a specific day.
  /// Returns a map of timestamp to bpm.
  static Future<List<HealthDataPoint>> fetchHeartRateSamplesForDay(
    DateTime day,
  ) async {
    final authorized = await requestPermissions();
    if (!authorized) return [];

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
        types: [HealthDataType.HEART_RATE],
      );

      debugPrint(
        "HealthService: Fetched ${healthData.length} heart rate samples for $start",
      );
      return healthData;
    } catch (e) {
      debugPrint("HealthService: Error fetching heart rate samples for $day: $e");
      return [];
    }
  }

  /// Fetches oxygen saturation samples for a specific day.
  static Future<List<HealthDataPoint>> fetchOxygenSaturationSamplesForDay(
    DateTime day,
  ) async {
    final authorized = await requestPermissions();
    if (!authorized) return [];

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
        types: [HealthDataType.BLOOD_OXYGEN],
      );

      debugPrint(
        "HealthService: Fetched ${healthData.length} oxygen samples for $start",
      );
      for (var p in healthData) {
        debugPrint("HealthService: [RAW SAMPLE] ${p.dateFrom}: ${p.value}");
      }
      return healthData;
    } catch (e) {
      debugPrint("HealthService: Error fetching oxygen samples for $day: $e");
      return [];
    }
  }

  /// Writes workout data to Apple Health / Google Fit.
  static Future<bool> writeWorkoutData({
    required HealthWorkoutActivityType activityType,
    required DateTime start,
    required DateTime end,
    int? totalEnergyBurned, // in kcal
    int? totalDistance, // in meters
  }) async {
    final authorized = await requestPermissions();
    if (!authorized) {
      debugPrint("HealthService: Cannot write workout, not authorized.");
      return false;
    }

    try {
      debugPrint("HealthService: Writing workout: $activityType from $start to $end");
      final success = await health.writeWorkoutData(
        activityType: activityType,
        start: start,
        end: end,
        totalEnergyBurned: totalEnergyBurned,
        totalDistance: totalDistance,
      );
      debugPrint("HealthService: Workout write status: $success");
      return success;
    } catch (e) {
      debugPrint("HealthService: Error writing workout: $e");
      return false;
    }
  }

  /// Helper to map application exercise strings to HealthWorkoutActivityType.
  static HealthWorkoutActivityType mapStringToActivityType(String? type) {
    if (type == null) return HealthWorkoutActivityType.OTHER;

    final lower = type.toLowerCase();
    if (lower.contains('run')) return HealthWorkoutActivityType.RUNNING;
    if (lower.contains('walk')) return HealthWorkoutActivityType.WALKING;
    if (lower.contains('cycle') || lower.contains('bike')) {
      return HealthWorkoutActivityType.BIKING;
    }
    if (lower.contains('swim')) return HealthWorkoutActivityType.SWIMMING;
    if (lower.contains('yoga')) return HealthWorkoutActivityType.YOGA;
    if (lower.contains('gym') ||
        lower.contains('strength') ||
        lower.contains('weight')) {
      return HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING;
    }
    if (lower.contains('hiit')) return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
    if (lower.contains('meditation') || lower.contains('breath')) {
      return HealthWorkoutActivityType.MIND_AND_BODY;
    }

    return HealthWorkoutActivityType.OTHER;
  }
}
