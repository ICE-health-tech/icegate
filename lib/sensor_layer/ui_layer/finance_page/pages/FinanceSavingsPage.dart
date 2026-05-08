import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/savings_streak_card.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/transaction_card.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Fourth Finance tab: savings-focused actions and history (replaces stocks).
class FinanceSavingsPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceSavingsPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    "RECENT SAVINGS",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    "${savingsTxns.length} ENTRIES",
                    style: TextStyle(
                      color: EntryColors.financeYellow.withValues(alpha: 0.9),
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
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No savings logged yet",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 14,
                      ),
                    ),
                    // const SizedBox(height: 8),
                    // Text(
                    //   "Tap Add savings above to record your first transfer",
                    //   textAlign: TextAlign.center,
                    //   style: TextStyle(
                    //     color: Colors.white.withValues(alpha: 0.22),
                    //     fontSize: 12,
                    //   ),
                    // ),
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
    required double total,
    required double monthly,
    required double savingsRatePercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.greenAccent.withValues(alpha: 0.85),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                "Total saved",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            financeBlock.formatCurrency(total),
            style: const TextStyle(
              color: Colors.white,
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
                  "This month",
                  financeBlock.formatCurrency(monthly),
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  "Of income",
                  "${savingsRatePercent.clamp(0, 999).toStringAsFixed(1)}%",
                  EntryColors.financeYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent.withValues(alpha: 0.95),
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
