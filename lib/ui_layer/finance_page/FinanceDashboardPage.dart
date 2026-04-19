import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

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
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            // Background Aesthetic Gradients
            Positioned(
              top: -150,
              right: -100,
              child: _buildBlurCircle(colorScheme.primary.withValues(alpha: 0.12), 400),
            ),
            Positioned(
              bottom: -50,
              left: -100,
              child: _buildBlurCircle(
                colorScheme.secondary.withValues(alpha: 0.08),
                350,
              ),
            ),

            SafeArea(
              child: Watch((context) {
                final txns = block.transactions.value;
                final totalBalance = block.totalBalance.value;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Premium Pinned App Bar
                    _buildPremiumAppBar(context, colorScheme),

                    // --- CHARTS SECTION ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBalanceTrend(context, txns, totalBalance),
                            const SizedBox(height: 24),
                            _buildComparisonSection(context, block),
                          ],
                        ),
                      ),
                    ),

                    // --- TRANSACTION HISTORY HEADER ---
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverHeaderDelegate(
                        backgroundColor: colorScheme.surface.withValues(alpha: 0.1),
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'HISTORY',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Icon(
                                    Icons.filter_list_rounded,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- TRANSACTION LIST ---
                    if (txns.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: Text('No transactions found')),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final txn = txns[index];
                            return _buildHistoryItem(context, txn, block);
                          }, childCount: txns.length),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildPremiumAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.blurBackground,
          StretchMode.zoomBackground,
        ],
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
        centerTitle: false,
        background: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withValues(alpha: 0.9),
                    colorScheme.surface.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          'ANALYTICS ENGINE',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        Watch((context) {
          final block = context.read<FinanceBlock>();
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                block.toggleCurrency();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: block.useVnd.value
                    ? Text('₫', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 14))
                    : Icon(Icons.attach_money_rounded, size: 16, color: colorScheme.primary),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBalanceTrend(
    BuildContext context,
    List<TransactionData> txns,
    double currentTotal,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Reverse engineer balance history (simplified logic)
    List<double> history = [currentTotal];
    double running = currentTotal;

    // Take last 15 txns to show a trend
    for (var i = 0; i < txns.length && i < 15; i++) {
      final t = txns[i];
      if (t.type == 'income' || t.type == 'savings') {
        running -= t.amount;
      } else {
        running += t.amount;
      }
      history.add(running);
    }

    final chartData = history.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NET WORTH TREND',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.read<FinanceBlock>().formatCurrency(currentTotal),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1),
          ),
          const SizedBox(height: 24),
          if (chartData.length > 1)
            SimpleLineChart(
              data: chartData,
              color: colorScheme.primary,
              height: 140,
            )
          else
            const SizedBox(
              height: 140,
              child: Center(child: Text('Need more data for trend')),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(BuildContext context, FinanceBlock block) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = block.spendingByCategory.value;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BREAKDOWN',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: colorScheme.secondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                if (categories.isNotEmpty)
                  Center(
                    child: SimplePieChart(
                      data: categories,
                      colors: [
                        colorScheme.primary,
                        colorScheme.secondary,
                        colorScheme.tertiary,
                        colorScheme.error,
                        Colors.orange,
                        Colors.teal,
                      ],
                      size: 140,
                    ),
                  )
                else
                  const SizedBox(
                    height: 140,
                    child: Center(child: Text('No data')),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildMiniSummary(
                context,
                'Income',
                block.monthlyIncome.value,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildMiniSummary(
                context,
                'Expense',
                block.monthlySpending.value,
                Colors.redAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSummary(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 9,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              context.read<FinanceBlock>().formatCurrency(amount),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    TransactionData txn,
    FinanceBlock block,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpense = txn.type == 'expense' || txn.type == 'investment';
    final color = isExpense
        ? Colors.redAccent
        : (txn.type == 'savings' ? Colors.green : Colors.blueAccent);

    return Dismissible(
      key: Key('dash_txn_${txn.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
      ),
      onDismissed: (_) => block.deleteTransaction(txn.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              txn.type == 'income'
                  ? Icons.add_rounded
                  : (txn.type == 'savings'
                        ? Icons.savings_rounded
                        : Icons.remove_rounded),
              color: color,
            ),
          ),
          title: Text(
            txn.description ??
                (txn.category[0].toUpperCase() + txn.category.substring(1)),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          subtitle: Text(
            DateFormat.yMMMd().format(txn.transactionDate),
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          trailing: Text(
            '${isExpense ? '-' : '+'}${block.formatCurrency(txn.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  _SliverHeaderDelegate({required this.child, required this.backgroundColor});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: child);
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
