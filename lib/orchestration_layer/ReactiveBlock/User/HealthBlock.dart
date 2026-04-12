import 'dart:async';
import 'dart:io' show Platform;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart'
    show
        HealthLogsDAO,
        HealthMealDAO,
        HealthMetricsDAO,
        HealthMetricsTableCompanion,
        HourlyActivityLogDAO,
        HourlyActivityLogTableCompanion,
        WaterLogsTableCompanion,
        WeightLogsTableCompanion;
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/ui_layer/health_page/services/HealthService.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

class HealthBlock {
  String personId;
  final HealthMetricsDAO _healthDao;
  final HourlyActivityLogDAO _hourlyLogDao;

  final todaySteps = signal<int>(0);
  final hourlySteps = signal<Map<int, int>>({});
  final historicalSteps = signal<int>(0);
  final dailyStepsLast7Days = signal<Map<String, int>>({});
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
  final latestWeight = signal<double>(0.0);
  final hasInitialSync = signal<bool>(false);

  late final totalSteps = computed(
    () => todaySteps.value + historicalSteps.value,
  );

  late final weeklySteps = computed(() {
    return dailyStepsLast7Days.value.values
        .fold<int>(0, (sum, val) => sum + val);
  });

  StreamSubscription? _metricsSubscription;
  StreamSubscription? _hourlyLogsSubscription;

  HealthBlock({
    required String personId,
    required HealthMetricsDAO healthDao,
    required HealthLogsDAO healthLogsDao,
    required HealthMealDAO healthMealDao,
    required HourlyActivityLogDAO hourlyLogDao,
  }) : personId = personId,
       _healthDao = healthDao,
       _healthLogsDao = healthLogsDao,
       _healthMealDao = healthMealDao,
       _hourlyLogDao = hourlyLogDao;

  final HealthLogsDAO _healthLogsDao;
  final HealthMealDAO _healthMealDao;
  StreamSubscription? _waterSubscription;
  StreamSubscription? _mealSubscription;
  StreamSubscription? _exerciseSubscription; // watches exercise_logs → sums durationMinutes → health_metrics
  StreamSubscription? _weightSubscription;

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
    _hourlyLogsSubscription?.cancel();
    _waterSubscription?.cancel();
    _mealSubscription?.cancel();
    _exerciseSubscription?.cancel();
    _weightSubscription?.cancel();

    // Reset signals for new user
    batch(() {
      todaySteps.value = 0;
      hourlySteps.value = {};
      historicalSteps.value = 0;
      dailyStepsLast7Days.value = {};
      todaySleep.value = 0.0;
      todayHeartRate.value = 0;
      todayCaloriesBurned.value = 0;
      todayCaloriesConsumed.value = 0;
      todayWater.value = 0;
      todayExerciseMinutes.value = 0;
      todayFocusMinutes.value = 0;
      todayWeight.value = 0.0;
      latestWeight.value = 0.0;
      hasInitialSync.value = false;
    });

