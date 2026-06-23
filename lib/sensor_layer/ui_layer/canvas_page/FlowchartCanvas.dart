import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/PlanBlock.dart';
import 'GridLinePainter.dart';

class _StepDragPayload {
  const _StepDragPayload({required this.stepId, required this.fromColumnId});

  final String stepId;
  final String fromColumnId;
}

/// Pan/zoom schedule planner — columns & steps from [PlanBlock].
class FlowchartCanvas extends StatelessWidget {
  const FlowchartCanvas({super.key, this.nodeWidth = 196});

  final double nodeWidth;

  static const double _columnGap = 44;
  static const double _canvasPad = 48;

  @override
  Widget build(BuildContext context) {
    final planBlock = context.read<PlanBlock>();

    return Watch((context) {
      final root = planBlock.rootLabel.value;
      final cols = planBlock.columns.value;
      return _PlanBoardView(
        planBlock: planBlock,
        rootLabel: root,
        columns: cols,
        nodeWidth: nodeWidth,
      );
    });
  }
}

class _PlanBoardView extends StatelessWidget {
  const _PlanBoardView({
    required this.planBlock,
    required this.rootLabel,
    required this.columns,
    required this.nodeWidth,
  });

  final PlanBlock planBlock;
  final String rootLabel;
  final List<PlanColumn> columns;
  final double nodeWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boardColor = isDark
        ? cs.surfaceContainerLow.withValues(alpha: 0.92)
        : const Color(0xFFF3F4F6);
    final gridColor = isDark ? cs.onSurface : const Color(0xFF9CA3AF);

    final boardWidth =
        FlowchartCanvas._canvasPad * 2 +
        columns.length * nodeWidth +
        (columns.length - 1) * FlowchartCanvas._columnGap;
    const boardHeight = 1180.0;

    return Stack(
      children: [
        InteractiveViewer(
          minScale: 0.45,
          maxScale: 2.2,
          boundaryMargin: const EdgeInsets.all(280),
          child: SizedBox(
            width: boardWidth.clamp(600, double.infinity),
            height: boardHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: boardColor),
                    child: CustomPaint(
                      painter: GridLinePainter(
                        color: gridColor,
                        spacing: 24,
                        opacity: isDark ? 0.08 : 0.18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: FlowchartCanvas._canvasPad,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _RootPill(
                      label: rootLabel,
                      onTap: () => _editRootLabel(context, planBlock, rootLabel),
                    ),
                  ),
                ),
                Positioned(
                  top: FlowchartCanvas._canvasPad + 72,
                  left: FlowchartCanvas._canvasPad,
                  right: FlowchartCanvas._canvasPad,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < columns.length; i++) ...[
                        if (i > 0)
                          SizedBox(width: FlowchartCanvas._columnGap),
                        Expanded(
                          child: _PlanColumnView(
                            planBlock: planBlock,
                            column: columns[i],
                            columnIndex: i,
                            nodeWidth: nodeWidth,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: _PlanFab(planBlock: planBlock, columns: columns),
        ),
      ],
    );
  }

  Future<void> _editRootLabel(
    BuildContext context,
    PlanBlock block,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'My schedule'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) block.setRootLabel(result);
  }
}

class _PlanFab extends StatelessWidget {
  const _PlanFab({required this.planBlock, required this.columns});

  final PlanBlock planBlock;
  final List<PlanColumn> columns;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'plan_add_step',
          onPressed: columns.isEmpty
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  planBlock.addStep(columns.last.id);
                },
          tooltip: 'Add step',
          child: const Icon(Icons.add_task_rounded),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'plan_add_column',
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          onPressed: () {
            HapticFeedback.mediumImpact();
            planBlock.addColumn();
          },
          tooltip: 'Add column',
          child: const Icon(Icons.view_column_rounded),
        ),
      ],
    );
  }
}

class _RootPill extends StatelessWidget {
  const _RootPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit_rounded, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanColumnView extends StatefulWidget {
  const _PlanColumnView({
    required this.planBlock,
    required this.column,
    required this.columnIndex,
    required this.nodeWidth,
  });

  final PlanBlock planBlock;
  final PlanColumn column;
  final int columnIndex;
  final double nodeWidth;

  @override
  State<_PlanColumnView> createState() => _PlanColumnViewState();
}

class _PlanColumnViewState extends State<_PlanColumnView> {
  bool _stepDropHover = false;
  bool _columnDropHover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final col = widget.column;

