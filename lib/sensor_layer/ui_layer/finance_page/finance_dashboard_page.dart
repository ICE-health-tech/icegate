import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';

class FinanceDashboardPage extends StatelessWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final block = context.read<FinanceBlock>();

    return SwipeablePage(
      onSwipe: () => WidgetNavigatorAction.smartPop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D12), // Deep Obsidian
        body: Stack(
          children: [
            // --- PREMIUM BACKGROUND SYSTEM ---
            Positioned(
              top: -100,
              right: -50,
              child: _buildGlowSphere(EntryColors.financeYellow.withValues(alpha: 0.08), 350),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: _buildGlowSphere(const Color(0xFF6366F1).withValues(alpha: 0.05), 400),
            ),

            SafeArea(
              child: Watch((context) {
                final txns = block.transactions.value;
                final totalBalance = block.totalBalance.value;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildTacticalAppBar(context, colorScheme, block),

                    // --- HERO NET WORTH CARD ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: _buildNetWorthConsole(context, block, totalBalance),
                      ),
                    ),

                    // --- QUICK METRICS GRID ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: _buildMetricsGrid(context, block),
                      ),
                    ),

                    // --- TRANSACTION HISTORY HEADER ---
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PremiumHeaderDelegate(
                        child: _buildSectionHeader(context, "TERMINAL LOGS", Icons.analytics_outlined),
                      ),
                    ),

                    // --- LOGS LIST ---
                    if (txns.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final txn = txns[index];
                            return _buildLogEntry(context, txn, block);
                          }, childCount: txns.length),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowSphere(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalAppBar(BuildContext context, ColorScheme colorScheme, FinanceBlock block) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 70,
      leading: Center(
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            children: [
              _buildAppBarAction(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  block.toggleCurrency();
                },
                child: Text(
                  block.useVnd.value ? '₫' : '\$',
                  style: const TextStyle(
                    color: EntryColors.financeYellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildAppBarAction(
                onTap: () {}, // Future Settings
                child: const Icon(Icons.tune_rounded, color: Colors.white70, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarAction({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildNetWorthConsole(BuildContext context, FinanceBlock block, double balance) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CONSOLIDATED ASSETS",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          block.formatCurrency(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.north_east_rounded, color: Colors.green, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "+2.4%",
                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 120,
                  child: SimpleLineChart(
                    data: block.historicalNetWorth.value,
                    color: EntryColors.financeYellow,
                    height: 120,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, FinanceBlock block) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            "MONTHLY BURN",
            block.monthlySpending.value,
            Icons.local_fire_department_rounded,
            Colors.orangeAccent,
            block,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            "CASH FLOW",
            block.monthlyNetChange.value,
            Icons.account_balance_wallet_rounded,
            Colors.blueAccent,
            block,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, double amount, IconData icon, Color color, FinanceBlock block) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withValues(alpha: 0.6), size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            child: Text(
              block.formatCurrency(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xFF0D0D12).withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: EntryColors.financeYellow, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              const Icon(Icons.tune_rounded, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, TransactionData txn, FinanceBlock block) {
    final isExpense = txn.type == 'expense' || txn.type == 'investment';
    final color = isExpense ? Colors.redAccent : Colors.greenAccent;
    final isBig = txn.amount > (block.useVnd.value ? 10000000 : 500); // Highlight big txns

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBig ? color.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isBig ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getTacticalIcon(txn.category, txn.type),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          txn.description?.toUpperCase() ?? txn.category.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DateFormat('dd MMM · HH:mm').format(txn.transactionDate),
            style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '-' : '+'}${block.formatCurrency(txn.amount, compact: true)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            if (isBig)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  "MAJOR",
                  style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTacticalIcon(String category, String type) {
    if (type == 'income') return Icons.south_west_rounded;
    if (type == 'savings') return Icons.shield_rounded;
    
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant_rounded;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'travel': return Icons.flight_takeoff_rounded;
      case 'subscriptions': return Icons.auto_awesome_mosaic_rounded;
      case 'bills': return Icons.bolt_rounded;
      default: return Icons.adjust_rounded;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 60),
          const SizedBox(height: 16),
          const Text(
            "NO SYSTEM LOGS FOUND",
            style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _PremiumHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PremiumHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
