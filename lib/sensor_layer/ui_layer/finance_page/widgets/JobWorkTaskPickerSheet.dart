import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Models/JobTaskType.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/JobWorkLogBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/JobWorkTimePanel.dart';
import 'package:provider/provider.dart';

enum _PickerStep { groups, details, addJob, logTime, partTimeHours }

Future<void> showJobWorkTaskPicker(
  BuildContext context, {
  required String personId,
  required String jobId,
  required String jobTitle,
  required DateTime day,
  required Color accent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _JobWorkTaskPickerSheet(
      personId: personId,
      jobId: jobId,
      jobTitle: jobTitle,
      day: day,
      accent: accent,
    ),
  );
}

class _JobWorkTaskPickerSheet extends StatefulWidget {
  const _JobWorkTaskPickerSheet({
    required this.personId,
    required this.jobId,
    required this.jobTitle,
    required this.day,
    required this.accent,
  });

  final String personId;
  final String jobId;
  final String jobTitle;
  final DateTime day;
  final Color accent;

  @override
  State<_JobWorkTaskPickerSheet> createState() =>
      _JobWorkTaskPickerSheetState();
}

class _JobWorkTaskPickerSheetState extends State<_JobWorkTaskPickerSheet> {
  _PickerStep _step = _PickerStep.groups;
  JobTaskGroup? _group;
  JobTaskDetail? _selectedDetail;
  JobWorkTask? _task;
  final _subTaskCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '4');
  bool _savingShift = false;

  @override
  void dispose() {
    _subTaskCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  void _goToLogTime(JobWorkTask task) {
    setState(() {
      _task = task;
      _step = _PickerStep.logTime;
    });
  }

  void _openGroup(JobTaskGroup group) {
    final details = JobTaskDetail.forGroup(group);
    setState(() {
      _group = group;
      _selectedDetail = details.first;
      _step = details.length > 1 ? _PickerStep.details : _PickerStep.logTime;
      if (details.length == 1) {
        _task = JobWorkTask.detail(details.first);
      }
    });
  }

  void _openDetail(JobTaskDetail detail) {
    _goToLogTime(JobWorkTask.detail(detail));
  }

  Future<void> _logShiftHours({
    required JobTaskDetail detail,
    required int minutes,
  }) async {
    if (_savingShift || minutes <= 0) return;
    setState(() => _savingShift = true);
    final l10n = AppLocalizations.of(context)!;
    final work = context.read<JobWorkLogBlock>();
    final finance = context.read<FinanceBlock>();
    try {
      await work.logImmediately(
        personId: widget.personId,
        jobId: widget.jobId,
        day: widget.day,
        task: JobWorkTask.detail(detail),
        minutes: minutes,
      );
      unawaited(finance.syncJobWork());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.finance_job_time_logged(minutes))),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _savingShift = false);
    }
  }

  Future<void> _onFullTime() => _logShiftHours(
        detail: JobTaskDetail.fullTime,
        minutes: 8 * 60,
      );

  void _openPartTime() {
    _hoursCtrl.text = '4';
    setState(() => _step = _PickerStep.partTimeHours);
  }

  Future<void> _onPartTimeSave() async {
    final hours = double.tryParse(_hoursCtrl.text.trim().replaceAll(',', '.'));
    if (hours == null || hours <= 0) return;
    final minutes = (hours * 60).round().clamp(1, 24 * 60);
    await _logShiftHours(
      detail: JobTaskDetail.partTime,
      minutes: minutes,
    );
  }

  Future<void> _saveSubTaskAndLog() async {
    final name = _subTaskCtrl.text.trim();
    if (name.isEmpty) return;
    final block = context.read<JobWorkLogBlock>();
    final id = await block.insertSubTask(
      personId: widget.personId,
      jobId: widget.jobId,
      name: name,
    );
    if (!mounted) return;
    _goToLogTime(JobWorkTask.custom(customId: id, customName: name));
  }

  void _openAddJob() {
    _subTaskCtrl.clear();
    setState(() => _step = _PickerStep.addJob);
  }

  void _back() {
    setState(() {
      switch (_step) {
        case _PickerStep.logTime:
          if (_task?.customId != null) {
            _step = _PickerStep.addJob;
            break;
          }
          if (_group != null &&
              JobTaskDetail.forGroup(_group!).length > 1) {
            _step = _PickerStep.details;
          } else {
            _step = _PickerStep.groups;
            _group = null;
            _task = null;
            _selectedDetail = null;
          }
        case _PickerStep.details:
          _step = _PickerStep.groups;
          _group = null;
          _selectedDetail = null;
          _task = null;
        case _PickerStep.addJob:
          _step = _group != null ? _PickerStep.details : _PickerStep.groups;
        case _PickerStep.partTimeHours:
          _step = _PickerStep.groups;
        case _PickerStep.groups:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: EntryColors.deepGlacier,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: switch (_step) {
          _PickerStep.logTime => JobWorkTimePanel(
              personId: widget.personId,
              jobId: widget.jobId,
              jobTitle: widget.jobTitle,
              day: widget.day,
              task: _task!,
              accent: widget.accent,
              onBack: _back,
            ),
          _PickerStep.details => _DetailsStep(
              group: _group!,
              accent: widget.accent,
              selected: _selectedDetail,
              onBack: _back,
              onSelect: (d) => setState(() => _selectedDetail = d),
              onContinue: _openDetail,
              onAddJob: _openAddJob,
            ),
          _PickerStep.addJob => _AddJobStep(
              accent: widget.accent,
              controller: _subTaskCtrl,
              onBack: _back,
              onContinue: _saveSubTaskAndLog,
            ),
          _PickerStep.partTimeHours => _PartTimeHoursStep(
              accent: widget.accent,
              controller: _hoursCtrl,
              saving: _savingShift,
              onBack: _back,
              onSave: _onPartTimeSave,
            ),
          _PickerStep.groups => _GroupsStep(
              jobTitle: widget.jobTitle,
              accent: widget.accent,
              saving: _savingShift,
              onGroup: _openGroup,
              onAddJob: _openAddJob,
              onFullTime: _onFullTime,
              onPartTime: _openPartTime,
            ),
        },
      ),
    );
  }
}

