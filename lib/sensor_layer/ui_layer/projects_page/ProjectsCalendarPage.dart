import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/TaskItem.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/widgets/AppSessionCalendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ProjectsCalendarPage extends StatefulWidget {
  const ProjectsCalendarPage({super.key});

  @override
  State<ProjectsCalendarPage> createState() => _ProjectsCalendarPageState();
}

class _ProjectsCalendarPageState extends State<ProjectsCalendarPage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedMonth = DateTime(today.year, today.month);
    _selectedDay = _dateOnly(today);
  }

  bool _isCalendarTask(GoalProtocol goal) {
    return goal.category == 'project' ||
        goal.projectID != null ||
        (goal.status != 'done' && goal.category == 'personal');
  }

  bool _sameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    final left = _dateOnly(a);
    final right = _dateOnly(b);
    return left == right;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final projectBlock = context.watch<ProjectBlock>();

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            l10n.projects_tile_calendar,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Watch((context) {
          final tasks = growthBlock.goals.value.where(_isCalendarTask).toList();
          final projects = projectBlock.projects.value;

          final taskMarkedDays = tasks
              .where((task) => task.targetDate != null)
              .map((task) => _dateOnly(task.targetDate!))
              .toSet();
          final projectCreatedDays = projects
              .map((p) => _dateOnly(p.createdAt.toLocal()))
              .toSet();
          final markedDays = {...taskMarkedDays, ...projectCreatedDays};

          final selectedTasks = tasks
              .where((task) => _sameDay(task.targetDate, _selectedDay))
              .toList()
            ..sort((a, b) => a.title.compareTo(b.title));

          final projectsCreatedHere = projects
              .where((p) => _sameDay(p.createdAt.toLocal(), _selectedDay))
              .toList()
            ..sort(
              (a, b) => a.createdAt.toLocal().compareTo(b.createdAt.toLocal()),
            );

          final hasTasks = selectedTasks.isNotEmpty;
          final hasProjectsHere = projectsCreatedHere.isNotEmpty;
          final createdTimeFormat = DateFormat.jm(
            Localizations.localeOf(context).toString(),
          );

          final selectedLabel = _selectedDay == _dateOnly(DateTime.now())
              ? l10n.date_today
              : DateFormat.yMMMd().format(_selectedDay);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppSessionCalendar(
                markedDays: markedDays,
                focusedMonth: _focusedMonth,
                selectedDay: _selectedDay,
                onMonthChanged: (month) {
                  setState(() => _focusedMonth = DateTime(month.year, month.month));
                },
                onDaySelected: (day) {
                  setState(() {
                    _selectedDay = _dateOnly(day);
                    _focusedMonth = DateTime(day.year, day.month);
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                selectedLabel,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (!hasTasks && !hasProjectsHere)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.projects_calendar_day_empty,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else ...[
                if (hasProjectsHere) ...[
                  Text(
                    l10n.projects_calendar_projects_created,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...projectsCreatedHere.map((project) {
                    final createdLocal = project.createdAt.toLocal();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push('/projects/${project.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.create_new_folder_outlined,
                                  size: 22,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        createdTimeFormat.format(createdLocal),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (hasTasks) const SizedBox(height: 20),
                ],
                if (hasTasks) ...[
                  Text(
                    l10n.tasks,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...selectedTasks.map((task) {
                    String? projectName;
                    if (task.projectID != null) {
                      for (final project in projects) {
                        if (project.projectID == task.projectID) {
                          projectName = project.name;
                          break;
                        }
                      }
                    }

                    return TaskItem(
                      task: task,
                      projectName: projectName,
                      onComplete: () => growthBlock.completeGoal(task.id),
                      onDeleteRequested: () => confirmDeleteTask(
                        context,
                        growthBlock,
                        task,
                      ),
                    );
                  }),
                ],
              ],
            ],
          );
        }),
      ),
    );
  }
}
