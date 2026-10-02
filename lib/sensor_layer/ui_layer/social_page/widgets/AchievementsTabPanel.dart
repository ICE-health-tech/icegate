import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementNostalgiaBanner.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryRail.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementUnifiedFeed.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Memory archive tab — reads from [project_notes].
class AchievementsTabPanel extends StatefulWidget {
  const AchievementsTabPanel({
    super.key,
    required this.notes,
    required this.emptyState,
  });

  final List<ProjectNoteData> notes;
  final Widget emptyState;

  @override
  State<AchievementsTabPanel> createState() => _AchievementsTabPanelState();
}

class _AchievementsTabPanelState extends State<AchievementsTabPanel> {
  DateTime? _monthFilter;
  String? _projectFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projects = context.watch<ProjectBlock>().projects.value;

    final filtered = ProjectNoteArchiveUtils.applyFilters(
      widget.notes,
      month: _monthFilter,
      projectId: _projectFilter,
    );
    final photoMemories = ProjectNoteArchiveUtils.photoMemories(filtered);
    final timeline = ProjectNoteArchiveUtils.timeline(filtered);
    final filterProjects = ProjectNoteArchiveUtils.projectsWithNotes(
      widget.notes,
      projects,
    );
    final onThisDay = ProjectNoteArchiveUtils.onThisDayMemories(widget.notes);
    final nostalgiaIds = onThisDay.map((n) => n.id).toSet();

    if (filtered.isEmpty && widget.notes.isEmpty) {
      return widget.emptyState;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: AchievementStoryRail.recordColumnFlex,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _ArchiveFilters(
                  month: _monthFilter,
                  projectId: _projectFilter,
                  projects: filterProjects,
                  onMonthChanged: (m) => setState(() => _monthFilter = m),
                  onProjectChanged: (id) =>
                      setState(() => _projectFilter = id),
                ),
              ),
              if (onThisDay.isNotEmpty && _monthFilter == null)
                SliverToBoxAdapter(
                  child: AchievementNostalgiaBanner(
                    memories: onThisDay,
                    photoMemories: ProjectNoteArchiveUtils.photoMemories(
                      widget.notes,
                    ),
                    projects: projects,
                  ),
                ),
              if (filtered.isNotEmpty)
                SliverToBoxAdapter(
                  child: _ArchiveMonthSummary(count: filtered.length),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 2),
                  child: Text(
                    l10n.achievement_feats_section.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AchievementUnifiedFeed(
                  items: timeline,
                  projects: projects,
                  photoMemories: photoMemories,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
        Expanded(
          flex: AchievementStoryRail.imageColumnFlex,
          child: AchievementStoryRail(
            notes: filtered,
            projects: projects,
            nostalgiaIds: nostalgiaIds,
          ),
        ),
      ],
    );
  }
}

class _ArchiveMonthSummary extends StatelessWidget {
  const _ArchiveMonthSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Text(
        l10n.achievement_archive_month_summary(count),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ArchiveFilters extends StatelessWidget {
  const _ArchiveFilters({
    required this.month,
    required this.projectId,
    required this.projects,
    required this.onMonthChanged,
    required this.onProjectChanged,
  });

  final DateTime? month;
  final String? projectId;
  final List<ProjectProtocol> projects;
  final ValueChanged<DateTime?> onMonthChanged;
  final ValueChanged<String?> onProjectChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final months = ProjectNoteArchiveUtils.recentMonths();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.achievement_filter_label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.achievement_filter_all_months),
                  selected: month == null,
                  onSelected: (_) => onMonthChanged(null),
                ),
                ...months.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(DateFormat.yMMM().format(m)),
                      selected: month != null &&
                          month!.year == m.year &&
                          month!.month == m.month,
                      onSelected: (_) => onMonthChanged(m),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (projects.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.achievement_filter_all_projects),
                    selected: projectId == null,
                    onSelected: (_) => onProjectChanged(null),
                  ),
                  ...projects.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(p.name, overflow: TextOverflow.ellipsis),
                        selected: projectId != null &&
                            (projectId == p.id || projectId == p.projectID),
                        onSelected: (_) =>
                            onProjectChanged(ProjectBlock.linkId(p)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
