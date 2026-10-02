part of 'ScoreBlock.dart';

extension ScoreBlockInit on ScoreBlock {
  void _deferStreamUpdate(int epoch, void Function() apply) {
    scheduleMicrotask(() {
      if (epoch != _streamEpoch) return;
      untracked(apply);
    });
  }

  Future<void> init(
    ScoreDAO dao,
    FinanceDAO financeDAO,
    HealthMealDAO mealDAO,
    MetricsDAO metricsDAO,
    ProjectNoteDAO noteDAO,
    String personID,
  ) async {
    if (personID.isEmpty) return;

    if (_initializedPersonID == personID) {
      debugPrint("ScoreBlock: ℹ️ Already initialized for $personID");
      return;
    }

    isReady.value = false;
    debugPrint("ScoreBlock: 🚀 Initializing for personID: $personID");
    _initializedPersonID = personID;
    _streamEpoch++;
    final epoch = _streamEpoch;
    _scoreUpdateTimer?.cancel();
    _todaySocialUpdateTimer?.cancel();

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
    _metricsDAO = metricsDAO;

    // Score update listeners removed as per XP removal request

    _subscriptions.add(
      _dao
          .watchScoreByPersonID(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((data) {
            if (data != null) {
              _scoreUpdateTimer?.cancel();
              final e = epoch;
              _scoreUpdateTimer = Timer(const Duration(milliseconds: 100), () {
                if (e != _streamEpoch) return;
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


    _subscriptions.add(
      financeDAO
          .watchAccounts(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((accounts) {
            _deferStreamUpdate(epoch, () => _latestAccounts.value = accounts);
          }),
    );
    _subscriptions.add(
      financeDAO
          .watchAssets(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((assets) {
            _deferStreamUpdate(epoch, () => _latestAssets.value = assets);
          }),
    );
    _subscriptions.add(
      financeDAO
          .watchAllTransactions(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((txs) {
            _deferStreamUpdate(epoch, () => _latestTransactions.value = txs);
          }),
    );
    _subscriptions.add(
      noteDAO
          .watchAllNotes(personID)
          .debounceTime(const Duration(milliseconds: 500))
          .listen((notes) {
            _deferStreamUpdate(epoch, () => _latestNotes.value = notes);
          }),
    );
    _subscriptions.add(
      mealDAO
          .watchDaysWithMeals(personID)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((meals) {
            _deferStreamUpdate(epoch, () => _latestMeals.value = meals);
          }),
    );

    _subscriptions.add(
      _metricsDAO
          .watchLastNDaysUsage(personID, 90)
          .debounceTime(const Duration(milliseconds: 300))
          .listen((data) {
            _deferStreamUpdate(epoch, () => usageHistory.value = data);
          }),
    );

    // Effects removed as per XP removal request

    // 5. Initial Bootstrapping
    try {
      // 5.1 Fetch Financial Data
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

      // 5.2 Fetch Historic Data (Quest Points removed)
      final notes = await noteDAO
          .watchAllNotes(_personID)
          .first
          .timeout(const Duration(seconds: 2), onTimeout: () => []);
      untracked(() => _latestNotes.value = notes);

      final meals = await mealDAO
          .watchDaysWithMeals(_personID)
          .first
          .timeout(const Duration(seconds: 2), onTimeout: () => []);
      untracked(() => _latestMeals.value = meals);

      // Initial score updates removed as per XP removal request

      // 5.4 Cleanup & Finalize
      await _metricsDAO.cleanupGenesisRecords(_personID);
      untracked(() => isReady.value = true);
      debugPrint("ScoreBlock: ✅ Initialization complete.");
    } catch (e) {
      debugPrint("ScoreBlock: Error during bootstrap: $e");
      // Still set ready to true to allow UI to show, or handle error state
      untracked(() => isReady.value = true);
    }
  }
}
