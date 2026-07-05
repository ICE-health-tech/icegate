import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:intl/intl.dart';

/// One calendar day — transactions plus linked jobs / due incomes.
class FinanceDayCellData {
  const FinanceDayCellData({
    this.transactions = const [],
    this.jobs = const [],
  });

  final List<TransactionData> transactions;
  final List<JobPositionData> jobs;

  bool get hasContent => transactions.isNotEmpty || jobs.isNotEmpty;
}

/// Month grid for Finance daily tab — each cell shows job + txn summary.
class FinanceDailyCalendar extends StatelessWidget {
  const FinanceDailyCalendar({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.dayData,
    required this.financeBlock,
    required this.onMonthChanged,
    required this.onDaySelected,
    this.outerDecoration,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<DateTime, FinanceDayCellData> dayData;
  final FinanceBlock financeBlock;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final BoxDecoration? outerDecoration;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = FinanceSurface.ink(isDark: isDark);
    final muted = FinanceSurface.mutedInk(isDark: isDark);
    final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leadingEmpty = monthStart.weekday - 1;
    final today = dateOnly(DateTime.now());
    final selected = dateOnly(selectedDay);
    final weekdayLabels = MaterialLocalizations.of(context).narrowWeekdays;
    final mondayFirstLabels = [
      ...weekdayLabels.sublist(1),
      weekdayLabels.first,
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final cellHeight = wide ? 96.0 : 84.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: outerDecoration ??
          FinanceSurface.panel(cs, isDark: isDark, radius: 20, elevated: true),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
                icon: Icon(Icons.chevron_left_rounded, color: accent),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(monthStart),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
                icon: Icon(Icons.chevron_right_rounded, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: mondayFirstLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: cellHeight,
            ),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();

              final day = index - leadingEmpty + 1;
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final key = dateOnly(date);
              final cell = dayData[key] ?? const FinanceDayCellData();
              final isToday = key == today;
              final isSelected = key == selected;

              return _DayCell(
                day: day,
                data: cell,
                financeBlock: financeBlock,
                isDark: isDark,
                accent: accent,
                muted: muted,
                isToday: isToday,
                isSelected: isSelected,
                onTap: () => onDaySelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.data,
    required this.financeBlock,
    required this.isDark,
    required this.accent,
    required this.muted,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final FinanceDayCellData data;
  final FinanceBlock financeBlock;
  final bool isDark;
  final Color accent;
  final Color muted;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasContent = data.hasContent;
    final job = data.jobs.isNotEmpty ? data.jobs.first : null;
    final txns = data.transactions;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FinanceSurface.silverAccent().withValues(alpha: 0.35),
                      FinanceSurface.silverAccent().withValues(alpha: 0.12),
                    ],
                  )
                : (hasContent
                    ? FinanceSurface.panelGradient(isDark: isDark)
                    : null),
            color: isSelected
                ? null
                : (hasContent ? null : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? FinanceSurface.silverAccent()
                  : (isToday
                      ? FinanceSurface.silverAccent().withValues(alpha: 0.7)
                      : (hasContent
                          ? FinanceSurface.border(isDark: isDark)
                              .withValues(alpha: 0.5)
                          : muted.withValues(alpha: 0.2))),
              width: isToday || isSelected ? 1.4 : 1,
            ),
            boxShadow: hasContent && !isSelected
                ? FinanceSurface.shadows(isDark: isDark)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? accent : accent.withValues(alpha: 0.9),
                  ),
                ),
                if (job != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    job.employer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      color: FinanceSurface.silverAccent(),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    job.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ],
                if (txns.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final t in txns.take(2))
                          _TxnLine(txn: t, block: financeBlock, muted: muted),
                        if (txns.length > 2)
                          Text(
                            '+${txns.length - 2}',
                            style: TextStyle(
                              fontSize: 6,
                              color: muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TxnLine extends StatelessWidget {
  const _TxnLine({
    required this.txn,
    required this.block,
    required this.muted,
  });

  final TransactionData txn;
  final FinanceBlock block;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final isOut =
        txn.type == 'expense' || txn.type == 'investment';
    final label = (txn.description?.trim().isNotEmpty ?? false)
        ? txn.description!.trim()
        : txn.category;
    return Text(
      '${isOut ? '−' : '+'}${block.formatCurrency(txn.amount, compact: true)} · $label',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 6.5,
        fontWeight: FontWeight.w700,
        color: isOut ? muted : FinanceSurface.silverAccent(),
        height: 1.25,
      ),
    );
  }
}

/// Builds per-day job + transaction map for [FinanceDailyCalendar].
FinanceDayCellData mergeDayCell(
  FinanceDayCellData existing, {
  TransactionData? transaction,
  JobPositionData? job,
}) {
  final txns = [...existing.transactions];
  final jobs = [...existing.jobs];

  if (transaction != null &&
      !txns.any((t) => t.id == transaction.id)) {
    txns.add(transaction);
  }
  if (job != null && !jobs.any((j) => j.id == job.id)) {
    jobs.add(job);
  }
  return FinanceDayCellData(transactions: txns, jobs: jobs);
}

JobPositionData? jobForTransaction(
  TransactionData txn,
  List<JobPositionData> jobs,
  List<RecurringIncomeData> incomes,
) {
  if (txn.type == 'income') {
    for (final income in incomes) {
      final jobId = income.jobPositionId;
      if (jobId == null) continue;
      final txnDesc = txn.description?.trim().toLowerCase();
      final incDesc = income.description?.trim().toLowerCase();
      if (txnDesc != null &&
          incDesc != null &&
          txnDesc == incDesc) {
        return jobs.where((j) => j.id == jobId).firstOrNull;
      }
      if (txn.amount == income.amount &&
          txn.category == income.category) {
        return jobs.where((j) => j.id == jobId).firstOrNull;
      }
    }
    for (final job in jobs) {
      final linkedId = job.linkedIncomeId;
      if (linkedId == null) continue;
      final income =
          incomes.where((i) => i.id == linkedId).firstOrNull;
      if (income != null &&
          txn.amount == income.amount &&
          txn.category == income.category) {
        return job;
      }
    }
  }
  if (txn.projectID != null) {
    return jobs
        .where((j) => j.linkedProjectId == txn.projectID)
        .firstOrNull;
  }
  return null;
}

JobPositionData? jobForRecurringIncome(
  RecurringIncomeData income,
  List<JobPositionData> jobs,
) {
  final id = income.jobPositionId;
  if (id != null) {
    return jobs.where((j) => j.id == id).firstOrNull;
  }
  return jobs.where((j) => j.linkedIncomeId == income.id).firstOrNull;
}

Map<DateTime, FinanceDayCellData> buildFinanceDayData({
  required List<TransactionData> transactions,
  required List<JobPositionData> jobs,
  required List<RecurringIncomeData> incomes,
}) {
  final map = <DateTime, FinanceDayCellData>{};

  void put(DateTime day, FinanceDayCellData Function(FinanceDayCellData) fn) {
    final key = FinanceDailyCalendar.dateOnly(day);
    map[key] = fn(map[key] ?? const FinanceDayCellData());
  }

  for (final txn in transactions) {
    final day = txn.transactionDate.toLocal();
    final job = jobForTransaction(txn, jobs, incomes);
    put(day, (c) => mergeDayCell(c, transaction: txn, job: job));
  }

  for (final income in incomes) {
    if (!income.isActive) continue;
    final day = income.nextDueAt.toLocal();
    final job = jobForRecurringIncome(income, jobs);
    put(day, (c) {
      var next = c;
      if (job != null) next = mergeDayCell(next, job: job);
      return next;
    });
  }

  return map;
}
