import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceInflowPillars.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FixedIncomeManager.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/SavingsStreakCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/TransactionBuilderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceAssetPillars.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/finance_form/AddAssetDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import '../finance_form/AddAccountDialog.dart';

class FinanceOverviewPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceOverviewPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  cs.surface,
                  EntryColors.obsidianBase.withValues(alpha: 0.35),
                ]
              : [
                  const Color(0xFFF4F7FA),
                  cs.surface,
                ],
        ),
      ),
      child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 920 : double.infinity,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 20,
            8,
            isDesktop ? 32 : 20,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isDesktop ? 16 : 20),
          Watch((context) {
            return Align(
              alignment: Alignment.centerRight,
              child: FinanceOverviewStreakChip(financeBlock: financeBlock),
            );
          }),
          const SizedBox(height: 16),
          // Main Billing Card
          Watch((context) {
            return _buildPremiumIceCard(context, financeBlock);
          }),
          const SizedBox(height: 28),

          Watch((context) {
            return _buildSummaryCardRow(context, financeBlock);
          }),
          const SizedBox(height: 28),
          FinanceInflowPillarsStrip(financeBlock: financeBlock),
          const SizedBox(height: 28),
          _FinanceQuickActions(financeBlock: financeBlock),
          const SizedBox(height: 28),
          Watch((context) {
            return FixedIncomeManager(financeBlock: financeBlock);
          }),
          const SizedBox(height: 36),

          // Accounts Section
          Watch((context) {
            return _buildAccountsSection(context, financeBlock);
          }),
          const SizedBox(height: 44),

          _FinanceGoalsSection(financeBlock: financeBlock),
          const SizedBox(height: 120),
            ],
          ),
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

    final pad = dense ? 24.0 : 28.0;
    final radius = dense ? 24.0 : 32.0;
    final mainAmtSize = dense ? 30.0 : 42.0;
    final gapAfterTitle = dense ? 18.0 : 28.0;
    final gapBeforeBar = dense ? 14.0 : 20.0;

    final limit = block.monthlyBudgetLimit.value;

    return FinanceSurface.card(
      cs: cs,
      isDark: isDark,
      radius: radius,
      padding: EdgeInsets.all(pad),
      margin: FinanceSurface.cardMargin,
      elevated: true,
      onTap: () => _showBudgetLimitEditor(context, block),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              Text(
                "LIMIT: ${block.formatCurrency(limit, compact: true)}"
                "${block.budgetLimitPeriod.value == 'week' ? '/wk' : '/mo'}",
                style: TextStyle(
                  color: FinanceSurface.mutedInk(isDark: isDark),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_rounded,
                size: 12,
                color: FinanceSurface.mutedInk(isDark: isDark),
              ),
            ],
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

  void _showBudgetLimitEditor(BuildContext context, FinanceBlock block) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(
      text: block.convertToDisplay(block.monthlyBudgetLimit.value)
          .toStringAsFixed(0),
    );
    var period = block.budgetLimitPeriod.value;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.finance_budget_limit_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.finance_budget_limit_label,
                  prefixText: block.useVnd.value ? '₫ ' : '\$ ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'week',
                    label: Text(l10n.finance_budget_limit_per_week),
                  ),
                  ButtonSegment(
                    value: 'month',
                    label: Text(l10n.finance_budget_limit_per_month),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (s) => setState(() => period = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(ctrl.text.trim());
                if (parsed != null && parsed > 0) {
                  block.setBudgetLimit(
                    block.convertToBase(parsed),
                    period: period,
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(l10n.projects_calendar_save),
            ),
          ],
        ),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final income = block.monthlyFixedIncome.value;
    final spending = block.monthlySpending.value;
    final savings = block.totalSavings.value;
    final total = income + spending;
    final incomeRatio = total > 0 ? income / total : 0.5;

    final incomeColor = FinanceSurface.silverAccent();
    final spendingColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : cs.onSurface.withValues(alpha: 0.3);

    return FinanceSurface.card(
      cs: cs,
      isDark: isDark,
      radius: 24,
      padding: FinanceSurface.cardPadding,
      margin: FinanceSurface.cardMargin,
      elevated: true,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _CashflowDonutPainter(
                    incomeRatio: incomeRatio,
                    incomeColor: incomeColor,
                    spendingColor: spendingColor,
                    trackColor: cs.outline.withValues(alpha: 0.12),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      block.formatCurrency(savings, compact: true),
                      style: TextStyle(
                        color: FinanceSurface.ink(isDark: isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'SAVINGS',
                      style: TextStyle(
                        color: FinanceSurface.mutedInk(isDark: isDark),
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(
                  color: incomeColor,
                  label: 'INCOME',
                  value: block.formatCurrency(income, compact: true),
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _legendRow(
                  color: spendingColor,
                  label: 'SPENDING',
                  value: block.formatCurrency(spending, compact: true),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: FinanceSurface.mutedInk(isDark: isDark),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: FinanceSurface.ink(isDark: isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSection(BuildContext context, FinanceBlock block) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = block.accounts.value;
    final liquid = accounts
        .where(
          (a) =>
              FinanceAssetPillar.pillarForAccountType(a.accountType) ==
              FinanceAssetPillar.liquidity,
        )
        .toList();
    final investment = accounts
        .where((a) => a.accountType.toLowerCase() == 'investment')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _accountsGroupHeader(
          context,
          title: l10n.finance_accounts_liquidity_title,
          onAdd: () => AddAccountDialog.show(context, initialAccountType: 'checking'),
          cs: cs,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        if (liquid.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: l10n.finance_record_liquidity_account,
            subtitle: l10n.finance_record_liquidity_hint,
            onTap: () => AddAccountDialog.show(context, initialAccountType: 'checking'),
          )
        else
          _accountsHorizontalList(context, liquid, block, isDark: isDark),
        const SizedBox(height: 24),
        _accountsGroupHeader(
          context,
          title: l10n.finance_accounts_investment_title,
          onAdd: () => AddAccountDialog.show(context, initialAccountType: 'investment'),
          cs: cs,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        if (investment.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.candlestick_chart_rounded,
            title: l10n.finance_record_investment_account,
            subtitle: l10n.finance_record_investment_account_hint,
            onTap: () => AddAccountDialog.show(context, initialAccountType: 'investment'),
          )
        else
          _accountsHorizontalList(context, investment, block, isDark: isDark),
      ],
    );
  }

  Widget _accountsGroupHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onAdd,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 12),
            child: Row(
              children: [
                Icon(
                  Icons.add_rounded,
                  color: FinanceSurface.silverAccent(),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.add.toUpperCase(),
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
    );
  }

  Widget _accountsHorizontalList(
    BuildContext context,
    List<FinancialAccountProtocol> accounts,
    FinanceBlock block, {
    required bool isDark,
  }) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 4),
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildAccountCard(
            context,
            accounts[index],
            block,
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    FinancialAccountProtocol account,
    FinanceBlock block, {
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      width: 176,
      child: FinanceSurface.card(
        cs: cs,
        isDark: isDark,
        radius: 24,
        padding: FinanceSurface.cardPaddingCompact,
        margin: const EdgeInsets.only(right: 4, bottom: 8),
        elevated: true,
        onTap: () => AddAccountDialog.show(context, account: account),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _getAccountIcon(account.accountType, isDark: isDark),
                const SizedBox(width: 10),
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
      ),
    );
  }

  Widget _getAccountIcon(String type, {required bool isDark}) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'investment':
        icon = Icons.candlestick_chart_rounded;
        break;
      case 'savings':
      case 'deposit':
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
    return FinanceSurface.card(
      cs: cs,
      isDark: isDark,
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      margin: FinanceSurface.cardMargin,
      elevated: true,
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: cs.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceQuickActions extends StatelessWidget {
  const _FinanceQuickActions({required this.financeBlock});

  final FinanceBlock financeBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      (
        icon: Icons.receipt_long_rounded,
        label: l10n.finance_shortcut_transaction,
        onTap: () => TransactionBuilderDialog.show(
          context,
          financeBlock: financeBlock,
        ),
      ),
      (
        icon: Icons.account_balance_rounded,
        label: l10n.finance_shortcut_account,
        onTap: () => AddAccountDialog.show(context),
      ),
      (
        icon: Icons.diamond_outlined,
        label: l10n.finance_shortcut_asset,
        onTap: () => AddAssetDialog.show(context),
      ),
      (
        icon: Icons.trending_up_rounded,
        label: l10n.finance_shortcut_income,
        onTap: () => showFixedIncomeEditor(context, financeBlock),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: FinanceSurface.card(
              cs: cs,
              isDark: isDark,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 6),
              elevated: true,
              onTap: actions[i].onTap,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FinanceSurface.silverAccent()
                          .withValues(alpha: isDark ? 0.16 : 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      actions[i].icon,
                      size: 18,
                      color: FinanceSurface.silverAccent(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actions[i].label,
                    style: TextStyle(
                      color: FinanceSurface.ink(isDark: isDark),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CashflowDonutPainter extends CustomPainter {
  _CashflowDonutPainter({
    required this.incomeRatio,
    required this.incomeColor,
    required this.spendingColor,
    required this.trackColor,
  });

  final double incomeRatio;
  final Color incomeColor;
  final Color spendingColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 10.0;
    const startAngle = -math.pi / 2;
    const gap = 0.04;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final ratio = incomeRatio.clamp(0.0, 1.0);
    final incomeAngle = ratio * (2 * math.pi) - gap;
    final spendingAngle = (1 - ratio) * (2 * math.pi) - gap;

    if (incomeAngle > 0.01) {
      final incomePaint = Paint()
        ..color = incomeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        incomeAngle,
        false,
        incomePaint,
      );
    }

    if (spendingAngle > 0.01) {
      final spendingPaint = Paint()
        ..color = spendingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + incomeAngle + gap * 2,
        spendingAngle,
        false,
        spendingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CashflowDonutPainter oldDelegate) =>
      incomeRatio != oldDelegate.incomeRatio;
}

class _FinanceGoalsSection extends StatelessWidget {
  const _FinanceGoalsSection({required this.financeBlock});

  final FinanceBlock financeBlock;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Watch((context) {
      final growthBlock = context.read<GrowthBlock>();
      final allGoals = growthBlock.goals.value;
      final financeGoals = allGoals
          .where((g) => g.category == 'finance' && g.status == 'active')
          .toList();

      if (financeGoals.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINANCE GOALS',
            style: TextStyle(
              color: FinanceSurface.mutedInk(isDark: isDark),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          for (final goal in financeGoals) ...[
            _FinanceGoalCard(
              goal: goal,
              financeBlock: financeBlock,
              isDark: isDark,
              colorScheme: cs,
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    });
  }
}

class _FinanceGoalCard extends StatelessWidget {
  const _FinanceGoalCard({
    required this.goal,
    required this.financeBlock,
    required this.isDark,
    required this.colorScheme,
  });

  final GoalProtocol goal;
  final FinanceBlock financeBlock;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progressPercentage / 100).clamp(0.0, 1.0);
    final accent = progress >= 1.0
        ? const Color(0xFF4CAF50)
        : FinanceSurface.silverAccent();
    final dateFmt = DateFormat.yMMMd();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: FinanceSurface.panel(colorScheme, isDark: isDark, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                progress >= 1.0
                    ? Icons.check_circle_rounded
                    : Icons.flag_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FinanceSurface.ink(isDark: isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${goal.progressPercentage}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: colorScheme.outline.withValues(
                alpha: isDark ? 0.2 : 0.15,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (goal.targetDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Target: ${dateFmt.format(goal.targetDate!)}',
              style: TextStyle(
                color: FinanceSurface.mutedInk(isDark: isDark),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
