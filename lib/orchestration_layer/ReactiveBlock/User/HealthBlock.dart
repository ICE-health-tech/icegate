import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'
    show
        HealthLogsDAO,
        HealthMealDAO,
        HealthMetricsDAO,
        HealthMetricsTableCompanion;
import 'package:signals/signals.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

class HealthBlock {
  String personId;
  final HealthMetricsDAO _healthDao;

  final todaySteps = signal<int>(0);
  final historicalSteps = signal<int>(0);
  final todaySleep = signal<double>(0.0);
  final todayHeartRate = signal<int>(0);
  final todayCaloriesBurned = signal<int>(0);
  final dailyStepGoal = signal<int>(10000);
  final dailyKcalGoal = signal<int>(2500);
  final dailyWaterGoal = signal<int>(2000);
  final dailyFocusGoal = signal<int>(60);
  final dailyExerciseGoal = signal<int>(30);
  final dailySleepGoal = signal<double>(8.0);
  final todayWater = signal<int>(0);
  final todayExerciseMinutes = signal<int>(0);
  final todayFocusMinutes = signal<int>(0);
  final todayCaloriesConsumed = signal<int>(0);
  final todayWeight = signal<double>(0.0);
  final hasInitialSync = signal<bool>(false);

  late final totalSteps = computed(
    () => todaySteps.value + historicalSteps.value,
  );

  StreamSubscription? _metricsSubscription;

  HealthBlock({
    required String personId,
    required HealthMetricsDAO healthDao,
    required HealthLogsDAO healthLogsDao,
    required HealthMealDAO healthMealDao,
  }) : personId = personId,
       _healthDao = healthDao,
       _healthLogsDao = healthLogsDao;

  final HealthLogsDAO _healthLogsDao;
  StreamSubscription? _waterSubscription;

  String? _initializedPersonId;

  void init() {
    _loadGoals();
    if (personId.isEmpty) {
      debugPrint("HealthBlock: Skipping init, personId is empty.");
      return;
    }

    if (_initializedPersonId == personId) {
      debugPrint("HealthBlock: ℹ️ Already initialized for $personId");
      return;
    }

    debugPrint("HealthBlock: 🚀 Initializing for $personId");
    _initializedPersonId = personId;

    // Cleanup old subscriptions
    _metricsSubscription?.cancel();
    _waterSubscription?.cancel();
    hasInitialSync.value = false;

    // 0. Cleanup duplicates before starting watch to prevent sync conflicts
    _healthDao.cleanupDuplicates(personId).then((_) {
      if (_initializedPersonId != personId)
        return; // Guard against race condition

      // Watch all metrics to calculate historical steps (excluding today)
      _metricsSubscription = _healthDao.watchAllMetrics(personId).listen(
        (metrics) {
          final today = DateTime.now();
          final todayStr = "${today.year}-${today.month}-${today.day}";

          int totalHistorical = 0;
          int foundTodaySteps = 0;
          double foundTodaySleep = 0;
          int foundTodayHeartRate = 0;
          int foundTodayCaloriesBurned = 0;

          debugPrint(
            "HealthBlock: 📊 Received ${metrics.length} metrics from DB",
          );
          for (var m in metrics) {
            final dateStr = "${m.date.year}-${m.date.month}-${m.date.day}";
            final isTodayMatch = dateStr == todayStr;
            debugPrint(
              "HealthBlock:   - Date: ${m.date} (Str: $dateStr), Steps: ${m.steps}, isToday: $isTodayMatch",
            );

            if (isTodayMatch) {
              foundTodaySteps = m.steps ?? 0;
              foundTodaySleep = m.sleepHours ?? 0.0;
              foundTodayHeartRate = m.heartRate ?? 0;
              foundTodayCaloriesBurned = m.caloriesBurned ?? 0;
              todayWeight.value = m.weightKg ?? 0.0;
              todayExerciseMinutes.value = m.exerciseMinutes ?? 0;
              todayFocusMinutes.value = m.focusMinutes ?? 0;
            } else {
              totalHistorical += m.steps ?? 0;
            }
          }

          debugPrint(
            "HealthBlock: 🔄 Result: foundTodaySteps=$foundTodaySteps, totalHistorical=$totalHistorical",
          );
          historicalSteps.value = totalHistorical;
          // Only update todaySteps from DB if it's larger than current volatile state
          if (foundTodaySteps > todaySteps.value) {
            debugPrint(
              "HealthBlock: 📈 Updating todaySteps to $foundTodaySteps (was ${todaySteps.value})",
            );
            todaySteps.value = foundTodaySteps;
          } else if (foundTodaySteps < todaySteps.value) {
            debugPrint(
              "HealthBlock: 🛡️ Protected todaySteps: keeps ${todaySteps.value} (DB has $foundTodaySteps)",
            );
          }

          if (foundTodaySleep > todaySleep.value) {
            todaySleep.value = foundTodaySleep;
          }

          if (foundTodayHeartRate > todayHeartRate.value) {
            todayHeartRate.value = foundTodayHeartRate;
          }

          if (foundTodayCaloriesBurned > todayCaloriesBurned.value) {
            todayCaloriesBurned.value = foundTodayCaloriesBurned;
          }

          // Mark initial sync complete
          if (!hasInitialSync.value) {
            debugPrint("HealthBlock: ✅ Initial DB sync complete.");
            hasInitialSync.value = true;
          }
        },
        onError: (e) =>
            debugPrint("HealthBlock: Error watching health metrics: $e"),
      );
    });

    _waterSubscription = _healthLogsDao
        .watchDailyWaterLogs(personId, DateTime.now())
        .listen(
          (logs) {
            todayWater.value = logs.fold<int>(
              0,
              (sum, log) => sum + log.amount,
            );
            _saveWater(todayWater.value);
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching water logs: $e"),
        );

    // Watch goals and save to SharedPreferences
    effect(() => _saveGoal('dailyStepGoal', dailyStepGoal.value));
    effect(() => _saveGoal('dailyKcalGoal', dailyKcalGoal.value));
    effect(() => _saveGoal('dailyWaterGoal', dailyWaterGoal.value));
    effect(() => _saveGoal('dailyFocusGoal', dailyFocusGoal.value));
    effect(() => _saveGoal('dailyExerciseGoal', dailyExerciseGoal.value));
    effect(() => _saveGoal('dailySleepGoal', dailySleepGoal.value));
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dailyStepGoal.value = prefs.getInt('dailyStepGoal') ?? 10000;
      dailyKcalGoal.value = prefs.getInt('dailyKcalGoal') ?? 2500;
      dailyWaterGoal.value = prefs.getInt('dailyWaterGoal') ?? 2000;
      dailyFocusGoal.value = prefs.getInt('dailyFocusGoal') ?? 60;
      dailyExerciseGoal.value = prefs.getInt('dailyExerciseGoal') ?? 30;
      dailySleepGoal.value = prefs.getDouble('dailySleepGoal') ?? 8.0;
      debugPrint("HealthBlock: 🎯 Goals loaded from SharedPreferences");
    } catch (e) {
      debugPrint("HealthBlock: Error loading goals: $e");
    }
  }

