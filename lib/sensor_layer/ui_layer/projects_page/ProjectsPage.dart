import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/link_layer/skills/skill_practice_streak.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/utils/L10nExtensions.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/AddPluginForm.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/WorkspaceSidebarLayout.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/ProjectsQuickActionsHub.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'TaskItem.dart';
import 'CreateProjectDialog.dart';
import 'ProjectSkillsPicker.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick-action routes already represented by built-in tiles (avoid duplicates).
const _builtInQuickActionPaths = {
  '/social/blocker',
  '/health/block-reminder',
  '/projects/calendar',
  '/projects/sdlc',
  '/health/focus',
  '/focus-history',
  '/canvas',
};

/// Responsive layout breakpoints for Projects page.
abstract final class _ProjectsHubGridSpec {
  static bool useSplitLayout(double w) => w >= 1120;
  static bool isDesktop(double w) => w >= 900;
}

const _kTaskPreviewLimit = 6;
const _kRecentNotesPreviewLimit = 4;
const _kRecentNotesFetchLimit = 12;

/// Stronger surfaces on the soft pink projects background.
abstract final class _ProjectsSurface {
  static BoxDecoration panel(ColorScheme cs, {double radius = 18}) {
    return BoxDecoration(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: cs.outline.withValues(alpha: 0.16),
        width: 1,
      ),
    );
  }

  static BoxDecoration folderCard({
    required ColorScheme cs,
    required Color accent,
    required double radius,
  }) {
    return BoxDecoration(
      color: Color.alphaBlend(
        accent.withValues(alpha: 0.12),
        cs.surface.withValues(alpha: 0.94),
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent.withValues(alpha: 0.22),
        width: 1,
      ),
    );
  }
}

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
    final topPad = MediaQuery.paddingOf(context).top;

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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final layoutW = constraints.maxWidth;
            final isDesktop = _ProjectsHubGridSpec.isDesktop(layoutW);
            final useSplit = _ProjectsHubGridSpec.useSplitLayout(layoutW);
            final hPad = isDesktop ? 28.0 : 20.0;
            const islandHeight = 56.0;
            final contentTop = isDesktop
                ? topPad + 12.0
                : topPad + islandHeight + 8;

            final tagline = Text(
              context.l10n.projects_page_tagline,
              style: TextStyle(
                fontSize: isDesktop ? 15 : 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            );

            final scrollBody = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1320 : double.infinity,
                ),
                child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, contentTop, hPad, 20),
                child: useSplit
                    ? _buildSplitTopSection(
                        context,
                        colorScheme,
                        growthBlock,
                        internalWidgetBlock,
                        database,
                        tagline: tagline,
                      )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActionsBlock(
                      context,
                      internalWidgetBlock,
                    ),
                    if (!useSplit) ...[
                    const SizedBox(height: 14),
                    _buildSectionTitle(context, context.l10n.my_projects_label),
                    const SizedBox(height: 8),
                    Watch((context) {
                      final projectBlock = context.read<ProjectBlock>();
                      final activeProjects = projectBlock.projects.value
                          .where((p) => p.status == 0)
                          .rootsOnly
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
                    const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            if (!useSplit) ...[
            // --- COMPLETED PROJECTS SECTION ---
            SliverToBoxAdapter(
              child: Watch((context) {
                final projectBlock = context.read<ProjectBlock>();
                final completedList = projectBlock.projects.value
                    .where((p) => p.status == 1)
                    .rootsOnly
                    .toList();

                if (completedList.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 16),
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
                  .rootsOnly
                  .toList();

              if (completedList.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverLayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.crossAxisExtent;
                  if (_ProjectGridSpec.usePhoneList(w)) {
                    return SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final bottom = index < completedList.length - 1
                                ? 6.0
                                : 0.0;
                            return Padding(
                              padding: EdgeInsets.only(bottom: bottom),
                              child: Opacity(
                                opacity: 0.82,
                                child: _ProjectCard(
                                  project: completedList[index],
                                  compactList: true,
                                  phoneList: true,
                                ),
                              ),
                            );
                          },
                          childCount: completedList.length,
                        ),
                      ),
                    );
                  }
                  final spec = _ProjectGridSpec.forWidth(w);
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: spec.crossAxisCount,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: spec.childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Opacity(
                            opacity: 0.82,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: _ProjectCard(
                                project: completedList[index],
                                compactList: true,
                              ),
                            ),
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
                padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
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
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: const _EmptyState(
                      icon: Icons.checklist_rounded,
                      message: 'No tasks yet. Add one to stay productive.',
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _LimitedTaskList(
                    tasks: tasks,
                    projects: projects,
                    growthBlock: growthBlock,
                    colorScheme: colorScheme,
                  ),
                ),
              );
            }),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 16),
                child: _buildSectionTitle(
                  context,
                  context.l10n.recent_notes_label,
                ),
              ),
            ),
            StreamBuilder<List<ProjectNoteData>>(
              stream: context.read<ProjectNoteDAO>().watchRecentNotes(
                context.read<PersonBlock>().information.value.profiles.id ?? "",
                _kRecentNotesFetchLimit,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad - 4),
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

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _LimitedRecentNotesList(notes: snapshot.data!),
                  ),
                );
              },
            ),
            ],
          ],
        ),
              ),
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

  Widget _buildSplitTopSection(
    BuildContext context,
    ColorScheme colorScheme,
    GrowthBlock growthBlock,
    InternalWidgetBlock internalWidgetBlock,
    AppDatabase database, {
    required Widget tagline,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tagline,
              const SizedBox(height: 16),
              _buildQuickActionsBlock(context, internalWidgetBlock),
              const SizedBox(height: 6),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildWorkbenchColumn(
            context,
            colorScheme,
            growthBlock,
            internalWidgetBlock,
            database,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsBlock(
    BuildContext context,
    InternalWidgetBlock internalWidgetBlock,
  ) {
    return Watch((context) {
      final l10n = context.l10n;
      final colorScheme = Theme.of(context).colorScheme;
      final allApps = internalWidgetBlock.listInternalWidgetProjectsPage.value;
      final apps = List<InternalWidgetProtocol>.from(allApps)
        ..removeWhere((a) => _builtInQuickActionPaths.contains(a.url))
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      Future<void> openNewNote() async {
        final ext = await showDialog<String>(
          context: context,
          builder: (context) => Center(child: SimpleDialog(
            title: const Text('Choose Note Type'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, '.md'),
                child: const Text('Markdown (.md)'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, '.txt'),
                child: const Text('Plain Text (.txt)'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, '.docx'),
                child: const Text('Word (.docx)'),
              ),
            ],
          ),
        ));
        if (ext != null && context.mounted) {
          context.push('/projects/editor', extra: {'extension': ext});
        }
      }

      final tiles = <QuickActionTileSpec>[
        QuickActionTileSpec(
          label: l10n.new_label,
          icon: Icons.note_add_rounded,
          accent: HealthMetricColors.pillarAccentAt(0),
          onTap: openNewNote,
        ),
        QuickActionTileSpec(
          label: l10n.project_notes_label,
          icon: Icons.edit_note_rounded,
          accent: HealthMetricColors.pillarAccentAt(1),
          onTap: () => context.push('/projects/notes'),
        ),
        QuickActionTileSpec(
          label: l10n.projects_tile_social_blocker,
          icon: Icons.groups_rounded,
          accent: HealthMetricColors.pillarAccentAt(2),
          onTap: () => context.push('/social/blocker'),
        ),
        QuickActionTileSpec(
          label: l10n.projects_tile_reminders,
          icon: Icons.notifications_active_rounded,
          accent: HealthMetricColors.pillarAccentAt(3),
          onTap: () => context.push('/health/block-reminder'),
        ),
        QuickActionTileSpec(
          label: l10n.projects_tile_calendar,
          icon: Icons.calendar_month_rounded,
          accent: HealthMetricColors.pillarAccentAt(0),
          onTap: () => context.push('/projects/calendar'),
        ),
        QuickActionTileSpec(
          label: l10n.projects_tile_sdlc,
          icon: Icons.view_kanban_outlined,
          accent: HealthMetricColors.pillarAccentAt(3),
          onTap: () => context.push('/projects/sdlc'),
        ),
        QuickActionTileSpec(
          label: l10n.projects_tile_focus,
          icon: Icons.bolt_rounded,
          accent: HealthMetricColors.pillarAccentAt(1),
          onTap: () => context.push('/health/focus'),
        ),
        QuickActionTileSpec(
          label: l10n.projects_tile_pomodoro,
          icon: Icons.timer_rounded,
          accent: HealthMetricColors.pillarAccentAt(2),
          onTap: () => context.push('/focus-history'),
        ),
        QuickActionTileSpec(
          label: l10n.projects_tile_canvas,
          icon: Icons.grid_view_rounded,
          accent: HealthMetricColors.pillarAccentAt(4),
          onTap: () => context.go('/canvas'),
        ),
        ...apps.asMap().entries.map(
          (entry) => QuickActionTileSpec(
            label: _pluginDisplayLabel(context, entry.value.name),
            icon: _getAppIcon(entry.value.name),
            accent: HealthMetricColors.pillarAccentAt(3 + entry.key),
            onTap: () => context.push(entry.value.url),
            onLongPress: () => _showDeletePluginDialog(context, entry.value),
          ),
        ),
        QuickActionTileSpec(
          label: l10n.add,
          icon: Icons.add_rounded,
          accent: colorScheme.primary,
          isAddSlot: true,
          onTap: () => _showAddPluginDialog(context),
        ),
      ];

      return ProjectsQuickActionsBlock(
        title: l10n.quick_actions,
        tiles: tiles,
      );
    });
  }

  Widget _buildWorkbenchColumn(
    BuildContext context,
    ColorScheme colorScheme,
    GrowthBlock growthBlock,
    InternalWidgetBlock internalWidgetBlock,
    AppDatabase database,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(context, context.l10n.my_projects_label),
        const SizedBox(height: 12),
        Watch((context) {
          final activeProjects = context
              .read<ProjectBlock>()
              .projects
              .value
              .where((p) => p.status == 0)
              .rootsOnly
              .toList();
          return _ProjectsWorkspaceCard(
            activeProjects: activeProjects,
            onCreateProject: () {
              showDialog<void>(
                context: context,
                builder: (context) => const CreateProjectDialog(),
              );
            },
          );
        }),
        const SizedBox(height: 20),
        Watch((context) {
          final completedList = context
              .read<ProjectBlock>()
              .projects
              .value
              .where((p) => p.status == 1)
              .rootsOnly
              .toList();
          if (completedList.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(
                context,
                context.l10n.completed_projects_label,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  return _ProjectFolderLayout.gridOrList(
                    projects: completedList,
                    maxWidth: c.maxWidth,
                    compactList: true,
                    phoneList: true,
                    opacity: 0.6,
                    maxCrossAxisCount: 2,
                  );
                },
              ),
            ],
          );
        }),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // _buildSectionTitle(context, context.l10n.active_tasks_label),
            TextButton(
              onPressed: () => _showAddTaskDialog(context, growthBlock),
              child: const Text('Add Task'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Watch((context) {
          final projectBlock = context.read<ProjectBlock>();
          final projects = projectBlock.projects.value;
          final tasks = growthBlock.goals.value.where((g) {
            return g.category == 'project' ||
                g.projectID != null ||
                (g.status != 'done' && g.category == 'personal');
          }).toList();
          tasks.sort((a, b) {
            if (a.status != 'done' && b.status == 'done') return -1;
            if (a.status == 'done' && b.status != 'done') return 1;
            return b.goalID.compareTo(a.goalID);
          });
          if (tasks.isEmpty) {
            return const _EmptyState(
              icon: Icons.checklist_rounded,
              message: 'No tasks yet. Add one to stay productive.',
            );
          }
          return _LimitedTaskList(
            tasks: tasks,
            projects: projects,
            growthBlock: growthBlock,
            colorScheme: colorScheme,
          );
        }),
        const SizedBox(height: 20),
        _buildSectionTitle(context, context.l10n.recent_notes_label),
        const SizedBox(height: 10),
        StreamBuilder<List<ProjectNoteData>>(
          stream: database.projectNoteDAO.watchRecentNotes(
            context.read<PersonBlock>().information.value.profiles.id ?? '',
            _kRecentNotesFetchLimit,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'No recent notes',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            }
            return _LimitedRecentNotesList(notes: snapshot.data!);
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: HealthMetricColors.pillarBlue.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
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

  static bool usePhoneList(double width) => width < 520;

  static _ProjectGridSpec forWidth(double width) {
    if (width >= 1240) {
      return const _ProjectGridSpec(crossAxisCount: 4, childAspectRatio: 3.1);
    }
    if (width >= 900) {
      return const _ProjectGridSpec(crossAxisCount: 3, childAspectRatio: 2.85);
    }
    if (width >= 520) {
      return const _ProjectGridSpec(crossAxisCount: 2, childAspectRatio: 3.35);
    }
    return const _ProjectGridSpec(crossAxisCount: 1, childAspectRatio: 4.2);
  }
}

/// Folder cards on phone use a [Column] so height matches content (no grid gap).
class _ProjectFolderLayout {
  static Widget gridOrList({
    required List<ProjectProtocol> projects,
    required double maxWidth,
    bool slim = false,
    bool compactList = false,
    bool phoneList = false,
    double opacity = 1.0,
    int? maxCrossAxisCount,
    double gridSpacing = 6,
  }) {
    final listMode = phoneList || _ProjectGridSpec.usePhoneList(maxWidth);
    if (listMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < projects.length; i++) ...[
            if (i > 0) SizedBox(height: gridSpacing),
            Opacity(
              opacity: opacity,
              child: _ProjectCard(
                project: projects[i],
                slim: slim,
                compactList: compactList,
                phoneList: true,
              ),
            ),
          ],
        ],
      );
    }

    final spec = _ProjectGridSpec.forWidth(maxWidth);
    final crossAxis = maxCrossAxisCount != null
        ? spec.crossAxisCount.clamp(1, maxCrossAxisCount)
        : spec.crossAxisCount;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        childAspectRatio: spec.childAspectRatio,
      ),
      itemCount: projects.length,
      itemBuilder: (context, i) => Opacity(
        opacity: opacity,
        child: Align(
          alignment: Alignment.topCenter,
          child: _ProjectCard(
            project: projects[i],
            slim: slim,
            compactList: compactList,
          ),
        ),
      ),
    );
  }
}

