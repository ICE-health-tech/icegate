part of 'ScoreBlock.dart';

extension ScoreBlockActions on ScoreBlock {
  // Score calculation methods removed as per XP removal request

  // Action Methods

  Future<void> trackAppUsage(
    double minutes, {
    required String sector,
    String? pagePath,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (!isReady.value || _personID.isEmpty) return;
    
    // 1. Daily aggregate in app_usage_history
    await _metricsDAO.incrementAppUsage(
      _personID,
      minutes,
      sector: sector,
      pagePath: pagePath,
    );

    // 2. Granular session log in app_time_spending
    if (startTime != null && endTime != null) {
      await _metricsDAO.logAppSpending(
        personId: _personID,
        startTime: startTime,
        endTime: endTime,
        sector: sector,
        pagePath: pagePath,
      );
    }
  }


  Future<double> getTodaySpending() async {
    if (!isReady.value || _personID.isEmpty) return 0.0;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await _metricsDAO.getPeriodSpendingMinutes(
      _personID,
      start: startOfDay,
      end: endOfDay,
    );
  }
}
