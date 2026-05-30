import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/TransactionCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/widgets/AppSessionCalendar.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Daily spending & income log with calendar (chi tiêu / vui trong ngày).
class FinanceDailyPage extends StatefulWidget {
  final FinanceBlock financeBlock;

  const FinanceDailyPage({super.key, required this.financeBlock});

  @override
  State<FinanceDailyPage> createState() => _FinanceDailyPageState();
}

class _FinanceDailyPageState extends State<FinanceDailyPage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = _dateOnly(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd(l10n.localeName);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Watch((context) {
      final txns = widget.financeBlock.transactions.value;
      final marked =
          txns.map((t) => _dateOnly(t.transactionDate.toLocal())).toSet();

      final onDay = txns
          .where((t) => _dateOnly(t.transactionDate.toLocal()) == _selectedDay)
          .toList()
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      final dayIncome = onDay
          .where((t) => t.type == 'income' || t.type == 'savings')
          .fold(0.0, (s, t) => s + t.amount);
      final daySpend = onDay
          .where((t) => t.type == 'expense' || t.type == 'investment')
          .fold(0.0, (s, t) => s + t.amount);

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.finance_tab_daily_subtitle,
              style: TextStyle(
                color: FinanceSurface.mutedInk(isDark: isDark),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            AppSessionCalendar(
              markedDays: marked,
              focusedMonth: _focusedMonth,
              selectedDay: _selectedDay,
              accentColor: FinanceSurface.ink(isDark: isDark),
              outerDecoration: FinanceSurface.panel(cs, isDark: isDark, radius: 20),
              onMonthChanged: (m) =>
                  setState(() => _focusedMonth = DateTime(m.year, m.month)),
              onDaySelected: (d) => setState(() {
                _selectedDay = _dateOnly(d);
                _focusedMonth = DateTime(d.year, d.month);
              }),
            ),
            const SizedBox(height: 16),
            Text(
              dateFmt.format(_selectedDay).toUpperCase(),
              style: TextStyle(
                color: FinanceSurface.ink(isDark: isDark),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dayStat(
                    isDark: isDark,
                    cs: cs,
                    label: l10n.finance_daily_in,
                    value: widget.financeBlock.formatCurrency(
                      dayIncome,
                      compact: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dayStat(
                    isDark: isDark,
                    cs: cs,
                    label: l10n.finance_daily_out,
                    value: widget.financeBlock.formatCurrency(
                      daySpend,
                      compact: true,
                    ),
                    muted: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (onDay.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    l10n.finance_daily_empty,
                    style: TextStyle(
                      color: FinanceSurface.mutedInk(isDark: isDark),
                    ),
                  ),
                ),
              )
            else
              ...onDay.map(
                (txn) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TransactionCard(txn: txn, block: widget.financeBlock),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _dayStat({
    required bool isDark,
    required ColorScheme cs,
    required String label,
    required String value,
    bool muted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: FinanceSurface.mutedInk(isDark: isDark),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: muted
                  ? FinanceSurface.mutedInk(isDark: isDark)
                  : FinanceSurface.ink(isDark: isDark),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }
}
