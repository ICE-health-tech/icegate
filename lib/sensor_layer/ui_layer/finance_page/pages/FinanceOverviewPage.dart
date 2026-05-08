import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import '../finance_form/add_account_dialog.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/savings_streak_card.dart';

class FinanceOverviewPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceOverviewPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Watch((context) {
            return Align(
              alignment: Alignment.centerRight,
              child: FinanceOverviewStreakChip(financeBlock: financeBlock),
            );
          }),
          const SizedBox(height: 10),
          // Main Billing Card
          Watch((context) {
            return _buildPremiumIceCard(context, financeBlock);
          }),
          const SizedBox(height: 24),

          Watch((context) {
            return _buildSummaryCardRow(context, financeBlock);
          }),
          const SizedBox(height: 32),

          // Accounts Section
          Watch((context) {
            return _buildAccountsSection(context, financeBlock);
          }),
          const SizedBox(height: 40),

          // Dynamic Analytics Charts
          Watch((context) {
            final txns = financeBlock.transactions.value;
            final currentTotal = financeBlock.totalBalance.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalysisHeader(context),
                const SizedBox(height: 16),
                _buildBalanceTrend(context, txns, currentTotal),
                const SizedBox(height: 24),
                _buildComparisonSection(context, financeBlock),
              ],
            );
          }),
          const SizedBox(height: 120), // Bottom space
        ],
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
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: EntryColors.glassBorder.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        EntryColors.primaryIceBlue.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MONTHLY BURN",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            block.formatCurrency(burnRate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10, left: 4),
                          child: Text(
                            "/ mo",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _buildIceSubStat(
                            label: "ACTUAL SPENT",
                            value: block.formatCurrency(
                              totalSpent,
                              compact: true,
                            ),
                            icon: Icons.payments_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildIceSubStat(
                            label: "BUDGET HEALTH",
                            value: "${(progress * 100).toStringAsFixed(0)}%",
                            icon: Icons.shield_moon_rounded,
                            color: progress > 0.8
                                ? Colors.redAccent
                                : Colors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.9
                              ? Colors.redAccent
                              : EntryColors.primaryIceBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIceSubStat({
    required String label,
    required String value,
    required IconData icon,
    Color color = EntryColors.primaryIceBlue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white24, size: 10),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
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
            label: "SAVINGS",
            value: block.formatCurrency(
              block.totalSavings.value,
              compact: true,
            ),
            color: const Color(0xFF4CAF50),
            icon: Icons.savings_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSimpleStatsCard(
            context,
            label: "SPENDING",
            value: block.formatCurrency(
              block.monthlySpending.value,
              compact: true,
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader(BuildContext context) {
    return const Text(
      "FINANCIAL EFFICIENCY",
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildBalanceTrend(
    BuildContext context,
    List<TransactionData> txns,
    double currentTotal,
  ) {
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
        color: EntryColors.primaryIceBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: EntryColors.primaryIceBlue.withValues(alpha: 0.1)),
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
              color: EntryColors.primaryIceBlue.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            financeBlock.formatCurrency(currentTotal),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          if (chartData.length > 1)
            SimpleLineChart(
              data: chartData,
              color: EntryColors.primaryIceBlue,
              height: 140,
            )
          else
            const SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Need more data for trend',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountsSection(BuildContext context, FinanceBlock block) {
    final accounts = block.accounts.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "LIQUID ASSETS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: () => AddAccountDialog.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: EntryColors.financeYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EntryColors.financeYellow.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: EntryColors.financeYellow, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "ADD",
                      style: TextStyle(
                        color: EntryColors.financeYellow,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (accounts.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: "No accounts linked",
            subtitle: "Add your first bank account or wallet",
            onTap: () => AddAccountDialog.show(context),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return _buildAccountCard(context, account, block);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    FinancialAccountProtocol account,
    FinanceBlock block,
  ) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _getAccountIcon(account.accountType),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.accountName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            block.formatCurrency(account.balance, compact: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAccountIcon(String type) {
    IconData icon;
    Color color;
    switch (type.toLowerCase()) {
      case 'savings':
        icon = Icons.savings_rounded;
        color = Colors.greenAccent;
        break;
      case 'credit_card':
        icon = Icons.credit_card_rounded;
        color = Colors.orangeAccent;
        break;
      case 'cash':
        icon = Icons.payments_rounded;
        color = Colors.yellowAccent;
        break;
      default:
        icon = Icons.account_balance_rounded;
        color = EntryColors.primaryIceBlue;
    }
    return Icon(icon, color: color.withValues(alpha: 0.5), size: 14);
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white12, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection(BuildContext context, FinanceBlock block) {
    final categories = block.spendingByCategory.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          if (categories.isNotEmpty)
            Center(
              child: SimplePieChart(
                data: categories,
                colors: const [
                  EntryColors.primaryIceBlue,
                  Color(0xFF839BF3),
                  Color(0xFFA5B4FC),
                  Color(0xFFF0FDFA),
                  Color(0xFF00E5FF),
                  Color(0xFF4F46E5),
                ],
                size: 140,
              ),
            )
          else
            const SizedBox(
              height: 140,
              child: Center(
                child: Text('No data', style: TextStyle(color: Colors.white38)),
              ),
            ),
        ],
      ),
    );
  }
}
