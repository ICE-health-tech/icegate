part of 'HealthBlock.dart';

extension HealthBlockInit on HealthBlock {
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

    // Paint today's pillar card from Drift immediately (avoid 0 → real flash).
    unawaited(_hydrateTodayFromLocal());

    _healthDao.cleanupDuplicates(personId).then((_) {
      if (_initializedPersonId != personId) {
        return;
      }

      _metricsSubscription = _healthDao
          .watchAllMetrics(personId)
          .debounceTime(const Duration(milliseconds: 120))
          .listen(
            (metrics) {
              Timer(Duration.zero, () {
                untracked(() {
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
                      if ((m.caloriesConsumed ?? 0) >
                          foundTodayCaloriesConsumed) {
                        foundTodayCaloriesConsumed = m.caloriesConsumed ?? 0;
                      }
                      if ((m.weightKg ?? 0.0) > 0) {
                        todayWeight.value = m.weightKg ?? 0.0;
                      }
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

                    final thirtyDaysAgo = today.subtract(
                      const Duration(days: 30),
                    );
                    if (m.date.isAfter(thirtyDaysAgo)) {
                      if ((m.weightKg ?? 0) > 0) {
                        weightHistory[dateStr] = m.weightKg!;
                      }
                      if ((m.waterGlasses ?? 0) > 0) {
                        waterHistory[dateStr] = m.waterGlasses!;
                      }
                    }
                  }

                  batch(() {
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
                    if (foundTodayOxygenSaturation >
                        todayOxygenSaturation.value) {
                      todayOxygenSaturation.value = foundTodayOxygenSaturation;
                    }
                    if (foundTodayCaloriesBurned > todayCaloriesBurned.value) {
                      todayCaloriesBurned.value = foundTodayCaloriesBurned;
                    }
                    if (foundTodayCaloriesConsumed >
                        todayCaloriesConsumed.value) {
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
                  });

                  final yesterdayVal = stepsLast7Days[yesterdayStr] ?? 0;
                  debugPrint(
                    "📊 [HealthBlock] UI Update - Today: ${todaySteps.value}, Yesterday ($yesterdayStr): $yesterdayVal, Historical Total: $totalHistorical",
                  );
                });
              });
            },
            onError: (e) =>
                debugPrint("HealthBlock: Error watching health metrics: $e"),
          );

      _hourlyLogsSubscription = _hourlyLogDao
          .watchHourlyLogs(personId, DateTime.now())
          .debounceTime(const Duration(milliseconds: 120))
          .listen(
            (logs) {
              Timer(Duration.zero, () {
                untracked(() {
                  final Map<int, int> hourlyMap = {
                    for (var i = 0; i < 24; i++) i: 0,
                  };
                  for (var log in logs) {
                    final hour = log.startTime.hour;
                    hourlyMap[hour] = ((hourlyMap[hour] ?? 0) + log.stepsCount)
                        .toInt();
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
                });
              });
            },
            onError: (e) =>
                debugPrint("HealthBlock: Error watching hourly logs: $e"),
          );
    });

    _waterSubscription = _healthLogsDao
        .watchDailyWaterLogs(personId, DateTime.now())
        .debounceTime(const Duration(milliseconds: 400))
        .listen(
          (logs) {
            Timer(Duration.zero, () {
              untracked(() {
                final totalMl = logs.fold<int>(
                  0,
                  (sum, log) => sum + log.amount,
                );
                if (totalMl == todayWater.value) return;
                todayWater.value = totalMl;
                _saveWater(
                  totalMl,
                  source: HealthSourceService.sourceManual,
                );
              });
            });
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching water logs: $e"),
        );

    _mealSubscription = _healthMealDao
        .watchDailyCalories(personId, DateTime.now())
        .debounceTime(const Duration(milliseconds: 400))
        .listen(
          (cals) {
            Timer(Duration.zero, () {
              untracked(() {
                final kcal = cals.toInt();
                if (kcal == todayCaloriesConsumed.value) return;
                todayCaloriesConsumed.value = kcal;
                final pushCloud = _mealDerivedMetricsCloudSkipCount == 0;
                if (!pushCloud) {
                  _mealDerivedMetricsCloudSkipCount--;
                }
                _saveCaloriesConsumed(
                  kcal,
                  pushToCloud: pushCloud,
                );
              });
            });
          },

          onError: (e) =>
              debugPrint("HealthBlock: Error watching meal calories: $e"),
        );

    _exerciseSubscription = _healthLogsDao
        .watchDailyExerciseLogs(personId, DateTime.now())
        .debounceTime(const Duration(milliseconds: 400))
        .listen(
          (logs) {
            Timer(Duration.zero, () {
              untracked(() {
                final totalMinutes = logs.fold<int>(
                  0,
                  (sum, log) => sum + log.durationMinutes,
                );
                if (totalMinutes == todayExerciseMinutes.value) return;
                todayExerciseMinutes.value = totalMinutes;
                _saveExercise(
                  totalMinutes,
                  source: HealthSourceService.sourceGT6,
                );
              });
            });
          },
          onError: (e) =>
              debugPrint("HealthBlock: Error watching exercise logs: $e"),
        );

    _weightSubscription = _healthLogsDao.watchLatestWeightLog(personId).listen(
      (log) {
        Timer(Duration.zero, () {
          untracked(() {
            if (log != null) {
              latestWeight.value = log.weightKg;
            } else {
              latestWeight.value = 0.0;
            }
          });
        });
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
          debugPrint(
            "HealthBlock: ⚠️ Silent sync oxygen saturation failed: $e",
          );
        });

    syncTodaySleep(() => HealthService.fetchSleepData())
        .then((_) {
          debugPrint("HealthBlock: 🔄 Silent sync of sleep data completed.");
        })
        .catchError((e) {
          debugPrint("HealthBlock: ⚠️ Silent sync sleep data failed: $e");
        });

    syncTodayWeight(() => HealthService.fetchLatestWeight())
        .then((_) {
          debugPrint("HealthBlock: 🔄 Silent sync of weight completed.");
        })
        .catchError((e) {
          debugPrint("HealthBlock: ⚠️ Silent sync weight failed: $e");
        });

    syncWeightHistory(HealthService.fetchWeightForDay).catchError((e) {
      debugPrint("HealthBlock: ⚠️ Weight history sync failed: $e");
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
      untracked(() {
        dailyStepGoal.value = prefs.getInt('dailyStepGoal') ?? 10000;
        dailyKcalGoal.value = prefs.getInt('dailyKcalGoal') ?? 2500;
        dailyWaterGoal.value = prefs.getInt('dailyWaterGoal') ?? 2000;
        dailyFocusGoal.value = prefs.getInt('dailyFocusGoal') ?? 60;
        dailyExerciseGoal.value = prefs.getInt('dailyExerciseGoal') ?? 30;
        dailySleepGoal.value = prefs.getDouble('dailySleepGoal') ?? 8.0;
      });
      debugPrint("HealthBlock: 🎯 Goals loaded from SharedPreferences");
    } catch (e) {
      debugPrint("HealthBlock: Error loading goals: $e");
    }
  }

  Future<void> _hydrateTodayFromLocal() async {
    final pid = personId;
    if (pid.isEmpty) return;

    try {
      final row = await _healthDao.getMetricsForDate(pid, DateTime.now());
      if (row == null || _initializedPersonId != pid) return;

      untracked(() {
        batch(() {
          final steps = row.steps ?? 0;
          if (steps > todaySteps.value) todaySteps.value = steps;
          final sleep = row.sleepHours ?? 0.0;
          if (sleep > todaySleep.value) todaySleep.value = sleep;
          final hr = row.heartRate ?? 0;
          if (hr > todayHeartRate.value) todayHeartRate.value = hr;
          final burned = row.caloriesBurned ?? 0;
          if (burned > todayCaloriesBurned.value) {
            todayCaloriesBurned.value = burned;
          }
          final consumed = row.caloriesConsumed ?? 0;
          if (consumed > todayCaloriesConsumed.value) {
            todayCaloriesConsumed.value = consumed;
          }
          final weight = row.weightKg ?? 0.0;
          if (weight > 0) {
            todayWeight.value = weight;
            latestWeight.value = weight;
          }
          final exercise = row.exerciseMinutes ?? 0;
          if (exercise > todayExerciseMinutes.value) {
            todayExerciseMinutes.value = exercise;
          }
          final focus = row.focusMinutes ?? 0;
          if (focus > todayFocusMinutes.value) {
            todayFocusMinutes.value = focus;
          }
          hasInitialSync.value = true;
        });
      });
    } catch (e) {
      debugPrint('HealthBlock: hydrate today failed: $e');
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
