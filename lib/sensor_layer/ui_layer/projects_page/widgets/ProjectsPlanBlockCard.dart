import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

/// Compact glass block for the free-form plan canvas.
class ProjectsPlanBlockCard extends StatelessWidget {
  const ProjectsPlanBlockCard({
    super.key,
    required this.column,
    required this.accent,
    required this.onHide,
    required this.onAddStep,
    this.notesController,
    this.onNotesChanged,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.elevated = false,
    this.connectMode = false,
    this.linkSelected = false,
    this.onConnectTap,
  });

  final PlanColumn column;
  final Color accent;
  final VoidCallback onHide;
  final VoidCallback onAddStep;
  final TextEditingController? notesController;
  final ValueChanged<String>? onNotesChanged;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final bool elevated;
  final bool connectMode;
  final bool linkSelected;
  final VoidCallback? onConnectTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final kind = column.kind.normalized;

    return Material(
      color: Colors.transparent,
      elevation: elevated || linkSelected ? 8 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: connectMode ? onConnectTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: linkSelected
                ? accent
                : elevated
                ? accent.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.35),
            width: linkSelected ? 2 : (elevated ? 1.4 : 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onPanStart: connectMode ? null : onDragStart,
              onPanUpdate: connectMode ? null : onDragUpdate,
              onPanEnd: connectMode ? null : onDragEnd,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 4),
                  Icon(_iconFor(kind), size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      column.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: onHide,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (kind.isNotes)
              _NotesBlockBody(
                controller: notesController!,
                hint: l10n.plan_notes_hint,
                tags: column.tags,
                accent: accent,
                onChanged: onNotesChanged!,
              )
            else
              _StepsBlockBody(
                steps: column.steps,
                accent: accent,
                showTimeColumn: kind == PlanColumnKind.schedule,
                emptyLabel: kind == PlanColumnKind.goals
                    ? l10n.plan_goals_empty
                    : l10n.plan_schedule_empty,
                addLabel: kind == PlanColumnKind.goals
                    ? l10n.plan_add_goal
                    : l10n.plan_add_step,
                onAddStep: onAddStep,
              ),
          ],
        ),
      ),
      ),
    );
  }

  static IconData _iconFor(PlanColumnKind kind) => switch (kind) {
    PlanColumnKind.notes => Icons.notes_rounded,
    PlanColumnKind.goals => Icons.flag_rounded,
    PlanColumnKind.schedule || PlanColumnKind.steps => Icons.view_timeline_rounded,
  };
}

class _StepsBlockBody extends StatelessWidget {
  const _StepsBlockBody({
    required this.steps,
    required this.accent,
    required this.showTimeColumn,
    required this.emptyLabel,
    required this.addLabel,
    required this.onAddStep,
  });

  final List<PlanStep> steps;
  final Color accent;
  final bool showTimeColumn;
  final String emptyLabel;
  final String addLabel;
  final VoidCallback onAddStep;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 132),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (steps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      emptyLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < steps.length; i++) ...[
                    _StepRow(
                      step: steps[i],
                      accent: accent,
                      showTimeColumn: showTimeColumn,
                    ),
                    if (i < steps.length - 1)
                      Padding(
                        padding: EdgeInsets.only(
                          left: showTimeColumn ? 30 : 0,
                          bottom: 2,
                        ),
                        child: Container(
                          width: 2,
                          height: 8,
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                  ],
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAddStep,
            icon: Icon(Icons.add_rounded, size: 14, color: accent),
            label: Text(
              addLabel,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.accent,
    required this.showTimeColumn,
  });

  final PlanStep step;
  final Color accent;
  final bool showTimeColumn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTimeColumn)
            SizedBox(
              width: 36,
              child: Text(
                step.connectorLabel ?? '',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (step.subtitle != null && step.subtitle!.isNotEmpty)
                  Text(
                    step.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesBlockBody extends StatelessWidget {
  const _NotesBlockBody({
    required this.controller,
    required this.hint,
    required this.tags,
    required this.accent,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final List<String> tags;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          onChanged: onChanged,
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final tag in tags) _PlanTagChip(label: tag, accent: accent),
            ],
          ),
        ],
      ],
    );
  }
}

class _PlanTagChip extends StatelessWidget {
  const _PlanTagChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        color: accent.withValues(alpha: 0.1),
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}
