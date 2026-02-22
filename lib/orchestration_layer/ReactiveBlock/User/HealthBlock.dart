import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart'
    show HealthMetricsDAO, HealthMetricsTableCompanion, HealthLogsDAO;
import 'package:signals/signals.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

class HealthBlock {
  int personId;
  final HealthMetricsDAO _healthDao;

  final todaySteps = signal<int>(0);
  final historicalSteps = signal<int>(0);
  final todaySleep = signal<double>(0.0);
  final todayHeartRate = signal<int>(0);
  final dailyStepGoal = signal<int>(10000);
  final dailyKcalGoal = signal<int>(2500);
  final todayWater = signal<int>(0);

  late final totalSteps = computed(
    () => todaySteps.value + historicalSteps.value,
  );

  StreamSubscription? _metricsSubscription;

  HealthBlock({
    required this.personId,
    required HealthMetricsDAO healthDao,
    required HealthLogsDAO healthLogsDao,
  }) : _healthDao = healthDao,
       _healthLogsDao = healthLogsDao;

  final HealthLogsDAO _healthLogsDao;
  StreamSubscription? _waterSubscription;

  void init() {
    // Watch all metrics to calculate historical steps (excluding today)
    _metricsSubscription = _healthDao.watchAllMetrics(personId).listen(
      (metrics) {
        final today = DateTime.now();
        final todayStr = "${today.year}-${today.month}-${today.day}";

        int totalHistorical = 0;
        int foundTodaySteps = 0;
        double foundTodaySleep = 0;
        int foundTodayHeartRate = 0;

        for (var m in metrics) {
          final dateStr = "${m.date.year}-${m.date.month}-${m.date.day}";
          if (dateStr == todayStr) {
            foundTodaySteps = m.steps;
            foundTodaySleep = m.sleepHours;
            foundTodayHeartRate = m.heartRate;
          } else {
            totalHistorical += m.steps;
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

  Future<void> _saveSteps(int steps) async {
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
