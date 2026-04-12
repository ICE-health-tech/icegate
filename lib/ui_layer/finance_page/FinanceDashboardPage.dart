import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';

class FinanceDashboardPage extends StatelessWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final financeBlock = context.read<FinanceBlock>();

    return SwipeablePage(
      onSwipe: () => WidgetNavigatorAction.smartPop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => WidgetNavigatorAction.smartPop(context),
          ),
          title: Text(
            'Financial Analysis',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
        ),
        body: Watch((context) {
          final txns = financeBlock.transactions.value;
          final totalBalance = financeBlock.totalBalance.value;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- CHARTS SECTION ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceTrend(context, txns, totalBalance),
                      const SizedBox(height: 24),
                      _buildComparisonSection(context, financeBlock),
                    ],
                  ),
                ),
              ),

              // --- TRANSACTION HISTORY HEADER ---
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  backgroundColor: colorScheme.surface,
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
                            color: colorScheme.onSurfaceVariant,
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

              // --- TRANSACTION LIST ---
              if (txns.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No transactions found')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final txn = txns[index];
                      return _buildHistoryItem(context, txn, financeBlock);
                    }, childCount: txns.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }),
      ),
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
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NET WORTH TREND',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.read<FinanceBlock>().formatCurrency(currentTotal),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28),
          ),
          const SizedBox(height: 24),
          if (chartData.length > 1)
            SimpleLineChart(
              data: chartData,
              color: colorScheme.primary,
              height: 120,
            )
          else
            const SizedBox(
              height: 120,
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
              color: colorScheme.secondaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BREAKDOWN',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.5,
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
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
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
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
      ),
      onDismissed: (_) => block.deleteTransaction(txn.id),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
