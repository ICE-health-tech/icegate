import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/utils/L10nExtensions.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/AddPluginForm.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/WorkspaceSidebarLayout.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'TaskItem.dart';
import 'CreateProjectDialog.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick-action routes already represented by built-in tiles (avoid duplicates).
const _builtInQuickActionPaths = {
  '/social/blocker',
  '/health/block-reminder',
  '/projects/calendar',
  '/health/focus',
  '/focus-history',
};

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "projects",
      destination: "/projects",
      mainFunction: () {
        showDialog(
          context: context,
          builder: (context) => const CreateProjectDialog(),
        );
      },
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      icon: Icons.rocket_launch_rounded,
      onLongPress: () {
        context.go("/projects/dashboard");
      },
      subButtons: [],
    );
  }

  void _showAddPluginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: AddPluginForm(
          data: FormData(
            title: "Add App Plugin",
            description: "Choose a plugin to extend your dashboard",
          ),
          scope: 'projects',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final internalWidgetBlock = context.read<InternalWidgetBlock>();
    final database = context.read<AppDatabase>();

    // Initial fetch for projects scope
    final String personId = Supabase.instance.client.auth.currentUser?.id ?? "";
    if (personId.isNotEmpty) {
      Future.microtask(() {
        internalWidgetBlock.refreshBlock(
          database.internalWidgetsDAO,
          personId,
          'projects',
        );
      });
    }

    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 72,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
          titleSpacing: 0,
          title: _buildPageBrandHeader(context, colorScheme),
          flexibleSpace: _buildProjectsAppBarBackground(context, colorScheme),
          actions: [
            // IconButton(
            //   icon: Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
            //       shape: BoxShape.circle,
            //     ),
            //     child: const Icon(Icons.home_rounded, size: 22),
            //   ),
            //   onPressed: () {
            //     WidgetNavigatorAction.smartPop(context);
            //   },
            // ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final scrollBody = CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Watch((context) {
                      final projectBlock = context.read<ProjectBlock>();
                      final growthBlock = context.read<GrowthBlock>();
                      final pluginsCount = internalWidgetBlock
                          .listInternalWidgetProjectsPage
                          .value
                          .length;
                      final notePersonId =
                          context
                              .read<PersonBlock>()
                              .information
                              .value
                              .profiles
                              .id ??
                          '';

                      final allProjects = projectBlock.projects.value;
                      final projectsDone = allProjects
                          .where((p) => p.status == 1)
                          .length;
                      final projectsActive = allProjects
                          .where((p) => p.status == 0)
                          .length;
                      final totalProjects = projectsActive + projectsDone;

                      final projectGoals = growthBlock.goals.value
                          .where((g) => g.category == 'project')
                          .toList();
                      final tasksDone = projectGoals
                          .where((g) => g.status == 'done')
                          .length;
                      final tasksActive = projectGoals
                          .where((g) => g.status != 'done')
                          .length;
                      final totalTasks = tasksDone + tasksActive;

                      final workspaceDetail =
                          '${context.l10n.home_projects_active} $projectsActive · ${context.l10n.home_projects_done} $projectsDone';
                      final taskDetail =
                          '${context.l10n.home_tasks_active} $tasksActive · ${context.l10n.home_tasks_done} $tasksDone';

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primaryContainer.withValues(
                                    alpha: 0.4,
                                  ),
                                  colorScheme.primaryContainer.withValues(
                                    alpha: 0.1,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final twoRows = box.maxWidth < 400;
                                Widget workspaces() => _buildSummaryItem(
                                  context,
                                  context.l10n.projects_summary_workspaces,
                                  totalProjects > 0
                                      ? '$projectsDone/$totalProjects'
                                      : '0',
                                  Icons.folder_copy_rounded,
                                  Colors.blue,
                                  detail: workspaceDetail,
                                );
                                Widget tasks() => _buildSummaryItem(
                                  context,
                                  context.l10n.tasks,
                                  totalTasks > 0
                                      ? '$tasksDone/$totalTasks'
                                      : '0',
                                  Icons.task_alt_rounded,
                                  Colors.orange,
                                  detail: taskDetail,
                                );
                                Widget notes() =>
                                    StreamBuilder<List<ProjectNoteData>>(
                                      stream: database.projectNoteDAO
                                          .watchAllNotes(notePersonId),
                                      builder: (context, snapshot) {
                                        final n = snapshot.data?.length ?? 0;
                                        return _buildSummaryItem(
                                          context,
                                          context.l10n.project_notes_label,
                                          '$n',
                                          Icons.edit_note_rounded,
                                          Colors.lightBlueAccent,
                                          detail:
                                              context.l10n.recent_notes_label,
                                        );
                                      },
                                    );
                                Widget plugins() => _buildSummaryItem(
                                  context,
                                  context.l10n.projects_summary_plugins,
                                  '$pluginsCount',
                                  Icons.extension_rounded,
                                  Colors.teal,
                                );

                                if (twoRows) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: workspaces()),
                                          Expanded(child: tasks()),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: notes()),
                                          Expanded(child: plugins()),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: workspaces()),
                                    Expanded(child: tasks()),
                                    Expanded(child: notes()),
                                    Expanded(child: plugins()),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    _buildSectionTitle(context, context.l10n.quick_actions),
                    const SizedBox(height: 12),
                    Watch((context) {
                      final allApps = internalWidgetBlock
                          .listInternalWidgetProjectsPage
                          .value;
                      final apps = List<InternalWidgetProtocol>.from(allApps)
                        ..removeWhere(
                          (a) => _builtInQuickActionPaths.contains(a.url),
                        )
                        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final isDesktopQuick = w >= 880;
                              final narrowPhone = w < 540;

                              late final int crossAxisCount;
                              late final double tileSpacing;
                              late final double childAspectRatio;

                              if (isDesktopQuick) {
                                tileSpacing = 8;
                                if (w >= 1280) {
                                  crossAxisCount = 6;
                                  childAspectRatio = 1.56;
                                } else if (w >= 1040) {
                                  crossAxisCount = 5;
                                  childAspectRatio = 1.52;
                                } else {
                                  crossAxisCount = 4;
                                  childAspectRatio = 1.46;
                                }
                              } else {
                                crossAxisCount = w >= 720
                                    ? 4
                                    : w >= 520
                                        ? 3
                                        : narrowPhone
                                            ? 3
                                            : 2;
                                tileSpacing = narrowPhone ? 8.0 : 12.0;
                                childAspectRatio =
                                    narrowPhone ? 1.12 : 1.05;
                              }

                              Future<void> openNewNote() async {
                                  final ext = await showDialog<String>(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                      title: const Text('Choose Note Type'),
                                      children: [
                                        SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, '.md'),
                                          child: const Text('Markdown (.md)'),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, '.txt'),
                                          child: const Text('Plain Text (.txt)'),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, '.docx'),
                                          child: const Text('Word (.docx)'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ext != null && context.mounted) {
                                    context.push(
                                      '/projects/editor',
                                      extra: {'extension': ext},
                                    );
                                  }
                                }

                                final coreTiles = <Widget>[
                                  _ProjectsGridTile(
                                    icon: Icons.note_add_rounded,
                                    label: context.l10n.new_label,
                                    accent: Colors.orange,
                                    onTap: openNewNote,
                                  ),
                                  _ProjectsGridTile(
                                    icon: Icons.edit_note_rounded,
                                    label: context.l10n.project_notes_label,
                                    accent: Colors.blue,
                                    onTap: () => context.push('/projects/notes'),
                                  ),
                                  _ProjectsGridTile(
                                    icon: Icons.groups_rounded,
                                    label:
                                        context.l10n.projects_tile_social_blocker,
                                    accent: Colors.teal,
                                    onTap: () =>
                                        context.push('/social/blocker'),
                                  ),
                                  _ProjectsGridTile(
                                    icon: Icons.notifications_active_rounded,
                                    label: context.l10n.projects_tile_reminders,
                                    accent: Colors.deepPurple,
                                    onTap: () =>
                                        context.push('/health/block-reminder'),
                                  ),
                                  _ProjectsGridTile(
                                    icon: Icons.calendar_month_rounded,
                                    label: context.l10n.projects_tile_calendar,
                                    accent: Colors.amber.shade700,
                                    onTap: () =>
                                        context.push('/projects/calendar'),
                                  ),
                                  _ProjectsGridTile(
                                    icon: Icons.bolt_rounded,
                                    label: context.l10n.projects_tile_focus,
                                    accent: Colors.indigo,
                                    onTap: () => context.push('/health/focus'),
                                  ),
                                ];

                                final extraTiles = <Widget>[
                                  _ProjectsGridTile(
                                    icon: Icons.timer_rounded,
                                    label: context.l10n.projects_tile_pomodoro,
                                    accent: Colors.red.shade400,
                                    onTap: () =>
                                        context.push('/focus-history'),
                                  ),
                                  ...apps.map(
                                    (app) => _ProjectsGridTile(
                                      icon: _getAppIcon(app.name),
                                      label: _pluginDisplayLabel(
                                        context,
                                        app.name,
                                      ),
                                      accent: Colors.cyan,
                                      actionHint:
                                          context.l10n.projects_plugin_open,
                                      onTap: () => context.push(app.url),
                                      onLongPress: () =>
                                          _showDeletePluginDialog(context, app),
                                    ),
                                  ),
                                  _ProjectsGridTile(
                                    icon: Icons.add_rounded,
                                    label: context.l10n.add,
                                    accent: colorScheme.primary,
                                    isAddSlot: true,
                                    onTap: () => _showAddPluginDialog(context),
                                  ),
                                ];

                                final allTiles = <Widget>[
                                  ...coreTiles,
                                  ...extraTiles,
                                ];

                                final gridDelegate =
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: tileSpacing,
                                  crossAxisSpacing: tileSpacing,
                                  childAspectRatio: childAspectRatio,
                                );

                                final Widget body;
                                if (narrowPhone) {
                                  body = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: tileSpacing,
                                          crossAxisSpacing: tileSpacing,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                        itemCount: coreTiles.length,
                                        itemBuilder: (context, index) =>
                                            coreTiles[index],
                                      ),
                                      if (extraTiles.isNotEmpty) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            context.l10n.projects_quick_more,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.62),
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                        ),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            mainAxisSpacing: tileSpacing,
                                            crossAxisSpacing: tileSpacing,
                                            childAspectRatio: childAspectRatio,
                                          ),
                                          itemCount: extraTiles.length,
                                          itemBuilder: (context, index) =>
                                              extraTiles[index],
                                        ),
                                      ],
                                    ],
                                  );
                                } else {
                                  body = GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate: gridDelegate,
                                    itemCount: allTiles.length,
                                    itemBuilder: (context, index) =>
                                        allTiles[index],
                                  );
                                }

                                return Container(
                                  padding: EdgeInsets.all(
                                    isDesktopQuick ? 10 : 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.45),
                                        colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.12),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      isDesktopQuick ? 18 : 22,
                                    ),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: body,
                                );
                              },
                            ),
                          ),
                        );
                    }),
                    const SizedBox(height: 28),
                    _buildSectionTitle(context, context.l10n.my_projects_label),
                    const SizedBox(height: 12),
                    Watch((context) {
                      final projectBlock = context.read<ProjectBlock>();
                      final activeProjects = projectBlock.projects.value
                          .where((p) => p.status == 0)
                          .toList();

                      return _ProjectsWorkspaceCard(
                        activeProjects: activeProjects,
                        onCreateProject: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) =>
                                const CreateProjectDialog(),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // --- COMPLETED PROJECTS SECTION ---
            SliverToBoxAdapter(
              child: Watch((context) {
                final projectBlock = context.read<ProjectBlock>();
                final completedList = projectBlock.projects.value
                    .where((p) => p.status == 1)
                    .toList();

                if (completedList.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: _buildSectionTitle(
                    context,
                    context.l10n.completed_projects_label,
                  ),
                );
              }),
            ),
            Watch((context) {
              final projectBlock = context.read<ProjectBlock>();
              final completedList = projectBlock.projects.value
                  .where((p) => p.status == 1)
                  .toList();

              if (completedList.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverLayoutBuilder(
                builder: (context, constraints) {
                  final spec =
                      _ProjectGridSpec.forWidth(constraints.crossAxisExtent);
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: spec.crossAxisCount,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: spec.childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final project = completedList[index];
                          return Opacity(
                            opacity: 0.6,
                            child: _ProjectCard(project: project),
                          );
                        },
                        childCount: completedList.length,
                      ),
                    ),
                  );
                },
              );
            }),
            // --- ALL TASKS SECTION ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(
                      context,
                      context.l10n.active_tasks_label,
                    ),
                    TextButton(
                      onPressed: () => _showAddTaskDialog(context, growthBlock),
                      child: const Text('Add Task'),
                    ),
                  ],
                ),
              ),
            ),
            Watch((context) {
              final projectBlock = context.read<ProjectBlock>();
              final projects = projectBlock.projects.value;

              final tasks = growthBlock.goals.value.where((g) {
                // Include all project tasks and active personal tasks
                return g.category == 'project' ||
                    g.projectID != null ||
                    (g.status != 'done' && g.category == 'personal');
              }).toList();

              // Sort: active first, then by ID (assuming newer is larger)
              tasks.sort((a, b) {
                if (a.status != 'done' && b.status == 'done') return -1;
                if (a.status == 'done' && b.status != 'done') return 1;
                return b.goalID.compareTo(a.goalID);
              });

              if (tasks.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyState(
                      icon: Icons.checklist_rounded,
                      message: 'No tasks yet. Add one to stay productive.',
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final task = tasks[index];

                    // Find project name if it exists
                    String? projectName;
                    if (task.projectID != null) {
                      try {
                        projectName = projects
                            .firstWhere((p) => p.projectID == task.projectID)
                            .name;
                      } catch (_) {
                        projectName = null;
                      }
                    }

                    return TaskItem(
                      task: task,
                      projectName: projectName,
                      onComplete: () async {
                        await growthBlock.completeGoal(
                          task.id,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Task complete! 🚀',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              backgroundColor: colorScheme.primary,
                            ),
                          );
                        }
                      },
                      onDeleteRequested: () => confirmDeleteTask(
                        context,
                        growthBlock,
                        task,
                      ),
                    );
                  }, childCount: tasks.length),
                ),
              );
            }),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: _buildSectionTitle(
                  context,
                  context.l10n.recent_notes_label,
                ),
              ),
            ),
            StreamBuilder<List<ProjectNoteData>>(
              stream: context.read<ProjectNoteDAO>().watchRecentNotes(
                context.read<PersonBlock>().information.value.profiles.id ?? "",
                6,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.surfaceContainerHighest,
                            width: 1,
                          ),
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'No recent notes',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final recentNotes = snapshot.data!;

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = recentNotes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: _RecentNoteItem(note: note),
                    );
                  }, childCount: recentNotes.length),
                );
              },
            ),
          ],
        );

            return WorkspaceSidebarLayout.useWorkspace(constraints.maxWidth)
                ? WorkspaceSidebarLayout(
                    onPluginTap: () => _showAddPluginDialog(context),
                    child: scrollBody,
                  )
                : scrollBody;
          },
        ),
      ),
    );
  }

  Widget _buildProjectsAppBarBackground(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.22),
                    colorScheme.surface.withValues(alpha: 0.72),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBrandHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.l10n.projects.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.projects_page_tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSection(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    String? detail,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.35,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: colorScheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
              if (detail != null)
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  String _pluginDisplayLabel(BuildContext context, String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final l10n = context.l10n;
    final key = name.trim().toLowerCase();
    switch (key) {
      case 'location tracker':
      case 'location':
        return l10n.projects_plugin_location_tracker;
      case 'live web map':
      case 'live map':
        return l10n.projects_plugin_live_map;
      case 'social blocker':
        return l10n.projects_tile_social_blocker;
      case 'block reminder':
        return l10n.projects_tile_reminders;
      case 'focus':
        return l10n.projects_tile_focus;
      case 'pomodoro':
        return l10n.projects_tile_pomodoro;
      default:
        return name;
    }
  }

  IconData _getAppIcon(String? name) {
    if (name == null) return Icons.apps_rounded;
    final n = name.toLowerCase();
    if (n.contains('health')) return Icons.favorite_rounded;
    if (n.contains('finance')) return Icons.account_balance_wallet_rounded;
    if (n.contains('project')) return Icons.rocket_launch_rounded;
    if (n.contains('social')) return Icons.people_alt_rounded;
    if (n.contains('profile')) return Icons.person_rounded;
    if (n.contains('focus')) return Icons.timer_rounded;
    if (n.contains('note')) return Icons.edit_note_rounded;
    if (n.contains('tracker') || n.contains('gps')) {
      return Icons.location_on_rounded;
    }
    if (n.contains('setting')) return Icons.settings_rounded;
    return Icons.apps_rounded;
  }

  void _showDeletePluginDialog(
    BuildContext context,
    InternalWidgetProtocol app,
  ) {
    final l10n = context.l10n;
    final displayName = _pluginDisplayLabel(context, app.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.projects_remove_plugin_title),
        content: Text(l10n.projects_remove_plugin_body(displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final dao = context.read<InternalWidgetsDAO>();
              if (app.rowId != null) {
                await dao.deleteInternalWidgetById(app.rowId!);
              } else {
                await dao.deleteInternalWidget(app.name);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(
              l10n.projects_remove_plugin_confirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, GrowthBlock growthBlock) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'What needs to be done?',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add some details...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await growthBlock.createNewTask(
                  titleController.text,
                  descController.text,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}

/// More columns + wider aspect on large screens so project cards stay compact.
class _ProjectGridSpec {
  const _ProjectGridSpec({
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  final int crossAxisCount;
  final double childAspectRatio;

  static _ProjectGridSpec forWidth(double width) {
    if (width >= 1240) {
      return const _ProjectGridSpec(crossAxisCount: 4, childAspectRatio: 2.25);
    }
    if (width >= 900) {
      return const _ProjectGridSpec(crossAxisCount: 3, childAspectRatio: 2.05);
    }
    if (width >= 520) {
      return const _ProjectGridSpec(crossAxisCount: 2, childAspectRatio: 1.82);
    }
    return const _ProjectGridSpec(crossAxisCount: 1, childAspectRatio: 2.55);
  }
}

class _ProjectsWorkspaceCard extends StatelessWidget {
  const _ProjectsWorkspaceCard({
    required this.activeProjects,
    required this.onCreateProject,
  });

  final List<ProjectProtocol> activeProjects;
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(wide ? 18 : 22),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
        color: cs.surface.withValues(alpha: 0.35),
      ),
      padding: EdgeInsets.all(
        activeProjects.isEmpty
            ? (wide ? 22 : 28)
            : (wide ? 12 : 18),
      ),
      child: activeProjects.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(wide ? 18 : 22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.layers_rounded,
                    size: wide ? 36 : 44,
                    color: cs.primary.withValues(alpha: 0.75),
                  ),
                ),
                SizedBox(height: wide ? 14 : 18),
                Text(
                  l10n.projects_workspace_empty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: wide ? 14 : 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                SizedBox(height: wide ? 16 : 22),
                FilledButton.tonal(
                  onPressed: onCreateProject,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 22 : 28,
                      vertical: wide ? 12 : 14,
                    ),
                  ),
                  child: Text(l10n.projects_workspace_start),
                ),
              ],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final spec = _ProjectGridSpec.forWidth(constraints.maxWidth);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: spec.crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: spec.childAspectRatio,
                  ),
                  itemCount: activeProjects.length,
                  itemBuilder: (context, i) =>
                      _ProjectCard(project: activeProjects[i]),
                );
              },
            ),
    );
  }
}

