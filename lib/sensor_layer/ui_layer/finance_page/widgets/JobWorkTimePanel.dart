import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Models/JobTaskType.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/JobWorkLogBlock.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// "Log thời gian" — final step for every task type.
class JobWorkTimePanel extends StatefulWidget {
  const JobWorkTimePanel({
    super.key,
    required this.personId,
    required this.jobId,
    required this.jobTitle,
    required this.day,
    required this.task,
    required this.accent,
    this.onBack,
  });

  final String personId;
  final String jobId;
  final String jobTitle;
  final DateTime day;
  final JobWorkTask task;
  final Color accent;
  final VoidCallback? onBack;

  @override
  State<JobWorkTimePanel> createState() => _JobWorkTimePanelState();
}

class _JobWorkTimePanelState extends State<JobWorkTimePanel> {
  final _planCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();

  JobDayTimeSummary? _summary;
  Timer? _tick;
  bool _loading = true;

  int get _plannedMinutes {
    final parsed = int.tryParse(_planCtrl.text.trim());
    if (parsed == null || parsed < 1) return 1;
    return parsed.clamp(1, 999);
  }

  @override
  void initState() {
    super.initState();
    _reload();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _planCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final block = context.read<JobWorkLogBlock>();
    final summary = await block.summaryForDay(
      personId: widget.personId,
      jobId: widget.jobId,
      day: widget.day,
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      if (summary.plannedMinutes > 0) {
        _planCtrl.text = '${summary.plannedMinutes}';
      }
      _loading = false;
    });
  }

  bool _isActiveHere(JobWorkLogBlock block) {
    return block.hasActiveSession &&
        block.activeJobId == widget.jobId &&
        block.activeTask == widget.task;
  }

  Future<void> _onStartTimer(JobWorkLogBlock block) async {
    final l10n = AppLocalizations.of(context)!;
    final minutes = _plannedMinutes;
    await block.startWork(
      personId: widget.personId,
      jobId: widget.jobId,
      day: widget.day,
      task: widget.task,
      plannedMinutes: minutes,
    );

    final finance = context.read<FinanceBlock>();
    String? linkedProjectId;
    for (final job in finance.jobPositions.peek()) {
      if (job.id == widget.jobId) {
        linkedProjectId = job.linkedProjectId;
        break;
      }
    }

    context.read<FocusBlock>().startJobWorkFocus(
      minutes: minutes,
      projectId: linkedProjectId,
      notes: _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : '${widget.task.label(l10n)} · ${widget.jobTitle}',
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    context.push('/health/focus');
  }

  Future<void> _onLogNow(JobWorkLogBlock block) async {
    final l10n = AppLocalizations.of(context)!;
    final minutes = _plannedMinutes;
    await block.logImmediately(
      personId: widget.personId,
      jobId: widget.jobId,
      day: widget.day,
      task: widget.task,
      minutes: minutes,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    unawaited(context.read<FinanceBlock>().syncJobWork());
    if (!mounted) return;
    await _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.finance_job_time_logged(minutes))),
    );
    Navigator.of(context).pop();
  }

  Future<void> _onStop(JobWorkLogBlock block) async {
    final focus = context.read<FocusBlock>();
    if (focus.isRunning.value || focus.isJobWorkMode.value) {
      await focus.stopTimer();
    } else {
      await block.stopWork();
    }
    unawaited(context.read<FinanceBlock>().syncJobWork());
    if (!mounted) return;
    setState(() {});
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final block = context.watch<JobWorkLogBlock>();
    final activeHere = _isActiveHere(block);
    final elapsed = activeHere ? block.elapsedMinutes() : 0;
    final summary = _summary;
    final minuteUnit =
        l10n.localeName.startsWith('vi') ? 'phút' : 'min';
    final dayLabel = DateFormat.yMMMEd(l10n.localeName).format(widget.day);
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.onBack != null)
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                color: Colors.white54,
                visualDensity: VisualDensity.compact,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.finance_job_time_log_title,
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.task.label(l10n)} · ${widget.jobTitle}',
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
        const SizedBox(height: 16),
        Text(
          l10n.finance_job_time_plan,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _planCtrl,
          enabled: !activeHere,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: '1',
            suffixText: minuteUnit,
            suffixStyle: TextStyle(
              color: widget.accent.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accent),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.finance_job_time_notes,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          enabled: !activeHere,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n.finance_job_time_notes_hint,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accent),
            ),
          ),
        ),
        if (activeHere) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              l10n.finance_job_time_elapsed(elapsed),
              style: TextStyle(
                color: widget.accent,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
        if (summary != null && summary.totalActual > 0) ...[
          const SizedBox(height: 16),
          Text(
            l10n.finance_job_time_actual_summary(
              summary.totalActual,
              summary.plannedMinutes,
            ),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (activeHere)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _onStop(block),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.stop_rounded),
              label: Text(
                l10n.finance_job_time_stop,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onLogNow(block),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    l10n.finance_job_time_log_now,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _onStartTimer(block),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    l10n.finance_job_time_start_timer,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
