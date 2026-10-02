import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/finance_form/AddAccountDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceEntryInsightPanel.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Finance health alerts — net worth trend + spending breakdown as alert cards.
class FinanceAlertPanel extends StatelessWidget {
  const FinanceAlertPanel({super.key, required this.financeBlock});

  final FinanceBlock financeBlock;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final txns = financeBlock.transactions.value;
      final currentTotal = financeBlock.totalBalance.value;
      final categories = financeBlock.spendingByCategory.value;
      final accounts = financeBlock.accounts.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'FINANCE ALERTS'),
          const SizedBox(height: 16),
          _netWorthAlertCard(
            context,
            txns: txns,
            currentTotal: currentTotal,
            hasAccounts: accounts.isNotEmpty,
          ),
          const SizedBox(height: 16),
          _breakdownAlertCard(
            context,
            categories: categories,
            monthlySpending: financeBlock.monthlySpending.value,
          ),
          if (financeBlock.budgetUsagePercent.value >= 80) ...[
            const SizedBox(height: 16),
            _budgetAlertCard(context),
          ],
        ],
      );
    });
  }

  Widget _sectionTitle(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  _FinanceAlertMeta _netWorthMeta({
    required double currentTotal,
    required bool hasAccounts,
    required List<double> chartData,
  }) {
    if (!hasAccounts && currentTotal <= 0) {
      return const _FinanceAlertMeta(
        tone: FinanceInsightTone.risk,
        badge: 'ACTION',
        message: 'No accounts linked — add a wallet or bank account to track net worth.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    if (chartData.length > 1) {
      final first = chartData.first;
      final last = chartData.last;
      if (last < first * 0.95) {
        final drop = first == 0 ? 0.0 : ((first - last) / first * 100);
        return _FinanceAlertMeta(
          tone: FinanceInsightTone.caution,
          badge: 'WARNING',
          message:
              'Net worth dipped ~${drop.toStringAsFixed(0)}% in recent activity.',
          icon: Icons.trending_down_rounded,
        );
      }
      if (last > first * 1.02) {
        return const _FinanceAlertMeta(
          tone: FinanceInsightTone.positive,
          badge: 'STABLE',
          message: 'Net worth is trending up from recent transactions.',
          icon: Icons.trending_up_rounded,
        );
      }
    }
    return const _FinanceAlertMeta(
      tone: FinanceInsightTone.neutral,
      badge: 'MONITOR',
      message: 'Net worth is flat — keep logging income and expenses.',
      icon: Icons.show_chart_rounded,
    );
  }

  _FinanceAlertMeta _breakdownMeta({
    required Map<String, double> categories,
    required double monthlySpending,
  }) {
    if (categories.isEmpty || monthlySpending <= 0) {
      return const _FinanceAlertMeta(
        tone: FinanceInsightTone.caution,
        badge: 'ACTION',
        message: 'No spending logged this month — add expenses to unlock breakdown alerts.',
        icon: Icons.pie_chart_outline_rounded,
      );
    }

    final top = categories.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final share = top.value / monthlySpending;
    if (share >= 0.55) {
      final pct = (share * 100).toStringAsFixed(0);
      return _FinanceAlertMeta(
        tone: FinanceInsightTone.caution,
        badge: 'WARNING',
        message: '$pct% of spending is ${top.key} — review if this is intentional.',
        icon: Icons.warning_amber_rounded,
      );
    }
    return const _FinanceAlertMeta(
      tone: FinanceInsightTone.positive,
      badge: 'OK',
      message: 'Spending is spread across categories — no single bucket dominates.',
      icon: Icons.check_circle_outline_rounded,
    );
  }

  List<double> _netWorthHistory(List<TransactionData> txns, double currentTotal) {
    final history = <double>[currentTotal];
    var running = currentTotal;
    for (var i = 0; i < txns.length && i < 15; i++) {
      final t = txns[i];
      if (t.type == 'income' || t.type == 'savings') {
        running -= t.amount;
      } else {
        running += t.amount;
      }
      history.add(running);
    }
    return history.reversed.toList();
  }

  Widget _netWorthAlertCard(
    BuildContext context, {
    required List<TransactionData> txns,
    required double currentTotal,
    required bool hasAccounts,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dense = MediaQuery.sizeOf(context).width >= 900;
    final chartData = _netWorthHistory(txns, currentTotal);
    final meta = _netWorthMeta(
      currentTotal: currentTotal,
      hasAccounts: hasAccounts,
      chartData: chartData,
    );
    final accent = _accentFor(meta.tone);
    final pad = dense ? 18.0 : 20.0;
    final chartH = dense ? 110.0 : 130.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: !hasAccounts ? () => AddAccountDialog.show(context) : null,
        borderRadius: BorderRadius.circular(dense ? 26 : 28),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(pad),
          decoration: _alertDecoration(cs, isDark, accent, dense ? 26 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _alertBanner(context, meta: meta, accent: accent),
              const SizedBox(height: 14),
              Text(
                'NET WORTH TREND',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                financeBlock.formatCurrency(currentTotal),
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: dense ? 26 : 30,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: dense ? 14 : 18),
              if (chartData.length > 1)
                SimpleLineChart(
                  data: chartData,
                  color: accent,
                  height: chartH,
                )
              else
                SizedBox(
                  height: chartH,
                  child: Center(
                    child: Text(
                      'Need more data for trend',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breakdownAlertCard(
    BuildContext context, {
    required Map<String, double> categories,
    required double monthlySpending,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final meta = _breakdownMeta(
      categories: categories,
      monthlySpending: monthlySpending,
    );
    final accent = _accentFor(meta.tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _alertDecoration(cs, isDark, accent, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _alertBanner(context, meta: meta, accent: accent),
          const SizedBox(height: 14),
          Text(
            'BREAKDOWN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isNotEmpty)
            Center(
              child: SimplePieChart(
                data: categories,
                colors: const [
                  EntryColors.mercurySilver,
                  EntryColors.deepGlacier,
                  EntryColors.polishedSteel,
                  EntryColors.darkSilver,
                  EntryColors.neonSilver,
                  EntryColors.midSilver,
                ],
                size: 130,
              ),
            )
          else
            SizedBox(
              height: 130,
              child: Center(
                child: Text(
                  'No category data',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _budgetAlertCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = financeBlock.budgetUsagePercent.value;
    final tone = pct >= 100
        ? FinanceInsightTone.risk
        : FinanceInsightTone.caution;
    final accent = _accentFor(tone);
    final meta = _FinanceAlertMeta(
      tone: tone,
      badge: pct >= 100 ? 'CRITICAL' : 'WARNING',
      message: pct >= 100
          ? 'Subscription burn exceeds your monthly budget cap.'
          : 'Subscription burn is at ${pct.toStringAsFixed(0)}% of budget — slow new subs.',
      icon: Icons.local_fire_department_rounded,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _alertDecoration(cs, isDark, accent, 22),
      child: _alertBanner(context, meta: meta, accent: accent),
    );
  }

  BoxDecoration _alertDecoration(
    ColorScheme cs,
    bool isDark,
    Color accent,
    double radius,
  ) {
    return BoxDecoration(
      color: isDark
          ? EntryColors.obsidianBase.withValues(alpha: 0.94)
          : EntryColors.frostedWhite.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _alertBanner(
    BuildContext context, {
    required _FinanceAlertMeta meta,
    required Color accent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(meta.icon, color: accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      meta.badge,
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                meta.message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.88,
                  ),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _accentFor(FinanceInsightTone tone) {
    switch (tone) {
      case FinanceInsightTone.positive:
        return const Color(0xFF4CAF50);
      case FinanceInsightTone.caution:
        return Colors.amberAccent;
      case FinanceInsightTone.risk:
        return Colors.redAccent;
      case FinanceInsightTone.neutral:
        return FinanceSurface.silverAccent();
    }
  }
}

class _FinanceAlertMeta {
  const _FinanceAlertMeta({
    required this.tone,
    required this.badge,
    required this.message,
    required this.icon,
  });

  final FinanceInsightTone tone;
  final String badge;
  final String message;
  final IconData icon;
}
