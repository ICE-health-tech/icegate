import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals/signals_flutter.dart';

class FinanceHeader extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceHeader({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Watch((context) {
      final balance = financeBlock.totalBalance.value;
      final spending = financeBlock.monthlySpending.value;
      final income = financeBlock.monthlyIncome.value;
      final savings = financeBlock.totalSavings.value;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF0A0A0A),
            ],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              l10n.balance.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              financeBlock.formatCurrency(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  l10n.income,
                  financeBlock.formatCurrency(income),
                  Colors.blueAccent,
                ),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                _buildStatItem(
                  context,
                  l10n.spent,
                  financeBlock.formatCurrency(spending),
                  Colors.redAccent,
                ),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                _buildStatItem(
                  context,
                  l10n.savings,
                  financeBlock.formatCurrency(savings),
                  Colors.greenAccent,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