class _ProjectSkillSummary {
  const _ProjectSkillSummary({
    required this.name,
    required this.xp,
    required this.streak,
  });

  final String name;
  final int xp;
  final int streak;
}

class _ProjectFolderStats {
  const _ProjectFolderStats({
    required this.projectSkills,
    required this.taskDone,
    required this.taskTotal,
    required this.noteCount,
    required this.financeNet,
    required this.financeCount,
  });

  final List<_ProjectSkillSummary> projectSkills;
  final int taskDone;
  final int taskTotal;
  final int noteCount;
  final double financeNet;
  final int financeCount;

  int get skillCount => projectSkills.length;
  int get skillXp =>
      projectSkills.fold<int>(0, (sum, s) => sum + s.xp);

  static _ProjectFolderStats compute({
    required ProjectProtocol project,
    required GrowthBlock growthBlock,
    required FinanceBlock financeBlock,
    required List<ProjectNoteData> notes,
    required List<MindLogData> mindLogs,
    ProjectBlock? projectBlock,
  }) {
    final streakIndex = SkillPracticeStreak.buildDayIndex(mindLogs);
    final seenSkillKeys = <String>{};
    final skills = <_ProjectSkillSummary>[];
    for (final s in growthBlock.skillsForProject(
      project.id,
      altProjectId: project.projectID,
    )) {
      final key = s.skillName.trim().toLowerCase();
      if (key.isEmpty || seenSkillKeys.contains(key)) continue;
      seenSkillKeys.add(key);
      skills.add(
        _ProjectSkillSummary(
          name: s.skillName,
          xp: growthBlock.unifiedPracticePointsFor(s.skillName),
          streak: SkillPracticeStreak.streakForProtocol(
            streakIndex,
            s.skillName,
          ),
        ),
      );
    }
    skills.sort((a, b) {
      final byStreak = b.streak.compareTo(a.streak);
      if (byStreak != 0) return byStreak;
      return b.xp.compareTo(a.xp);
    });

    final scopeIds = projectBlock != null
        ? projectBlock.scopeIdsFor(project)
        : {project.id, project.projectID}
          ..removeWhere((id) => id.isEmpty);
    final tasks = growthBlock.goals.value.where((g) {
      final pid = g.projectID;
      if (pid == null || pid.isEmpty) return false;
      return scopeIds.contains(pid);
    }).toList();

    final txs = financeBlock.transactions.value
        .where((t) => t.projectID == project.projectID)
        .toList();
    var net = 0.0;
    for (final tx in txs) {
      final isExpense = tx.type == 'expense' || tx.type == 'investment';
      net += isExpense ? -tx.amount : tx.amount;
    }

    final noteCount = notes
        .where((n) => n.projectID == project.projectID)
        .length;

    return _ProjectFolderStats(
      projectSkills: skills,
      taskDone: tasks.where((t) => t.status == 'done').length,
      taskTotal: tasks.length,
      noteCount: noteCount,
      financeNet: net,
      financeCount: txs.length,
    );
  }

