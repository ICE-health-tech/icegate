import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Active project tasks shown inside a mind focus session; links to [ProjectsPage].
class MindFocusTodosSection extends StatefulWidget {
  static const _noProject = '__none__';

  final MindFocusTrend trend;
  final VoidCallback? onLogTap;

  const MindFocusTodosSection({
    super.key,
    required this.trend,
    this.onLogTap,
  });

  @override
  State<MindFocusTodosSection> createState() => _MindFocusTodosSectionState();
}

class _MindFocusTodosSectionState extends State<MindFocusTodosSection> {
  MindFocusDailyTodosSnapshot _daily = const MindFocusDailyTodosSnapshot();
  String? _dailyLoadKey;

  MindFocusTrend get trend => widget.trend;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshDaily();
  }

  Future<void> _refreshDaily() async {
    final personId =
        context.read<PersonBlock>().information.value.profiles.id ?? '';
    final key = '${personId}_${trend.id}_${_todayKey()}';
    if (_dailyLoadKey == key) return;
    _dailyLoadKey = key;
    final snap = await MindFocusDailyTodosPrefs.load(
      personId: personId,
      trendId: trend.id,
    );
    if (!mounted || _dailyLoadKey != key) return;
    setState(() => _daily = snap);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String? _personId(BuildContext context) =>
      context.read<PersonBlock>().information.value.profiles.id;

  static List<GoalProtocol> _activeProjectTasks(List<GoalProtocol> goals) {
    return goals
        .where((g) => g.category == 'project' && g.status != 'done')
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  List<GoalProtocol> _todayTasks(
    List<GoalProtocol> goals,
    MindFocusDailyTodosSnapshot daily,
  ) {
    if (daily.taskIds.isEmpty) return const [];
    final ids = daily.taskIds.toSet();
    return _activeProjectTasks(goals).where((g) => ids.contains(g.id)).toList();
  }

  static String? _projectRouteId(
    GoalProtocol task,
    List<ProjectProtocol> projects,
  ) {
    final pid = task.projectID;
    if (pid == null || pid.isEmpty) return null;
    for (final p in projects) {
      if (p.id == pid || p.projectID == pid) return p.id;
    }
    return pid;
  }

  static String? _projectName(
    GoalProtocol task,
    List<ProjectProtocol> projects,
  ) {
    final pid = task.projectID;
    if (pid == null || pid.isEmpty) return null;
    for (final p in projects) {
      if (p.id == pid || p.projectID == pid) return p.name;
    }
    return null;
  }

  static String? _taskProjectLinkId(
    GoalProtocol task,
    List<ProjectProtocol> projects,
  ) {
    final pid = task.projectID;
    if (pid == null || pid.isEmpty) return null;
    for (final p in projects) {
      if (p.id == pid || p.projectID == pid) return ProjectBlock.linkId(p);
    }
    return pid;
  }

  static ProjectProtocol? _resolveLinkedProject(
    String? linkedId,
    List<ProjectProtocol> projects,
  ) {
    if (linkedId == null || linkedId.isEmpty) return null;
    for (final p in projects) {
      if (p.id == linkedId || p.projectID == linkedId) return p;
    }
    return null;
  }

  static String? _defaultProjectLinkId(
    MindFocusTrend trend,
    List<ProjectProtocol> activeRoots,
  ) {
    final linked = _resolveLinkedProject(trend.linkedProjectId, activeRoots);
    if (linked != null) return ProjectBlock.linkId(linked);
    return null;
  }

  static String? _resolveTenantId(PersonBlock personBlock) {
    final profile = personBlock.information.value.profiles;
    final raw = profile.tenantId;
    final trimmed = raw?.toString().trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final meta = Supabase.instance.client.auth.currentUser?.appMetadata;
    final fromMeta = meta?['tenant_id']?.toString().trim();
    return fromMeta != null && fromMeta.isNotEmpty ? fromMeta : null;
  }

  Future<void> _logSpecialMoodReward(
    BuildContext context,
    AppLocalizations l10n,
    String personId,
  ) async {
    final personBlock = context.read<PersonBlock>();
    final activities = <String>[
      ...trend.activityTokens,
      'focus:todos_streak',
    ];

    await context.read<MindBlock>().addMindLog(
      moodScore: 6,
      activities: activities,
      note: l10n.mind_focus_special_mood,
      personId: personId,
      tenantId: _resolveTenantId(personBlock),
    );

    await MindFocusDailyTodosPrefs.markMoodAwarded(
      personId: personId,
      trendId: trend.id,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.mind_focus_special_mood),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    GrowthBlock growthBlock,
    List<ProjectProtocol> activeRoots,
    MindFocusDailyTodosSnapshot daily,
    String personId,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (!MindFocusDailyTodosPrefs.canAdd(daily)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.mind_focus_daily_cap(MindFocusDailyTodosPrefs.maxAddsPerDay),
          ),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    var selectedLinkId = _defaultProjectLinkId(trend, activeRoots);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final canSave = titleController.text.trim().isNotEmpty;

            return AlertDialog(
              title: Text(l10n.mind_focus_add_task_title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.mind_focus_add_task_name,
                      ),
                      onChanged: (_) => setLocal(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.mind_focus_add_task_desc,
                      ),
                    ),
                    if (activeRoots.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedLinkId ?? MindFocusTodosSection._noProject,
                        decoration: InputDecoration(
                          labelText: l10n.mind_focus_linked_project,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: MindFocusTodosSection._noProject,
                            child: Text(l10n.mind_focus_linked_project_none),
                          ),
                          for (final p in activeRoots)
                            DropdownMenuItem(
                              value: ProjectBlock.linkId(p),
                              child: Text(p.name),
                            ),
                        ],
                        onChanged: (v) => setLocal(
                          () => selectedLinkId =
                              v == null || v == MindFocusTodosSection._noProject
                              ? null
                              : v,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: canSave ? () => Navigator.pop(ctx, true) : null,
                  child: Text(l10n.mind_focus_add_task_confirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final taskId = await growthBlock.createNewTask(
        titleController.text.trim(),
        descController.text.trim(),
        projectID: selectedLinkId,
      );
      if (taskId != null && personId.isNotEmpty) {
        await MindFocusDailyTodosPrefs.registerAddedTask(
          personId: personId,
          trendId: trend.id,
          taskId: taskId,
        );
        _dailyLoadKey = null;
        await _refreshDaily();
      }
    }

    titleController.dispose();
    descController.dispose();
  }

  Future<void> _completeTask(
    BuildContext context,
    GrowthBlock growthBlock,
    GoalProtocol task,
    String personId,
    AppLocalizations l10n,
  ) async {
    await growthBlock.completeGoal(
      task.id,
      projectId: task.projectID,
    );

    if (personId.isEmpty || !_daily.taskIds.contains(task.id)) {
      _dailyLoadKey = null;
      await _refreshDaily();
      return;
    }

    final completed = await MindFocusDailyTodosPrefs.registerCompletion(
      personId: personId,
      trendId: trend.id,
    );

    final snap = _daily.copyWith(completedCount: completed);
    final award = snap.shouldAwardMoodNow;
    if (award) {
      await _logSpecialMoodReward(context, l10n, personId);
    }

    _dailyLoadKey = null;
    await _refreshDaily();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final growthBlock = context.read<GrowthBlock>();
    final projectBlock = context.read<ProjectBlock>();
    final personId = _personId(context) ?? '';
    final daily = _daily;

    return Watch((context) {
      final projects = projectBlock.projects.value;
      final activeRoots = projects.where((p) => p.status == 0).rootsOnly.toList();
      final tasks = _todayTasks(growthBlock.goals.value, daily);
      final canAdd = daily.addedCount < MindFocusDailyTodosPrefs.maxAddsPerDay;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 16, color: trend.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.mind_focus_todos.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: trend.color,
                  ),
                ),
              ),
              if (widget.onLogTap != null)
                TextButton.icon(
                  onPressed: widget.onLogTap,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  icon: Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: trend.color,
                  ),
                  label: Text(
                    l10n.mind_focus_log_now,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: trend.color,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => context.push('/projects'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  l10n.mind_focus_open_projects,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trend.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.mind_focus_daily_progress(
              daily.addedCount,
              MindFocusDailyTodosPrefs.maxAddsPerDay,
              daily.completedCount,
            ),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: trend.color.withValues(alpha: 0.8),
            ),
          ),
          Text(
            l10n.mind_focus_daily_hint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          if (tasks.isEmpty)
            Text(
              l10n.mind_focus_no_todos,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...tasks.map((task) {
              final projectName = _projectName(task, projects);
              final routeId = _projectRouteId(task, projects);
              final projectLinkId = _taskProjectLinkId(task, projects);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: false,
                        activeColor: trend.color,
                        side: BorderSide(
                          color: trend.color.withValues(alpha: 0.5),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (_) {
                          final taskId = task.id;
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (!context.mounted) return;
                            final goals = growthBlock.goals.value;
                            final current = goals.firstWhere(
                              (g) => g.id == taskId,
                              orElse: () => task,
                            );
                            await _completeTask(
                              context,
                              growthBlock,
                              current,
                              personId,
                              l10n,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (routeId != null) {
                            context.push('/projects/$routeId');
                          } else {
                            context.push('/projects');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _TaskProjectPicker(
                      label: projectName ?? l10n.mind_focus_assign_project,
                      selectedLinkId: projectLinkId,
                      activeRoots: activeRoots,
                      accent: trend.color,
                      noneLabel: l10n.mind_focus_linked_project_none,
                      onChanged: (linkId) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          growthBlock.updateGoalProjectId(task.id, linkId);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canAdd
                  ? () => _showAddTaskDialog(
                      context,
                      growthBlock,
                      activeRoots,
                      daily,
                      personId,
                    )
                  : null,
              icon: Icon(Icons.add_rounded, size: 18, color: trend.color),
              label: Text(l10n.mind_focus_add_task_title),
              style: OutlinedButton.styleFrom(
                foregroundColor: trend.color,
                side: BorderSide(color: trend.color.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

extension on MindFocusDailyTodosSnapshot {
  MindFocusDailyTodosSnapshot copyWith({
    List<String>? taskIds,
    int? completedCount,
    bool? moodAwarded,
  }) {
    return MindFocusDailyTodosSnapshot(
      taskIds: taskIds ?? this.taskIds,
      completedCount: completedCount ?? this.completedCount,
      moodAwarded: moodAwarded ?? this.moodAwarded,
    );
  }
}

class _TaskProjectPicker extends StatelessWidget {
  const _TaskProjectPicker({
    required this.label,
    required this.selectedLinkId,
    required this.activeRoots,
    required this.accent,
    required this.noneLabel,
    required this.onChanged,
  });

  final String label;
  final String? selectedLinkId;
  final List<ProjectProtocol> activeRoots;
  final Color accent;
  final String noneLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (activeRoots.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 108),
      child: PopupMenuButton<String?>(
        tooltip: label,
        padding: EdgeInsets.zero,
        onSelected: onChanged,
        itemBuilder: (ctx) => [
          PopupMenuItem<String?>(
            value: null,
            child: Text(noneLabel),
          ),
          for (final p in activeRoots)
            PopupMenuItem<String?>(
              value: ProjectBlock.linkId(p),
              child: Text(p.name),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: accent.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
