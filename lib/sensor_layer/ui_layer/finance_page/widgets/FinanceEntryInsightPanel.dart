import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';

/// Live preview of how a draft finance entry affects the month.
class FinanceEntryInsight {
  const FinanceEntryInsight({
    required this.analysis,
    this.suggestions = const [],
    this.tone = FinanceInsightTone.neutral,
  });

  final String analysis;
  final List<String> suggestions;
  final FinanceInsightTone tone;
}

enum FinanceInsightTone { neutral, positive, caution, risk }

double monthlyFromRecurringAmount(double amount, String interval) {
  switch (interval) {
    case 'weekly':
      return amount * 52 / 12;
    case 'yearly':
      return amount / 12;
    case 'monthly':
    default:
      return amount;
  }
}

FinanceEntryInsight buildFixedIncomeInsight({
  required AppLocalizations l10n,
  required FinanceBlock block,
  required double? draftAmountBase,
  required String interval,
  required String category,
  RecurringIncomeData? editing,
}) {
  if (draftAmountBase == null || draftAmountBase <= 0) {
    return FinanceEntryInsight(
      analysis: l10n.finance_insight_enter_amount,
      tone: FinanceInsightTone.neutral,
    );
  }

  final draftMonthly = monthlyFromRecurringAmount(draftAmountBase, interval);
  var currentMonthly = block.monthlyFixedIncome.value;
  if (editing != null) {
    currentMonthly -= monthlyFromRecurringAmount(
      editing.amount,
      editing.interval,
    );
  }
  final projectedMonthly = currentMonthly + draftMonthly;
  final spending = block.monthlySpending.value;

  final analysisParts = <String>[
    l10n.finance_insight_fixed_after(
      block.formatCurrency(projectedMonthly, compact: true),
    ),
  ];

  FinanceInsightTone tone = FinanceInsightTone.positive;
  if (spending > 0) {
    final pct = (projectedMonthly / spending * 100).clamp(0, 999);
    analysisParts.add(
      l10n.finance_insight_covers_spending(
        pct.toStringAsFixed(0),
        block.formatCurrency(spending, compact: true),
      ),
    );
    final gap = projectedMonthly - spending;
    if (gap < 0) {
      analysisParts.add(
        l10n.finance_insight_shortfall(
          block.formatCurrency(gap.abs(), compact: true),
        ),
      );
      tone = FinanceInsightTone.risk;
    } else if (gap > 0) {
      analysisParts.add(
        l10n.finance_insight_surplus(
          block.formatCurrency(gap, compact: true),
        ),
      );
    }
  }

  final suggestions = <String>[];
  for (final item in block.recurringIncomes.value) {
    if (editing != null && item.id == editing.id) continue;
    if (item.category == category) {
      final name = (item.description?.trim().isNotEmpty ?? false)
          ? item.description!.trim()
          : FinancePage.getCategoryName(l10n, item.category);
      suggestions.add(l10n.finance_insight_duplicate_fixed(name));
      break;
    }
  }

  return FinanceEntryInsight(
    analysis: analysisParts.join(' '),
    suggestions: suggestions,
    tone: tone,
  );
}

FinanceEntryInsight buildTransactionInsight({
  required AppLocalizations l10n,
  required FinanceBlock block,
  required double? draftAmountBase,
  required String type,
  required bool recurringIncome,
  required String recurringInterval,
}) {
  if (draftAmountBase == null || draftAmountBase <= 0) {
    return FinanceEntryInsight(
      analysis: l10n.finance_insight_enter_amount,
      tone: FinanceInsightTone.neutral,
    );
  }

  final suggestions = <String>[];
  var tone = FinanceInsightTone.neutral;
  String analysis;

  switch (type) {
    case 'expense':
      final spending = block.monthlySpending.value;
      final projected = spending + draftAmountBase;
      if (spending > 0) {
        final pct = (draftAmountBase / spending * 100).clamp(0, 999);
        analysis = l10n.finance_insight_expense_share(pct.toStringAsFixed(0));
        if (pct >= 25) {
          suggestions.add(l10n.finance_insight_expense_large);
          tone = FinanceInsightTone.caution;
        } else {
          tone = FinanceInsightTone.neutral;
        }
      } else {
        analysis = l10n.finance_insight_expense_share('100');
        tone = FinanceInsightTone.caution;
      }
      final fixed = block.monthlyFixedIncome.value;
      if (fixed > 0 && projected > fixed) {
        suggestions.add(l10n.finance_insight_shortfall(
          block.formatCurrency(projected - fixed, compact: true),
        ));
        tone = FinanceInsightTone.risk;
      }
      break;

    case 'income':
      final income = block.monthlyIncome.value;
      if (income > 0) {
        final pct = (draftAmountBase / income * 100).clamp(0, 999);
        analysis = l10n.finance_insight_income_share(pct.toStringAsFixed(0));
      } else {
        analysis = l10n.finance_insight_income_share('100');
      }
      tone = FinanceInsightTone.positive;
      if (recurringIncome) {
        final monthly = monthlyFromRecurringAmount(
          draftAmountBase,
          recurringInterval,
        );
        suggestions.add(
          l10n.finance_insight_recurring_equiv(
            block.formatCurrency(monthly, compact: true),
          ),
        );
      }
      break;

    case 'savings':
      final total = block.totalSavings.value + draftAmountBase;
      analysis = l10n.finance_insight_savings_total(
        block.formatCurrency(total, compact: true),
      );
      tone = FinanceInsightTone.positive;
      break;

    default:
      analysis = l10n.finance_insight_enter_amount;
  }

  return FinanceEntryInsight(
    analysis: analysis,
    suggestions: suggestions,
    tone: tone,
  );
}

class FinanceEntryInsightPanel extends StatelessWidget {
  const FinanceEntryInsightPanel({super.key, required this.insight});

  final FinanceEntryInsight insight;

  Color _accentFor(FinanceInsightTone tone) {
    switch (tone) {
      case FinanceInsightTone.positive:
        return const Color(0xFF4CAF50);
      case FinanceInsightTone.caution:
        return Colors.amberAccent;
      case FinanceInsightTone.risk:
        return Colors.redAccent;
      case FinanceInsightTone.neutral:
        return EntryColors.financeSilverAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = _accentFor(insight.tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.finance_insight_title.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.analysis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (insight.suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.finance_insight_suggestions.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            ...insight.suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
