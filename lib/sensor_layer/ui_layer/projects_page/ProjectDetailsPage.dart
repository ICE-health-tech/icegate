import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/link_layer/skills/skill_practice_streak.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/utils/L10nExtensions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
    
import 'TaskItem.dart';
import 'ProjectNoteItem.dart';
import 'ProjectSkillItem.dart';
import 'ProjectSkillsPicker.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SnowfallOverlay.dart';

class ProjectDetailsPage extends StatelessWidget {
  final ProjectProtocol project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final documentationBlock = context.watch<DocumentationBlock>();
    final database = context.read<AppDatabase>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          const SnowfallOverlay(opacity: 0.15),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 212,
                pinned: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 3,
                actions: [
                  IconButton(
                    padding: const EdgeInsets.only(right: 4),
                    icon: const Icon(Icons.view_kanban_outlined),
                    tooltip: AppLocalizations.of(context)!.project_sdlc_open,
                    onPressed: () =>
                        context.push('/projects/${project.id}/sdlc'),
                  ),
                  if (project.status == 0)
                    IconButton(
                      padding: const EdgeInsets.only(right: 16),
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: AppLocalizations.of(
                        context,
                      )!.project_mark_done_tooltip,
                      onPressed: () async {
                        final projectBlock = context.read<ProjectBlock>();
                        await projectBlock.completeProject(context, project);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  Watch((context) {
                    final isSyncing = documentationBlock.isSyncing.value;
                    return isSyncing
                        ? const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            padding: const EdgeInsets.only(right: 16),
                            icon: const Icon(Icons.cloud_sync_rounded),
                            tooltip: context.l10n.project_drive_sync_tooltip,
                            onPressed: () async {
                              try {
                                await documentationBlock.syncWithGoogleDrive();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.project_sync_success,
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.green.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.project_sync_failed(
                                          e.toString(),
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                  }),
                  IconButton(
                    padding: const EdgeInsets.only(right: 16),
                    icon: const Icon(Icons.analytics_outlined),
                    tooltip: AppLocalizations.of(context)!.analysis,
                    onPressed: () => context.go('/projects/dashboard'),
                  ),
                  IconButton(
                    padding: const EdgeInsets.only(right: 16),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: AppLocalizations.of(
                      context,
                    )!.project_delete_tooltip,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!.project_delete_confirm_title,
                          ),
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.project_delete_confirm_msg(project.name),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                AppLocalizations.of(context)!.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        final projectBlock = context.read<ProjectBlock>();
                        await projectBlock.deleteProject(project.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.project_deleted_msg,
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  expandedTitleScale: 1.0,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14, right: 8),
                  title: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Luminous Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (project.color != null
                                      ? Color(int.parse(project.color!))
                                      : colorScheme.primary)
                                  .withValues(alpha: 0.8),
                              (project.color != null
                                      ? Color(int.parse(project.color!))
                                      : colorScheme.primary)
                                  .withValues(alpha: 0.3),
                              colorScheme.onSurface.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                      // Deep Glass Blur
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.1),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Content with Modern Typography
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 52),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (project.description != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  project.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: project.description != null ? 10 : 0,
                            ),
                            StreamBuilder<List<GoalData>>(
                              stream: database.growthDAO.watchGoalsByProject(
                                project.projectID,
                              ),
                              builder: (context, snapshot) {
                                final tasks = snapshot.data ?? [];
                                final completed = tasks
                                    .where((t) => t.status == 'done')
                                    .length;
                                final total = tasks.length;
                                final progress = total > 0
                                    ? completed / total
                                    : 0.0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 28,
                                                letterSpacing: -1.5,
                                              ),
                                            ),
                                            Text(
                                              context
                                                  .l10n
                                                  .project_complete_label,
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.4),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 9,
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.auto_awesome_mosaic_rounded,
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.1),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Stack(
                                      children: [
                                        // Track
                                        Container(
                                          height: 10,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        // Luminous Progress
                                        FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            height: 10,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  colorScheme.primary,
                                                  colorScheme.primary
                                                      .withValues(alpha: 0.5),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!project.isRoot)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildParentProjectLink(context, colorScheme),
                        ),
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(context)!.project_sub_projects_label,
                        () => _showAddSubProjectDialog(context, project),
                        onSync: () async {
                          try {
                            await context.read<ProjectBlock>().syncFromCloud();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.project_sync_success,
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.project_sync_failed(
                                      e.toString(),
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Watch((context) {
                        final children = context
                            .read<ProjectBlock>()
                            .childrenOf(project.id);
                        if (children.isEmpty) {
                          return _buildEmptyState(
                            context,
                            AppLocalizations.of(context)!
                                .project_no_sub_projects,
                          );
                        }
                        return Column(
                          children: children.map((child) {
                            return _buildSubProjectTile(
                              context,
                              colorScheme,
                              child,
                            );
                          }).toList(),
                        );
                      }),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(context)!.tasks,
                        () {
                          _showAddTaskDialog(
                            context,
                            growthBlock,
                            project,
                          );
                        },
                        onSync: () async {
                          try {
                            await growthBlock.sync();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.project_sync_success,
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.project_sync_failed(
                                      e.toString(),
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Watch((context) {
                        final projectBlock = context.read<ProjectBlock>();
                        final tasks = projectBlock.goalsInScope(
                          growthBlock.goals.value,
                          project,
                        );
                        if (tasks.isEmpty) {
                          return _buildEmptyState(
                            context,
                            AppLocalizations.of(context)!.project_no_tasks,
                          );
                        }

                        // Sort: active tasks first, completed tasks last
                        final sortedTasks = List<GoalProtocol>.from(tasks);
                        sortedTasks.sort((a, b) {
                          if (a.status == 'done' && b.status != 'done') {
                            return 1;
                          }
                          if (a.status != 'done' && b.status == 'done') {
                            return -1;
                          }
                          return 0;
                        });

                        return Column(
                          children: sortedTasks.map((protocol) {
                            return TaskItem(
                              task: protocol,
                              projectName: projectBlock.subProjectLabelForGoal(
                                protocol,
                                project,
                              ),
                              onComplete: () async {
                                final hadSkills = growthBlock
                                    .skillsForProject(
                                      project.id,
                                      altProjectId: project.projectID,
                                    )
                                    .isNotEmpty;
                                await growthBlock.completeGoal(
                                  protocol.id,
                                  projectId: project.id,
                                  altProjectId: project.projectID,
                                );
                                if (context.mounted &&
                                    hadSkills &&
                                    protocol.status != 'done') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .project_skill_xp_granted(15),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              onDeleteRequested: () => confirmDeleteTask(
                                context,
                                growthBlock,
                                protocol,
                              ),
                            );
                          }).toList(),
                        );
                      }),

                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(context)!.project_notes_label,
                        () => _createNewNote(
                          context,
                          database.projectNoteDAO,
                          project.projectID,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<ProjectNoteData>>(
                        stream: database.projectNoteDAO.watchNotesByProject(
                          project.projectID,
                        ),
                        builder: (context, snapshot) {
                          final notes = snapshot.data ?? [];
                          if (notes.isEmpty) {
                            return _buildEmptyState(
                              context,
                              AppLocalizations.of(context)!.project_no_notes,
                            );
                          }

                          return Column(
                            children: notes
                                .map(
                                  (note) => ProjectNoteItem(
                                    note: note,
                                    project: project,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(context)!.project_finance_label,
                        () {
                          _showAddProjectTransactionDialog(
                            context,
                            context.read<FinanceBlock>(),
                            project.projectID,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Watch((context) {
                        final financeBlock = Provider.of<FinanceBlock>(
                          context,
                          listen: false,
                        );
                        final txs = financeBlock.transactions.value
                            .where((t) => t.projectID == project.projectID)
                            .toList();

                        final l10n = AppLocalizations.of(context)!;
                        if (txs.isEmpty) {
                          return _buildEmptyState(
                            context,
                            l10n.project_no_finance,
                          );
                        }
                        return Column(
                          children: txs.map((tx) {
                            final isExpense =
                                tx.type == 'expense' || tx.type == 'investment';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.03,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        (isExpense
                                                ? Colors.redAccent
                                                : Colors.greenAccent)
                                            .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isExpense
                                        ? Icons.arrow_outward_rounded
                                        : Icons.call_received_rounded,
                                    color: isExpense
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  FinancePage.getCategoryName(
                                    l10n,
                                    tx.category,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(tx.transactionDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                trailing: Text(
                                  '${isExpense ? "-" : "+"}\$${tx.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: isExpense
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(context)!.project_skills_label,
                        () => showProjectSkillsPicker(context, project: project),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .project_skill_xp_on_complete,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!
                                  .project_skill_tap_to_start,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Watch((context) {
                        final projectSkills = growthBlock.skillsForProject(
                          project.id,
                          altProjectId: project.projectID,
                        );
                        if (projectSkills.isEmpty) {
                          return _buildEmptyState(
                            context,
                            AppLocalizations.of(context)!.project_no_skills,
                          );
                        }
                        final personId = context
                                .read<PersonBlock>()
                                .information
                                .value
                                .profiles
                                .id ??
                            '';
                        return StreamBuilder<List<MindLogData>>(
                          stream: personId.isEmpty
                              ? const Stream<List<MindLogData>>.empty()
                              : context
                                  .read<MindBlock>()
                                  .watchMindLogs(personId),
                          builder: (context, logSnapshot) {
                            final streakIndex = SkillPracticeStreak.buildDayIndex(
                              logSnapshot.data ?? [],
                            );
                            return _ProjectSkillSessionPicker(
                              project: project,
                              skills: projectSkills,
                              streakIndex: streakIndex,
                              onDeleteSkill: (skill) => _confirmDeleteSkill(
                                context,
                                growthBlock,
                                skill,
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentProjectLink(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final parentId = project.parentProjectId;
    if (parentId == null || parentId.isEmpty) {
      return const SizedBox.shrink();
    }
    final parent = context.read<ProjectBlock>().projects.value
        .cast<ProjectProtocol?>()
        .firstWhere((p) => p?.id == parentId, orElse: () => null);
    if (parent == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () => context.push('/projects/${parent.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_left_rounded,
              size: 18,
              color: colorScheme.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parent.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubProjectTile(
    BuildContext context,
    ColorScheme colorScheme,
    ProjectProtocol child,
  ) {
    final done = child.status == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => context.push('/projects/${child.id}'),
        leading: Icon(
          Icons.folder_outlined,
          color: done
              ? colorScheme.onSurface.withValues(alpha: 0.35)
              : colorScheme.primary,
        ),
        title: Text(
          child.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            decoration: done ? TextDecoration.lineThrough : null,
            color: done
                ? colorScheme.onSurface.withValues(alpha: 0.45)
                : colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  void _showAddSubProjectDialog(
    BuildContext context,
    ProjectProtocol parent,
  ) {
    final nameController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.project_add_sub_project_title),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: l10n.project_sub_project_name_hint,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await context.read<ProjectBlock>().createProject(
                    name,
                    null,
                    parent.color,
                    parentProjectId: parent.id,
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onAdd, {
    VoidCallback? onSync,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.onSurface.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        if (onSync != null) ...[
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.integrations_sync_now,
            icon: const Icon(Icons.sync_rounded, size: 20),
            onPressed: onSync,
          ),
        ],
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 32,
              color: colorScheme.onSurface.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSkill(
    BuildContext context,
    GrowthBlock growthBlock,
    SkillProtocol skill,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.project_skill_delete_confirm(skill.skillName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await growthBlock.deleteSkill(skill.id);
    }
  }

  void _showAddTaskDialog(
    BuildContext context,
    GrowthBlock growthBlock,
    ProjectProtocol project,
  ) {
    final projectBlock = context.read<ProjectBlock>();
    final children = projectBlock.childrenOf(project.id);
  final targets = <({String id, String label})>[
      (id: ProjectBlock.linkId(project), label: project.name),
      for (final c in children)
        (id: ProjectBlock.linkId(c), label: c.name),
    ];

    final titleController = TextEditingController();
    var targetProjectId = targets.first.id;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.project_add_task_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (targets.length > 1) ...[
                Text(
                  l10n.project_task_assign_to,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: targetProjectId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: targets
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.label, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => targetProjectId = v);
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: l10n.project_task_title_hint,
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                await growthBlock.createNewTask(
                  title,
                  '',
                  projectID: targetProjectId,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProjectTransactionDialog(
    BuildContext context,
    FinanceBlock financeBlock,
    String projectID,
  ) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.project_add_investment_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.project_add_investment_desc,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '\$',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description_optional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                await financeBlock.addTransaction(
                  category: 'investing',
                  type: 'investment',
                  amount: amount,
                  description: descriptionController.text.isEmpty
                      ? l10n.project_investment_default_desc
                      : descriptionController.text,
                  projectID: projectID,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(l10n.project_add_investment_btn),
          ),
        ],
      ),
    );
  }

  void _createNewNote(
    BuildContext context,
    ProjectNoteDAO dao,
    String projectID,
  ) async {
    final personBlock = context.read<PersonBlock>();
    final docBlock = context.read<DocumentationBlock>();

    // 1. Ensure a project-specific folder exists
    final folderName = project.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await docBlock.createLocalFolder(folderName);

    // Show a quick dialog to choose type
    if (!context.mounted) return;

    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _DocumentTypePicker(),
    );

    if (type == null) return;

    String content = '';
    String title = AppLocalizations.of(context)!.project_new_note_title;

    final l10n = AppLocalizations.of(context)!;
    if (type == 'tech_doc') {
      title = l10n.project_doc_tech_title;
      content =
          '# ${l10n.project_doc_tech_title}\n\n## Overview\n\n## Architecture\n\n## Implementation Details\n';
    } else if (type == 'api_spec') {
      title = l10n.project_doc_api_title;
      content =
          '# ${l10n.project_doc_api_title}\n\n## Endpoints\n\n### GET /v1/...\n';
    }

    // 2. Resolve the directory for the editor
    final projectDir = Directory('${docBlock.rootDir?.path}/$folderName');

    final noteID = await dao.insertNote(
      title: title,
      content: content,
      projectID: projectID,
      personID: personBlock.currentPersonID.value,
    );

    final note = await dao.getNoteById(noteID);
    if (note != null && context.mounted) {
      await context.push(
        '/projects/editor',
        extra: {'note': note, 'initialDirectory': projectDir},
      );
      // No setState needed here as it's a StatelessWidget,
      // but the StreamBuilder will catch the DB change.
    }
  }
}

class _DocumentTypePicker extends StatelessWidget {
  const _DocumentTypePicker();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.project_choose_document_type,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          _buildTypeOption(
            context,
            'note',
            l10n.project_doc_blank_note,
            l10n.project_doc_blank_note_desc,
            Icons.edit_note_rounded,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTypeOption(
            context,
            'tech_doc',
            l10n.project_doc_tech,
            l10n.project_doc_tech_desc,
            Icons.account_tree_rounded,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildTypeOption(
            context,
            'api_spec',
            l10n.project_doc_api,
            l10n.project_doc_api_desc,
            Icons.api_rounded,
            Colors.orange,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    BuildContext context,
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSkillSessionPicker extends StatefulWidget {
  final ProjectProtocol project;
  final List<SkillProtocol> skills;
  final Map<String, Set<DateTime>> streakIndex;
  final void Function(SkillProtocol skill) onDeleteSkill;

  const _ProjectSkillSessionPicker({
    required this.project,
    required this.skills,
    required this.streakIndex,
    required this.onDeleteSkill,
  });

  @override
  State<_ProjectSkillSessionPicker> createState() =>
      _ProjectSkillSessionPickerState();
}

class _ProjectSkillSessionPickerState extends State<_ProjectSkillSessionPicker> {
  final Set<String> _selectedNames = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<GrowthBlock>().syncSkills());
    });
  }

  void _toggleSkill(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }

  void _startSession() {
    if (_selectedNames.isEmpty) return;
    final title = Uri.encodeComponent(widget.project.name);
    final pid = Uri.encodeComponent(widget.project.id);
    final alt = Uri.encodeComponent(widget.project.projectID);
    final skillsParam = _selectedNames
        .map(Uri.encodeComponent)
        .join('|');
    context.push(
      '/social/skills?projectId=$pid&altProjectId=$alt&title=$title'
      '&startSkills=$skillsParam&autoStart=1',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedNames.length;

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.skills.map((skill) {
          final name = skill.skillName;
          final selected = _selectedNames.contains(name);
          return ProjectSkillItem(
            skill: skill,
            isSelected: selected,
            practiceStreak: SkillPracticeStreak.streakForProtocol(
              widget.streakIndex,
              name,
            ),
            onTap: () => _toggleSkill(name),
            onDelete: () => widget.onDeleteSkill(skill),
          );
        }),
        if (count > 0) ...[
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: _startSession,
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(l10n.project_skill_start_session(count)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            final title = Uri.encodeComponent(widget.project.name);
            final pid = Uri.encodeComponent(widget.project.id);
            final alt = Uri.encodeComponent(widget.project.projectID);
            context.push(
              '/social/skills?projectId=$pid&altProjectId=$alt&title=$title',
            );
          },
          icon: Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: colorScheme.primary.withValues(alpha: 0.8),
          ),
          label: Text(l10n.project_skill_practice),
        ),
      ],
    );
  }
}
