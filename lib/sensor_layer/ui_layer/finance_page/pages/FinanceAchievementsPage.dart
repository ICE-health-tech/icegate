import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementBuilderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/widgets/AppSessionCalendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  height: 1.35,
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
                      return Colors.black;
                    }
                    return Colors.white70;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return EntryColors.financeSilverAccent;
                    }
                    return Colors.white.withValues(alpha: 0.05);
                  }),
                ),
              ),
              const SizedBox(height: 16),
              if (_mode == _PeriodMode.month) ...[
                AppSessionCalendar(
                  markedDays: marked,
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  onMonthChanged: (m) =>
                      setState(() => _focusedMonth = DateTime(m.year, m.month)),
                  onDaySelected: (d) => setState(() {
                    _selectedDay = _dateOnly(d);
                    _focusedMonth = DateTime(d.year, d.month);
                  }),
                ),
                if (onSelectedDay.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...onSelectedDay.map((a) => _achievementTile(a, l10n)),
                ],
              ],
              const SizedBox(height: 20),
              Text(
                _mode == _PeriodMode.month
                    ? DateFormat.yMMMM(l10n.localeName)
                        .format(_focusedMonth)
                        .toUpperCase()
                    : '${_focusedMonth.year}',
                style: const TextStyle(
                  color: Colors.white54,
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
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                )
              else ...[
                ...periodAuto.map((m) => _milestoneTile(m)),
                ...periodAchievements.map((a) => _achievementTile(a, l10n)),
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

  Widget _achievementTile(AchievementData a, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EntryColors.financeSilverAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (a.description != null && a.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    a.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  DateFormat.yMMMd(l10n.localeName).format(a.createdAt.toLocal()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
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

  Widget _milestoneTile(_Milestone m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  m.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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
