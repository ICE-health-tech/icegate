import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
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
import 'package:ice_gate/ui_layer/finance_page/FinancePage.dart';
import 'TaskItem.dart';

class ProjectDetailsPage extends StatelessWidget {
  final ProjectProtocol project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final database = context.read<AppDatabase>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              if (project.status == 0)
                IconButton(
                  padding: const EdgeInsets.only(right: 16),
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: AppLocalizations.of(context)!.project_mark_done_tooltip,
                  onPressed: () async {
                    final projectBlock = context.read<ProjectBlock>();
                    await projectBlock.completeProject(context, project);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.project_completed_msg(PROJECT_SCORE_INCREMENT.toInt()),
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
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
                      title: Text(AppLocalizations.of(context)!.project_delete_confirm_title),
                      content: Text(
                        AppLocalizations.of(context)!.project_delete_confirm_msg(project.name),
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
                          content: Text(AppLocalizations.of(context)!.project_deleted_msg),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (project.color != null
                              ? Color(int.parse(project.color!))
                              : Colors.blue)
                          .withOpacity(0.4),
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project.description != null)
                        Text(
                          project.description!,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 16),
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
                          final progress = total > 0 ? completed / total : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.project_complete_label,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: colorScheme.primary
                                      .withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(
                        height: 60,
                      ), // Increased height to prevent overlap with title
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, AppLocalizations.of(context)!.tasks, () {
                    _showAddTaskDialog(context, growthBlock, project.projectID);
                  }),
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
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, AppLocalizations.of(context)!.project_notes_label, () {
                    _createNewNote(
                      context,
                      database.projectNoteDAO,
                      project.projectID,
                    );
                  }),
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
                            .map((note) => _NoteItem(note: note))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, AppLocalizations.of(context)!.project_finance_label, () {
                    _showAddProjectTransactionDialog(
                      context,
                      context.read<FinanceBlock>(),
                      project.projectID,
                    );
                  }),
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
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                (isExpense
                                        ? Colors.redAccent
                                        : Colors.greenAccent)
                                    .withOpacity(0.1),
                            child: Icon(
                              isExpense ? Icons.remove : Icons.add,
                              color: isExpense
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            FinancePage.getCategoryName(l10n, tx.category),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd().format(tx.transactionDate),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            '${isExpense ? "-" : "+"}\$${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isExpense
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
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
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onAdd,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline),
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        textAlign: TextAlign.center,
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
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.project_task_title_hint),
          autofocus: true,
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

  const _NoteItem({required this.note});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
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
              Icon(Icons.description, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      AppLocalizations.of(context)!.project_last_edited_msg(DateFormat.MMMd().format(note.updatedAt)),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
