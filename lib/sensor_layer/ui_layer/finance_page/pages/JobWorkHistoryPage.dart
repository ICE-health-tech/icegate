import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Models/JobTaskType.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/JobWorkLogBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class JobWorkHistoryPage extends StatefulWidget {
  const JobWorkHistoryPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  final String jobId;
  final String jobTitle;

  @override
  State<JobWorkHistoryPage> createState() => _JobWorkHistoryPageState();
}

class _JobWorkHistoryPageState extends State<JobWorkHistoryPage> {
  List<JobWorkTimeLogEntry> _logs = [];
  Map<String, String> _customNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final finance = context.read<FinanceBlock>();
    await finance.syncJobWork();
    if (!mounted) return;
    final personId = finance.personId;
    final block = context.read<JobWorkLogBlock>();
    final logs = await block.timeLogsForJob(
      personId: personId,
      jobId: widget.jobId,
    );
    final names = await block.subTaskNamesForJob(personId, widget.jobId);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _customNames = names;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accent = EntryColors.financeSilverAccent;
    final dayFmt = DateFormat.yMMMEd(l10n.localeName);
    final timeFmt = DateFormat.jm(l10n.localeName);

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(l10n.finance_job_history_title),
          backgroundColor: cs.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(
                      widget.jobTitle,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.finance_job_history_subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_logs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            l10n.finance_job_history_empty,
                            style: TextStyle(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._logs.map((log) {
                        String? customName;
                        if (log.taskCategory.startsWith('custom:')) {
                          final id =
                              log.taskCategory.replaceFirst('custom:', '');
                          customName = _customNames[id];
                        }
                        final taskLabel = jobTaskStoredLabel(
                          l10n,
                          log.taskCategory,
                          customName: customName,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.onSurface.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayFmt.format(log.workDate),
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeFmt.format(log.loggedAt),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$taskLabel · ${log.minutes}p',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (log.notes != null &&
                                    log.notes!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    log.notes!,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}