class _ProjectsGridTile extends StatelessWidget {
  const _ProjectsGridTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.onLongPress,
    this.isAddSlot = false,
    this.actionHint,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isAddSlot;
  final String? actionHint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenW = MediaQuery.sizeOf(context).width;
    final compact = screenW < 540;
    final desktopDense = screenW >= 880;

    final double iconBox;
    final double iconSize;
    final EdgeInsets pad;
    final BorderRadius radius;
    final double labelFontSize;
    final double shadowBlur;

    if (desktopDense) {
      iconBox = 34;
      iconSize = 19;
      pad = const EdgeInsets.fromLTRB(9, 9, 7, 8);
      radius = BorderRadius.circular(14);
      labelFontSize = 11;
      shadowBlur = 8;
    } else if (compact) {
      iconBox = 32;
      iconSize = 18;
      pad = const EdgeInsets.fromLTRB(8, 10, 6, 8);
      radius = BorderRadius.circular(14);
      labelFontSize = 10.5;
      shadowBlur = 12;
    } else {
      iconBox = 40;
      iconSize = 22;
      pad = const EdgeInsets.fromLTRB(10, 12, 8, 10);
      radius = BorderRadius.circular(18);
      labelFontSize = 12;
      shadowBlur = 12;
    }

    final faceTop = isAddSlot
        ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
        : Color.lerp(cs.surface, accent, 0.12)!.withValues(alpha: 0.92);
    final faceMid = isAddSlot
        ? cs.surface.withValues(alpha: 0.38)
        : cs.surface.withValues(alpha: 0.78);
    final faceBottom = isAddSlot
        ? cs.surfaceContainerLow.withValues(alpha: 0.5)
        : Color.lerp(cs.surface, accent, 0.22)!.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        splashColor: accent.withValues(alpha: 0.2),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [faceTop, faceMid, faceBottom],
              stops: const [0.0, 0.52, 1.0],
            ),
            // Must be uniform when combined with borderRadius (Flutter assertion).
            // Edge depth is handled by the highlight/shadow overlays below.
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: isAddSlot ? 0.22 : 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isAddSlot ? cs.shadow : accent)
                    .withValues(alpha: isAddSlot ? 0.2 : 0.22),
                blurRadius: shadowBlur,
                offset: Offset(0, desktopDense ? 3 : 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: desktopDense ? 6 : 10,
                offset: Offset(desktopDense ? 1 : 2, desktopDense ? 4 : 7),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.07),
                blurRadius: 2,
                offset: const Offset(-1, -1),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Top rim highlight (3D edge catch light).
              Positioned(
                left: 10,
                right: 10,
                top: 1,
                height: 1.2,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(
                            alpha: isAddSlot ? 0.22 : 0.45,
                          ),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Left edge highlight.
              Positioned(
                left: 1,
                top: 10,
                bottom: 14,
                width: 1,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(
                            alpha: isAddSlot ? 0.12 : 0.2,
                          ),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom inner shadow (depth inside the tile).
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: desktopDense ? 14 : 18,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(
                            alpha: isAddSlot ? 0.18 : 0.26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Right/bottom edge shade.
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 2,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(
                            alpha: isAddSlot ? 0.12 : 0.18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!isAddSlot)
                Positioned(
                  right: desktopDense ? -10 : -14,
                  bottom: desktopDense ? -12 : -18,
                  child: Icon(
                    icon,
                    size: iconBox * (desktopDense ? 2.4 : 2.8),
                    color: accent.withValues(alpha: 0.07),
                  ),
                ),
              Padding(
                padding: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: iconBox,
                          height: iconBox,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              compact ? 11 : (desktopDense ? 12 : 14),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isAddSlot
                                  ? [
                                      cs.surface.withValues(alpha: 0.5),
                                      cs.surface.withValues(alpha: 0.25),
                                    ]
                                  : [
                                      accent.withValues(alpha: 0.32),
                                      accent.withValues(alpha: 0.08),
                                    ],
                            ),
                            border: Border.all(
                              color: isAddSlot
                                  ? cs.outline.withValues(alpha: 0.4)
                                  : accent.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isAddSlot
                                ? cs.onSurface.withValues(alpha: 0.7)
                                : accent,
                            size: iconSize,
                          ),
                        ),
                        const Spacer(),
                        if (!isAddSlot)
                          Icon(
                            Icons.north_east_rounded,
                            size: desktopDense ? 13 : 14,
                            color: accent.withValues(alpha: 0.55),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      label,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: labelFontSize,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (actionHint != null && actionHint!.isNotEmpty) ...[
                      SizedBox(height: compact ? 2 : 3),
                      Text(
                        actionHint!,
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.85),
                          fontSize: compact ? 9 : 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentNoteItem extends StatelessWidget {
  final ProjectNoteData note;

  const _RecentNoteItem({required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final projectBlock = context.read<ProjectBlock>();

    // Look up the project name if this note belongs to a project
    String? projectName;
    if (note.projectID != null) {
      final match = projectBlock.projects.value.where(
        (p) => p.projectID == note.projectID,
      );
      if (match.isNotEmpty) {
        projectName = match.first.name;
      }
    }

    return InkWell(
      onTap: () {
        context.push('/projects/editor', extra: note);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (projectName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            projectName,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Edited ${DateFormat.MMMd().format(note.updatedAt)}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectProtocol project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final dense = w >= 720;
    final projectColor = project.color != null
        ? Color(int.parse(project.color!))
        : colorScheme.primary;
    final pad = dense ? 12.0 : 15.0;
    final iconInset = dense ? 8.0 : 10.0;
    final iconSize = dense ? 20.0 : 23.0;
    final radius = dense ? 18.0 : 22.0;

    return InkWell(
      onTap: () {
        context.push('/projects/${project.id}');
      },
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Project?'),
            content: Text('Are you sure you want to delete "${project.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          final projectBlock = context.read<ProjectBlock>();
          await projectBlock.deleteProject(project.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Project deleted.'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(radius + 2),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: projectColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: projectColor.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(iconInset),
                  decoration: BoxDecoration(
                    color: projectColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(dense ? 10 : 12),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: projectColor,
                    size: iconSize,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  size: dense ? 14 : 16,
                ),
              ],
            ),
            SizedBox(height: dense ? 8 : 10),
            Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: dense ? 13.5 : 14.5,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: dense ? 2 : 3),
            Text(
              'Created ${DateFormat.MMMd().format(project.createdAt.toLocal())}',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: dense ? 10 : 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
