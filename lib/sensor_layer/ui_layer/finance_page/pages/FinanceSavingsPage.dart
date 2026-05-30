import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/SavingsStreakCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/TransactionCard.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Fourth Finance tab: savings-focused actions and history (replaces stocks).
class FinanceSavingsPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceSavingsPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Watch((context) {
      final txns = financeBlock.transactions.value;
      final now = DateTime.now();
      final savingsTxns = txns.where((t) => t.type == 'savings').toList()
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      final monthlySavings = savingsTxns
          .where(
            (t) =>
                t.transactionDate.month == now.month &&
                t.transactionDate.year == now.year,
          )
          .fold(0.0, (sum, t) => sum + t.amount);

      final total = financeBlock.totalSavings.value;
      final rate = financeBlock.savingsRate.value;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            SavingsStreakCard(financeBlock: financeBlock),
            const SizedBox(height: 16),
            _buildSummaryCard(
              context,
              isDark: isDark,
              cs: cs,
              total: total,
              monthly: monthlySavings,
              savingsRatePercent: rate,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "RECENT SAVINGS",
                    style: TextStyle(
                      color: FinanceSurface.ink(isDark: isDark),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    "${savingsTxns.length} ENTRIES",
                    style: TextStyle(
                      color: FinanceSurface.silverAccent(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (savingsTxns.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 48,
                      color: FinanceSurface.mutedInk(isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No savings logged yet",
                      style: TextStyle(
                        color: FinanceSurface.mutedInk(isDark: isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...savingsTxns.map(
                (txn) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionCard(txn: txn, block: financeBlock),
                ),
              ),
            const SizedBox(height: 120),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required bool isDark,
    required ColorScheme cs,
    required double total,
    required double monthly,
    required double savingsRatePercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: FinanceSurface.silverAccent(),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                "Total saved",
                style: TextStyle(
                  color: FinanceSurface.mutedInk(isDark: isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            financeBlock.formatCurrency(total),
            style: TextStyle(
              color: FinanceSurface.ink(isDark: isDark),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  isDark: isDark,
                  cs: cs,
                  label: "This month",
                  value: financeBlock.formatCurrency(monthly),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  isDark: isDark,
                  cs: cs,
                  label: "Of income",
                  value: "${savingsRatePercent.clamp(0, 999).toStringAsFixed(1)}%",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required bool isDark,
    required ColorScheme cs,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: FinanceSurface.mutedInk(isDark: isDark),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: FinanceSurface.ink(isDark: isDark),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }
}
