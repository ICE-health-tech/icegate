import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/ui_layer/animation_page/components/entry_constants.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/finance_page/widgets/transaction_builder_dialog.dart';

class TransactionCard extends StatelessWidget {
  final TransactionData txn;
  final FinanceBlock block;

  const TransactionCard({
    super.key,
    required this.txn,
    required this.block,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'transport':
        return Icons.commute_rounded;
      case 'software':
        return Icons.code_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'rent':
        return Icons.home_work_rounded;
      case 'subscriptions':
        return Icons.autorenew_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'investing':
        return Icons.trending_up_rounded;
      case 'salary':
        return Icons.payments_rounded;
      case 'freelance':
        return Icons.work_rounded;
      case 'investment':
        return Icons.account_balance_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'bonus':
        return Icons.stars_rounded;
      case 'emergency':
        return Icons.emergency_rounded;
      case 'goal':
        return Icons.flag_rounded;
      case 'retirement':
        return Icons.elderly_rounded;
      case 'crypto':
        return Icons.currency_bitcoin_rounded;
      case 'stock':
        return Icons.show_chart_rounded;
      case 'real_estate':
        return Icons.apartment_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _getCategoryNameDisplay(AppLocalizations l10n, String category) {
    switch (category) {
      case 'food':
        return l10n.finance_cat_food;
      case 'coffee':
        return l10n.finance_cat_coffee;
      case 'transport':
        return l10n.finance_cat_transport;
      case 'software':
        return l10n.finance_cat_software;
      case 'shopping':
        return l10n.finance_cat_shopping;
      case 'bills':
        return l10n.finance_cat_bills;
      case 'rent':
        return l10n.finance_cat_rent;
      case 'subscriptions':
        return l10n.finance_cat_subscriptions;
      case 'entertainment':
        return l10n.finance_cat_entertainment;
      case 'health':
        return l10n.finance_cat_health;
      case 'education':
        return l10n.finance_cat_education;
      case 'investing':
        return l10n.finance_cat_investing;
      case 'general':
        return l10n.finance_cat_general;
      case 'salary':
        return l10n.finance_cat_salary;
      case 'freelance':
        return l10n.finance_cat_freelance;
      case 'investment':
        return l10n.finance_cat_investment;
      case 'gift':
        return l10n.finance_cat_gift;
      case 'bonus':
        return l10n.finance_cat_bonus;
      case 'emergency':
        return l10n.finance_cat_emergency;
      case 'goal':
        return l10n.finance_cat_goal;
      case 'retirement':
        return l10n.finance_cat_retirement;
      default:
        return category.isNotEmpty
            ? category[0].toUpperCase() + category.substring(1)
            : category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = txn.type == 'income';
    final isSavings = txn.type == 'savings';

    final amountColor = isIncome
        ? EntryColors.financeYellow
        : (isSavings ? Colors.greenAccent : Colors.white70);
    final prefix = isIncome ? "+" : (isSavings ? "" : "-");

    return InkWell(
      onTap: () => TransactionBuilderDialog.show(
        context,
        initialData: txn,
        financeBlock: block,
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getCategoryIcon(txn.category),
                color: isIncome ? EntryColors.financeYellow : Colors.white60,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description ?? _getCategoryNameDisplay(l10n, txn.category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txn.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$prefix${block.formatCurrency(txn.amount, compact: true)}",
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _formatDate(txn.transactionDate),
                  style: const TextStyle(
                    color: Colors.white12,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}";
  }
}
