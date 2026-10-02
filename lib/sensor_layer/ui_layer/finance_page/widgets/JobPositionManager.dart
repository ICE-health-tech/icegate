import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/JobWorkDayStrip.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/JobWorkTaskPickerSheet.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

void showJobPositionEditor(
  BuildContext context,
  FinanceBlock financeBlock, {
  JobPositionData? position,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isEdit = position != null;
  final employerCtrl = TextEditingController(text: position?.employer ?? '');
  final titleCtrl = TextEditingController(text: position?.jobTitle ?? '');
  final notesCtrl = TextEditingController(text: position?.notes ?? '');
  var contractType = position?.contractType ?? 'full_time';
  var startDate = position?.startDate ?? DateTime.now();
  DateTime? endDate = position?.endDate;

  // Load existing incomes linked to this job position.
  final existingIncomes = isEdit ? financeBlock.incomesForJob(position.id) : <RecurringIncomeData>[];

  // Also check the legacy linkedIncomeId field.
  final linkedIncomeId = position?.linkedIncomeId;
  if (isEdit && linkedIncomeId != null && linkedIncomeId.isNotEmpty) {
    final alreadyIncluded = existingIncomes.any((i) => i.id == linkedIncomeId);
    if (!alreadyIncluded) {
      for (final income in financeBlock.recurringIncomes.peek()) {
        if (income.id == linkedIncomeId) {
          existingIncomes.add(income);
          break;
        }
      }
    }
  }

  // Mutable list of income entries for the form.
  final incomeEntries = <_IncomeEntry>[
    for (final inc in existingIncomes)
      _IncomeEntry(
        id: inc.id,
        category: inc.category,
        amount: TextEditingController(
          text: financeBlock
              .convertToDisplay(inc.amount)
              .toStringAsFixed(financeBlock.useVnd.peek() ? 0 : 2),
        ),
      ),
  ];
  if (incomeEntries.isEmpty) {
    incomeEntries.add(_IncomeEntry(
      category: 'salary',
      amount: TextEditingController(),
    ));
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              color: EntryColors.deepGlacier,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    (isEdit ? l10n.finance_job_edit : l10n.finance_job_new)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editorField(employerCtrl, l10n.finance_job_employer),
                  const SizedBox(height: 12),
                  _editorField(titleCtrl, l10n.finance_job_role),
                  const SizedBox(height: 12),
                  _contractDropdown(l10n, contractType, (v) {
                    setState(() => contractType = v);
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        l10n.finance_job_income_type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            incomeEntries.add(_IncomeEntry(
                              category: 'salary',
                              amount: TextEditingController(),
                            ));
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white54, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              l10n.finance_fixed_income_add.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < incomeEntries.length; i++) ...[
                    _incomeEntryRow(
                      l10n,
                      financeBlock,
                      incomeEntries[i],
                      onCategoryChanged: (v) => setState(() => incomeEntries[i].category = v),
                      onRemove: incomeEntries.length > 1
                          ? () => setState(() => incomeEntries.removeAt(i))
                          : null,
                    ),
                    if (i < incomeEntries.length - 1) const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  _datePicker(
                    ctx,
                    label: l10n.finance_job_start_date,
                    date: startDate,
                    onPicked: (d) => setState(() => startDate = d),
                  ),
                  const SizedBox(height: 12),
                  _datePicker(
                    ctx,
                    label: l10n.finance_job_end_date,
                    date: endDate,
                    hint: l10n.finance_job_end_date_hint,
                    onPicked: (d) => setState(() => endDate = d),
                    clearable: true,
                    onClear: () => setState(() => endDate = null),
                  ),
                  const SizedBox(height: 12),
                  _editorField(notesCtrl, l10n.finance_job_notes, maxLines: 3),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (isEdit)
                        IconButton(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (c) => AlertDialog(
                                title: Text(l10n.finance_job_delete_confirm),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: Text(l10n.cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: Text(l10n.dev_quick_tabs_delete_confirm),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await financeBlock.deleteJobPosition(position.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: EntryColors.financeSilverAccent,
                          foregroundColor: EntryColors.deepGlacier,
                        ),
                        onPressed: () async {
                          final employer = employerCtrl.text.trim();
                          final title = titleCtrl.text.trim();
                          if (employer.isEmpty && title.isEmpty) return;

                          String jobId;
                          if (isEdit) {
                            jobId = position.id;
                            await financeBlock.updateJobPosition(
                              id: jobId,
                              employer: employer,
                              jobTitle: title,
                              contractType: contractType,
                              startDate: startDate,
                              endDate: endDate,
                              clearEndDate: endDate == null,
                              notes: notesCtrl.text.trim(),
                            );
                          } else {
                            jobId = await financeBlock.addJobPosition(
                              employer: employer,
                              jobTitle: title,
                              contractType: contractType,
                              startDate: startDate,
                              endDate: endDate,
                              notes: notesCtrl.text.trim(),
                            );
                          }

                          // Save each income entry linked to this job.
                          for (final entry in incomeEntries) {
                            final raw = double.tryParse(
                              entry.amount.text.replaceAll(',', '.').trim(),
                            );
                            if (raw == null || raw <= 0) continue;
                            await financeBlock.upsertJobSalaryIncome(
                              existingIncomeId: entry.id,
                              amount: financeBlock.convertToBase(raw),
                              label: title.isNotEmpty ? title : employer,
                              category: entry.category,
                              jobPositionId: jobId,
                            );
                          }
                          // if (ctx.mounted) Navigator.pop(ctx);
                          Navigator.maybeOf(context)?.pop();
                        },
                        child: Text(l10n.projects_calendar_save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _editorField(
  TextEditingController ctrl,
  String label, {
  int maxLines = 1,
}) {
  return TextField(
    controller: ctrl,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EntryColors.financeSilverAccent),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      isDense: true,
    ),
  );
}

Widget _contractDropdown(
  AppLocalizations l10n,
  String value,
  ValueChanged<String> onChanged,
) {
  final types = {
    'full_time': l10n.finance_job_contract_full_time,
    'part_time': l10n.finance_job_contract_part_time,
    'freelance': l10n.finance_job_contract_freelance,
    'internship': l10n.finance_job_contract_internship,
    'contract': l10n.finance_job_contract_contract,
  };
  return DropdownButtonFormField<String>(
    initialValue: types.containsKey(value) ? value : 'full_time',
    dropdownColor: EntryColors.deepGlacier,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: l10n.finance_job_contract_type,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EntryColors.financeSilverAccent),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      isDense: true,
    ),
    items: types.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}


Widget _datePicker(
  BuildContext context, {
  required String label,
  required DateTime? date,
  required ValueChanged<DateTime> onPicked,
  String? hint,
  bool clearable = false,
  VoidCallback? onClear,
}) {
  final fmt = DateFormat.yMMMd();
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) onPicked(picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        isDense: true,
        suffixIcon: clearable && date != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                onPressed: onClear,
              )
            : const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.white38,
              ),
      ),
      child: Text(
        date != null ? fmt.format(date) : (hint ?? ''),
        style: TextStyle(
          color: date != null ? Colors.white : Colors.white24,
          fontSize: 14,
        ),
      ),
    ),
  );
}

/// Card list of job positions — used on Overview tab and Career tab.
class JobPositionManager extends StatelessWidget {
  const JobPositionManager({super.key, required this.financeBlock});

  final FinanceBlock financeBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Watch((context) {
      final jobs = financeBlock.jobPositions.value;
      final incomes = financeBlock.recurringIncomes.value;

      String? salaryFor(JobPositionData job) {
        final incomeId = job.linkedIncomeId;
        if (incomeId == null || incomeId.isEmpty) return null;
        for (final income in incomes) {
          if (income.id == incomeId) {
            return financeBlock.formatCurrency(income.amount);
          }
        }
        return null;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline_rounded,
                  size: 18, color: FinanceSurface.mutedInk(isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.finance_job_title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: FinanceSurface.mutedInk(isDark: isDark),
                      ),
                    ),
                    Text(
                      l10n.finance_job_subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: FinanceSurface.mutedInk(isDark: isDark)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: FinanceSurface.mutedInk(isDark: isDark),
                  size: 20,
                ),
                onPressed: () =>
                    showJobPositionEditor(context, financeBlock),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: FinanceSurface.panel(cs, isDark: isDark),
              child: Center(
                child: Text(
                  l10n.finance_job_empty,
                  style: TextStyle(
                    color: FinanceSurface.mutedInk(isDark: isDark)
                        .withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...jobs.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JobCard(
                  job: job,
                  financeBlock: financeBlock,
                  isDark: isDark,
                  salaryText: salaryFor(job),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.financeBlock,
    required this.isDark,
    this.salaryText,
  });

  final JobPositionData job;
  final FinanceBlock financeBlock;
  final bool isDark;
  final String? salaryText;

  bool get _isCurrent => job.endDate == null;

  int get _tenureMonths {
    final end = job.endDate ?? DateTime.now();
    return (end.year - job.startDate.year) * 12 +
        (end.month - job.startDate.month);
  }

  String _contractLabel(AppLocalizations l10n) {
    switch (job.contractType) {
      case 'full_time':
        return l10n.finance_job_contract_full_time;
      case 'part_time':
        return l10n.finance_job_contract_part_time;
      case 'freelance':
        return l10n.finance_job_contract_freelance;
      case 'internship':
        return l10n.finance_job_contract_internship;
      case 'contract':
        return l10n.finance_job_contract_contract;
      default:
        return job.contractType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accent =
        _isCurrent ? EntryColors.financeSilverAccent : Colors.white38;

    final title = job.jobTitle.isNotEmpty ? job.jobTitle : job.employer;
    final today = DateTime.now();
    final dateFmt = DateFormat.yMMMd(l10n.localeName);
    final dateRange = job.endDate != null
        ? '${dateFmt.format(job.startDate)} – ${dateFmt.format(job.endDate!)}'
        : '${dateFmt.format(job.startDate)} – ${l10n.finance_job_present}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showJobWorkTaskPicker(
                context,
                personId: financeBlock.personId,
                jobId: job.id,
                jobTitle: title,
                day: DateTime(today.year, today.month, today.day),
                accent: accent,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCurrent ? Colors.greenAccent : Colors.white24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.push(
                      '/finance/jobs/${job.id}/history'
                      '?title=${Uri.encodeComponent(title)}',
                    );
                  },
                  icon: Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: accent.withValues(alpha: 0.7),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: l10n.finance_job_history,
                ),
                IconButton(
                  onPressed: () => showJobPositionEditor(
                    context,
                    financeBlock,
                    position: job,
                  ),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: accent.withValues(alpha: 0.5),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: l10n.finance_job_edit,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isCurrent
                        ? Colors.greenAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isCurrent
                        ? l10n.finance_job_current
                        : l10n.finance_job_ended,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color:
                          _isCurrent ? Colors.greenAccent : Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
            if (job.employer.isNotEmpty && job.jobTitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 2),
                child: Text(
                  job.employer,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (salaryText != null)
                    _chip(
                      Icons.payments_rounded,
                      l10n.finance_job_salary_suffix(salaryText!),
                    ),
                  _chip(Icons.schedule_rounded,
                      l10n.finance_job_tenure(_tenureMonths)),
                  _chip(Icons.badge_outlined, _contractLabel(l10n)),
                  _chip(Icons.date_range_rounded, dateRange),
                ],
              ),
            ),
            if (job.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 6),
                child: Text(
                  job.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          JobWorkDayStrip(
            personId: financeBlock.personId,
            jobId: job.id,
            jobTitle: title,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white30),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _IncomeEntry {
  String? id;
  String category;
  final TextEditingController amount;

  _IncomeEntry({this.id, required this.category, required this.amount});
}

Widget _incomeEntryRow(
  AppLocalizations l10n,
  FinanceBlock financeBlock,
  _IncomeEntry entry, {
  required ValueChanged<String> onCategoryChanged,
  VoidCallback? onRemove,
}) {
  final typeLabels = {
    'salary': l10n.finance_job_income_salary,
    'contract': l10n.finance_job_income_contract,
    'bonus': l10n.finance_job_income_bonus,
  };
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 130,
        child: DropdownButtonFormField<String>(
          value: typeLabels.containsKey(entry.category) ? entry.category : 'salary',
          dropdownColor: EntryColors.deepGlacier,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EntryColors.financeSilverAccent),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          items: typeLabels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) onCategoryChanged(v);
          },
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: entry.amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: financeBlock.useVnd.peek() ? 'VND' : 'USD',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EntryColors.financeSilverAccent),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ),
      if (onRemove != null)
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
    ],
  );
}
