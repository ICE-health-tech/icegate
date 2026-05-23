import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Active project tasks shown inside a mind focus session; links to [ProjectsPage].
class MindFocusTodosSection extends StatelessWidget {
  final MindFocusTrend trend;

  const MindFocusTodosSection({super.key, required this.trend});

  static List<GoalProtocol> _activeProjectTasks(List<GoalProtocol> goals) {
    return goals
        .where(
          (g) => g.category == 'project' && g.status != 'done',
        )
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final growthBlock = context.read<GrowthBlock>();
    final projectBlock = context.read<ProjectBlock>();

    return Watch((context) {
      final tasks = _activeProjectTasks(growthBlock.goals.value);
      final projects = projectBlock.projects.value;
      final shown = tasks.take(5).toList();

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
          const SizedBox(height: 6),
          if (shown.isEmpty)
            Text(
              l10n.mind_focus_no_todos,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...shown.map((task) {
              final projectName = _projectName(task, projects);
              final routeId = _projectRouteId(task, projects);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (routeId != null) {
                        context.push('/projects/$routeId');
                      } else {
                        context.push('/projects');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
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
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (_) =>
                                  growthBlock.completeGoal(task.id),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (projectName != null)
                                  Text(
                                    projectName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: trend.color.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (tasks.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.mind_focus_more_todos(tasks.length - 5),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      );
    });
  }
}
