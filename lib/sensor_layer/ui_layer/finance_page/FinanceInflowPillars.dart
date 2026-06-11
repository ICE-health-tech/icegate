import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FixedIncomeManager.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Personal-finance inflow layers (quant / portfolio mindset).
abstract final class FinanceInflowPillar {
  static const humanCapital = 'human_capital';
  static const liquidity = 'liquidity';
  static const fixedIncome = 'fixed_income';
  static const investment = 'investment';
  static const cashflow = 'cashflow';

  static const ordered = [
    humanCapital,
    liquidity,
    fixedIncome,
    investment,
    cashflow,
  ];

  /// Recurring-income / transaction categories mapped to a pillar.
  static String? pillarForCategory(String? category) {
    if (category == null || category.isEmpty) return null;
    switch (category.toLowerCase()) {
      case 'human_capital':
        return humanCapital;
      case 'salary':
      case 'freelance':
      case 'bonus':
        return humanCapital;
      case 'rent':
        return fixedIncome;
      case 'investment':
      case 'gift':
        return investment;
      default:
        return null;
    }
  }

  static String label(AppLocalizations l10n, String pillar) {
    switch (pillar) {
      case humanCapital:
        return l10n.finance_inflow_pillar_human_capital;
      case liquidity:
        return l10n.finance_inflow_pillar_liquidity;
      case fixedIncome:
        return l10n.finance_inflow_pillar_fixed_income;
      case investment:
        return l10n.finance_inflow_pillar_investment;
      case cashflow:
        return l10n.finance_inflow_pillar_cashflow;
      default:
        return pillar;
    }
  }

  static IconData icon(String pillar) {
    switch (pillar) {
      case humanCapital:
        return Icons.psychology_alt_rounded;
      case liquidity:
        return Icons.account_balance_wallet_rounded;
      case fixedIncome:
        return Icons.savings_rounded;
      case investment:
        return Icons.candlestick_chart_rounded;
      case cashflow:
        return Icons.loop_rounded;
      default:
        return Icons.trending_up_rounded;
    }
  }
}

/// Compact pillar legend on Finance overview.
class FinanceInflowPillarsStrip extends StatelessWidget {
  const FinanceInflowPillarsStrip({super.key, required this.financeBlock});

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
          l10n.finance_inflow_pillars_title.toUpperCase(),
          style: TextStyle(
            color: FinanceSurface.mutedInk(isDark: isDark),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.finance_inflow_pillars_subtitle,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Watch((context) {
          final byPillar = financeBlock.monthlyInflowByPillar.value;
          final capacity = financeBlock.monthlyHumanCapitalCapacity.value;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pillar in FinanceInflowPillar.ordered)
                _PillarChip(
                  label: FinanceInflowPillar.label(l10n, pillar),
                  icon: FinanceInflowPillar.icon(pillar),
                  amount: byPillar[pillar] ?? 0,
                  capacityHint: pillar == FinanceInflowPillar.humanCapital &&
                          capacity > 0
                      ? capacity
                      : null,
                  isDark: isDark,
                  colorScheme: cs,
                  emphasized: pillar == FinanceInflowPillar.humanCapital,
                  onTap: pillar == FinanceInflowPillar.humanCapital
                      ? () => showFixedIncomeEditor(
                            context,
                            financeBlock,
                            initialCategory: 'human_capital',
                          )
                      : null,
                  format: financeBlock.formatCurrency,
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _PillarChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final double amount;
  final double? capacityHint;
  final bool isDark;
  final ColorScheme colorScheme;
  final bool emphasized;
  final VoidCallback? onTap;
  final String Function(double, {bool compact}) format;

  const _PillarChip({
    required this.label,
    required this.icon,
    required this.amount,
    this.capacityHint,
    required this.isDark,
    required this.colorScheme,
    this.emphasized = false,
    this.onTap,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = emphasized
        ? FinanceSurface.silverAccent()
        : FinanceSurface.mutedInk(isDark: isDark);
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: FinanceSurface.panel(
        colorScheme,
        isDark: isDark,
        radius: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: emphasized
                      ? FinanceSurface.ink(isDark: isDark)
                      : FinanceSurface.mutedInk(isDark: isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (amount > 0 || capacityHint != null) ...[
            const SizedBox(height: 4),
            if (amount > 0)
              Text(
                format(amount, compact: true),
                style: TextStyle(
                  color: FinanceSurface.ink(isDark: isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            if (capacityHint != null && capacityHint! > 0)
              Text(
                '${l10n.finance_hc_capacity_label}: ${format(capacityHint!, compact: true)}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
          ],
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

/// Income category keys shown in editors (human capital first).
const List<String> financeIncomeCategoryKeys = [
  'human_capital',
  'salary',
  'freelance',
  'investment',
  'gift',
  'bonus',
  'rent',
];

String financeIncomeCategoryLabel(AppLocalizations l10n, String key) =>
    FinancePage.getCategoryName(l10n, key);
