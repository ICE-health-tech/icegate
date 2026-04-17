import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';

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
                if (!isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB2EBF2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFB2EBF2).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '+$TASK_SCORE_INCREMENT XP',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB2EBF2),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
