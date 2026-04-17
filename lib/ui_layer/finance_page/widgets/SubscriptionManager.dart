import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals/signals_flutter.dart';
import 'package:intl/intl.dart';

class SubscriptionManager extends StatelessWidget {
  final FinanceBlock financeBlock;

  const SubscriptionManager({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Watch((context) {
      final subs = financeBlock.subscriptions.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.finance_cat_subscriptions,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddSubscriptionDialog(context),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          if (subs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  "No active subscriptions",
                  style: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: subs.length,
                itemBuilder: (context, index) {
                  final sub = subs[index];
                  return _buildSubscriptionCard(context, sub);
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _buildSubscriptionCard(BuildContext context, dynamic sub) {
    final nextDate = DateFormat.MMMd().format(sub.nextBillingDate);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(sub.category),
              color: Colors.blueAccent,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            sub.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            financeBlock.formatCurrency(sub.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Next: $nextDate",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'software':
        return Icons.code_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'health':
        return Icons.fitness_center_rounded;
      default:
        return Icons.subscriptions_rounded;
    }
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    // Logic to show add subscription dialog
    // For now skip implementation to focus on UI structure
  }
}
