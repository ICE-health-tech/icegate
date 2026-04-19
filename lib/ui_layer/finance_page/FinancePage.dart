import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/finance_page/widgets/SubscriptionManager.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    final l10n = AppLocalizations.of(context)!;
    return MainButton(
      type: "finance",
      destination: "/finance",
      size: size,
      icon: Icons.add,
      mainFunction: () {
        _showAddTransactionDialog(context);
      },
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      subButtons: [
        SubButton(
          icon: Icons.savings_rounded,
          backgroundColor: Colors.green,
          label: l10n.finance_label_save,
          tooltip: l10n.finance_tooltip_add_savings,
          onPressed: () => _showAddTransactionDialog(context, type: 'savings'),
        ),
        SubButton(
          icon: Icons.shopping_cart_rounded,
          backgroundColor: Colors.red,
          label: l10n.finance_label_spend,
          tooltip: l10n.finance_tooltip_add_expense,
          onPressed: () => _showAddTransactionDialog(context, type: 'expense'),
        ),
        SubButton(
          icon: Icons.attach_money_rounded,
          backgroundColor: Colors.blue,
          label: l10n.finance_label_income,
          tooltip: l10n.finance_tooltip_add_income,
          onPressed: () => _showAddTransactionDialog(context, type: 'income'),
        ),
      ],
    );
  }

  static void _showAddTransactionDialog(BuildContext context, {String? type}) {
    final financeBlock = context.read<FinanceBlock>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String selectedType = type ?? 'expense';
    String selectedCategory = 'general';

    final categories = {
      'expense': [
        'food',
        'coffee',
        'transport',
        'software',
        'shopping',
        'bills',
        'rent',
        'subscriptions',
        'entertainment',
        'health',
        'education',
        'investing',
        'general',
      ],
      'income': [
        'salary',
        'freelance',
        'investment',
        'gift',
        'bonus',
        'general',
      ],
      'savings': ['emergency', 'goal', 'retirement', 'investment', 'general'],
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String dialogTitle = l10n.finance_add_transaction;
          if (type != null) {
            String typeName = type == 'expense'
                ? l10n.finance_type_expense
                : type == 'income'
                ? l10n.finance_type_income
                : l10n.finance_type_savings;
            dialogTitle = l10n.finance_add_type(typeName);
          }

          return AlertDialog(
            title: Text(dialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == null)
                    FittedBox(
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 'expense',
                            label: Text(l10n.finance_type_expense),
                          ),
                          ButtonSegment(
                            value: 'income',
                            label: Text(l10n.finance_type_income),
                          ),
                          ButtonSegment(
                            value: 'savings',
                            label: Text(l10n.finance_type_savings),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (val) {
                          setDialogState(() {
                            selectedType = val.first;
                            selectedCategory = 'general';
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.finance_label_amount,
                      prefixText: financeBlock.useVnd.value ? '₫ ' : '\$ ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.finance_label_category,
                      border: const OutlineInputBorder(),
                    ),
                    items: (categories[selectedType] ?? ['general'])
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(getCategoryName(l10n, c)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setDialogState(
                      () => selectedCategory = val ?? 'general',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: l10n.finance_label_description_optional,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) return;
                  await financeBlock.addTransaction(
                    category: selectedCategory,
                    type: selectedType,
                    amount: amount,
                    description: descController.text.isEmpty
                        ? null
                        : descController.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(l10n.finance_btn_add),
              ),
            ],
          );
        },
      ),
    );
  }

  static String getCategoryName(AppLocalizations l10n, String category) {
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
      case 'crypto':
        return l10n.finance_cat_crypto;
      case 'stock':
        return l10n.finance_cat_stock;
      case 'real_estate':
        return l10n.finance_cat_real_estate;
      default:
        return category.isNotEmpty
            ? category[0].toUpperCase() + category.substring(1)
            : category;
    }
  }

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final Map<String, String> _projectNamesCache = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final financeBlock = context.read<FinanceBlock>();
    final l10n = AppLocalizations.of(context)!;

    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(
            l10n.scoring_finance.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          centerTitle: false,
          actions: [
            Watch((context) {
              final useVnd = financeBlock.useVnd.value;
              return IconButton(
                onPressed: () => financeBlock.toggleCurrency(),
                icon: Text(
                  useVnd ? 'VND' : 'USD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }),
            // IconButton(
            //   icon: const Icon(Icons.settings),
            //   onPressed: () => context.go('/settings'),
            // ),
            // const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Billing Card
              Watch((context) {
                return _buildPremiumIceCard(context, financeBlock);
              }),
              const SizedBox(height: 24),

              // Subscription Manager
              SubscriptionManager(financeBlock: financeBlock),
              const SizedBox(height: 32),

              // Summary Cards
              Watch((context) {
                return _buildSummaryCardRow(context, financeBlock);
              }),
              const SizedBox(height: 40),

              // Daily Activity
              _buildDailyActivityHeader(context),
              const SizedBox(height: 16),
              Watch((context) {
                return _buildDailyActivityList(context, financeBlock);
              }),
              const SizedBox(height: 80), // Space for FAB padding
            ],
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => FinancePage._showAddTransactionDialog(context),
        //   backgroundColor: Colors.green.shade500,
        //   shape: const CircleBorder(),
        //   child: const Icon(Icons.add, color: Colors.white, size: 32),
        // ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildPremiumIceCard(BuildContext context, FinanceBlock block) {
    final burnRate = block.monthlyBurnRate.value;
    final totalSpent = block.monthlySpending.value;
    final progress = block.budgetUsagePercent.value / 100;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E1A47), // Deep Violet
            const Color(0xFF1A1A2E), // Obsidian
          ],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ESTIMATED MONTHLY BURN",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.ac_unit_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        block.formatCurrency(burnRate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12, left: 4),
                        child: Text(
                          "/ mo",
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildIceSubStat(
                          label: "ACTUAL SPENT",
                          value: block.formatCurrency(totalSpent),
                          icon: Icons.payments_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildIceSubStat(
                          label: "BUDGET HEALTH",
                          value: "${(progress * 100).toStringAsFixed(0)}%",
                          icon: Icons.shield_moon_rounded,
                          color: progress > 0.8 ? Colors.redAccent : Colors.tealAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.9 ? Colors.redAccent : Colors.blueAccent.shade100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIceSubStat({
    required String label,
    required String value,
    required IconData icon,
    Color color = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white24, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardRow(BuildContext context, FinanceBlock block) {
    return Row(
      children: [
        Expanded(
          child: _buildSimpleStatsCard(
            context,
            label: "TOTAL SAVINGS",
            value: block.formatCurrency(block.totalSavings.value),
            color: const Color(0xFF4CAF50),
            icon: Icons.savings_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSimpleStatsCard(
            context,
            label:
                "SPENDING ${DateFormat('MMM').format(DateTime.now()).toUpperCase()}",
            value: block.formatCurrency(block.monthlySpending.value),
            color: const Color(0xFFF44336),
            icon: Icons.shopping_cart_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStatsCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "DAILY ACTIVITY",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Text(
            "RECENT",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyActivityList(BuildContext context, FinanceBlock block) {
    final txns = block.transactions.value;
    if (txns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.history_rounded,
                  color: Colors.white.withValues(alpha: 0.05), size: 48),
              const SizedBox(height: 16),
              const Text(
                "NO RECENT ACTIVITY",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recent = txns.take(5).toList();

    return Column(
      children: recent
          .map((t) => _buildModernActivityCard(context, t, block))
          .toList(),
    );
  }

  Widget _buildModernActivityCard(
    BuildContext context,
    TransactionData txn,
    FinanceBlock block,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = txn.type == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getCategoryIcon(txn.category),
              color: Colors.white70,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description ??
                      _getCategoryNameDisplay(l10n, txn.category),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  txn.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                block.formatCurrency(txn.amount),
                style: TextStyle(
                  color: isIncome ? Colors.tealAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                txn.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  color: isIncome ? Colors.tealAccent : Colors.white24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryNameDisplay(AppLocalizations l10n, String category) {
    return FinancePage.getCategoryName(l10n, category);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'subscriptions':
        return Icons.subscriptions_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'software':
        return Icons.computer_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_rounded;
      case 'rent':
        return Icons.home_rounded;
      case 'entertainment':
        return Icons.movie_filter_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'investing':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'salary':
        return Icons.payments_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }
}
