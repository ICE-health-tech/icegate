import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/utils/l10n_extensions.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/widget_page/AddPluginForm.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'TaskItem.dart';
import 'CreateProjectDialog.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final scoreBlock = context.read<ScoreBlock>();
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
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
        body: CustomScrollView(
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

                      final allProjects = projectBlock.projects.value;
                      final projectsDone = allProjects
                          .where((p) => p.status == 1)
                          .length;
                      final projectsActive = allProjects
                          .where((p) => p.status == 0)
                          .length;

                      final projectGoals = growthBlock.goals.value
                          .where((g) => g.category == 'project')
                          .toList();
                      final tasksDone = projectGoals
                          .where((g) => g.status == 'done')
                          .length;
                      final tasksActive = projectGoals
                          .where((g) => g.status != 'done')
                          .length;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
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
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  context,
                                  context.l10n.projects,
                                  '$projectsDone/${projectsActive + projectsDone}',
                                  Icons.folder_copy_rounded,
                                  Colors.blue,
                                ),
                                _buildSummaryItem(
                                  context,
                                  context.l10n.tasks,
                                  '$tasksDone/${tasksDone + tasksActive}',
                                  Icons.task_alt_rounded,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, context.l10n.quick_actions),
                    const SizedBox(height: 16),
                    Watch((context) {
                      final apps = internalWidgetBlock
                          .listInternalWidgetProjectsPage
                          .value;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _ActionCard(
                              width: 100,
                              icon: Icons.note_add_rounded,
                              label: context.l10n.new_label,
                              color: Colors.orange,
                              onTap: () => context.push('/projects/editor'),
                            ),
                            const SizedBox(width: 12),
                            _ActionCard(
                              width: 150,
                              icon: Icons.edit_note_rounded,
                              label: context.l10n.project_notes_label,
                              color: Colors.blue,
                              onTap: () {
                                context.push("/projects/notes");
                              },
                            ),
                            const SizedBox(width: 12),
                            // Plugin Slot (Limit 1 - Showing Latest)
                            if (apps.isEmpty)
                              _ActionCard(
                                width: 130,
                                icon: Icons.add_circle_outline_rounded,
                                label: 'Plugin',
                                color: Colors.grey,
                                onTap: () {
                                  _showAddPluginDialog(context);
                                },
                              )
                            else ...[
                              (() {
                                final sortedApps =
                                    List<InternalWidgetProtocol>.from(apps);
                                sortedApps.sort((a, b) {
                                  final dateA = a.dateAdded;
                                  final dateB = b.dateAdded;
                                  return dateB.compareTo(dateA);
                                });
                                final latestApp = sortedApps.first;

                                return _ActionCard(
                                  width: 130,
                                  icon: _getAppIcon(latestApp.name),
                                  label: latestApp.name,
                                  color: Colors.teal,
                                  onTap: () {
                                    context.push(latestApp.url);
                                  },
                                  onLongPress: () {
                                    _showDeletePluginDialog(context, latestApp);
                                  },
                                );
                              })(),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, context.l10n.my_projects_label),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // --- MY PROJECTS SECTION ---
            Watch((context) {
              final projectBlock = context.read<ProjectBlock>();
              final projectList = projectBlock.projects.value
                  .where((p) => p.status == 0)
                  .toList();

              if (projectList.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyState(
                      icon: Icons.folder_off_rounded,
                      message: 'No projects yet. Create one to get started!',
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final project = projectList[index];
                    return _ProjectCard(project: project);
                  }, childCount: projectList.length),
                ),
              );
            }),
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
                  child: _buildSectionTitle(context, context.l10n.completed_projects_label),
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

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final project = completedList[index];
                    return Opacity(
                      opacity: 0.6,
                      child: _ProjectCard(project: project),
                    );
                  }, childCount: completedList.length),
                ),
              );
            }),
            // --- ALL TASKS SECTION ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(context, context.l10n.active_tasks_label),
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
                          scoreBlock: scoreBlock,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Task complete! XP Awarded 🚀',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              backgroundColor: colorScheme.primary,
                            ),
                          );
                        }
                      },
                    );
                  }, childCount: tasks.length),
                ),
              );
            }),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: _buildSectionTitle(context, context.l10n.recent_notes_label),
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
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'No recent notes',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
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
        ),
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
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Plugin?'),
        content: Text(
          'Do you want to remove "${app.name}" from quick actions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<InternalWidgetsDAO>().deleteInternalWidget(
                app.name,
              );
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
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
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double? width;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
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
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
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
                            color: colorScheme.primary.withOpacity(0.1),
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
                          color: colorScheme.onSurface.withOpacity(0.6),
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
              color: colorScheme.onSurface.withOpacity(0.4),
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
    final projectColor = project.color != null
        ? Color(int.parse(project.color!))
        : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          context.push('/projects/${project.projectID}');
        },
        onLongPress: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Project?'),
              content: Text(
                'Are you sure you want to delete "${project.name}"?',
              ),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: projectColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: projectColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: projectColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: projectColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (project.description != null &&
                        project.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          project.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Created ${DateFormat.MMMd().format(project.createdAt)}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
