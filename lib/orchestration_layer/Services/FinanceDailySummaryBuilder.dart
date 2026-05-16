import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:intl/intl.dart';

/// Aggregated finance summary for n8n / email (same rules as the on-device daily report).
class FinanceDailySummaryBuilder {
  static bool sameCalendarDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  static Map<String, dynamic> buildPayload({
    required List<TransactionData> transactions,
    required String personId,
    required String currency,
    required String locale,
    required String recipientEmail,
    DateTime? day,
    Map<String, String>? categoryLabels,
  }) {
    final targetDay = (day ?? DateTime.now()).toLocal();
    final start = DateTime(targetDay.year, targetDay.month, targetDay.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    final dayTx = transactions
        .where((t) => sameCalendarDay(t.transactionDate, targetDay))
        .toList();

    double income = 0;
    double expense = 0;
    final Map<String, double> byCategoryKey = {};

    for (final t in dayTx) {
      switch (t.type) {
        case 'income':
          income += t.amount;
          break;
        case 'expense':
        case 'investment':
          expense += t.amount;
          byCategoryKey[t.category] =
              (byCategoryKey[t.category] ?? 0) + t.amount;
          break;
        default:
          break;
      }
    }

    final byCategory = byCategoryKey.entries
        .map(
          (e) => {
            'category': e.key,
            if (categoryLabels != null && categoryLabels[e.key] != null)
              'label': categoryLabels[e.key],
            'amount': e.value,
          },
        )
        .toList()
      ..sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );

    final periodLabel = DateFormat.yMMMEd(locale).format(start);
    final net = income - expense;

    return {
      'schema_version': 1,
      'report_type': 'finance_daily',
      'person_id': personId,
      'locale': locale,
      'currency': currency,
      // Flat keys for n8n (POST JSON is usually under $json.body.*).
      'period_label': periodLabel,
      'income': income,
      'expense': expense,
      'net': net,
      'email_to': recipientEmail,
      'period': {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'label': periodLabel,
        'utc_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
      },
      'totals': {
        'income': income,
        'expense': expense,
        'net': net,
      },
      'by_category': byCategory,
      'transaction_count': dayTx.length,
      'delivery': {
        'to': recipientEmail,
      },
    };
  }
}
