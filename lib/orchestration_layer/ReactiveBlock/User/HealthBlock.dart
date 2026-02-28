import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart'
    show HealthMetricsDAO, HealthMetricsTableCompanion, HealthLogsDAO;
import 'package:signals/signals.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

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
  final todayWater = signal<int>(0);
  final todayExerciseMinutes = signal<int>(0);
  final todayFocusMinutes = signal<int>(0);

  late final totalSteps = computed(
    () => todaySteps.value + historicalSteps.value,
  );

  StreamSubscription? _metricsSubscription;

  HealthBlock({
    required String personId,
    required HealthMetricsDAO healthDao,
    required HealthLogsDAO healthLogsDao,
  }) : personId = personId,
       _healthDao = healthDao,
       _healthLogsDao = healthLogsDao;

  final HealthLogsDAO _healthLogsDao;
  StreamSubscription? _waterSubscription;

  void init() {
    if (personId.isEmpty) {
      debugPrint("HealthBlock: Skipping init, personId is empty.");
      return;
    }
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

        for (var m in metrics) {
          final dateStr = "${m.date.year}-${m.date.month}-${m.date.day}";
          if (dateStr == todayStr) {
            foundTodaySteps = m.steps ?? 0;
            foundTodaySleep = m.sleepHours ?? 0.0;
            foundTodayHeartRate = m.heartRate ?? 0;
            foundTodayCaloriesBurned = m.caloriesBurned ?? 0;
            todayExerciseMinutes.value = m.exerciseMinutes ?? 0;
            todayFocusMinutes.value = m.focusMinutes ?? 0;
          } else {
            totalHistorical += m.steps ?? 0;
          }
        }

        historicalSteps.value = totalHistorical;
        // Only update todaySteps from DB if it's larger than current volatile state
        if (foundTodaySteps > todaySteps.value) {
          todaySteps.value = foundTodaySteps;
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
      },
      onError: (e) =>
          debugPrint("HealthBlock: Error watching health metrics: $e"),
    );

    _waterSubscription = _healthLogsDao
        .watchDailyWaterLogs(personId, DateTime.now())
        .listen(
          (logs) {
            todayWater.value = logs.fold<int>(
              0,
              (sum, log) => sum + log.amount,
            );
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching water logs: $e"),
        );
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
        id: Value(IDGen.generateUuid()),
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
        id: Value(IDGen.generateUuid()),
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
        id: Value(IDGen.generateUuid()),
        personID: Value(personId),
        date: Value(normalizedToday),
        sleepHours: Value(hours),
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
        id: Value(IDGen.generateUuid()),
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
