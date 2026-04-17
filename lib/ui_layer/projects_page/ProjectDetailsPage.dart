import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/utils/l10n_extensions.dart';
import 'package:ice_gate/ui_layer/finance_page/FinancePage.dart';
import 'TaskItem.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/SSHStorageService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SSHService.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SnowfallOverlay.dart';

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
            expandedHeight: 200,
            pinned: true,
            actions: [
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.project_completed_msg(
                              PROJECT_SCORE_INCREMENT.toInt(),
                            ),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                                content: Text(context.l10n.project_sync_success),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green.withValues(alpha: 0.8),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.project_sync_failed(e.toString()),
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
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: AppLocalizations.of(context)!.project_delete_tooltip,
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
                            AppLocalizations.of(context)!.project_deleted_msg,
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
              title: Text(
                project.name,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  shadows: [
                    Shadow(
                      color: colorScheme.surface.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project.description != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              project.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
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
                                            fontSize: 32,
                                            letterSpacing: -1.5,
                                          ),
                                        ),
                                        Text(
                                          context.l10n.project_complete_label,
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withValues(
                                              alpha: 0.4,
                                            ),
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
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
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
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Stack(
                                  children: [
                                    // Track
                                    Container(
                                      height: 10,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
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
                                              colorScheme.primary.withValues(
                                                alpha: 0.5,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.tasks,
                    () {
                      _showAddTaskDialog(
                        context,
                        growthBlock,
                        project.projectID,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Watch((context) {
                    final allGoals = growthBlock.goals.value;
                    final tasks = allGoals
                        .where((g) => g.projectID == project.projectID)
                        .toList();
                    if (tasks.isEmpty) {
                      return _buildEmptyState(
                        context,
                        AppLocalizations.of(context)!.project_no_tasks,
                      );
                    }

                    // Sort: active tasks first, completed tasks last
                    final sortedTasks = List<GoalProtocol>.from(tasks);
                    sortedTasks.sort((a, b) {
                      if (a.status == 'done' && b.status != 'done') return 1;
                      if (a.status != 'done' && b.status == 'done') return -1;
                      return 0;
                    });

                    return Column(
                      children: sortedTasks.map((protocol) {
                        return TaskItem(
                          task: protocol,
                          onComplete: () => growthBlock.completeGoal(
                            protocol.id,
                            scoreBlock: context.read<ScoreBlock>(),
                          ),
                        );
                      }).toList(),
                    );
                  }),

                  const SizedBox(height: 16),
                  StreamBuilder<List<ProjectNoteData>>(
                    stream: database.projectNoteDAO.watchNotesByProject(
                      project.projectID,
                    ),
                    builder: (context, snapshot) {
                      final notes = snapshot.data ?? [];
                      if (notes.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          ...notes
                              .take(3)
                              .map(
                                (note) =>
                                    _NoteItem(note: note, project: project),
                              ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
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
                      return _buildEmptyState(context, l10n.project_no_finance);
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
                              FinancePage.getCategoryName(l10n, tx.category),
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onAdd,
  ) {
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
        const SizedBox(width: 16),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    GrowthBlock growthBlock,
    String projectID,
  ) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.project_add_task_title),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.project_task_title_hint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await growthBlock.createNewTask(
                  titleController.text,
                  '',
                  projectID: projectID,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
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
    final noteID = await dao.insertNote(
      title: AppLocalizations.of(context)!.project_new_note_title,
      content: '',
      projectID: projectID,
      personID: personBlock.currentPersonID.value,
    );

    final note = await dao.getNoteById(noteID);
    if (note != null && context.mounted) {
      context.push('/projects/editor', extra: note);
    }
  }
}

class _NoteItem extends StatelessWidget {
  final ProjectNoteData note;
  final ProjectProtocol project;

  const _NoteItem({required this.note, required this.project});

  Future<void> _sendToAI(BuildContext context) async {
    if (project.sshHostId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No SSH host linked to this project')),
        );
      }
      return;
    }

    final sshService = SSHService();
    final storage = SSHStorageService();

    final hosts = await storage.loadHosts();
    final host = hosts.where((h) => h.id == project.sshHostId).firstOrNull;

    if (host == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SSH host not found')));
      }
      return;
    }

    try {
      await sshService.connect(
        host: host.host,
        port: host.port,
        username: host.user,
        password: host.password ?? '',
        useTmux: true,
      );

      final remotePath = project.remotePath ?? '';
      final aiMode = project.aiModel ?? 'gemini';
      final content = note.content;

      if (remotePath.isNotEmpty) {
        sshService.write('cd $remotePath\r');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      String command;
      if (aiMode == 'opencode') {
        command = 'opencode "$content"\r';
      } else {
        command = 'gemini "$content"\r';
      }

      sshService.write(command);

      if (context.mounted) {
        context.push(
          '/widgets/ssh',
          extra: {
            'hostId': project.sshHostId,
            'remotePath': project.remotePath,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color:
                  (isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surface)
                      .withValues(alpha: 0.5),
              child: InkWell(
                onTap: () {
                  context.push('/projects/editor', extra: note);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: const Color(0xFFB2EBF2), // Icy Blue
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.project_last_edited_msg(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(note.updatedAt),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (project.sshHostId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getAiColor(
                              project.aiModel,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getAiColor(
                                project.aiModel,
                              ).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            (project.aiModel ?? 'gemini').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _getAiColor(project.aiModel),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendToAI(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.psychology_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAiColor(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'gemini':
        return Colors.blue;
      case 'opencode':
        return Colors.purple;
      case 'openclaw':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
