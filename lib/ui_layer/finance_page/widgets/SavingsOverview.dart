import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals/signals_flutter.dart';

class SavingsOverview extends StatelessWidget {
  final FinanceBlock financeBlock;

  const SavingsOverview({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Watch((context) {
      final savings = financeBlock.totalSavings.value;
      final spending = financeBlock.monthlySpending.value;
      final income = financeBlock.monthlyIncome.value;
      
      // Calculate savings rate
      final savingsRate = (income > 0) ? (savings / income) * 100 : 0.0;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF15151A),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.finance_label_save,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${savingsRate.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (income > 0) ? (spending + savings) / income : 0.0,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: Colors.greenAccent,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildLegendItem("Daily Limit", Colors.white24),
                const SizedBox(width: 16),
                _buildLegendItem("Actual Spent", Colors.redAccent),
                const SizedBox(width: 16),
                _buildLegendItem("Savings", Colors.greenAccent),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
