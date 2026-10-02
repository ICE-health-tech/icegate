import 'package:ice_gate/l10n/app_localizations.dart';

enum JobTaskGroup {
  code,
  sales,
  speech,
  health,
}

enum JobTaskDetail {
  codeVibe('code_vibe'),
  codeManual('code_manual'),
  readDocs('read_docs'),
  salesCustomer('sales_customer'),
  salesReadDocs('sales_read_docs'),
  salesReport('sales_report'),
  speech('speech'),
  health('health'),
  timeLog('time_log'),
  fullTime('full_time'),
  partTime('part_time');

  const JobTaskDetail(this.value);
  final String value;

  JobTaskGroup get group => switch (this) {
        JobTaskDetail.codeVibe ||
        JobTaskDetail.codeManual ||
        JobTaskDetail.readDocs =>
          JobTaskGroup.code,
        JobTaskDetail.salesCustomer ||
        JobTaskDetail.salesReadDocs ||
        JobTaskDetail.salesReport =>
          JobTaskGroup.sales,
        JobTaskDetail.speech => JobTaskGroup.speech,
        JobTaskDetail.health => JobTaskGroup.health,
        JobTaskDetail.timeLog ||
        JobTaskDetail.fullTime ||
        JobTaskDetail.partTime =>
          JobTaskGroup.speech,
      };

  static List<JobTaskDetail> forGroup(JobTaskGroup group) => switch (group) {
        JobTaskGroup.code => [
            JobTaskDetail.codeVibe,
            JobTaskDetail.codeManual,
            JobTaskDetail.readDocs,
          ],
        JobTaskGroup.sales => [
            JobTaskDetail.salesCustomer,
            JobTaskDetail.salesReadDocs,
            JobTaskDetail.salesReport,
          ],
        JobTaskGroup.speech => [JobTaskDetail.speech],
        JobTaskGroup.health => [JobTaskDetail.health],
      };

  static JobTaskDetail? tryParse(String raw) {
    for (final d in JobTaskDetail.values) {
      if (d.value == raw) return d;
    }
    return null;
  }

  static JobTaskDetail normalizeStored(String raw) {
    if (raw.startsWith('custom:')) return JobTaskDetail.timeLog;
    return switch (raw) {
      'sales_desk' => JobTaskDetail.salesCustomer,
      'sales_field' => JobTaskDetail.salesReadDocs,
      'communication' => JobTaskDetail.speech,
      'meditation' => JobTaskDetail.health,
      _ => tryParse(raw) ?? JobTaskDetail.timeLog,
    };
  }
}

/// Selected task — built-in detail or custom sub-task from "Add job".
class JobWorkTask {
  const JobWorkTask.detail(this.detail)
      : customId = null,
        customName = null;

  const JobWorkTask.custom({
    required this.customId,
    required this.customName,
  }) : detail = null;

  final JobTaskDetail? detail;
  final String? customId;
  final String? customName;

  String get categoryKey =>
      customId != null ? 'custom:$customId' : detail!.value;

  String label(AppLocalizations l10n) {
    if (customName != null && customName!.isNotEmpty) return customName!;
    return jobTaskDetailLabel(l10n, detail!);
  }

  @override
  bool operator ==(Object other) =>
      other is JobWorkTask && categoryKey == other.categoryKey;

  @override
  int get hashCode => categoryKey.hashCode;
}

String jobTaskGroupLabel(AppLocalizations l10n, JobTaskGroup group) {
  return switch (group) {
    JobTaskGroup.code => l10n.finance_job_task_group_code,
    JobTaskGroup.sales => l10n.finance_job_task_group_sales,
    JobTaskGroup.speech => l10n.finance_job_task_group_speech,
    JobTaskGroup.health => l10n.finance_job_task_group_health,
  };
}

String jobTaskDetailLabel(AppLocalizations l10n, JobTaskDetail detail) {
  return switch (detail) {
    JobTaskDetail.codeVibe => l10n.finance_job_time_category_code_vibe,
    JobTaskDetail.codeManual => l10n.finance_job_time_category_code_manual,
    JobTaskDetail.readDocs => l10n.finance_job_task_read_docs,
    JobTaskDetail.salesCustomer => l10n.finance_job_task_sales_customer,
    JobTaskDetail.salesReadDocs => l10n.finance_job_task_read_docs,
    JobTaskDetail.salesReport => l10n.finance_job_task_sales_report,
    JobTaskDetail.speech => l10n.finance_job_task_group_speech,
    JobTaskDetail.health => l10n.finance_job_task_group_health,
    JobTaskDetail.timeLog => l10n.finance_job_task_group_time_log,
    JobTaskDetail.fullTime => l10n.finance_job_task_full_time,
    JobTaskDetail.partTime => l10n.finance_job_task_part_time,
  };
}

String jobTaskStoredLabel(
  AppLocalizations l10n,
  String storedValue, {
  String? customName,
}) {
  if (storedValue.startsWith('custom:')) {
    return customName ?? storedValue.replaceFirst('custom:', '');
  }
  return jobTaskDetailLabel(l10n, JobTaskDetail.normalizeStored(storedValue));
}
