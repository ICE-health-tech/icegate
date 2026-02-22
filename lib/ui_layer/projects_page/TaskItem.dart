import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/Const.dart';

class TaskItem extends StatelessWidget {
  final GoalProtocol task;
  final String? projectName;
  final VoidCallback onComplete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onComplete,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = task.status == 'done';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? colorScheme.primary.withOpacity(0.2)
                : colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            if (!isDone)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: isDone ? null : onComplete,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone ? colorScheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (projectName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        projectName!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? colorScheme.onSurface.withOpacity(0.4)
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isDone && task.completionDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Completed on ${task.completionDate!.day}/${task.completionDate!.month}/${task.completionDate!.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$TASK_SCORE_INCREMENT XP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