    return LongPressDraggable<int>(
      data: widget.columnIndex,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.92,
          child: SizedBox(
            width: widget.nodeWidth,
            child: _ColumnHeader(title: col.title, dragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: _buildColumnBody(col)),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != widget.columnIndex,
        onAcceptWithDetails: (d) {
          widget.planBlock.reorderColumns(d.data, widget.columnIndex);
          setState(() => _columnDropHover = false);
        },
        onMove: (_) => setState(() => _columnDropHover = true),
        onLeave: (_) => setState(() => _columnDropHover = false),
        builder: (context, colCandidates, _) {
          return DragTarget<_StepDragPayload>(
            onWillAcceptWithDetails: (d) =>
                d.data.fromColumnId != col.id,
            onAcceptWithDetails: (d) {
              widget.planBlock.moveStepToColumn(
                stepId: d.data.stepId,
                fromColumnId: d.data.fromColumnId,
                toColumnId: col.id,
              );
              setState(() => _stepDropHover = false);
            },
            onMove: (_) => setState(() => _stepDropHover = true),
            onLeave: (_) => setState(() => _stepDropHover = false),
            builder: (context, stepCandidates, __) {
              final highlight = _stepDropHover || stepCandidates.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: highlight
                        ? cs.primary.withValues(alpha: 0.55)
                        : (_columnDropHover || colCandidates.isNotEmpty)
                        ? cs.tertiary.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: _buildColumnBody(col),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildColumnBody(PlanColumn col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColumnHeader(
          title: col.title,
          onEdit: () => _editColumnTitle(context, col),
          onDelete: widget.planBlock.columns.value.length > 1
              ? () => widget.planBlock.removeColumn(col.id)
              : null,
        ),
        const SizedBox(height: 8),
        if (col.steps.isEmpty)
          _EmptyColumnHint(
            onAdd: () => widget.planBlock.addStep(col.id),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: col.steps.length,
            onReorder: (oldIndex, newIndex) {
              widget.planBlock.reorderStepInColumn(col.id, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final step = col.steps[index];
              final isLast = index == col.steps.length - 1;
              return Column(
                key: ValueKey(step.id),
                children: [
                  _PlanStepRow(
                    step: step,
                    columnId: col.id,
                    stepIndex: index,
                    nodeWidth: widget.nodeWidth,
                    onEdit: () => _editStep(context, col.id, step),
                    onDelete: () =>
                        widget.planBlock.removeStep(col.id, step.id),
                  ),
                  if (!isLast) _FlowConnector(label: step.connectorLabel),
                ],
              );
            },
          ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => widget.planBlock.addStep(col.id),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add step'),
        ),
      ],
    );
  }

  Future<void> _editColumnTitle(BuildContext context, PlanColumn col) async {
    final controller = TextEditingController(text: col.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Column name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      widget.planBlock.updateColumnTitle(col.id, result);
    }
  }

  Future<void> _editStep(
    BuildContext context,
    String columnId,
    PlanStep step,
  ) async {
    final updated = await showDialog<PlanStep>(
      context: context,
      builder: (ctx) => _PlanStepEditorDialog(step: step),
    );
    if (updated != null) widget.planBlock.updateStep(columnId, updated);
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.title,
    this.onEdit,
    this.onDelete,
    this.dragging = false,
  });

  final String title;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            size: 18,
            color: cs.onSurfaceVariant.withValues(alpha: dragging ? 1 : 0.6),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: onDelete,
              icon: Icon(Icons.close_rounded, color: cs.error),
            ),
        ],
      ),
    );
  }
}

