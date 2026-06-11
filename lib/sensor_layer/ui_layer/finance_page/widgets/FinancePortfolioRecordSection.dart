import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceAssetPillars.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceInflowPillars.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/finance_form/AddAccountDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/finance_form/AddAssetDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FixedIncomeManager.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/SubscriptionManager.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Quick entry points to record each finance layer (assets + human capital + subs).
class FinancePortfolioRecordSection extends StatelessWidget {
  const FinancePortfolioRecordSection({super.key, required this.financeBlock});

  final FinanceBlock financeBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.finance_record_section_title.toUpperCase(),
          style: TextStyle(
            color: FinanceSurface.mutedInk(isDark: isDark),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.finance_record_section_subtitle,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RecordTile(
              label: l10n.finance_record_human_capital,
              subtitle: l10n.finance_record_human_capital_hint,
              icon: FinanceInflowPillar.icon(FinanceInflowPillar.humanCapital),
              isDark: isDark,
              colorScheme: cs,
              onTap: () => showFixedIncomeEditor(
                context,
                financeBlock,
                initialCategory: 'human_capital',
              ),
            ),
            _RecordTile(
              label: l10n.finance_record_liquidity_account,
              subtitle: l10n.finance_record_liquidity_hint,
              icon: FinanceAssetPillar.icon(FinanceAssetPillar.liquidity),
              isDark: isDark,
              colorScheme: cs,
              onTap: () => AddAccountDialog.show(
                context,
                initialAccountType: 'checking',
              ),
            ),
            _RecordTile(
              label: l10n.finance_record_fixed_income_asset,
              subtitle: l10n.finance_record_fixed_income_hint,
              icon: FinanceAssetPillar.icon(FinanceAssetPillar.fixedIncome),
              isDark: isDark,
              colorScheme: cs,
              onTap: () => AddAssetDialog.show(
                context,
                initialCategory: FinanceAssetCategories.bond,
              ),
            ),
            _RecordTile(
              label: l10n.finance_record_investment_account,
              subtitle: l10n.finance_record_investment_account_hint,
              icon: FinanceAssetPillar.icon(FinanceAssetPillar.investment),
              isDark: isDark,
              colorScheme: cs,
              onTap: () => AddAccountDialog.show(
                context,
                initialAccountType: 'investment',
              ),
            ),
            _RecordTile(
              label: l10n.finance_record_investment_holding,
              subtitle: l10n.finance_record_investment_holding_hint,
              icon: Icons.show_chart_rounded,
              isDark: isDark,
              colorScheme: cs,
              onTap: () => AddAssetDialog.show(
                context,
                initialCategory: FinanceAssetCategories.stock,
              ),
            ),
            _RecordTile(
              label: l10n.finance_record_cashflow_asset,
              subtitle: l10n.finance_record_cashflow_hint,
              icon: FinanceAssetPillar.icon(FinanceAssetPillar.cashflow),
              isDark: isDark,
              colorScheme: cs,
              onTap: () => AddAssetDialog.show(
                context,
                initialCategory: FinanceAssetCategories.cashflow,
              ),
            ),
            _RecordTile(
              label: l10n.finance_record_subscription,
              subtitle: l10n.finance_record_subscription_hint,
              icon: Icons.autorenew_rounded,
              isDark: isDark,
              colorScheme: cs,
              onTap: () => showSubscriptionEditor(context, financeBlock),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Watch((context) {
          final capacity = financeBlock.monthlyHumanCapitalCapacity.value;
          final realized = financeBlock.monthlyHumanCapitalRealized.value;
          if (capacity <= 0 && realized <= 0) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.finance_hc_gap_title,
                  style: TextStyle(
                    color: FinanceSurface.ink(isDark: isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                if (capacity > 0)
                  Text(
                    '${l10n.finance_hc_capacity_label}: ${financeBlock.formatCurrency(capacity, compact: true)}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                if (realized > 0)
                  Text(
                    '${l10n.finance_hc_realized_label}: ${financeBlock.formatCurrency(realized, compact: true)}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                if (capacity > realized && realized > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.finance_hc_gap_message(
                      financeBlock.formatCurrency(capacity, compact: true),
                      financeBlock.formatCurrency(realized, compact: true),
                      financeBlock.formatCurrency(capacity - realized, compact: true),
                    ),
                    style: TextStyle(
                      color: FinanceSurface.silverAccent(),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 158,
          padding: const EdgeInsets.all(10),
          decoration: FinanceSurface.panel(
            colorScheme,
            isDark: isDark,
            radius: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: FinanceSurface.silverAccent()),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FinanceSurface.ink(isDark: isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FinanceSurface.mutedInk(isDark: isDark),
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
