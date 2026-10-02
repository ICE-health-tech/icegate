import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/JobWorkLogBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/JobWorkTaskPickerSheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Tap days on a job card to mark when you worked.
class JobWorkDayStrip extends StatefulWidget {
  const JobWorkDayStrip({
    super.key,
    required this.personId,
    required this.jobId,
    required this.jobTitle,
    required this.accent,
  });

  final String personId;
  final String jobId;
  final String jobTitle;
  final Color accent;

  @override
  State<JobWorkDayStrip> createState() => _JobWorkDayStripState();
}

class _JobWorkDayStripState extends State<JobWorkDayStrip> {
  Set<DateTime> _workDays = {};
  bool _loading = true;

  JobWorkLogBlock get _block => context.read<JobWorkLogBlock>();
  
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(JobWorkDayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId != widget.jobId ||
        oldWidget.personId != widget.personId) {
      _reload();
    }
  }

  @override
  void activate() {
    super.activate();
    _reload();
  }

  Future<void> _reload() async {
    final days = await _block.loggedDaysForJob(widget.personId, widget.jobId);
    if (!mounted) return;
    setState(() {
      _workDays = days;
      _loading = false;
    });
  }

  Future<void> _openTimeSheet(DateTime day) async {
    await showJobWorkTaskPicker(
      context,
      personId: widget.personId,
      jobId: widget.jobId,
      jobTitle: widget.jobTitle,
      day: day,
      accent: widget.accent,
    );
    await _reload();
  }

  Future<void> _toggle(DateTime day) async {
    HapticFeedback.selectionClick();
    final today = _dateOnly(DateTime.now());
    if (day == today || !_workDays.contains(day)) {
      await _openTimeSheet(day);
      return;
    }
    await _block.toggleWorkDay(widget.personId, widget.jobId, day);
    await _reload();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = _dateOnly(DateTime.now());
    final streak = JobWorkLogBlock.streakFor(_workDays);
    final loggedToday = _workDays.contains(today);

    if (_loading) {
      return const SizedBox(height: 36);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.finance_job_work_days.toUpperCase(),
              style: TextStyle(
                color: widget.accent.withValues(alpha: 0.45),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (streak > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 12,
                    color: Colors.greenAccent.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l10n.finance_job_work_streak(streak),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final day = today.subtract(Duration(days: 6 - i));
            final logged = _workDays.contains(day);
            final isToday = day == today;
            final weekday = DateFormat.E(l10n.localeName)
                .format(day)
                .substring(0, 1)
                .toUpperCase();
            final dayNum = DateFormat.d(l10n.localeName).format(day);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
                child: GestureDetector(
                  onTap: () => _toggle(day),
                  child: Column(
                    children: [
                      Text(
                        isToday ? l10n.finance_job_log_today : weekday,
                        style: TextStyle(
                          fontSize: isToday ? 7 : 8,
                          fontWeight: FontWeight.w800,
                          color: isToday
                              ? widget.accent
                              : widget.accent.withValues(alpha: 0.35),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayNum,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isToday
                              ? widget.accent
                              : widget.accent.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 28,
                        decoration: BoxDecoration(
                          color: logged
                              ? Colors.greenAccent.withValues(alpha: 0.22)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isToday
                                ? widget.accent.withValues(alpha: 0.5)
                                : logged
                                    ? Colors.greenAccent.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.08),
                            width: isToday ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            logged
                                ? Icons.check_rounded
                                : Icons.remove_rounded,
                            size: 14,
                            color: logged
                                ? Colors.greenAccent
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        if (!loggedToday) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openTimeSheet(today),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.today_rounded, size: 14),
              label: Text(
                l10n.finance_job_log_today,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