class _EmptyColumnHint extends StatelessWidget {
  const _EmptyColumnHint({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Drop steps here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onAdd, child: const Text('Add first step')),
        ],
      ),
    );
  }
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({
    required this.step,
    required this.columnId,
    required this.stepIndex,
    required this.nodeWidth,
    required this.onEdit,
    required this.onDelete,
  });

  final PlanStep step;
  final String columnId;
  final int stepIndex;
  final double nodeWidth;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<_StepDragPayload>(
      data: _StepDragPayload(stepId: step.id, fromColumnId: columnId),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(
            width: nodeWidth - 12,
            child: _PlanNodeCard(step: step, width: nodeWidth),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: stepIndex,
            child: Padding(
              padding: const EdgeInsets.only(top: 14, right: 4),
              child: Icon(
                Icons.swap_vert_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              onLongPress: onDelete,
              child: _PlanNodeCard(step: step, width: nodeWidth),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lineColor = cs.outline.withValues(alpha: 0.45);

    return SizedBox(
      height: label == null ? 34 : 42,
      child: Column(
        children: [
          Container(width: 1.5, height: 16, color: lineColor),
          Icon(Icons.arrow_drop_down, size: 22, color: lineColor),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                fontSize: 10,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanNodeCard extends StatelessWidget {
  const _PlanNodeCard({required this.step, required this.width});

  final PlanStep step;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = cs.surface;
    Color border = cs.outlineVariant.withValues(alpha: 0.55);
    double borderWidth = 1;

    switch (step.variant) {
      case PlanNodeVariant.highlight:
        bg = isDark ? const Color(0xFF1B3D2A) : const Color(0xFFE8F5E9);
        border = isDark ? const Color(0xFF4CAF50) : const Color(0xFF81C784);
      case PlanNodeVariant.warning:
        bg = cs.surface;
        border = isDark ? const Color(0xFFFFAB91) : const Color(0xFFFFCCBC);
        borderWidth = 1.4;
      case PlanNodeVariant.dashed:
        bg = cs.surface.withValues(alpha: isDark ? 0.55 : 0.92);
      case PlanNodeVariant.standard:
        break;
    }

    final child = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: step.variant == PlanNodeVariant.dashed
            ? null
            : Border.all(color: border, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (step.variant == PlanNodeVariant.dashed)
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedBorderPainter(color: border, radius: 16),
              ),
            ),
          _NodeText(step: step),
        ],
      ),
    );

    if (step.route == null || step.route!.isEmpty) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(step.route!),
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _NodeText extends StatelessWidget {
  const _NodeText({required this.step});

  final PlanStep step;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 13.5,
      height: 1.2,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 11.5,
      height: 1.2,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          step.title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (step.subtitle != null && step.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            step.subtitle!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }
}

class _PlanStepEditorDialog extends StatefulWidget {
  const _PlanStepEditorDialog({required this.step});

  final PlanStep step;

  @override
  State<_PlanStepEditorDialog> createState() => _PlanStepEditorDialogState();
}

class _PlanStepEditorDialogState extends State<_PlanStepEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _connectorCtrl;
  late final TextEditingController _routeCtrl;
  late PlanNodeVariant _variant;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.step.title);
    _subtitleCtrl = TextEditingController(text: widget.step.subtitle ?? '');
    _connectorCtrl = TextEditingController(
      text: widget.step.connectorLabel ?? '',
    );
    _routeCtrl = TextEditingController(text: widget.step.route ?? '');
    _variant = widget.step.variant;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _connectorCtrl.dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit step'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(labelText: 'Subtitle'),
            ),
            TextField(
              controller: _connectorCtrl,
              decoration: const InputDecoration(
                labelText: 'Arrow label (below)',
              ),
            ),
            TextField(
              controller: _routeCtrl,
              decoration: const InputDecoration(
                labelText: 'Route (optional)',
                hintText: '/projects/calendar',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlanNodeVariant>(
              value: _variant,
              decoration: const InputDecoration(labelText: 'Style'),
              items: PlanNodeVariant.values
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _variant = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(
              context,
              widget.step.copyWith(
                title: title,
                subtitle: _subtitleCtrl.text.trim().isEmpty
                    ? null
                    : _subtitleCtrl.text.trim(),
                connectorLabel: _connectorCtrl.text.trim().isEmpty
                    ? null
                    : _connectorCtrl.text.trim(),
                route: _routeCtrl.text.trim().isEmpty
                    ? null
                    : _routeCtrl.text.trim(),
                variant: _variant,
                clearSubtitle: _subtitleCtrl.text.trim().isEmpty,
                clearConnectorLabel: _connectorCtrl.text.trim().isEmpty,
                clearRoute: _routeCtrl.text.trim().isEmpty,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
