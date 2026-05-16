import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

/// Consecutive-calendar-day savings streak derived from local transactions.
class SavingsStreak {
  final int current;
  final int longest;
  /// Index 0 = today, index 6 = six days ago — whether any savings exist that day.
  final List<bool> last7;

  const SavingsStreak({
    required this.current,
    required this.longest,
    required this.last7,
  });
}

Set<DateTime> _savingsDaysLocal(List<TransactionData> txns) {
  final set = <DateTime>{};
  for (final t in txns) {
    if (t.type != 'savings') continue;
    final d = t.transactionDate.toLocal();
    set.add(DateTime(d.year, d.month, d.day));
  }
  return set;
}

int _currentStreakFrom(Set<DateTime> days, DateTime todayLocal) {
  if (days.isEmpty) return 0;
  final today = DateTime(todayLocal.year, todayLocal.month, todayLocal.day);
  var d = today;
  const maxLookback = 400;
  var looked = 0;
  while (!days.contains(d) && looked < maxLookback) {
    d = d.subtract(const Duration(days: 1));
    looked++;
  }
  if (!days.contains(d)) return 0;
  var streak = 0;
  while (days.contains(d)) {
    streak++;
    d = d.subtract(const Duration(days: 1));
  }
  return streak;
}

int _longestStreak(Set<DateTime> days) {
  if (days.isEmpty) return 0;
  final sorted = days.toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    if (cur.difference(prev).inDays == 1) {
      run++;
      if (run > best) best = run;
    } else if (cur != prev) {
      run = 1;
    }
  }
  return best;
}

List<bool> _last7(Set<DateTime> days, DateTime todayLocal) {
  final today = DateTime(todayLocal.year, todayLocal.month, todayLocal.day);
  return List.generate(7, (i) {
    final day = today.subtract(Duration(days: i));
    return days.contains(day);
  });
}

/// Computes streak stats from all transactions (caller passes full list for person).
SavingsStreak computeSavingsStreak(List<TransactionData> txns) {
  final days = _savingsDaysLocal(txns);
  final now = DateTime.now();
  final todayLocal = DateTime(now.year, now.month, now.day);
  return SavingsStreak(
    current: _currentStreakFrom(days, todayLocal),
    longest: _longestStreak(days),
    last7: _last7(days, todayLocal),
  );
}
