import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/ui_layer/finance_page/models/FinanceAsset.dart';
import 'package:ice_gate/ui_layer/finance_page/services/FinanceService.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

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
                      prefixText: block.useVnd.value ? '₫ ' : '\$ ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
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
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late final List<FinanceAsset> _stocks = [];
  final Map<String, String> _projectNamesCache = {};

  Future<void> _initWatchlist() async {
    const List<String> myTickers = ['FPT', 'VNM', 'HPG', 'SSI', 'VIC', 'TCB'];

    for (String ticker in myTickers) {
      final asset = await FinanceService.fetchVnStock(ticker);
      if (mounted) {
        setState(() {
          _stocks.add(asset);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initWatchlist();
  }

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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 70,
              floating: true,
              pinned: true,
              elevation: 0,
              toolbarHeight: 70,
              backgroundColor: Colors.transparent,
              leadingWidth: 0,
              leading: const SizedBox.shrink(),
              actions: [
                IconButton(
                  icon: Watch((context) {
                    return Text(
                      financeBlock.useVnd.value ? 'VND' : 'USD',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.amberAccent,
                      ),
                    );
                  }),
                  onPressed: () => financeBlock.toggleCurrency(),
                ),
                IconButton(
                  icon: const Icon(Icons.home_rounded, size: 30),
                  onPressed: () {
                    WidgetNavigatorAction.smartPop(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view, size: 30),
                  onPressed: () => context.go('/canvas'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 30),
                  onPressed: () => context.go('/settings'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Portfolio Summary
            SliverToBoxAdapter(
              child: Watch((context) {
                return _buildPortfolioHeader(context, financeBlock);
              }),
            ),

            // Savings & Spending Overview
            SliverToBoxAdapter(
              child: Watch((context) {
                return _buildSavingsSpendingCards(context, financeBlock);
              }),
            ),

            // Monthly Spending Breakdown
            SliverToBoxAdapter(
              child: Watch((context) {
                return _buildMonthlyBreakdown(context, financeBlock);
              }),
            ),

            // Recent Transactions
            _buildSectionHeader(
              context,
              l10n.finance_recent_transactions,
              Icons.receipt_long_rounded,
            ),
            Watch((context) {
              final txns = financeBlock.transactions.value;
              if (txns.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: colorScheme.onSurface.withOpacity(0.3),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.finance_no_transactions,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.finance_tap_to_add,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final recentTxns = txns.take(10).toList();
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTransactionItem(
                      context,
                      recentTxns[index],
                      financeBlock,
                    ),
                    childCount: recentTxns.length,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioHeader(BuildContext context, FinanceBlock block) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalBalance = block.totalBalance.value;
    final financePoints = block.financePoints.value;
    final l10n = AppLocalizations.of(context)!;

    // Dynamic values for trend
    final totalChange = block.monthlyNetChange.watch(context);
    final changePercent = block.netChangePercent.watch(context);
    final isPositive = totalChange >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withRed(
              (colorScheme.primary.red + 40).clamp(0, 255),
            ),
            colorScheme.tertiary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.finance_total_net_worth,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.7),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(
                Icons.wallet_rounded,
                color: colorScheme.onPrimary.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            block.formatCurrency(totalBalance),
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (isPositive ? Colors.greenAccent : Colors.redAccent)
                          .withValues(alpha: 0.25),
                      (isPositive ? Colors.greenAccent : Colors.redAccent)
                          .withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isPositive ? Colors.greenAccent : Colors.redAccent)
                        .withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isPositive ? Colors.greenAccent : Colors.redAccent)
                              .withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isPositive ? '+' : ''}${block.formatCurrency(totalChange)} (${changePercent.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: isPositive
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Points display - REMOVED
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              //   decoration: BoxDecoration(
              //     color: Colors.white.withOpacity(0.15),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(
              //       color: Colors.white.withOpacity(0.2),
              //       width: 1,
              //     ),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       const Icon(
              //         Icons.bolt_rounded,
              //         color: Colors.amberAccent,
              //         size: 16,
              //       ),
              //       const SizedBox(width: 6),
              //       Text(
              //         '${financePoints.toInt()} ${l10n.social_points_suffix}',
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontWeight: FontWeight.w900,
              //           fontSize: 13,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress to next milestone (visual improvement)
          _buildPointsProgress(context, totalBalance),
        ],
      ),
    );
  }

  Widget _buildPointsProgress(BuildContext context, double totalBalance) {
    final block = context.read<FinanceBlock>();
    final l10n = AppLocalizations.of(context)!;

    // Use Watch for all dynamic signals
    return Watch((context) {
      final percentage = block.milestoneProgress.value;
      final nextVal = block.nextMilestone.value;
      final efficiency = block.spendingEfficiency.value;
      final savRate = block.savingsRate.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.finance_power_points,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${l10n.finance_goal}: ${block.formatCurrency(nextVal)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Gradient Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width *
                    0.8 *
                    percentage.clamp(0.01, 1.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amberAccent, Colors.orangeAccent, Colors.yellowAccent],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amberAccent.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Efficiency Dashboard
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPowerMetric(
                context,
                label: l10n.finance_efficiency ?? "Efficiency",
                percent: efficiency,
                icon: Icons.bolt_rounded,
                color: Colors.cyanAccent,
              ),
              _buildPowerMetric(
                context,
                label: l10n.finance_savings_rate ?? "Savings Rate",
                percent: savRate,
                icon: Icons.auto_graph_rounded,
                color: Colors.lightGreenAccent,
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPowerMetric(
    BuildContext context, {
    required String label,
    required double percent,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 100) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          // Mini progress bar for metric
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percent / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsSpendingCards(
    BuildContext context,
    FinanceBlock financeBlock,
  ) {
    final savings = financeBlock.totalSavings.value;
    final spending = financeBlock.monthlySpending.value;
    final income = financeBlock.monthlyIncome.value;
    final monthName = DateFormat.MMMM().format(DateTime.now());
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  context,
                  title: l10n.finance_total_savings,
                  amount: savings,
                  icon: Icons.savings_rounded,
                  color: Colors.green,
                  gradient: [Colors.green.shade600, Colors.green.shade400],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniCard(
                  context,
                  title: l10n.finance_month_spending(monthName),
                  amount: spending,
                  icon: Icons.shopping_cart_rounded,
                  color: Colors.redAccent,
                  gradient: [Colors.red.shade600, Colors.red.shade400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniCard(
            context,
            title: l10n.finance_month_income(monthName),
            amount: income,
            icon: Icons.trending_up_rounded,
            color: Colors.blue,
            gradient: [Colors.blue.shade600, Colors.blue.shade400],
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradient[0], gradient[1]],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.read<FinanceBlock>().formatCurrency(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown(
    BuildContext context,
    FinanceBlock financeBlock,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = financeBlock.spendingByCategory.value;
    final totalSpending = financeBlock.monthlySpending.value;
    final monthName = DateFormat.MMMM().format(DateTime.now());
    final l10n = AppLocalizations.of(context)!;

    if (categories.isEmpty) return const SizedBox.shrink();

    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoryIcons = {
      'food': Icons.restaurant_rounded,
      'coffee': Icons.coffee_rounded,
      'transport': Icons.directions_car_rounded,
      'software': Icons.code_rounded,
      'shopping': Icons.shopping_bag_rounded,
      'bills': Icons.receipt_rounded,
      'rent': Icons.home_rounded,
      'subscriptions': Icons.subscriptions_rounded,
      'entertainment': Icons.movie_rounded,
      'health': Icons.medical_services_rounded,
      'education': Icons.school_rounded,
      'investing': Icons.trending_up_rounded,
      'crypto': Icons.currency_bitcoin_rounded,
      'stock': Icons.show_chart_rounded,
      'real_estate': Icons.home_work_rounded,
      'salary': Icons.payments_rounded,
      'bonus': Icons.card_giftcard_rounded,
      'gift': Icons.redeem_rounded,
      'general': Icons.category_rounded,
    };

    final categoryColors = {
      'food': Colors.orange,
      'coffee': Colors.brown,
      'transport': Colors.blue,
      'software': Colors.indigo,
      'shopping': Colors.pink,
      'bills': Colors.teal,
      'rent': Colors.deepOrange,
      'subscriptions': Colors.deepPurple,
      'entertainment': Colors.purple,
      'health': Colors.red,
      'education': Colors.cyan,
      'investing': Colors.indigo,
      'crypto': Colors.amber,
      'stock': Colors.lightGreen,
      'real_estate': Colors.brown,
      'salary': Colors.green,
      'bonus': Colors.orangeAccent,
      'gift': Colors.pinkAccent,
      'general': Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.finance_monthly_breakdown(monthName),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Icon(
                  Icons.donut_large_rounded,
                  color: colorScheme.primary.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...sortedCategories.map((entry) {
              final percentage = totalSpending > 0
                  ? entry.value / totalSpending
                  : 0.0;
              final catColor = categoryColors[entry.key] ?? colorScheme.primary;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: catColor.withOpacity(0.1)),
                      ),
                      child: Icon(
                        categoryIcons[entry.key] ?? Icons.category_rounded,
                        color: catColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                FinancePage.getCategoryName(l10n, entry.key),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                               Text(
                                financeBlock.formatCurrency(entry.value),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percentage,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        catColor,
                                        catColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: catColor.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionData txn,
    FinanceBlock financeBlock,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isExpense = txn.type == 'expense' || txn.type == 'investment';
    final isSavings = txn.type == 'savings';
    final color = isExpense
        ? Colors.redAccent
        : isSavings
        ? Colors.greenAccent[700]!
        : Colors.blueAccent;
    final prefix = isExpense ? '-' : '+';

    final typeIcons = {
      'expense': Icons.arrow_downward_rounded,
      'income': Icons.arrow_upward_rounded,
      'savings': Icons.savings_rounded,
    };

    return Dismissible(
      key: Key('txn_${txn.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) => financeBlock.deleteTransaction(txn.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Icon(
                typeIcons[txn.type] ?? Icons.swap_horiz_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description ??
                        FinancePage.getCategoryName(l10n, txn.category),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (txn.projectID != null)
                        _buildProjectTag(context, txn.projectID!),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 10,
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${FinancePage.getCategoryName(l10n, txn.category)} • ${DateFormat.MMMd().format(txn.transactionDate)}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${financeBlock.formatCurrency(txn.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTag(BuildContext context, String projectID) {
    if (_projectNamesCache.containsKey(projectID)) {
      return _renderProjectTag(context, _projectNamesCache[projectID]!);
    }

    return FutureBuilder<ProjectData?>(
      future: context.read<AppDatabase>().projectsDAO.getProjectByProjectId(
        projectID,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _projectNamesCache[projectID] = snapshot.data!.name;
          return _renderProjectTag(context, snapshot.data!.name);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _renderProjectTag(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          name.toUpperCase(),
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 20, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/finance/dashboard'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.finance_see_all,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
