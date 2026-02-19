import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart'
    show HealthMetricsDAO, HealthMetricsTableCompanion, HealthLogsDAO;
import 'package:signals/signals.dart';

class HealthBlock {
  final int personId;
  final HealthMetricsDAO _healthDao;

  final todaySteps = signal<int>(0);
  final historicalSteps = signal<int>(0);
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
    _metricsSubscription = _healthDao.watchAllMetrics(personId).listen((
      metrics,
    ) {
      final today = DateTime.now();
      final todayStr = "${today.year}-${today.month}-${today.day}";

      int totalHistorical = 0;
      int foundTodaySteps = 0;

      for (var m in metrics) {
        final dateStr = "${m.date.year}-${m.date.month}-${m.date.day}";
        if (dateStr == todayStr) {
          foundTodaySteps = m.steps;
        } else {
          totalHistorical += m.steps;
        }
      }

      historicalSteps.value = totalHistorical;
      // Only update todaySteps from DB if it's larger than current volatile state
      if (foundTodaySteps > todaySteps.value) {
        todaySteps.value = foundTodaySteps;
      }
    });

    _waterSubscription = _healthLogsDao
        .watchDailyWaterLogs(personId, DateTime.now())
        .listen((logs) {
          todayWater.value = logs.fold<int>(0, (sum, log) => sum + log.amount);
        });
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

  Future<void> _saveSteps(int steps) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    debugPrint("HealthBlock: Saving $steps steps to DB for $normalizedToday");
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        personID: Value(personId),
        date: Value(normalizedToday),
        steps: Value(steps),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void dispose() {
    _metricsSubscription?.cancel();
    _waterSubscription?.cancel();
    todaySteps.dispose();
    historicalSteps.dispose();
    // totalSteps is a computed signal, it is handled automatically
    todayWater.dispose();
  }
}
