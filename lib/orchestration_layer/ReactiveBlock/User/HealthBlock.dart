import 'dart:async';
import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/AppleHealthServices.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/HealthSourceService.dart';
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
        WeightLogsTableCompanion,
        HeartRateLogsTableCompanion,
        OxygenSaturationLogsTableCompanion,
        OxygenSaturationLogData,
        SleepLogsTableCompanion;
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:rxdart/rxdart.dart';
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
  final todayOxygenSaturation = signal<double>(0.0);
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
  final dailyWeightLast30Days = signal<Map<String, double>>({});
  final dailyWaterLast30Days = signal<Map<String, int>>({});
  final hasInitialSync = signal<bool>(false);
  final isSyncing = signal<bool>(false);

  final isStepsLoading = signal<bool>(false);
  final isSleepLoading = signal<bool>(false);
  final isHeartRateLoading = signal<bool>(false);
  final isOxygenLoading = signal<bool>(false);
  final isWaterLoading = signal<bool>(false);
  final isExerciseLoading = signal<bool>(false);
  final isWeightLoading = signal<bool>(false);
  final isCaloriesBurnedLoading = signal<bool>(false);
  final isCaloriesConsumedLoading = signal<bool>(false);

  late final totalSteps = computed(
    () => todaySteps.value + historicalSteps.value,
  );

  late final weeklySteps = computed(() {
    return dailyStepsLast7Days.value.values.fold<int>(
      0,
      (sum, val) => sum + val,
    );
  });

  late final weightTrend = computed(() {
    final weights = dailyWeightLast30Days.value.values
        .where((w) => w < 0)
        .toList();
    if (weights.length < 2) return 0.0;
    return weights.last - weights.first;
  });

  late final averageWater7d = computed(() {
    final waters = dailyWaterLast30Days.value.values.toList();
    if (waters.isEmpty) return 0.0;
    final last7 = waters.length > 7
        ? waters.sublist(waters.length - 7)
        : waters;
    return last7.fold<int>(0, (sum, val) => sum + val) / 7;
  });

  StreamSubscription? _metricsSubscription;
  StreamSubscription? _hourlyLogsSubscription;
  Timer? _realtimeSyncTimer;

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
  StreamSubscription?
  _exerciseSubscription;
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

    _metricsSubscription?.cancel();
    _hourlyLogsSubscription?.cancel();
    _waterSubscription?.cancel();
    _mealSubscription?.cancel();
    _exerciseSubscription?.cancel();
    _weightSubscription?.cancel();

    batch(() {
      todaySteps.value = 0;
      hourlySteps.value = {};
      historicalSteps.value = 0;
      dailyStepsLast7Days.value = {};
      todaySleep.value = 0.0;
      todayHeartRate.value = 0;
      todayOxygenSaturation.value = 0.0;
      todayCaloriesBurned.value = 0;
      todayCaloriesConsumed.value = 0;
      todayWater.value = 0;
      todayExerciseMinutes.value = 0;
      todayFocusMinutes.value = 0;
      todayWeight.value = 0.0;
      latestWeight.value = 0.0;
      hasInitialSync.value = false;
    });

    _healthDao.cleanupDuplicates(personId).then((_) {
      if (_initializedPersonId != personId) {
        return;
      }

      _metricsSubscription = _healthDao
          .watchAllMetrics(personId)
          .debounceTime(const Duration(milliseconds: 500))
          .listen(
            (metrics) {
              final today = DateTime.now();
              final todayStr =
                  "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
              final yesterday = today.subtract(const Duration(days: 1));
              final yesterdayStr =
                  "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

              final sevenDaysAgo = DateTime(
                today.year,
                today.month,
                today.day,
              ).subtract(const Duration(days: 7));

              int totalHistorical = 0;
              int foundTodaySteps = 0;
              double foundTodaySleep = 0.0;
              int foundTodayHeartRate = 0;
              double foundTodayOxygenSaturation = 0.0;
              int foundTodayCaloriesBurned = 0;
              int foundTodayCaloriesConsumed = 0;
              int foundTodayExerciseMinutes = 0;
              int foundTodayFocusMinutes = 0;
              final Map<String, int> stepsLast7Days = {};
              final Map<String, double> weightHistory = {};
              final Map<String, int> waterHistory = {};

              for (var m in metrics) {
                final dateStr =
                    "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}";
                final isTodayMatch = dateStr == todayStr;
                final steps = m.steps ?? 0;

                if (isTodayMatch) {
                  if (steps > foundTodaySteps) foundTodaySteps = steps;
                  if ((m.sleepHours ?? 0.0) > foundTodaySleep) {
                    foundTodaySleep = m.sleepHours ?? 0.0;
                  }
                  if ((m.heartRate ?? 0) > foundTodayHeartRate) {
                    foundTodayHeartRate = m.heartRate ?? 0;
                  }
                  if ((m.oxygenSaturation ?? 0.0) >
                      foundTodayOxygenSaturation) {
                    foundTodayOxygenSaturation = m.oxygenSaturation ?? 0.0;
                  }
                  if ((m.caloriesBurned ?? 0) > foundTodayCaloriesBurned) {
                    foundTodayCaloriesBurned = m.caloriesBurned ?? 0;
                  }
                  if ((m.caloriesConsumed ?? 0) > foundTodayCaloriesConsumed) {
                    foundTodayCaloriesConsumed = m.caloriesConsumed ?? 0;
                  }
                  if ((m.weightKg ?? 0.0) > 0)
                    todayWeight.value = m.weightKg ?? 0.0;
                  if ((m.exerciseMinutes ?? 0) > 0) {
                    foundTodayExerciseMinutes += (m.exerciseMinutes ?? 0)
                        .toInt();
                  }
                  if ((m.focusMinutes ?? 0) > 0) {
                    foundTodayFocusMinutes += (m.focusMinutes ?? 0).toInt();
                  }
                } else {
                  totalHistorical += steps.toInt();
                }

                final normalizedDate = DateTime(
                  m.date.year,
                  m.date.month,
                  m.date.day,
                );
                if (normalizedDate.isAfter(sevenDaysAgo) ||
                    normalizedDate.isAtSameMomentAs(sevenDaysAgo)) {
                  stepsLast7Days[dateStr] =
                      (stepsLast7Days[dateStr] ?? 0) + steps.toInt();
                }

                final thirtyDaysAgo = today.subtract(const Duration(days: 30));
                if (m.date.isAfter(thirtyDaysAgo)) {
                  if ((m.weightKg ?? 0) > 0)
                    weightHistory[dateStr] = m.weightKg!;
                  if ((m.waterGlasses ?? 0) > 0)
                    waterHistory[dateStr] = m.waterGlasses!;
                }
              }

              historicalSteps.value = totalHistorical;

              if (foundTodaySteps > todaySteps.value) {
                todaySteps.value = foundTodaySteps;
              }
              if (foundTodaySleep > todaySleep.value) {
                todaySleep.value = foundTodaySleep;
              }
              if (foundTodayHeartRate > todayHeartRate.value) {
                todayHeartRate.value = foundTodayHeartRate;
              }
              if (foundTodayOxygenSaturation > todayOxygenSaturation.value) {
                todayOxygenSaturation.value = foundTodayOxygenSaturation;
              }
              if (foundTodayCaloriesBurned > todayCaloriesBurned.value) {
                todayCaloriesBurned.value = foundTodayCaloriesBurned;
              }
              if (foundTodayCaloriesConsumed > todayCaloriesConsumed.value) {
                todayCaloriesConsumed.value = foundTodayCaloriesConsumed;
              }

              todayExerciseMinutes.value = foundTodayExerciseMinutes;
              todayFocusMinutes.value = foundTodayFocusMinutes;

              final bestTodaySteps =
                  (stepsLast7Days[todayStr] ?? 0) > todaySteps.value
                  ? (stepsLast7Days[todayStr] ?? 0)
                  : todaySteps.value;
              stepsLast7Days[todayStr] = bestTodaySteps;

              dailyStepsLast7Days.value = Map.from(stepsLast7Days);
              dailyWeightLast30Days.value = Map.from(weightHistory);
              dailyWaterLast30Days.value = Map.from(waterHistory);

              if (!hasInitialSync.value) {
                debugPrint("HealthBlock: ✅ Initial DB sync complete.");
                hasInitialSync.value = true;
              }

              final yesterdayVal = stepsLast7Days[yesterdayStr] ?? 0;
              debugPrint(
                "📊 [HealthBlock] UI Update - Today: ${todaySteps.value}, Yesterday ($yesterdayStr): $yesterdayVal, Historical Total: $totalHistorical",
              );
            },
            onError: (e) =>
                debugPrint("HealthBlock: Error watching health metrics: $e"),
          );

      _hourlyLogsSubscription = _hourlyLogDao
          .watchHourlyLogs(personId, DateTime.now())
          .debounceTime(const Duration(milliseconds: 500))
          .listen(
            (logs) {
              final Map<int, int> hourlyMap = {
                for (var i = 0; i < 24; i++) i: 0,
              };
              for (var log in logs) {
                final hour = log.startTime.hour;
                hourlyMap[hour] =
                    (hourlyMap[hour] ?? 0) + log.stepsCount.toInt();
              }

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
            onError: (e) =>
                debugPrint("HealthBlock: Error watching hourly logs: $e"),
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
            _saveWater(todayWater.value, source: HealthSourceService.sourceManual);
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching water logs: $e"),
        );

    _mealSubscription = _healthMealDao
        .watchDailyCalories(personId, DateTime.now())
        .listen(
          (cals) {
            untracked(() {
              todayCaloriesConsumed.value = cals.toInt();
              _saveCaloriesConsumed(cals.toInt());
            });
          },

          onError: (e) =>
              debugPrint("HealthBlock: Error watching meal calories: $e"),
        );

    _exerciseSubscription = _healthLogsDao
        .watchDailyExerciseLogs(personId, DateTime.now())
        .listen(
          (logs) {
            final totalMinutes = logs.fold<int>(
              0,
              (sum, log) => sum + log.durationMinutes,
            );
            todayExerciseMinutes.value = totalMinutes;
            _saveExercise(totalMinutes, source: HealthSourceService.sourceGT6);
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching exercise logs: $e"),
        );

    _weightSubscription = _healthLogsDao.watchLatestWeightLog(personId).listen(
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

    effect(() => _saveGoal('dailyStepGoal', dailyStepGoal.value));
    effect(() => _saveGoal('dailyKcalGoal', dailyKcalGoal.value));
    effect(() => _saveGoal('dailyWaterGoal', dailyWaterGoal.value));
    effect(() => _saveGoal('dailyFocusGoal', dailyFocusGoal.value));
    effect(() => _saveGoal('dailyExerciseGoal', dailyExerciseGoal.value));
    effect(() => _saveGoal('dailySleepGoal', dailySleepGoal.value));

    syncTodaySteps(() => HealthService.fetchStepCount())
        .then((_) {
          debugPrint("HealthBlock: 🔄 Silent sync of today's steps completed.");
        })
        .catchError((e) {
          debugPrint("HealthBlock: ⚠️ Silent sync failed: $e");
        });

    syncTodayHeartRate(() => HealthService.fetchLatestHeartRate())
        .then((_) {
          debugPrint("HealthBlock: 🔄 Silent sync of heart rate completed.");
        })
        .catchError((e) {
          debugPrint("HealthBlock: ⚠️ Silent sync heart rate failed: $e");
        });

    syncTodayOxygenSaturation(() => HealthService.fetchLatestOxygenSaturation())
        .then((_) {
          debugPrint(
            "HealthBlock: 🔄 Silent sync of oxygen saturation completed.",
          );
        })
        .catchError((e) {
          debugPrint("HealthBlock: ⚠️ Silent sync oxygen saturation failed: $e",
          );
        });

    syncTodaySleep(() => HealthService.fetchSleepData())
        .then((_) {
          debugPrint("HealthBlock: 🔄 Silent sync of sleep data completed.");
        })
        .catchError((e) {
          debugPrint("HealthBlock: ⚠️ Silent sync sleep data failed: $e");
        });
  }

  void startRealtimeSync({Duration interval = const Duration(seconds: 30)}) {
    if (_realtimeSyncTimer?.isActive ?? false) return;

    debugPrint(
      "HealthBlock: ⚡ Starting realtime sync every ${interval.inSeconds}s",
    );
    _realtimeSyncTimer = Timer.periodic(interval, (_) async {
      debugPrint("HealthBlock: ⚡ Realtime sync pulse...");
      await syncAllFromPlatform();
    });
  }

  void stopRealtimeSync() {
    if (_realtimeSyncTimer != null) {
      debugPrint("HealthBlock: 🛑 Stopping realtime sync timer.");
      _realtimeSyncTimer?.cancel();
      _realtimeSyncTimer = null;
    }
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
    final day = date ?? DateTime.now();
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    if (isToday) {
      todaySteps.value = steps;
    }

    _saveSteps(steps, date: day, force: force, source: HealthSourceService.sourceAppleHealth);
  }

  bool get _isDesktop =>
      kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> syncHistory(Future<int> Function(DateTime) fetcher) async {
    if (_isDesktop) {
      debugPrint("HealthBlock: ⏭️ Skipping history sync on desktop.");
      return;
    }
    debugPrint("HealthBlock: 🔄 Starting history sync...");
    final baseline = DateTime.now();
    final todayStart = DateTime(baseline.year, baseline.month, baseline.day);

    debugPrint(
      "🚀 [HealthBlock] Starting History Sync for 30 days. Baseline: $todayStart",
    );

    for (int i = 0; i <= 30; i++) {
      final day = todayStart.subtract(Duration(days: i));
      final steps = await fetcher(day);

      final isYesterday = i == 1;
      if (isYesterday) {
        debugPrint("📅 [HealthBlock] Yesterday ($day) Steps: $steps");
      }

      updateSteps(steps, date: day, force: true);
    }
    debugPrint("✅ [HealthBlock] History Sync Completed");
    debugPrint("HealthBlock: ✅ History sync complete.");
  }

  Future<void> syncWeightHistory(
    Future<double> Function(DateTime) fetcher,
  ) async {
    if (_isDesktop) {
      debugPrint("HealthBlock: ⏭️ Skipping weight history sync on desktop.");
      return;
    }
    isWeightLoading.value = true;
    try {
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
    } finally {
      isWeightLoading.value = false;
    }
  }

  Future<void> syncExerciseHistory() async {
    if (personId.isEmpty) return;
    isExerciseLoading.value = true;
    try {
      debugPrint("HealthBlock: 🏋️ Starting exercise history sync...");
      final baseline = DateTime.now();
      final todayStart = DateTime(baseline.year, baseline.month, baseline.day);

      for (int i = 0; i <= 30; i++) {
        final day = todayStart.subtract(Duration(days: i));
        final totalMinutes = await _healthLogsDao.getDailyExerciseTotal(
          personId,
          day,
        );

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
    } finally {
      isExerciseLoading.value = false;
    }
  }

  Future<void> syncTodaySteps(Future<int> Function() fetcher) async {
    if (_isDesktop) {
      debugPrint("HealthBlock: ⏭️ Skipping today's steps sync on desktop.");
      return;
    }
    debugPrint(
      "HealthBlock: 🔄 [SYNC] Fetching today's steps from platform...",
    );
    isStepsLoading.value = true;
    try {
      final steps = await fetcher();
      debugPrint(
        "HealthBlock: 🔄 [SYNC] Platform returned $steps steps for today.",
      );
      updateSteps(steps, force: true);
      debugPrint("HealthBlock: ✅ [SYNC] Today's steps synced: $steps");
    } finally {
      isStepsLoading.value = false;
    }
  }

  Future<void> syncTodayHeartRate(Future<int> Function() fetcher) async {
    isHeartRateLoading.value = true;
    try {
      final bpm = await fetcher();
      if (bpm > 0) {
        updateHeartRate(bpm);
        
        syncHeartRateSamples(DateTime.now()).catchError((e) => debugPrint("Background HR sync error: $e"));
      }
    } finally {
      isHeartRateLoading.value = false;
    }
  }

  Future<void> syncTodayOxygenSaturation(
    Future<double> Function() fetcher,
  ) async {
    isOxygenLoading.value = true;
    try {
      final saturation = await fetcher();
      if (saturation > 0) {
        updateOxygenSaturation(saturation);
        
        syncOxygenSamples(DateTime.now()).catchError((e) => debugPrint("Background SpO2 sync error: $e"));
      }
    } finally {
      isOxygenLoading.value = false;
    }
  }

  Future<void> syncTodaySleep(Future<double> Function() fetcher) async {
    isSleepLoading.value = true;
    try {
      final hours = await fetcher();
      if (hours > 0) {
        updateSleep(hours);
      }
      await syncSleepSessions(DateTime.now());
    } finally {
      isSleepLoading.value = false;
    }
  }

  Future<void> syncSleepSessions(DateTime day) async {
    if (_isDesktop) return;

    final sessions = await HealthService.fetchSleepSessions(day);
    if (sessions.isEmpty) return;

    for (var session in sessions) {
      final startTime = session['startTime'] as DateTime;
      final endTime = session['endTime'] as DateTime;

      try {
        await _healthLogsDao.insertSleepLog(
          SleepLogsTableCompanion.insert(
            id: IDGen.UUIDV7(),
            personID: Value(personId),
            startTime: startTime,
            endTime: Value(endTime),
            quality: const Value(4),
            source: Value(session['sourceName'] as String?),
          ),
        );
      } catch (e) {
        debugPrint("HealthBlock: Skip duplicate sleep session: $e");
      }
    }
  }

  Future<void> syncAllFromPlatform() async {
    if (_isDesktop) {
      debugPrint("HealthBlock: ⏭️ Skipping platform sync on desktop.");
      return;
    }
    if (isSyncing.value) return;
    isSyncing.value = true;

    try {
      debugPrint("HealthBlock: 🔄 Starting global platform sync...");

      await Future.wait([
        syncTodaySteps(HealthService.fetchStepCount),
        syncTodayHeartRate(HealthService.fetchLatestHeartRate),
        syncTodayOxygenSaturation(HealthService.fetchLatestOxygenSaturation),
        syncTodaySleep(HealthService.fetchSleepData),
        syncSleepSessions(DateTime.now()),
        HealthService.fetchHourlyStepsForDay(DateTime.now()).then((hourly) {
          updateHourlySteps(hourly);
        }),
        syncHeartRateSamples(DateTime.now()),
      ]);

      debugPrint("HealthBlock: ✅ Global platform sync complete.");
    } catch (e) {
      debugPrint("HealthBlock: ❌ Global platform sync failed: $e");
    } finally {
      isSyncing.value = false;
    }
  }

  void updateHourlySteps(Map<int, int> hourly, {DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    debugPrint(
      "HealthBlock: updateHourlySteps called with ${hourly.length} hours for $targetDate",
    );

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
    final startTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
    );
    final endTime = startTime.add(const Duration(hours: 1));

    final distanceKm = steps * 0.0008;
    final caloriesBurned = (steps * 0.04).round();

    final logId = IDGen.generateDeterministicUuid(
      personId,
      "hourly_steps:${targetDate.year}-${targetDate.month}-${targetDate.day}:$hour",
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
    todaySleep.value = hours;

    _saveSleep(hours, source: HealthSourceService.sourceAppleHealth);
  }

  void updateHeartRate(int bpm) {
    if (bpm > 0) {
      todayHeartRate.value = bpm;

      _saveHeartRate(bpm, source: HealthSourceService.sourceAppleHealth);
    }
  }

  Future<void> syncHeartRateSamples(DateTime date) async {
    if (_isDesktop) return;
    final samples = await HealthService.fetchHeartRateSamplesForDay(date);
    debugPrint(
      "HealthBlock: 🫀 Syncing ${samples.length} heart rate samples...",
    );
    for (var sample in samples) {
      try {
        final value = sample.value;
        if (value is NumericHealthValue) {
          await _saveHeartRateLog(value.numericValue.round(), sample.dateFrom);
        }
      } catch (e) {
        debugPrint("HealthBlock: Error syncing individual HR sample: $e");
      }
    }
  }

  Future<void> _saveHeartRateLog(int bpm, DateTime timestamp) async {
    if (personId.isEmpty) return;
    final id = IDGen.generateDeterministicUuid(
      personId,
      "hr_log:${timestamp.toIso8601String()}",
    );

    await _healthLogsDao.insertHeartRateLog(
      HeartRateLogsTableCompanion.insert(
        id: id,
        personID: Value(personId),
        bpm: bpm,
        timestamp: timestamp,
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> syncOxygenSamples(DateTime date) async {
    if (_isDesktop) return;
    final samples = await HealthService.fetchOxygenSaturationSamplesForDay(
      date,
    );
    debugPrint("HealthBlock: 🫁 Syncing ${samples.length} oxygen samples...");
    for (var sample in samples) {
      try {
        final value = sample.value;
        if (value is NumericHealthValue) {
          double val = value.numericValue.toDouble();
          if (val <= 1.0 && val > 0) val *= 100.0;
          debugPrint(
            "HealthBlock: Syncing SpO2: $val% (Raw: ${value.numericValue})",
          );
          await _saveOxygenLog(val, sample.dateFrom);
        }
      } catch (e) {
        debugPrint("HealthBlock: Error syncing individual Oxygen sample: $e");
      }
    }
  }

  Future<void> _saveOxygenLog(double saturation, DateTime timestamp) async {
    if (personId.isEmpty) return;
    final id = IDGen.generateDeterministicUuid(
      personId,
      "oxygen_log:${timestamp.toIso8601String()}",
    );

    await _healthLogsDao.insertOxygenSaturationLog(
      OxygenSaturationLogsTableCompanion.insert(
        id: id,
        personID: Value(personId),
        saturation: saturation,
        timestamp: timestamp,
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<OxygenSaturationLogData>> watchOxygenLogs(DateTime date) {
    if (personId.isEmpty) return Stream.value([]);
    return _healthLogsDao.watchDailyOxygenLogs(personId, date);
  }

  void updateOxygenSaturation(double saturation) {
    if (saturation > 0) {
      todayOxygenSaturation.value = saturation;

      _saveOxygenSaturation(saturation, source: HealthSourceService.sourceAppleHealth);
    }
  }

  Future<void> updateWeight(
    double weight, {
    DateTime? date,
    bool force = false,
  }) async {
    final targetDate = date ?? DateTime.now();
    final now = DateTime.now();
    final isToday =
        targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    debugPrint(
      "HealthBlock: updateWeight called with $weight kg for $targetDate (force: $force)",
    );

    if (isToday) {
      if (force || weight > 0) {
        todayWeight.value = weight;
        _saveWeight(weight, date: targetDate, force: force, source: HealthSourceService.sourceManual);
      }
    } else {
      _saveWeight(weight, date: targetDate, force: force, source: HealthSourceService.sourceManual);
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
    return IDGen.generateDeterministicUuid(personId, "$dateStr:General");
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

  Future<void> _saveSteps(
    int steps, {
    DateTime? date,
    bool force = false,
    String? source,
  }) async {
    if (personId.isEmpty) {
      debugPrint("HealthBlock: Cannot save steps, personId is empty");
      return;
    }
    final targetDate = date ?? DateTime.now();
    // Normalize to noon to match DAO lookup logic exactly
    final normalizedDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      12,
    );

    debugPrint(
      "HealthBlock: Saving $steps steps to DB for $normalizedDate (force: $force)",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(targetDate),
        personID: Value(personId),
        date: normalizedDate,
        steps: Value(steps),
        source: Value(source),
      ),
      force: force,
    );
  }

  Future<void> _saveSleep(double hours, {bool force = false, String? source}) async {
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
        source: Value(source),
      ),
      force: force,
    );
  }

  Future<void> _saveWater(int ml, {bool force = false, String? source}) async {
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
        waterGlasses: Value(
          ml,
        ), // Store ml directly (SUM of water_logs.amount for the day)
        source: Value(source),
      ),
      force: force,
    );
  }

  /// Persist the SUM of exercise_logs.duration_minutes for today into
  /// health_metrics.exercise_minutes. Called by _exerciseSubscription on every
  /// stream update (i.e. whenever a new exercise log is inserted or deleted).
  /// Strong data wins: insertOrUpdateMetrics only updates when minutes > existing value.
  Future<void> _saveExercise(int minutes, {bool force = false, String? source}) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint(
      "HealthBlock: Saving $minutes exercise minutes to DB for $normalizedToday",
    );

    // Write SUM(duration_minutes) of today's exercise_logs to health_metrics.exercise_minutes.
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        exerciseMinutes: Value(
          minutes,
        ), // SUM(exercise_logs.duration_minutes) for the day
        source: Value(source),
      ),
      force: force,
    );
  }

  Future<void> _saveWeight(
    double kg, {
    DateTime? date,
    bool force = false,
    String? source,
  }) async {
    if (personId.isEmpty || personId == DataSeeder.guestPersonId) {
      debugPrint(
        "HealthBlock: ⚠️ Skipping weight save for Guest or Empty ID ($personId)",
      );
      return;
    }
    final targetDate = date ?? DateTime.now();
    final normalizedTarget = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      12,
    );

    debugPrint(
      "HealthBlock: Saving $kg kg weight to DB for $normalizedTarget (force: $force)",
    );

    // 1. Update daily summary
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(targetDate),
        personID: Value(personId),
        date: normalizedTarget,
        weightKg: Value(kg),
        source: Value(source ?? HealthSourceService.sourceGT6),
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

  Future<void> _saveHeartRate(int bpm, {bool force = false, String? source}) async {
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
        source: Value(source),
      ),
      force: force,
    );
  }

  Future<void> _saveOxygenSaturation(
    double saturation, {
    bool force = false,
    String? source,
  }) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint(
      "HealthBlock: Saving $saturation% oxygen saturation to DB for $normalizedToday",
    );
    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        oxygenSaturation: Value(saturation),
        source: Value(source),
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
    stopRealtimeSync();
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