  static String formatMoney(double amount) {
    final sign = amount >= 0 ? '+' : '-';
    final abs = amount.abs();
    if (abs >= 1000000) {
      return '$sign\$${(abs / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '$sign\$${(abs / 1000).toStringAsFixed(1)}k';
    }
    return '$sign\$${abs.toStringAsFixed(0)}';
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
    final w = MediaQuery.sizeOf(context).width;
    final wide = w >= 800;
    final narrow = _ProjectGridSpec.usePhoneList(w);

    return Container(
      width: double.infinity,
      decoration: _ProjectsSurface.panel(
        cs,
        radius: wide ? 18 : (narrow ? 16 : 20),
      ),
      // padding: EdgeInsets.all(
      //   activeProjects.isEmpty
      //       ? (wide ? 22 : (narrow ? 20 : 24))
      //       : (wide ? 12 : (narrow ? 8 : 14)),
      // ),
      child: activeProjects.isEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(wide ? 16: 22),
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
                // SizedBox(height: wide ? 16 : 22),
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
                return _ProjectFolderLayout.gridOrList(
                  projects: activeProjects,
                  maxWidth: constraints.maxWidth,
                  slim: true,
                );
              },
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

class _LimitedRecentNotesList extends StatefulWidget {
  const _LimitedRecentNotesList({required this.notes});

  final List<ProjectNoteData> notes;

  @override
  State<_LimitedRecentNotesList> createState() => _LimitedRecentNotesListState();
}

class _LimitedRecentNotesListState extends State<_LimitedRecentNotesList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hidden = widget.notes.length - _kRecentNotesPreviewLimit;
    final visible = _expanded || hidden <= 0
        ? widget.notes
        : widget.notes.take(_kRecentNotesPreviewLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final note in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RecentNoteItem(note: note, compact: true),
          ),
        if (!_expanded && hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = true),
              child: Text('Show $hidden more'),
            ),
          ),
      ],
    );
  }
}

