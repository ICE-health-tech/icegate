part of 'HealthBlock.dart';

extension HealthBlockActions on HealthBlock {
  void updateSteps(int steps, {DateTime? date, bool force = false}) {
    final day = date ?? DateTime.now();
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    if (isToday) {
      untracked(() => todaySteps.value = steps);
    }

    _saveSteps(
      steps,
      date: day,
      force: force,
      source: HealthSourceService.sourceAppleHealth,
    );
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
    untracked(() => hourlySteps.value = currentMap);
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
    untracked(() => todaySleep.value = hours);
    _saveSleep(hours, source: HealthSourceService.sourceAppleHealth);
  }

  void updateHeartRate(int bpm) {
    if (bpm > 0) {
      untracked(() => todayHeartRate.value = bpm);
      _saveHeartRate(bpm, source: HealthSourceService.sourceAppleHealth);
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

  void updateOxygenSaturation(double saturation) {
    if (saturation > 0) {
      untracked(() => todayOxygenSaturation.value = saturation);
      _saveOxygenSaturation(
        saturation,
        source: HealthSourceService.sourceAppleHealth,
      );
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
        untracked(() => todayWeight.value = weight);
        _saveWeight(
          weight,
          date: targetDate,
          force: force,
          source: HealthSourceService.sourceManual,
        );
      }
    } else {
      _saveWeight(
        weight,
        date: targetDate,
        force: force,
        source: HealthSourceService.sourceManual,
      );
    }
  }

  void updateCalories(int calories) {
    debugPrint(
      "HealthBlock: updateCalories called with $calories kcal (current: ${todayCaloriesBurned.value})",
    );
    if (calories > todayCaloriesBurned.value) {
      untracked(() => todayCaloriesBurned.value = calories);
      _saveCaloriesBurned(calories);
    }
  }

  String _getDeterministicId(DateTime date) {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return IDGen.generateDeterministicUuid(personId, "$dateStr:General");
  }

  /// Call before saving a **manual edit** to an existing meal so [health_metrics] stays local only.
  void skipCloudSyncForNextMealDerivedMetrics([int n = 1]) {
    if (n <= 0) return;
    _mealDerivedMetricsCloudSkipCount += n;
  }

  Future<void> _saveCaloriesConsumed(
    int calories, {
    bool force = false,
    bool pushToCloud = true,
  }) async {
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
      pushToCloud: pushToCloud,
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

  Future<void> _saveSleep(
    double hours, {
    bool force = false,
    String? source,
  }) async {
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

    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        waterGlasses: Value(ml),
        source: Value(source),
      ),
      force: force,
    );
  }

  Future<void> _saveExercise(
    int minutes, {
    bool force = false,
    String? source,
  }) async {
    if (personId.isEmpty) return;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day, 12);

    debugPrint(
      "HealthBlock: Saving $minutes exercise minutes to DB for $normalizedToday",
    );

    await _healthDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: _getDeterministicId(today),
        personID: Value(personId),
        date: normalizedToday,
        exerciseMinutes: Value(minutes),
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

    await _healthLogsDao.insertWeightLog(
      WeightLogsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: Value(personId),
        weightKg: Value(kg),
        timestamp: Value(targetDate),
      ),
    );
  }

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

  Future<void> deleteWaterLog(String id) async {
    if (personId.isEmpty) return;
    await _healthLogsDao.deleteWaterLog(id);
  }

  Future<void> _saveHeartRate(
    int bpm, {
    bool force = false,
    String? source,
  }) async {
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
    untracked(() => dailyExerciseGoal.value = minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('exercise_goal', minutes);
  }

  int estimateCalories(String type, int minutes, String intensity) {
    if (minutes <= 0) return 0;
    final weight = todayWeight.value > 0 ? todayWeight.value : 70.0;
    double met = 3.0;
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
    return ((met * 3.5 * weight) / 200 * minutes).round();
  }
}