    // 0. Cleanup duplicates before starting watch to prevent sync conflicts
    _healthDao.cleanupDuplicates(personId).then((_) {
      if (_initializedPersonId != personId) {
        return; // Guard against race condition
      }

      // Watch all metrics to calculate historical steps (excluding today)
      _metricsSubscription = _healthDao.watchAllMetrics(personId).listen(
        (metrics) {
          final today = DateTime.now();
          final todayStr =
              "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
          final yesterday = today.subtract(const Duration(days: 1));
          final yesterdayStr =
              "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
          
          final sevenDaysAgo =
              DateTime(today.year, today.month, today.day)
                  .subtract(const Duration(days: 7));

          int totalHistorical = 0;
          int foundTodaySteps = 0;
          double foundTodaySleep = 0.0;
          int foundTodayHeartRate = 0;
          int foundTodayCaloriesBurned = 0;
          int foundTodayCaloriesConsumed = 0;
          int foundTodayExerciseMinutes = 0;
          int foundTodayFocusMinutes = 0;
          final Map<String, int> stepsLast7Days = {};

          debugPrint(
            "HealthBlock: 📊 Received ${metrics.length} metrics from DB. Today: $todayStr, Yesterday: $yesterdayStr",
          );

          for (var m in metrics) {
            final dateStr =
                "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}";
            final isTodayMatch = dateStr == todayStr;
            final steps = m.steps ?? 0;

            if (isTodayMatch) {
              if (steps > foundTodaySteps) foundTodaySteps = steps;
              if ((m.sleepHours ?? 0.0) > foundTodaySleep) {
                foundTodaySleep = m.sleepHours!;
              }
              if ((m.heartRate ?? 0) > foundTodayHeartRate) {
                foundTodayHeartRate = m.heartRate!;
              }
              if ((m.caloriesBurned ?? 0) > foundTodayCaloriesBurned) {
                foundTodayCaloriesBurned = m.caloriesBurned!;
              }
              if ((m.caloriesConsumed ?? 0) > foundTodayCaloriesConsumed) {
                foundTodayCaloriesConsumed = m.caloriesConsumed!;
              }
              if ((m.weightKg ?? 0.0) > 0) todayWeight.value = m.weightKg!;
              if ((m.exerciseMinutes ?? 0) > 0) {
                foundTodayExerciseMinutes += m.exerciseMinutes!;
              }
              if ((m.focusMinutes ?? 0) > 0) {
                foundTodayFocusMinutes += m.focusMinutes!;
              }
            } else {
              totalHistorical += steps;
            }

            // Fill last 7 days map
            final normalizedDate =
                DateTime(m.date.year, m.date.month, m.date.day);
            if (normalizedDate.isAfter(sevenDaysAgo) ||
                normalizedDate.isAtSameMomentAs(sevenDaysAgo)) {
              stepsLast7Days[dateStr] = (stepsLast7Days[dateStr] ?? 0) + steps;
            }
          }

          historicalSteps.value = totalHistorical;

          // Update signals from aggregated DB data (Phone-wins: only update if DB has MORE data than current signal)
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
          if (foundTodayCaloriesConsumed > todayCaloriesConsumed.value) {
            todayCaloriesConsumed.value = foundTodayCaloriesConsumed;
          }
          
          todayExerciseMinutes.value = foundTodayExerciseMinutes;
          todayFocusMinutes.value = foundTodayFocusMinutes;

          // Ensure today's entry in weekly map also reflects the best data (signal or DB)
          final bestTodaySteps = (stepsLast7Days[todayStr] ?? 0) > todaySteps.value 
              ? (stepsLast7Days[todayStr] ?? 0) 
              : todaySteps.value;
          stepsLast7Days[todayStr] = bestTodaySteps;
          
          dailyStepsLast7Days.value = Map.from(stepsLast7Days);

          // Mark initial sync complete
          if (!hasInitialSync.value) {
            debugPrint("HealthBlock: ✅ Initial DB sync complete.");
            hasInitialSync.value = true;
          }
          
          final yesterdayVal = stepsLast7Days[yesterdayStr] ?? 0;
          debugPrint("📊 [HealthBlock] UI Update - Today: ${todaySteps.value}, Yesterday ($yesterdayStr): $yesterdayVal, Historical Total: $totalHistorical");
        },
        onError: (e) =>
            debugPrint("HealthBlock: Error watching health metrics: $e"),
      );

      // Watch hourly logs for today
      _hourlyLogsSubscription = _hourlyLogDao.watchHourlyLogs(personId, DateTime.now()).listen(
        (logs) {
          final Map<int, int> hourlyMap = {for (var i = 0; i < 24; i++) i: 0};
          for (var log in logs) {
            final hour = log.startTime.hour;
            hourlyMap[hour] = (hourlyMap[hour] ?? 0) + log.stepsCount;
          }
          
          // Merge strategy: only update signal if DB has more data OR if it's a new hour
          // This prevents DB downloads from downgrading current session data.
          final currentMap = Map<int, int>.from(hourlySteps.value);
          bool changed = false;
          
          hourlyMap.forEach((hour, steps) {
            if (steps > (currentMap[hour] ?? 0)) {
              currentMap[hour] = steps;
              changed = true;
            }
          });
          
          if (changed || hourlySteps.value.isEmpty) {
            hourlySteps.value = currentMap;
          }
        },
        onError: (e) => debugPrint("HealthBlock: Error watching hourly logs: $e"),
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

    _mealSubscription = _healthMealDao
        .watchDailyCalories(personId, DateTime.now())
        .listen(
          (cals) {
            todayCaloriesConsumed.value = cals.toInt();
            _saveCaloriesConsumed(cals.toInt());
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching meal calories: $e"),
        );

    // Watch exercise_logs daily stream → SUM(duration_minutes) → health_metrics.exercise_minutes.
    // This gives immediate reactivity when exercises are logged, without waiting for _metricsSubscription.
    _exerciseSubscription = _healthLogsDao
        .watchDailyExerciseLogs(personId, DateTime.now())
        .listen(
          (logs) {
            // SUM(duration_minutes) for today — all exercise sessions aggregated by day
            final totalMinutes = logs.fold<int>(
              0,
              (sum, log) => sum + log.durationMinutes,
            );
            todayExerciseMinutes.value = totalMinutes;
            _saveExercise(totalMinutes); // persist to health_metrics
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching exercise logs: $e"),
        );

    _weightSubscription = _healthLogsDao
        .watchLatestWeightLog(personId)
        .listen(
          (log) {
            if (log != null) {
              latestWeight.value = log.weightKg;
            } else {
              latestWeight.value = 0.0;
            }
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching latest weight logs: $e"),
        );

    // Watch goals and save to SharedPreferences
    effect(() => _saveGoal('dailyStepGoal', dailyStepGoal.value));
    effect(() => _saveGoal('dailyKcalGoal', dailyKcalGoal.value));
    effect(() => _saveGoal('dailyWaterGoal', dailyWaterGoal.value));
    effect(() => _saveGoal('dailyFocusGoal', dailyFocusGoal.value));
    effect(() => _saveGoal('dailyExerciseGoal', dailyExerciseGoal.value));
    effect(() => _saveGoal('dailySleepGoal', dailySleepGoal.value));

    // 1. Silent Sync today's data on init (non-blocking)
    syncTodaySteps(() => HealthService.fetchStepCount()).then((_) {
      debugPrint("HealthBlock: 🔄 Silent sync of today's steps completed.");
    }).catchError((e) {
      debugPrint("HealthBlock: ⚠️ Silent sync failed: $e");
    });
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

  void updateSteps(int steps, {DateTime? date, bool force = false}) {
    final targetDate = date ?? DateTime.now();
    final now = DateTime.now();
    final isToday = targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    if (force) {
      debugPrint("🔄 [HealthBlock] Forcing Step Update for $targetDate: $steps steps");
    }

    debugPrint(
      "HealthBlock: updateSteps called with $steps steps for $targetDate (force: $force)",
    );
    
    if (isToday) {
      if (force || steps > todaySteps.value) {
        print("TODAY STEP DUYLONG: $steps");
        todaySteps.value = steps;
        _saveSteps(steps, date: targetDate, force: force);
      }
    } else {
      _saveSteps(steps, date: targetDate, force: force);
    }
  }

  bool get _isDesktop =>
      kIsWeb ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;

  Future<void> syncHistory(Future<int> Function(DateTime) fetcher) async {
    if (_isDesktop) {
      debugPrint("HealthBlock: ⏭️ Skipping history sync on desktop.");
      return;
    }
    debugPrint("HealthBlock: 🔄 Starting history sync...");
    // Use a fixed baseline for 'now' to ensure consistent date subtraction throughout the loop
    final baseline = DateTime.now();
    final todayStart = DateTime(baseline.year, baseline.month, baseline.day);

    // Sync last 30 days
    debugPrint("🚀 [HealthBlock] Starting History Sync for 30 days. Baseline: $todayStart");

    for (int i = 0; i <= 30; i++) {
      final day = todayStart.subtract(Duration(days: i));
      final steps = await fetcher(day);
      
      final isYesterday = i == 1;
      if (isYesterday) {
        debugPrint("📅 [HealthBlock] Yesterday ($day) Steps: $steps");
      }

      // We sync even if steps are 0 to ensure local cache is accurate
      updateSteps(steps, date: day, force: true);
    }
    debugPrint("✅ [HealthBlock] History Sync Completed");
    debugPrint("HealthBlock: ✅ History sync complete.");
  }

  Future<void> syncWeightHistory(Future<double> Function(DateTime) fetcher) async {
    if (_isDesktop) {
      debugPrint("HealthBlock: ⏭️ Skipping weight history sync on desktop.");
      return;
    }
    debugPrint("HealthBlock: ⚖️ Starting weight history sync...");
    final baseline = DateTime.now();
    final todayStart = DateTime(baseline.year, baseline.month, baseline.day);

    for (int i = 0; i <= 30; i++) {
      final day = todayStart.subtract(Duration(days: i));
      final weight = await fetcher(day);
      
      if (weight > 0) {
        updateWeight(weight, date: day, force: true);
      }
    }
    debugPrint("✅ [HealthBlock] Weight History Sync Completed");
  }

  /// Re-aggregates exercise_logs into health_metrics.exercise_minutes
  /// for the last 30 days. Source of truth is exercise_logs (Supabase/PowerSync),
  /// not Apple HealthKit. This runs on ALL platforms (including macOS)
  /// since it reads from the local DB populated by PowerSync.
  Future<void> syncExerciseHistory() async {
    if (personId.isEmpty) return;
    debugPrint("HealthBlock: 🏋️ Starting exercise history sync...");
    final baseline = DateTime.now();
    final todayStart = DateTime(baseline.year, baseline.month, baseline.day);

    for (int i = 0; i <= 30; i++) {
      final day = todayStart.subtract(Duration(days: i));
      // SUM(duration_minutes) from exercise_logs for this day
      final totalMinutes = await _healthLogsDao.getDailyExerciseTotal(personId, day);

      if (totalMinutes > 0) {
        final normalizedDay = DateTime(day.year, day.month, day.day, 12);
        await _healthDao.insertOrUpdateMetrics(
          HealthMetricsTableCompanion.insert(
            id: _getDeterministicId(day),
            personID: Value(personId),
            date: normalizedDay,
            exerciseMinutes: Value(totalMinutes),
          ),
          force: true,
        );
      }
    }
    debugPrint("✅ [HealthBlock] Exercise History Sync Completed");
  }

  Future<void> syncTodaySteps(Future<int> Function() fetcher) async {
    if (_isDesktop) {
      debugPrint("HealthBlock: ⏭️ Skipping today's steps sync on desktop.");
      return;
    }
    debugPrint("HealthBlock: 🔄 [SYNC] Fetching today's steps from platform...");
    final steps = await fetcher();
    debugPrint("HealthBlock: 🔄 [SYNC] Platform returned $steps steps for today.");
    updateSteps(steps, force: true); // Force update to match platform exactly
    debugPrint("HealthBlock: ✅ [SYNC] Today's steps synced: $steps");
  }

  void updateHourlySteps(Map<int, int> hourly, {DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    debugPrint("HealthBlock: updateHourlySteps called with ${hourly.length} hours for $targetDate");
    
    // Optimistically update the signal first (Phone wins)
    final currentMap = Map<int, int>.from(hourlySteps.value);
    hourly.forEach((hour, steps) {
      if (steps > (currentMap[hour] ?? 0)) {
        currentMap[hour] = steps;
      }
      _saveHourlyStep(hour, steps, date: targetDate);
    });
    hourlySteps.value = currentMap;
  }

  Future<void> _saveHourlyStep(int hour, int steps, {DateTime? date}) async {
    if (personId.isEmpty) return;
    final targetDate = date ?? DateTime.now();
    final startTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour);
    final endTime = startTime.add(const Duration(hours: 1));
    
    // Calculate related metrics
    final distanceKm = steps * 0.0008; // Roughly 0.8m per step
    final caloriesBurned = (steps * 0.04).round(); // Roughly 0.04 kcal per step
    
    // Deterministic ID for hourly log
    final logId = IDGen.generateDeterministicUuid(
      personId, 
      "hourly_steps:${targetDate.year}-${targetDate.month}-${targetDate.day}:$hour"
    );

    await _hourlyLogDao.upsertHourlyLog(
      HourlyActivityLogTableCompanion.insert(
        id: logId,
        personID: personId,
        startTime: startTime,
        endTime: Value(endTime),
        logDate: DateTime(targetDate.year, targetDate.month, targetDate.day),
        stepsCount: Value(steps),
        distanceKm: Value(distanceKm),
        caloriesBurned: Value(caloriesBurned),
      ),
    );
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

  Future<void> updateWeight(double weight, {DateTime? date, bool force = false}) async {
    final targetDate = date ?? DateTime.now();
    final now = DateTime.now();
    final isToday = targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    debugPrint(
      "HealthBlock: updateWeight called with $weight kg for $targetDate (force: $force)",
    );
    
    if (isToday) {
      if (force || weight > 0) {
        todayWeight.value = weight;
        _saveWeight(weight, date: targetDate, force: force);
      }
    } else {
      _saveWeight(weight, date: targetDate, force: force);
    }
  }

  void updateCalories(int calories) {
    debugPrint(
      "HealthBlock: updateCalories called with $calories kcal (current: ${todayCaloriesBurned.value})",
    );
    if (calories > todayCaloriesBurned.value) {
      todayCaloriesBurned.value = calories;
      _saveCaloriesBurned(calories);
    }
  }

  String _getDeterministicId(DateTime date) {
    // Standardize date format to match Database DAO (YYYY-MM-DD)
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        
    // Use IDGen matching HealthMetricsDAO fallback check
    return IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:General",
    );
  }

  Future<void> _saveCaloriesConsumed(int calories, {bool force = false}) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint(
      "HealthBlock: Saving $calories calories consumed to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        caloriesConsumed: Value(calories),
      ),
      force: force,
    );
  }

  Future<void> _saveCaloriesBurned(int calories, {bool force = false}) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint(
      "HealthBlock: Saving $calories calories burned to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        caloriesBurned: Value(calories),
      ),
      force: force,
    );
  }

  Future<void> _saveSteps(int steps, {DateTime? date, bool force = false}) async {
    if (personId.isEmpty) {
      debugPrint("HealthBlock: Cannot save steps, personId is empty");
      return;
    }
    final targetDate = date ?? DateTime.now();
    // Normalize to noon to match DAO lookup logic exactly
    final normalizedDate =
        DateTime(targetDate.year, targetDate.month, targetDate.day, 12);

    debugPrint("HealthBlock: Saving $steps steps to DB for $normalizedDate (force: $force)");
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(targetDate),
        personID: Value(personId),
        date: normalizedDate,
        steps: Value(steps),
      ),
      force: force,
    );
  }

