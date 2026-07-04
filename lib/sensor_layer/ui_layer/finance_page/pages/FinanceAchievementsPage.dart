import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementBuilderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/widgets/AppSessionCalendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
enum _PeriodMode { month, year }

class FinanceAchievementsPage extends StatefulWidget {
  final FinanceBlock financeBlock;

  const FinanceAchievementsPage({super.key, required this.financeBlock});

  @override
  State<FinanceAchievementsPage> createState() => _FinanceAchievementsPageState();
}

class _FinanceAchievementsPageState extends State<FinanceAchievementsPage> {
  _PeriodMode _mode = _PeriodMode.month;
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = _dateOnly(now);
  }

  bool _inMonth(DateTime d, DateTime month) =>
      d.year == month.year && d.month == month.month;

  bool _inYear(DateTime d, int year) => d.year == year;

  List<AchievementData> _financeAchievements(List<AchievementData> all) {
    return all
        .where((a) => a.domain.toLowerCase().contains('finance'))
        .toList();
  }

  // STORY: A job "covers" a day when the day is on or after its start
  // and on or before its end (no end = still working). So picking any
  // day on the calendar shows which jobs you held that day.
  List<JobPositionData> _jobsOnDay(DateTime day) {
    final d = _dateOnly(day);
    return widget.financeBlock.jobPositions.value.where((job) {
      final start = _dateOnly(job.startDate.toLocal());
      if (d.isBefore(start)) return false;
      final end = job.endDate;
      if (end == null) return true;
      return !d.isAfter(_dateOnly(end.toLocal()));
    }).toList();
  }

  Set<DateTime> _markedDays(
    List<AchievementData> financeAchievements,
    List<_Milestone> auto,
  ) {
    final days = <DateTime>{};
    for (final a in financeAchievements) {
      days.add(_dateOnly(a.createdAt.toLocal()));
    }
    for (final m in auto) {
      days.add(_dateOnly(m.date));
    }
    return days;
  }

  List<_Milestone> _autoMilestones(AppLocalizations l10n) {
    final txns = widget.financeBlock.transactions.value;
    final year = _focusedMonth.year;
    final results = <_Milestone>[];

    if (_mode == _PeriodMode.month) {
      final monthTxns = txns.where(
        (t) => _inMonth(t.transactionDate.toLocal(), _focusedMonth),
      );
      final income = monthTxns
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final savings = monthTxns
          .where((t) => t.type == 'savings')
          .fold(0.0, (s, t) => s + t.amount);
      if (income > 0) {
        results.add(_Milestone(
          date: DateTime(_focusedMonth.year, _focusedMonth.month, 1),
          title: l10n.finance_milestone_month_income,
          subtitle: widget.financeBlock.formatCurrency(income),
        ));
      }
      if (savings > 0) {
        results.add(_Milestone(
          date: DateTime(_focusedMonth.year, _focusedMonth.month, 15),
          title: l10n.finance_milestone_month_savings,
          subtitle: widget.financeBlock.formatCurrency(savings),
        ));
      }
    } else {
      for (var m = 1; m <= 12; m++) {
        final month = DateTime(year, m);
        final monthTxns = txns.where(
          (t) => _inMonth(t.transactionDate.toLocal(), month),
        );
        final income = monthTxns
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        if (income > 0) {
          results.add(_Milestone(
            date: month,
            title: DateFormat.MMMM(l10n.localeName).format(month),
            subtitle: '${l10n.finance_milestone_month_income}: ${widget.financeBlock.formatCurrency(income, compact: true)}',
          ));
        }
      }
      final yearIncome = txns
          .where(
            (t) =>
                _inYear(t.transactionDate.toLocal(), year) && t.type == 'income',
          )
          .fold(0.0, (s, t) => s + t.amount);
      if (yearIncome > 0) {
        results.add(_Milestone(
          date: DateTime(year, 12, 31),
          title: l10n.finance_milestone_year_total,
          subtitle: widget.financeBlock.formatCurrency(yearIncome),
        ));
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final personId = context.watch<PersonBlock>().currentPersonID.value ?? '';
    final dao = context.read<AchievementsDAO>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<AchievementData>>(
      stream: dao.watchAchievementsByPerson(personId),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final financeOnly = _financeAchievements(all);
        final auto = _autoMilestones(l10n);
        final marked = _markedDays(financeOnly, auto);

        final periodAchievements = financeOnly.where((a) {
          final d = a.createdAt.toLocal();
          return _mode == _PeriodMode.month
              ? _inMonth(d, _focusedMonth)
              : _inYear(d, _focusedMonth.year);
        }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final periodAuto = auto.where((m) {
          return _mode == _PeriodMode.month
              ? _inMonth(m.date, _focusedMonth)
              : _inYear(m.date, _focusedMonth.year);
        }).toList();

        final onSelectedDay = [
          ...financeOnly.where(
            (a) => _dateOnly(a.createdAt.toLocal()) == _selectedDay,
          ),
        ];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.finance_achievements_subtitle,
                style: TextStyle(
                  color: FinanceSurface.mutedInk(isDark: isDark),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<_PeriodMode>(
                segments: [
                  ButtonSegment(
                    value: _PeriodMode.month,
                    label: Text(l10n.finance_period_month),
                  ),
                  ButtonSegment(
                    value: _PeriodMode.year,
                    label: Text(l10n.finance_period_year),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) {
                  setState(() => _mode = s.first);
                },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return FinanceSurface.ink(isDark: isDark);
                    }
                    return FinanceSurface.mutedInk(isDark: isDark);
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return FinanceSurface.silverAccent();
                    }
                    return FinanceSurface.panel(cs, isDark: isDark, radius: 12)
                        .color;
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(color: FinanceSurface.border(isDark: isDark)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_mode == _PeriodMode.month) ...[
                AppSessionCalendar(
                  markedDays: marked,
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  accentColor: FinanceSurface.ink(isDark: isDark),
                  outerDecoration:
                      FinanceSurface.panel(cs, isDark: isDark, radius: 20),
                  onMonthChanged: (m) =>
                      setState(() => _focusedMonth = DateTime(m.year, m.month)),
                  onDaySelected: (d) => setState(() {
                    _selectedDay = _dateOnly(d);
                    _focusedMonth = DateTime(d.year, d.month);
                  }),
                ),
                Watch((context) {
                  final jobs = _jobsOnDay(_selectedDay);
                  if (jobs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        l10n.finance_job_on_day.toUpperCase(),
                        style: TextStyle(
                          color: FinanceSurface.mutedInk(isDark: isDark),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...jobs.map((job) => _jobTile(job, l10n, isDark, cs)),
                    ],
                  );
                }),
                if (onSelectedDay.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...onSelectedDay.map((a) => _achievementTile(a, l10n, isDark, cs)),
                ],
              ],
              const SizedBox(height: 20),
              Text(
                _mode == _PeriodMode.month
                    ? DateFormat.yMMMM(l10n.localeName)
                        .format(_focusedMonth)
                        .toUpperCase()
                    : '${_focusedMonth.year}',
                style: TextStyle(
                  color: FinanceSurface.ink(isDark: isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              if (periodAuto.isEmpty && periodAchievements.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.finance_achievements_empty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FinanceSurface.mutedInk(isDark: isDark),
                      ),
                    ),
                  ),
                )
              else ...[
                ...periodAuto.map((m) => _milestoneTile(m, isDark, cs)),
                ...periodAchievements.map(
                  (a) => _achievementTile(a, l10n, isDark, cs),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => AchievementBuilderDialog.show(
                    context,
                    initialDomain: 'finance',
                  ),
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: Text(l10n.finance_achievements_add),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _achievementTile(
    AchievementData a,
    AppLocalizations l10n,
    bool isDark,
    ColorScheme cs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: FinanceSurface.silverAccent(),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: FinanceSurface.ink(isDark: isDark),
                  ),
                ),
                if (a.description != null && a.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    a.description!,
                    style: TextStyle(
                      color: FinanceSurface.mutedInk(isDark: isDark),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  DateFormat.yMMMd(l10n.localeName).format(a.createdAt.toLocal()),
                  style: TextStyle(
                    color: FinanceSurface.mutedInk(isDark: isDark),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobTile(
    JobPositionData job,
    AppLocalizations l10n,
    bool isDark,
    ColorScheme cs,
  ) {
    final isCurrent = job.endDate == null;
    final fmt = DateFormat.yMMMd(l10n.localeName);
    final range = isCurrent
        ? '${fmt.format(job.startDate.toLocal())} — ${l10n.finance_job_current}'
        : '${fmt.format(job.startDate.toLocal())} — ${fmt.format(job.endDate!.toLocal())}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 20),
      child: Row(
        children: [
          Icon(
            Icons.work_outline_rounded,
            color: isCurrent
                ? Colors.greenAccent
                : FinanceSurface.silverAccent(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.jobTitle.isNotEmpty ? job.jobTitle : job.employer,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: FinanceSurface.ink(isDark: isDark),
                  ),
                ),
                if (job.employer.isNotEmpty && job.jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    job.employer,
                    style: TextStyle(
                      color: FinanceSurface.mutedInk(isDark: isDark),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  range,
                  style: TextStyle(
                    color: FinanceSurface.mutedInk(isDark: isDark),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneTile(_Milestone m, bool isDark, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 20),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: FinanceSurface.silverAccent(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: FinanceSurface.ink(isDark: isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.subtitle,
                  style: TextStyle(
                    color: FinanceSurface.mutedInk(isDark: isDark),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone {
  final DateTime date;
  final String title;
  final String subtitle;
  const _Milestone({
    required this.date,
    required this.title,
    required this.subtitle,
  });
}