class _GroupsStep extends StatelessWidget {
  const _GroupsStep({
    required this.jobTitle,
    required this.accent,
    required this.saving,
    required this.onGroup,
    required this.onAddJob,
    required this.onFullTime,
    required this.onPartTime,
  });

  final String jobTitle;
  final Color accent;
  final bool saving;
  final ValueChanged<JobTaskGroup> onGroup;
  final VoidCallback onAddJob;
  final VoidCallback onFullTime;
  final VoidCallback onPartTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <(IconData, String, VoidCallback?)>[
      (
        Icons.work_rounded,
        l10n.finance_job_task_full_time,
        saving ? null : onFullTime
      ),
      (
        Icons.schedule_rounded,
        l10n.finance_job_task_part_time,
        saving ? null : onPartTime
      ),
      (
        Icons.code_rounded,
        l10n.finance_job_task_group_code,
        () => onGroup(JobTaskGroup.code)
      ),
      (
        Icons.storefront_rounded,
        l10n.finance_job_task_group_sales,
        () => onGroup(JobTaskGroup.sales)
      ),
      (
        Icons.record_voice_over_rounded,
        l10n.finance_job_task_group_speech,
        () => onGroup(JobTaskGroup.speech)
      ),
      (
        Icons.self_improvement_rounded,
        l10n.finance_job_task_group_health,
        () => onGroup(JobTaskGroup.health)
      ),
      (Icons.add_task_rounded, l10n.finance_job_task_add_job, onAddJob),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jobTitle,
          style: TextStyle(
            color: accent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.finance_job_task_pick_group,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: tiles.map((t) {
            return Material(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: t.$3,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(t.$1, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PartTimeHoursStep extends StatelessWidget {
  const _PartTimeHoursStep({
    required this.accent,
    required this.controller,
    required this.saving,
    required this.onBack,
    required this.onSave,
  });

  final Color accent;
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hourUnit = l10n.localeName.startsWith('vi') ? 'giờ' : 'h';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: saving ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: Colors.white54,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              l10n.finance_job_task_part_time,
              style: TextStyle(
                color: accent,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          autofocus: true,
          enabled: !saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: l10n.finance_job_task_part_time_hours,
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            suffixText: hourUnit,
            suffixStyle: TextStyle(
              color: accent.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(backgroundColor: accent),
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              l10n.finance_job_task_part_time_save,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.group,
    required this.accent,
    required this.selected,
    required this.onBack,
    required this.onSelect,
    required this.onContinue,
    required this.onAddJob,
  });

  final JobTaskGroup group;
  final Color accent;
  final JobTaskDetail? selected;
  final VoidCallback onBack;
  final ValueChanged<JobTaskDetail> onSelect;
  final ValueChanged<JobTaskDetail> onContinue;
  final VoidCallback onAddJob;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final details = JobTaskDetail.forGroup(group);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: Colors.white54,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              jobTaskGroupLabel(l10n, group),
              style: TextStyle(
                color: accent,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.finance_job_task_pick_detail,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...details.map((d) {
              final isSel = selected == d;
              return ActionChip(
                label: Text(jobTaskDetailLabel(l10n, d)),
                backgroundColor: isSel
                    ? accent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                labelStyle: TextStyle(
                  color: isSel ? accent : Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onPressed: () => onSelect(d),
              );
            }),
            ActionChip(
              avatar: Icon(Icons.add_rounded, size: 16, color: accent),
              label: Text(l10n.finance_job_task_add_job),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              labelStyle: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              onPressed: onAddJob,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: selected == null ? null : () => onContinue(selected!),
            style: FilledButton.styleFrom(backgroundColor: accent),
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: Text(
              l10n.finance_job_time_log,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddJobStep extends StatelessWidget {
  const _AddJobStep({
    required this.accent,
    required this.controller,
    required this.onBack,
    required this.onContinue,
  });

  final Color accent;
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: Colors.white54,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              l10n.finance_job_task_add_job,
              style: TextStyle(
                color: accent,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: l10n.finance_job_sub_task_name,
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onContinue,
            style: FilledButton.styleFrom(backgroundColor: accent),
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: Text(
              l10n.finance_job_time_log,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