  Future<void> _saveSleep(double hours, {bool force = false}) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint(
      "HealthBlock: Saving $hours sleep hours to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        sleepHours: Value(hours),
      ),
      force: force,
    );
  }

  Future<void> _saveWater(int ml, {bool force = false}) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint("HealthBlock: Saving $ml ml water to DB for $normalizedToday");

    // Store raw ml total in waterGlasses field.
    // Despite the field being named "waterGlasses", it stores ml for precision.
    // health_metrics.water_glasses is compared against WATER_GOAL (2000ml) in the UI.
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        waterGlasses: Value(ml), // Store ml directly (SUM of water_logs.amount for the day)
      ),
      force: force,
    );
  }

  /// Persist the SUM of exercise_logs.duration_minutes for today into
  /// health_metrics.exercise_minutes. Called by _exerciseSubscription on every
  /// stream update (i.e. whenever a new exercise log is inserted or deleted).
  /// Strong data wins: insertOrUpdateMetrics only updates when minutes > existing value.
  Future<void> _saveExercise(int minutes, {bool force = false}) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint("HealthBlock: Saving $minutes exercise minutes to DB for $normalizedToday");

    // Write SUM(duration_minutes) of today's exercise_logs to health_metrics.exercise_minutes.
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        exerciseMinutes: Value(minutes), // SUM(exercise_logs.duration_minutes) for the day
      ),
      force: force,
    );
  }

  Future<void> _saveWeight(double kg, {DateTime? date, bool force = false}) async {
    if (personId.isEmpty || personId == DataSeeder.guestPersonId) {
      debugPrint("HealthBlock: ⚠️ Skipping weight save for Guest or Empty ID ($personId)");
      return;
    }
    final targetDate = date ?? DateTime.now();
    final normalizedTarget = DateTime(targetDate.year, targetDate.month, targetDate.day, 12);

    debugPrint("HealthBlock: Saving $kg kg weight to DB for $normalizedTarget (force: $force)");
    
    // 1. Update daily summary
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(targetDate),
        personID: Value(personId),
        date: normalizedTarget,
        weightKg: Value(kg),
      ),
      force: force,
    );

    // 2. Insert detailed log entry for history
    await _healthLogsDao.insertWeightLog(
      WeightLogsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: Value(personId),
        weightKg: Value(kg),
        timestamp: Value(targetDate),
      ),
    );
  }

  /// Public method to add water log entry
  Future<void> updateWaterLevel(int ml) async {
    if (personId.isEmpty) return;
    await _healthLogsDao.insertWaterLog(
      WaterLogsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: Value(personId),
        amount: Value(ml),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  /// Public method to delete a specific water log entry
  Future<void> deleteWaterLog(String id) async {
    if (personId.isEmpty) return;
    await _healthLogsDao.deleteWaterLog(id);
  }

  Future<void> _saveHeartRate(int bpm, {bool force = false}) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint(
      "HealthBlock: Saving $bpm heart rate to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        heartRate: Value(bpm),
      ),
      force: force,
    );
  }

  Future<void> updateExerciseGoal(int minutes) async {
    dailyExerciseGoal.value = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('exercise_goal', minutes);
  }

  /// Estimates calories burned based on MET values
  /// Reference: https://en.wikipedia.org/wiki/Metabolic_equivalent_of_task
  int estimateCalories(String type, int minutes, String intensity) {
    if (minutes <= 0) return 0;
    
    // Default weight if todayWeight is not set
    final weight = todayWeight.value > 0 ? todayWeight.value : 70.0;
    
    double met = 3.0; // Baseline for low intensity activity
    
    final lowerType = type.toLowerCase();
    if (lowerType.contains('run')) {
      met = intensity == 'high' ? 12.0 : (intensity == 'medium' ? 10.0 : 8.0);
    } else if (lowerType.contains('gym') || lowerType.contains('strength')) {
      met = intensity == 'high' ? 8.0 : (intensity == 'medium' ? 5.0 : 3.0);
    } else if (lowerType.contains('swim')) {
      met = intensity == 'high' ? 10.0 : 7.0;
    } else if (lowerType.contains('yoga') || lowerType.contains('breath')) {
      met = intensity == 'high' ? 3.5 : 2.5;
    } else if (lowerType.contains('cycling') || lowerType.contains('bike')) {
      met = intensity == 'high' ? 10.0 : 6.0;
    } else if (intensity == 'high') {
      met = 8.0;
    } else if (intensity == 'medium') {
      met = 5.0;
    }
    
    // Formula: (MET * 3.5 * weight) / 200 * minutes
    return ((met * 3.5 * weight) / 200 * minutes).round();
  }

  void dispose() {
    _metricsSubscription?.cancel();
    _hourlyLogsSubscription?.cancel();
    _waterSubscription?.cancel();
    _mealSubscription?.cancel();
    _exerciseSubscription?.cancel();
    _weightSubscription?.cancel();
    todaySteps.dispose();
    historicalSteps.dispose();
    dailyStepsLast7Days.dispose();
    todaySleep.dispose();
    todayHeartRate.dispose();
    todayCaloriesBurned.dispose();
    todayCaloriesConsumed.dispose();
    dailyStepGoal.dispose();
    dailyKcalGoal.dispose();
    dailyWaterGoal.dispose();
    dailyFocusGoal.dispose();
    dailyExerciseGoal.dispose();
    dailySleepGoal.dispose();
    todayWater.dispose();
    todayExerciseMinutes.dispose();
    todayFocusMinutes.dispose();
    todayWeight.dispose();
    latestWeight.dispose();
    hasInitialSync.dispose();
  }
}