  Future<void> _saveGoal(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
      debugPrint("HealthBlock: 💾 Saved $key = $value");
    } catch (e) {
      debugPrint("HealthBlock: Error saving goal $key: $e");
    }
  }

  void updateSteps(int steps) {
    debugPrint(
      "HealthBlock: updateSteps called with $steps steps (current: ${todaySteps.value})",
    );
    if (steps > todaySteps.value) {
      todaySteps.value = steps;
      _saveSteps(steps);
    }
  }

  void updateSleep(double hours) {
    debugPrint(
      "HealthBlock: updateSleep called with $hours hours (current: ${todaySleep.value})",
    );
    if (hours > todaySleep.value) {
      todaySleep.value = hours;
      _saveSleep(hours);
    }
  }

  void updateHeartRate(int bpm) {
    debugPrint(
      "HealthBlock: updateHeartRate called with $bpm bpm (current: ${todayHeartRate.value})",
    );
    if (bpm > 0) {
      todayHeartRate.value = bpm;
      _saveHeartRate(bpm);
    }
  }

  void updateWeight(double weight) {
    debugPrint(
      "HealthBlock: updateWeight called with $weight kg (current: ${todayWeight.value})",
    );
    if (weight > 0) {
      todayWeight.value = weight;
      _saveWeight(weight);
    }
  }

  void updateCalories(int calories) {
    debugPrint(
      "HealthBlock: updateCalories called with $calories kcal (current: ${todayCaloriesBurned.value})",
    );
    if (calories > todayCaloriesBurned.value) {
      todayCaloriesBurned.value = calories;
      _saveCalories(calories);
    }
  }

  Future<void> _saveCalories(int calories) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    debugPrint(
      "HealthBlock: Saving $calories calories to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        date: Value(normalizedToday),
        caloriesBurned: Value(calories),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _saveSteps(int steps) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    debugPrint("HealthBlock: Saving $steps steps to DB for $normalizedToday");
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        date: Value(normalizedToday),
        steps: Value(steps),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _saveSleep(double hours) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    debugPrint(
      "HealthBlock: Saving $hours sleep hours to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        date: Value(normalizedToday),
        sleepHours: Value(hours),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _saveWater(int ml) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    debugPrint("HealthBlock: Saving $ml ml water to DB for $normalizedToday");
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        date: Value(normalizedToday),
        waterGlasses: Value((ml / 250).round()), // Estimate glasses from ML
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _saveWeight(double kg) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    debugPrint("HealthBlock: Saving $kg kg weight to DB for $normalizedToday");
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        date: Value(normalizedToday),
        weightKg: Value(kg),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _saveHeartRate(int bpm) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    debugPrint(
      "HealthBlock: Saving $bpm heart rate to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        date: Value(normalizedToday),
        heartRate: Value(bpm),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void dispose() {
    _metricsSubscription?.cancel();
    _waterSubscription?.cancel();
    todaySteps.dispose();
    historicalSteps.dispose();
    todaySleep.dispose();
    todayHeartRate.dispose();
    // totalSteps is a computed signal, it is handled automatically
    todayWater.dispose();
  }
}
