import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/DailyFinanceReportReminderCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/ReportMailPanel.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// On-device summary for the current calendar day (same sources as [FinanceBlock]).
class FinanceDailyReportPage extends StatelessWidget {
  const FinanceDailyReportPage({super.key});

  static bool _sameCalendarDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final block = context.read<FinanceBlock>();
    final theme = Theme.of(context);

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: EntryColors.silverMetallicGradient,
                ),
              ),
            ),
            SafeArea(
              child: Watch((context) {
                final now = DateTime.now();
                final dayLabel = DateFormat.yMMMEd().format(now);
                final txs = block.transactions.value
                    .where((t) => _sameCalendarDay(t.transactionDate, now))
                    .toList()
                  ..sort(
                    (a, b) =>
                        b.transactionDate.compareTo(a.transactionDate),
                  );

                double income = 0;
                double outflows = 0;
                final Map<String, double> expenseByCategory = {};

                for (final t in txs) {
                  switch (t.type) {
                    case 'income':
                      income += t.amount;
                      break;
                    case 'expense':
                    case 'investment':
                      outflows += t.amount;
                      final label =
                          FinancePage.getCategoryName(l10n, t.category);
                      expenseByCategory[label] =
                          (expenseByCategory[label] ?? 0) + t.amount;
                      break;
                    default:
                      break;
                  }
                }

                final net = income - outflows;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      title: Text(
                        l10n.reports_hub_title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            dayLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white54,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const ReportMailPanel(),
                          const SizedBox(height: 28),
                          Text(
                            l10n.reports_finance_section.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white38,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const DailyFinanceReportReminderCard(
                            showOpenShortcut: false,
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            label: l10n.finance_daily_report_income,
                            value: block.formatCurrency(income),
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: l10n.finance_daily_report_expense,
                            value: block.formatCurrency(outflows),
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: l10n.finance_daily_report_net,
                            value: block.formatCurrency(net),
                            color: EntryColors.financeSilverAccent,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            l10n.finance_daily_report_spending_by_category
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white38,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (expenseByCategory.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                l10n.finance_daily_report_empty_day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white38),
                              ),
                            )
                          else ...[
                            Center(
                              child: SimplePieChart(
                                data: expenseByCategory,
                                colors: const [
                                  EntryColors.financeSilverAccent,
                                  Color(0xFF839BF3),
                                  Color(0xFFA5B4FC),
                                  Color(0xFFF0FDFA),
                                  Color(0xFF00E5FF),
                                  Color(0xFF4F46E5),
                                ],
                                size: 160,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...expenseByCategory.entries.map((e) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.key,
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                    ),
                                    Text(
                                      block.formatCurrency(e.value),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 28),
                          Text(
                            l10n.finance_daily_report_today_transactions
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white38,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (txs.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                l10n.finance_daily_report_empty_day,
                                style: const TextStyle(color: Colors.white38),
                              ),
                            )
                          else
                            ...txs.map((t) => _TxnTile(t: t, block: block)),
                          const SizedBox(height: 80),
                        ]),
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
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final TransactionData t;
  final FinanceBlock block;

  const _TxnTile({required this.t, required this.block});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeStr =
        DateFormat.Hm().format(t.transactionDate.toLocal());
    final cat = FinancePage.getCategoryName(l10n, t.category);
    final typeLabel = switch (t.type) {
      'income' => l10n.finance_type_income,
      'expense' => l10n.finance_type_expense,
      'savings' => l10n.finance_type_savings,
      'investment' => l10n.finance_cat_investing,
      _ => t.type,
    };
    final isOutflow = t.type == 'expense' || t.type == 'investment';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                timeStr,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                  if (t.description != null && t.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        t.description!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${isOutflow ? '-' : '+'}${block.formatCurrency(t.amount)}',
              style: TextStyle(
                color: isOutflow ? Colors.redAccent : Colors.greenAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
