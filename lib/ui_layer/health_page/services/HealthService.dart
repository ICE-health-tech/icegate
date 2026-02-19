import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final Health health = Health();
  static bool _isAuthorized = false;

  /// Requests permission to access health data.
  static Future<bool> requestPermissions() async {
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

    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];

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
}
