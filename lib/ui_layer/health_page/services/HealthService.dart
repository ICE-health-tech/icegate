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
    ];
    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
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
      final steps = await health.getTotalStepsInInterval(midnight, now);
      debugPrint("HealthService: Fetched steps from HealthKit: $steps");
      return steps ?? 0;
    } catch (e) {
      debugPrint("HealthService: Error fetching steps: $e");
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
}
