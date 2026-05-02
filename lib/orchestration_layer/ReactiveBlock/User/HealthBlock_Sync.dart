part of 'HealthBlock.dart';

extension HealthBlockSync on HealthBlock {
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
    untracked(() => isWeightLoading.value = true);
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
      untracked(() => isWeightLoading.value = false);
    }
  }

  Future<void> syncExerciseHistory() async {
    if (personId.isEmpty) return;
    untracked(() => isExerciseLoading.value = true);
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
      untracked(() => isExerciseLoading.value = false);
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
    untracked(() => isStepsLoading.value = true);
    try {
      final steps = await fetcher();
      debugPrint(
        "HealthBlock: 🔄 [SYNC] Platform returned $steps steps for today.",
      );
      updateSteps(steps, force: true);
      debugPrint("HealthBlock: ✅ [SYNC] Today's steps synced: $steps");
    } finally {
      untracked(() => isStepsLoading.value = false);
    }
  }

  Future<void> syncTodayHeartRate(Future<int> Function() fetcher) async {
    untracked(() => isHeartRateLoading.value = true);
    try {
      final bpm = await fetcher();
      if (bpm > 0) {
        updateHeartRate(bpm);

        syncHeartRateSamples(
          DateTime.now(),
        ).catchError((e) => debugPrint("Background HR sync error: $e"));
      }
    } finally {
      untracked(() => isHeartRateLoading.value = false);
    }
  }

  Future<void> syncTodayOxygenSaturation(
    Future<double> Function() fetcher,
  ) async {
    untracked(() => isOxygenLoading.value = true);
    try {
      final saturation = await fetcher();
      if (saturation > 0) {
        updateOxygenSaturation(saturation);

        syncOxygenSamples(
          DateTime.now(),
        ).catchError((e) => debugPrint("Background SpO2 sync error: $e"));
      }
    } finally {
      untracked(() => isOxygenLoading.value = false);
    }
  }

  Future<void> syncTodaySleep(Future<double> Function() fetcher) async {
    untracked(() => isSleepLoading.value = true);
    try {
      final hours = await fetcher();
      if (hours > 0) {
        updateSleep(hours);
      }
      await syncSleepSessions(DateTime.now());
    } finally {
      untracked(() => isSleepLoading.value = false);
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
    if (isSyncing.peek()) return;
    untracked(() => isSyncing.value = true);

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
      untracked(() => isSyncing.value = false);
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
}
