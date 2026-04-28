part of 'ScoreBlock.dart';

extension ScoreBlockActions on ScoreBlock {
  void _triggerHealthUpdate(
    int steps,
    int kcal,
    int water,
    int exercise,
    int focus,
    double sleep,
    List<DayWithMeal> meals,
  ) {
    _healthUpdateSubject.add(null);
  }

  void _triggerCareerUpdate(double questXP) {
    _careerUpdateSubject.add(null);
  }

  void _triggerFinanceUpdate() {
    _financeUpdateSubject.add(null);
  }

  void _triggerMindUpdate(List<ProjectNoteData> notes, double questXP) {
    _mindUpdateSubject.add(null);
  }

  void _updateFinanceScore({bool isBootstrap = false}) {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;

    Timer(Duration.zero, () {
      final accounts = _latestAccounts.value;
      final assets = _latestAssets.value;
      final txs = _latestTransactions.value;

      double accountWorth = 0;
      for (var acc in accounts) {
        accountWorth += acc.balance;
      }
      double assetWorth = 0;
      for (var asset in assets) {
        assetWorth += (asset.currentEstimatedValue ?? 0.0);
      }

      final income = txs
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = txs
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);
      final investment = txs
          .where((t) => t.type == 'investment')
          .fold(0.0, (sum, t) => sum + t.amount);
      final savings = txs
          .where((t) => t.type == 'savings')
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalNetWorth =
          accountWorth + assetWorth + (income + savings - expense - investment);

      double finalScore = 0;
      if (FINANCE_NET_WORTH_PER_POINT > 0) {
        finalScore = totalNetWorth / FINANCE_NET_WORTH_PER_POINT;
      }

      final questXP = _totalFinanceQuestPoints.value;
      finalScore += questXP;

      _dao.updateFinancialScore(_personID, finalScore, tenantId: _tenantID);
    });
  }

  Future<void> _updateMindScore({
    bool isBootstrap = false,
  }) async {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;

    final notes = _latestNotes.value;
    final questXP = _totalSocialQuestPoints.value;

    Timer(Duration.zero, () async {
      await _dao.updateMindScore(
        _personID,
        strategyNoteCount: notes.length,
        questXP: questXP,
        tenantId: _tenantID,
      );
    });
  }

  Future<void> _updateHealthScore({
    bool isBootstrap = false,
  }) async {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;

    final totalSteps = _healthBlock.totalSteps.value;
    final waterIntake = _healthBlock.todayWater.value;
    final exerciseMinutes = _healthBlock.todayExerciseMinutes.value;
    final focusMinutes = _healthBlock.todayFocusMinutes.value;
    final sleepHours = _healthBlock.todaySleep.value;
    final meals = _latestMeals.value;

    Timer(Duration.zero, () async {
      double stepsPoints = 0;
      if (STEPS_PER_POINT > 0) stepsPoints = (totalSteps / STEPS_PER_POINT);

      double dietPoints = 0;
      final todayDate = DateTime.now();
      double todayKcal = 0;
      for (var item in meals) {
        final d = item.meal.eatenAt;
        if (d.year == todayDate.year &&
            d.month == todayDate.month &&
            d.day == todayDate.day) {
          todayKcal += item.meal.calories;
        }
      }
      if (todayKcal > 0 && todayKcal < CALORIE_LIMIT) {
        dietPoints += CALORIE_LIMIT_BONUS;
      }

      double exercisePoints = 0;
      if (EXERCISE_PER_POINT > 0) {
        exercisePoints = (exerciseMinutes / EXERCISE_PER_POINT);
      }

      double focusPoints = 0;
      if (FOCUS_MINUTES_PER_POINT > 0) {
        focusPoints = (focusMinutes / FOCUS_MINUTES_PER_POINT);
      }

      double waterPoints = 0;
      if (waterIntake >= WATER_GOAL) waterPoints += WATER_BONUS_POINTS;

      double sleepPoints = (sleepHours * SLEEP_POINTS_PER_HOUR);

      final baseHealthScore =
          stepsPoints +
          dietPoints +
          exercisePoints +
          focusPoints +
          waterPoints +
          sleepPoints;
      final questXP = _totalHealthQuestPoints.value;
      final historicalXP = _historicalHealthMetricPoints.value;
      final finalScore = baseHealthScore + questXP + historicalXP;

      await _dao.updateHealthScore(_personID, finalScore, tenantId: _tenantID);
    });
  }

  Future<void> _updateCareerScore({
    bool isBootstrap = false,
  }) async {
    if (!isBootstrap && !isReady.value) return;
    if (_personID.isEmpty) return;

    final questXP = _totalProjectQuestPoints.value;

    Timer(Duration.zero, () async {
      await _dao.updateCareerScore(_personID, questXP, tenantId: _tenantID);
    });
  }

  // Action Methods
  Future<void> manualSocialIncrement(double amount) async {
    final now = DateTime.now();
    await _dao.incrementScore(_personID, now, amount, 'social', _tenantID);
  }

  Future<void> manualMindIncrement(double points, {String? label}) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementSocialQuestPoints(
      _personID,
      points,
      category: label ?? 'Mind',
      tenantId: _tenantID,
    );
  }

  Future<void> persistentCareerIncrement(double points, {String? label}) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementProjectQuestPoints(
      _personID,
      points,
      category: label ?? (points >= 50.0 ? 'Projects' : 'Tasks'),
      tenantId: _tenantID,
    );
  }

  Future<void> persistentHealthIncrement(double points, {String? label}) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementHealthQuestPoints(
      _personID,
      points,
      category: label ?? 'Quests',
      tenantId: _tenantID,
    );
  }

  Future<void> persistentFinanceIncrement(
    double points, {
    String? label,
  }) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementFinancialQuestPoints(
      _personID,
      points,
      category: label ?? 'General',
      tenantId: _tenantID,
    );
  }

  Future<void> trackAppUsage(
    double minutes, {
    required String sector,
    String? pagePath,
  }) async {
    if (!isReady.value || _personID.isEmpty) return;
    await _metricsDAO.incrementAppUsage(
      _personID,
      minutes,
      sector: sector,
      pagePath: pagePath,
    );
  }

  void addPoints(double points, {String? label}) {
    persistentCareerIncrement(points, label: label);
  }
}
