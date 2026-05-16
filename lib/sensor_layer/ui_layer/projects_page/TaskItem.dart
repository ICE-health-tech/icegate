import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/utils/L10nExtensions.dart';

/// Confirms in a dialog, then deletes the goal locally.
Future<void> confirmDeleteTask(
  BuildContext context,
  GrowthBlock growthBlock,
  GoalProtocol task,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.task_delete_confirm_title),
      content: Text(l10n.task_delete_confirm_msg(task.title)),
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
  if (confirmed == true && context.mounted) {
    await growthBlock.deleteGoal(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.task_deleted_msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class TaskItem extends StatelessWidget {
  final GoalProtocol task;
  final String? projectName;
  final VoidCallback onComplete;
  final VoidCallback? onDeleteRequested;

  const TaskItem({
    super.key,
    required this.task,
    required this.onComplete,
    this.projectName,
    this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = task.status == 'done';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDone)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.surface)
                  .withValues(alpha: isDone ? 0.3 : 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: isDone ? null : onComplete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFFB2EBF2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFFB2EBF2)
                            : const Color(0xFFB2EBF2).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        if (isDone)
                          BoxShadow(
                            color: const Color(
                              0xFFB2EBF2,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: isDone
                        ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF00050A),
                        )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (projectName != null) ...[
                        Text(
                          projectName!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFB2EBF2),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? colorScheme.onSurface.withValues(alpha: 0.4)
                              : colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDeleteRequested != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    tooltip: AppLocalizations.of(context)!.task_delete_tooltip,
                    onPressed: onDeleteRequested,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