class _RecentNoteItem extends StatelessWidget {
  final ProjectNoteData note;
  final bool compact;

  const _RecentNoteItem({required this.note, this.compact = false});

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
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 7 : 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(compact ? 7 : 8),
              ),
              child: Icon(
                Icons.description_outlined,
                color: colorScheme.primary,
                size: compact ? 18 : 20,
              ),
            ),
            SizedBox(width: compact ? 10 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: compact ? 14 : 16,
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
  final bool compactList;
  final bool slim;
  final bool phoneList;

  const _ProjectCard({
    required this.project,
    this.compactList = false,
    this.slim = false,
    this.phoneList = false,
  });

  @override
  Widget build(BuildContext context) {
    final personId =
        context.read<PersonBlock>().information.value.profiles.id ?? '';
    final database = context.read<AppDatabase>();

    final mindBlock = context.read<MindBlock>();
    return StreamBuilder<List<ProjectNoteData>>(
      stream: personId.isEmpty
          ? const Stream<List<ProjectNoteData>>.empty()
          : database.projectNoteDAO.watchAllNotes(personId),
      builder: (context, noteSnapshot) {
        return StreamBuilder<List<MindLogData>>(
          stream: personId.isEmpty
              ? const Stream<List<MindLogData>>.empty()
              : mindBlock.watchMindLogs(personId),
          builder: (context, mindSnapshot) {
            return Watch((context) {
              final stats = _ProjectFolderStats.compute(
                project: project,
                growthBlock: context.read<GrowthBlock>(),
                financeBlock: context.read<FinanceBlock>(),
                notes: noteSnapshot.data ?? [],
                mindLogs: mindSnapshot.data ?? [],
                projectBlock: context.read<ProjectBlock>(),
              );
              return _ProjectCardBody(
                project: project,
                stats: stats,
                compactList: compactList,
                slim: slim,
                phoneList: phoneList,
              );
            });
          },
        );
      },
    );
  }
}

