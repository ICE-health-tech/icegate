part of 'ScoreBlock.dart';

extension ScoreBlockInit on ScoreBlock {
  Future<void> init(
    ScoreDAO dao,
    PersonManagementDAO personDAO,
    FinanceDAO financeDAO,
    HealthBlock healthBlock,
    HealthMealDAO mealDAO,
    MetricsDAO metricsDAO,
    ProjectNoteDAO noteDAO,
    String personID, {
    String? tenantID,
  }) async {
    if (personID.isEmpty) return;

    if (_initializedPersonID == personID) {
      debugPrint("ScoreBlock: ℹ️ Already initialized for $personID");
      return;
    }

    isReady.value = false;
    debugPrint("ScoreBlock: 🚀 Initializing for personID: $personID");
    _initializedPersonID = personID;

    // Clear old subscriptions
    for (var s in _subscriptions) {
      if (s is StreamSubscription) {
        s.cancel();
      } else if (s is void Function()) {
        s();
      }
    }
    _subscriptions.clear();

    _dao = dao;
    _financeDAO = financeDAO;
    _personID = personID;
    _healthBlock = healthBlock;
    _metricsDAO = metricsDAO;
    _tenantID = tenantID;

    // 0. Setup RxDart Subject Listeners for debounced side-effects
    _subscriptions.add(
      _healthUpdateSubject
          .debounceTime(const Duration(milliseconds: 500))
          .listen((_) => _updateHealthScore()),
    );
    _subscriptions.add(
      _careerUpdateSubject
          .debounceTime(const Duration(milliseconds: 500))
          .listen((_) => _updateCareerScore()),
    );
    _subscriptions.add(
      _financeUpdateSubject
          .debounceTime(const Duration(milliseconds: 500))
          .listen((_) => _updateFinanceScore()),
    );
    _subscriptions.add(
      _mindUpdateSubject
          .debounceTime(const Duration(milliseconds: 500))
          .listen((_) => _updateMindScore()),
    );

    _subscriptions.add(
      _dao
          .watchScoreByPersonID(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((data) {
            if (data != null) {
              _scoreUpdateTimer?.cancel();
              _scoreUpdateTimer = Timer(const Duration(milliseconds: 100), () {
                updateScore(
                  ScoreData(
                    healthGlobalScore: data.healthGlobalScore ?? 0.0,
                    socialGlobalScore: data.socialGlobalScore ?? 0.0,
                    financialGlobalScore: data.financialGlobalScore ?? 0.0,
                    careerGlobalScore: data.careerGlobalScore ?? 0.0,
                  ),
                );
              });
            }
          }),
    );

    // 1. Total Point Watchers
    _subscriptions.add(
      _metricsDAO
          .watchTotalHealthQuestPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => _totalHealthQuestPoints.value = pts),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTotalSocialQuestPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => _totalSocialQuestPoints.value = pts),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTotalProjectQuestPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => _totalProjectQuestPoints.value = pts),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTotalFinancialQuestPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => _totalFinanceQuestPoints.value = pts),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchHistoricalHealthMetricPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => _historicalHealthMetricPoints.value = pts),
            );
          }),
    );

    // Today's Points Watchers
    _subscriptions.add(
      _metricsDAO
          .watchTodayHealthQuestPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => todayHealthPoints.value = pts),
            );
          }),
    );

    _subscriptions.add(
      _metricsDAO.watchTodaySocialQuestPoints(personID).distinct().listen((
        pts,
      ) {
        // Use batch to ensure the signal update is atomic and safe
        batch(() {
          todaySocialPoints.value = pts;
        });
      }),
    );

    _subscriptions.add(
      _metricsDAO
          .watchTodayProjectQuestPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => todayProjectPoints.value = pts),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchTodayFinancialQuestPoints(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((pts) {
            Timer(
              Duration.zero,
              () => untracked(() => todayFinancePoints.value = pts),
            );
          }),
    );

    // 2. Breakdown Watchers
    _subscriptions.add(
      _metricsDAO
          .watchProjectBreakdown(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((data) {
            Timer(
              Duration.zero,
              () => untracked(() => projectsBreakdown.value = data),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchHealthBreakdown(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((data) {
            Timer(
              Duration.zero,
              () => untracked(() => healthBreakdown.value = data),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchSocialBreakdown(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((data) {
            Timer(
              Duration.zero,
              () => untracked(() => socialBreakdown.value = data),
            );
          }),
    );
    _subscriptions.add(
      _metricsDAO
          .watchFinancialBreakdown(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((data) {
            Timer(
              Duration.zero,
              () => untracked(() => financeBreakdown.value = data),
            );
          }),
    );

    _subscriptions.add(
      financeDAO
          .watchAccounts(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((accounts) {
            Timer(Duration.zero, () {
              untracked(() {
                batch(() {
                  _latestAccounts.value = accounts;
                  _triggerFinanceUpdate();
                });
              });
            });
          }),
    );
    _subscriptions.add(
      financeDAO
          .watchAssets(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((assets) {
            Timer(Duration.zero, () {
              untracked(() {
                batch(() {
                  _latestAssets.value = assets;
                  _triggerFinanceUpdate();
                });
              });
            });
          }),
    );
    _subscriptions.add(
      financeDAO
          .watchAllTransactions(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((txs) {
            Timer(Duration.zero, () {
              untracked(() {
                batch(() {
                  _latestTransactions.value = txs;
                  _triggerFinanceUpdate();
                });
              });
            });
          }),
    );
    _subscriptions.add(
      noteDAO
          .watchAllNotes(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((notes) {
            Timer(
              Duration.zero,
              () => untracked(() => _latestNotes.value = notes),
            );
          }),
    );
    _subscriptions.add(
      mealDAO
          .watchDaysWithMeals(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((meals) {
            Timer(
              Duration.zero,
              () => untracked(() => _latestMeals.value = meals),
            );
          }),
    );

    _subscriptions.add(
      _metricsDAO
          .watchLastNDaysUsage(personID, 3)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((data) {
            Timer(
              Duration.zero,
              () => untracked(() => usageHistory.value = data),
            );
          }),
    );

    // 4. Reactive Effects
    _subscriptions.add(
      effect(() {
        // Track dependencies
        final ready = isReady.value;
        final healthSync = _healthBlock.hasInitialSync.value;
        if (!ready || !healthSync) return;

        // Metric dependencies
        final steps = _healthBlock.totalSteps.value;
        final kcal = _healthBlock.todayCaloriesBurned.value;
        final water = _healthBlock.todayWater.value;
        final exercise = _healthBlock.todayExerciseMinutes.value;
        final focus = _healthBlock.todayFocusMinutes.value;
        final sleep = _healthBlock.todaySleep.value;
        final meals = _latestMeals.value;

        untracked(() {
          _triggerHealthUpdate(
            steps,
            kcal,
            water,
            exercise,
            focus,
            sleep,
            meals,
          );
        });
      }),
    );

    _subscriptions.add(
      effect(() {
        final ready = isReady.value;
        final pts = _totalProjectQuestPoints.value;
        if (!ready) return;

        untracked(() {
          _triggerCareerUpdate(pts);
        });
      }),
    );

    _subscriptions.add(
      effect(() {
        final ready = isReady.value;
        final notes = _latestNotes.value;
        final pts = _totalSocialQuestPoints.value;
        if (!ready) return;

        untracked(() {
          _triggerMindUpdate(notes, pts);
        });
      }),
    );

    // 5. Initial Bootstrapping
    Timer(Duration.zero, () async {
      try {
        final accounts = await _financeDAO
            .watchAccounts(_personID)
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
        untracked(() => _latestAccounts.value = accounts);

        final assets = await _financeDAO
            .watchAssets(_personID)
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
        untracked(() => _latestAssets.value = assets);

        final txs = await _financeDAO
            .watchAllTransactions(_personID)
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
        untracked(() => _latestTransactions.value = txs);

        _updateFinanceScore(isBootstrap: true);

        await noteDAO
            .watchAllNotes(_personID)
            .first
            .timeout(const Duration(seconds: 2), onTimeout: () => []);
        _updateMindScore(isBootstrap: true);

        await _updateCareerScore(isBootstrap: true);

        await _metricsDAO.cleanupGenesisRecords(_personID);
        untracked(() => isReady.value = true);
        debugPrint("ScoreBlock: ✅ Initialization complete.");
      } catch (e) {
        debugPrint("ScoreBlock: Error during bootstrap: $e");
      }
    });
  }
}
