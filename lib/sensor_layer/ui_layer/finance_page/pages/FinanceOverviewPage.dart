import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceAlertPanel.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FixedIncomeManager.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/SavingsStreakCard.dart';
import '../finance_form/AddAccountDialog.dart';

class FinanceOverviewPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceOverviewPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 900;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 920 : double.infinity,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isDesktop ? 12 : 16),
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

          Watch((context) {
            return FixedIncomeManager(financeBlock: financeBlock);
          }),
          const SizedBox(height: 32),

          // Accounts Section
          Watch((context) {
            return _buildAccountsSection(context, financeBlock);
          }),
          const SizedBox(height: 40),

          // Finance health alerts (net worth + breakdown)
          FinanceAlertPanel(financeBlock: financeBlock),
          const SizedBox(height: 120), // Bottom space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumIceCard(BuildContext context, FinanceBlock block) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dense = MediaQuery.sizeOf(context).width >= 900;
    final burnRate = block.monthlyBurnRate.value;
    final totalSpent = block.monthlySpending.value;
    final progress = block.budgetUsagePercent.value / 100;

    final pad = dense ? 20.0 : 28.0;
    final radius = dense ? 24.0 : 32.0;
    final mainAmtSize = dense ? 30.0 : 42.0;
    final gapAfterTitle = dense ? 18.0 : 28.0;
    final gapBeforeBar = dense ? 14.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: FinanceSurface.panel(
        cs,
        isDark: isDark,
        radius: radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MONTHLY BURN",
            style: TextStyle(
              color: FinanceSurface.mutedInk(isDark: isDark),
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
                  style: TextStyle(
                    color: FinanceSurface.ink(isDark: isDark),
                    fontSize: mainAmtSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: dense ? 6 : 10,
                  left: 4,
                ),
                child: Text(
                  "/ mo",
                  style: TextStyle(
                    color: FinanceSurface.mutedInk(isDark: isDark),
                    fontSize: dense ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: gapAfterTitle),
          Row(
            children: [
              Expanded(
                child: _buildIceSubStat(
                  cs: cs,
                  isDark: isDark,
                  label: "ACTUAL SPENT",
                  value: block.formatCurrency(
                    totalSpent,
                    compact: true,
                  ),
                  icon: Icons.payments_rounded,
                  dense: dense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIceSubStat(
                  cs: cs,
                  isDark: isDark,
                  label: "BUDGET HEALTH",
                  value: "${(progress * 100).toStringAsFixed(0)}%",
                  icon: Icons.shield_moon_rounded,
                  color: progress > 0.8
                      ? cs.error
                      : FinanceSurface.silverAccent(),
                  dense: dense,
                ),
              ),
            ],
          ),
          SizedBox(height: gapBeforeBar),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: dense ? 5 : 6,
              backgroundColor: cs.outline.withValues(alpha: isDark ? 0.25 : 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? cs.error : FinanceSurface.silverAccent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIceSubStat({
    required ColorScheme cs,
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    bool dense = false,
  }) {
    final accent = color ?? FinanceSurface.ink(isDark: isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: FinanceSurface.mutedInk(isDark: isDark), size: 10),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: FinanceSurface.mutedInk(isDark: isDark),
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
            color: accent,
            fontSize: dense ? 14 : 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardRow(BuildContext context, FinanceBlock block) {
    final dense = MediaQuery.sizeOf(context).width >= 900;
    final l10n = AppLocalizations.of(context)!;
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
            color: FinanceSurface.silverAccent(),
            icon: Icons.savings_rounded,
            dense: dense,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSimpleStatsCard(
            context,
            label: l10n.finance_fixed_income_title.toUpperCase(),
            value: block.formatCurrency(
              block.monthlyFixedIncome.value,
              compact: true,
            ),
            color: FinanceSurface.mutedInk(isDark: Theme.of(context).brightness == Brightness.dark),
            icon: Icons.trending_up_rounded,
            dense: dense,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSimpleStatsCard(
            context,
            label: "SPENDING",
            value: block.formatCurrency(
              block.monthlySpending.value,
              compact: true,
            ),
            color: FinanceSurface.ink(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            icon: Icons.shopping_cart_rounded,
            dense: dense,
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
    bool dense = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pad = dense ? 12.0 : 16.0;
    final radius = dense ? 20.0 : 24.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: FinanceSurface.panel(
        cs,
        isDark: isDark,
        radius: radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: dense ? 15 : 16),
          SizedBox(height: dense ? 8 : 12),
          Text(
            label,
            style: TextStyle(
              color: FinanceSurface.mutedInk(isDark: isDark),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: FinanceSurface.ink(isDark: isDark),
              fontSize: dense ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsSection(BuildContext context, FinanceBlock block) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = block.accounts.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "LIQUID ASSETS",
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: () => AddAccountDialog.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: FinanceSurface.panel(
                  cs,
                  isDark: isDark,
                  radius: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: FinanceSurface.silverAccent(),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "ADD",
                      style: TextStyle(
                        color: cs.onSurface,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: FinanceSurface.panel(
        cs,
        isDark: isDark,
        radius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _getAccountIcon(account.accountType, isDark: isDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.accountName.toUpperCase(),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
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
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAccountIcon(String type, {required bool isDark}) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'savings':
        icon = Icons.savings_rounded;
        break;
      case 'credit_card':
        icon = Icons.credit_card_rounded;
        break;
      case 'cash':
        icon = Icons.payments_rounded;
        break;
      default:
        icon = Icons.account_balance_rounded;
    }
    return Icon(
      icon,
      color: FinanceSurface.mutedInk(isDark: isDark),
      size: 14,
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: FinanceSurface.panel(
          cs,
          isDark: isDark,
          radius: 24,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: cs.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