class _ProjectCardBody extends StatelessWidget {
  final ProjectProtocol project;
  final _ProjectFolderStats stats;
  final bool compactList;
  final bool slim;
  final bool phoneList;

  const _ProjectCardBody({
    required this.project,
    required this.stats,
    this.compactList = false,
    this.slim = false,
    this.phoneList = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final dense = w >= 720 && !compactList && !slim && !phoneList;
    final compact = compactList || w < 720 || slim || phoneList;
    final projectColor = project.color != null
        ? Color(int.parse(project.color!))
        : colorScheme.primary;
    final pad = phoneList
        ? 6.0
        : (slim ? 6.0 : (compact ? 7.0 : (dense ? 9.0 : 11.0)));
    final iconInset =
        phoneList ? 3.0 : (slim ? 4.0 : (compact ? 5.0 : (dense ? 6.0 : 7.0)));
    final iconSize = phoneList
        ? 11.0
        : (slim ? 12.0 : (compact ? 14.0 : (dense ? 16.0 : 18.0)));
    final radius = phoneList
        ? 9.0
        : (slim ? 10.0 : (compact ? 11.0 : (dense ? 13.0 : 15.0)));

    if (phoneList) {
      return _buildPhoneListCard(
        context,
        l10n: l10n,
        colorScheme: colorScheme,
        projectColor: projectColor,
        pad: pad,
        iconInset: iconInset,
        iconSize: iconSize,
        radius: radius,
      );
    }

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
        clipBehavior: Clip.antiAlias,
        decoration: _ProjectsSurface.folderCard(
          cs: colorScheme,
          accent: projectColor,
          radius: radius,
        ),
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(iconInset),
                  decoration: BoxDecoration(
                    color: projectColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(compact ? 8 : 10),
                    border: Border.all(
                      color: projectColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: projectColor,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: slim ? 11.5 : (compact ? 12 : (dense ? 13 : 13.5)),
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                          height: 1.05,
                        ),
                      ),
                      if (!slim)
                        Text(
                          DateFormat.MMMd().format(project.createdAt.toLocal()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.38),
                            fontSize: compact ? 8.5 : 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!slim)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.28),
                    size: compact ? 16 : 18,
                  ),
              ],
            ),
            SizedBox(height: slim ? 4 : (compact ? 5 : 7)),
            _ProjectFolderStatsRow(
              stats: stats,
              l10n: l10n,
              projectColor: projectColor,
              dense: dense || compact,
              compact: compact,
              hideFinance: compactList || slim || phoneList,
              slim: slim || phoneList,
              maxSkillTags: phoneList ? 2 : (slim ? 3 : 4),
              onAddSkill: () => showProjectSkillsPicker(context, project: project),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneListCard(
    BuildContext context, {
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
    required Color projectColor,
    required double pad,
    required double iconInset,
    required double iconSize,
    required double radius,
  }) {
    return InkWell(
      onTap: () => context.push('/projects/${project.id}'),
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
          await context.read<ProjectBlock>().deleteProject(project.id);
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
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad - 1),
        decoration: _ProjectsSurface.folderCard(
          cs: colorScheme,
          accent: projectColor,
          radius: radius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(iconInset),
              decoration: BoxDecoration(
                color: projectColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: projectColor.withValues(alpha: 0.18)),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: projectColor,
                size: iconSize,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.25,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ProjectFolderStatsRow(
                    stats: stats,
                    l10n: l10n,
                    projectColor: projectColor,
                    dense: true,
                    compact: true,
                    hideFinance: true,
                    slim: true,
                    maxSkillTags: 2,
                    onAddSkill: () =>
                        showProjectSkillsPicker(context, project: project),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.28),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectFolderStatsRow extends StatelessWidget {
  const _ProjectFolderStatsRow({
    required this.stats,
    required this.l10n,
    required this.projectColor,
    required this.dense,
    this.compact = false,
    this.hideFinance = false,
    this.slim = false,
    this.maxSkillTags = 4,
    this.onAddSkill,
  });

  final _ProjectFolderStats stats;
  final AppLocalizations l10n;
  final Color projectColor;
  final bool dense;
  final bool compact;
  final bool hideFinance;
  final bool slim;
  final int maxSkillTags;
  final VoidCallback? onAddSkill;

  @override
  Widget build(BuildContext context) {
    const skillColor = HealthMetricColors.pillarGreen;
    final tagLimit = maxSkillTags.clamp(1, 8);
    final visibleSkills = stats.projectSkills.take(tagLimit).toList();
    final hiddenSkillCount = stats.projectSkills.length - visibleSkills.length;
    final showSkillRow =
        stats.projectSkills.isNotEmpty || onAddSkill != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: compact ? 4 : (dense ? 5 : 6),
          runSpacing: compact ? 3 : 4,
          children: [
            if (!hideFinance)
              _chip(
                context,
                icon: Icons.account_balance_wallet_rounded,
                label: l10n.project_finance_label,
                value: stats.financeCount > 0
                    ? _ProjectFolderStats.formatMoney(stats.financeNet)
                    : '—',
                color: stats.financeNet >= 0
                    ? HealthMetricColors.pillarYellow
                    : Colors.redAccent,
              ),
            _chip(
              context,
              icon: Icons.task_alt_rounded,
              label: l10n.tasks,
              value: stats.taskTotal > 0
                  ? '${stats.taskDone}/${stats.taskTotal}'
                  : '—',
              color: HealthMetricColors.pillarBlue,
            ),
            _chip(
              context,
              icon: Icons.description_outlined,
              label: l10n.project_notes_label,
              value: stats.noteCount > 0 ? '${stats.noteCount}' : '—',
              color: projectColor,
            ),
            if (stats.projectSkills.isNotEmpty)
              _chip(
                context,
                icon: Icons.psychology_alt_rounded,
                label: l10n.project_skills_label,
                value: stats.skillCount > 0
                    ? '${stats.skillCount}'
                    : '—',
                color: skillColor,
              ),
          ],
        ),
        if (showSkillRow) ...[
          SizedBox(height: compact ? 3 : 4),
          _skillTagsScroller(
            context,
            skillColor: skillColor,
            visibleSkills: visibleSkills,
            hiddenSkillCount: hiddenSkillCount,
            tagLimit: tagLimit,
          ),
        ],
      ],
    );
  }

  Widget _skillTagsScroller(
    BuildContext context, {
    required Color skillColor,
    required List<_ProjectSkillSummary> visibleSkills,
    required int hiddenSkillCount,
    required int tagLimit,
  }) {
    final chips = <Widget>[
      for (final skill in visibleSkills)
        _skillNameChip(
          context,
          skill: skill,
          color: skillColor,
          compact: compact || slim,
        ),
      if (hiddenSkillCount > 0)
        _skillNameChip(
          context,
          skill: _ProjectSkillSummary(
            name: '+$hiddenSkillCount',
            xp: 0,
            streak: 0,
          ),
          color: skillColor.withValues(alpha: 0.7),
          isMore: true,
          compact: compact || slim,
          tagLimit: tagLimit,
        ),
      if (onAddSkill != null) _addSkillChip(context, skillColor),
    ];

    if (compact || slim) {
      return SizedBox(
        height: 24,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (_, i) => chips[i],
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: chips,
    );
  }

  Widget _addSkillChip(BuildContext context, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAddSkill,
        borderRadius: BorderRadius.circular(compact || slim ? 6 : 8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact || slim ? 6 : 8,
            vertical: compact || slim ? 2 : 3,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(compact || slim ? 6 : 8),
            border: Border.all(
              color: color.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: compact || slim
              ? Icon(Icons.add_rounded, size: 12, color: color)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 12, color: color),
                    const SizedBox(width: 3),
                    Text(
                      l10n.add,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _skillNameChip(
    BuildContext context, {
    required _ProjectSkillSummary skill,
    required Color color,
    bool isMore = false,
    bool compact = false,
    int tagLimit = 4,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: isMore
          ? stats.projectSkills
              .skip(tagLimit)
              .map((s) {
                final streak = s.streak > 0 ? ' · ${s.streak}d streak' : '';
                return '${s.name} (${s.xp} XP$streak)';
              })
              .join('\n')
          : skill.streak > 0
              ? '${skill.name} · ${skill.xp} XP · ${skill.streak} day streak'
              : '${skill.name} · ${skill.xp} XP',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : (dense ? 7 : 8),
          vertical: compact ? 2 : (dense ? 3 : 4),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: isMore
            ? Text(
                skill.name,
                style: TextStyle(
                  fontSize: compact ? 8.5 : 9,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
              )
            : Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(
                          Icons.psychology_alt_outlined,
                          size: compact ? 10 : 11,
                          color: color.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: skill.name,
                      style: TextStyle(
                        fontSize: compact ? 8.5 : 9,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                    TextSpan(
                      text: ' ${skill.xp}',
                      style: TextStyle(
                        fontSize: compact ? 7.5 : 8,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    if (skill.streak > 0)
                      TextSpan(
                        text: ' 🔥${skill.streak}',
                        style: TextStyle(
                          fontSize: compact ? 7.5 : 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact || slim ? 4 : (dense ? 5 : 6),
          vertical: compact || slim ? 2 : (dense ? 3 : 4),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact || slim ? 9 : (dense ? 10 : 11), color: color),
            SizedBox(width: compact || slim ? 3 : 4),
            Text(
              value,
              style: TextStyle(
                fontSize: compact || slim ? 8.5 : (dense ? 9 : 9.5),
                fontWeight: FontWeight.w800,
                color: cs.onSurface.withValues(alpha: 0.82),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitedTaskList extends StatefulWidget {
  final List<GoalProtocol> tasks;
  final List<ProjectProtocol> projects;
  final GrowthBlock growthBlock;
  final ColorScheme colorScheme;

  const _LimitedTaskList({
    required this.tasks,
    required this.projects,
    required this.growthBlock,
    required this.colorScheme,
  });

  @override
  State<_LimitedTaskList> createState() => _LimitedTaskListState();
}

class _LimitedTaskListState extends State<_LimitedTaskList> {
  bool _expanded = false;

  String? _projectName(GoalProtocol task) {
    if (task.projectID == null) return null;
    try {
      return widget.projects
          .firstWhere((p) => p.projectID == task.projectID)
          .name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final hidden = tasks.length - _kTaskPreviewLimit;
    final visible = _expanded || hidden <= 0
        ? tasks
        : tasks.take(_kTaskPreviewLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final task in visible)
          TaskItem(
            task: task,
            projectName: _projectName(task),
            onComplete: () async {
              await widget.growthBlock.completeGoal(task.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Task complete! 🚀'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    backgroundColor: widget.colorScheme.primary,
                  ),
                );
              }
            },
            onDeleteRequested: () =>
                confirmDeleteTask(context, widget.growthBlock, task),
          ),
        if (!_expanded && hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = true),
              child: Text('Show $hidden more'),
            ),
          ),
      ],
    );
  }
}
