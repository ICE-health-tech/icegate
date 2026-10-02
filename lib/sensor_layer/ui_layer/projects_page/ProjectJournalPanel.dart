import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindLogEntryDialog.dart';
import 'package:provider/provider.dart';

import 'ProjectJournalInlineForm.dart';
import 'ProjectJournalLogItem.dart';

/// Project mood + image journal — sidebar on wide layouts, inline on phone.
class ProjectJournalPanel extends StatelessWidget {
  const ProjectJournalPanel({
    super.key,
    required this.project,
    this.showSectionHeader = true,
  });

  final ProjectProtocol project;
  final bool showSectionHeader;

  void _openLog(BuildContext context) {
    MindLogEntryDialog.show(
      context,
      projectId: project.projectID,
      projectName: project.name,
      initialMood: 4,
      initialActivities: const ['act_deep_work'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final database = context.read<AppDatabase>();

    return StreamBuilder<List<ProjectNoteData>>(
      stream: database.projectNoteDAO.watchNotesByProject(project.projectID),
      builder: (context, snapshot) {
        final journalLogs = (snapshot.data ?? [])
            .where((n) => n.category == 'project_log')
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final personId = context.read<PersonBlock>().currentPersonID.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 260 ? 1 : 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSectionHeader) ...[
                  Row(
                    children: [
                      Text(
                        l10n.project_journal_label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                          letterSpacing: 2,
                        ),
                      ),
                      if (journalLogs.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.project_journal_count(journalLogs.length),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        onPressed: () => _openLog(context),
                        icon: const Icon(Icons.add_rounded),
                        tooltip: l10n.mind_focus_log_now,
                        style: IconButton.styleFrom(
                          backgroundColor: cs.primary.withValues(alpha: 0.12),
                          foregroundColor: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                ProjectJournalInlineForm(project: project),
                const SizedBox(height: 14),
                if (journalLogs.isEmpty)
                  _EmptyJournalHint(
                    message: l10n.project_no_journal,
                    colorScheme: cs,
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: journalLogs.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: crossAxisCount == 1 ? 1.35 : 0.72,
                    ),
                    itemBuilder: (context, index) => ProjectJournalLogItem(
                      note: journalLogs[index],
                      personId: personId,
                      layout: ProjectJournalLogLayout.grid,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptyJournalHint extends StatelessWidget {
  const _EmptyJournalHint({
    required this.message,
    required this.colorScheme,
  });

  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
