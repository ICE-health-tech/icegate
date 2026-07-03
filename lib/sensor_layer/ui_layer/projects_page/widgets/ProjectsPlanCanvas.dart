import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/PlanBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanDiagramLayout.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/PlanDiagramEdgesPainter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/GridLinePainter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/ProjectsPlanBlockCard.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Free-form plan canvas — compact blocks at persisted (x, y) positions.
class ProjectsPlanCanvas extends StatefulWidget {
  const ProjectsPlanCanvas({super.key});

  static const double _shellFabClearance = 96;
  static const double _horizontalPad = 16;

  @override
  State<ProjectsPlanCanvas> createState() => _ProjectsPlanCanvasState();
}

class _ProjectsPlanCanvasState extends State<ProjectsPlanCanvas> {
  final _notesControllers = <String, TextEditingController>{};
  bool _canvasPanLocked = false;
  String? _draggingBlockId;
  bool _connectMode = false;
  String? _linkSourceId;

  @override
  void dispose() {
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _notesControllerFor(PlanColumn column) {
    final existing = _notesControllers[column.id];
    if (existing != null) {
      if (existing.text != column.notesBody) {
        existing.text = column.notesBody;
      }
      return existing;
    }
    final controller = TextEditingController(text: column.notesBody);
    _notesControllers[column.id] = controller;
    return controller;
  }

  void _pruneNotesControllers(List<PlanColumn> columns) {
    final ids = columns.where((c) => c.kind.isNotes).map((c) => c.id).toSet();
    final stale =
        _notesControllers.keys.where((id) => !ids.contains(id)).toList();
    for (final id in stale) {
      _notesControllers.remove(id)?.dispose();
    }
  }

  Future<void> _editRootLabel(BuildContext context, PlanBlock block) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: block.rootLabel.value);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.projects_plan_section_title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              InputDecoration(hintText: l10n.projects_plan_section_title),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.projects_calendar_save),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      block.setRootLabel(result);
    }
  }

  void _showManageBlocks(BuildContext context, PlanBlock block) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = block.columns.value.where((c) => c.hidden).toList();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.plan_manage_blocks,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.view_timeline_rounded),
              title: Text(l10n.plan_add_block_schedule),
              onTap: () {
                Navigator.pop(ctx);
                block.addBlock(PlanColumnKind.schedule);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: Text(l10n.plan_add_block_flow),
              onTap: () {
                Navigator.pop(ctx);
                block.addBlock(PlanColumnKind.schedule, title: 'Process');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded),
              title: Text(l10n.plan_add_block_goals),
              onTap: () {
                Navigator.pop(ctx);
                block.addBlock(PlanColumnKind.goals);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notes_rounded),
              title: Text(l10n.plan_add_block_notes),
              onTap: () {
                Navigator.pop(ctx);
                block.addBlock(PlanColumnKind.notes);
              },
            ),
            if (hidden.isNotEmpty) const Divider(height: 1),
            for (final col in hidden)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(col.title),
                onTap: () {
                  block.showBlock(col.id);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _addStep(PlanBlock block, PlanColumn column) {
    HapticFeedback.lightImpact();
    block.addStep(column.id);
  }

  void _addFirstScheduleStep(PlanBlock block) {
    HapticFeedback.lightImpact();
    block.addStepToSchedule();
  }

  void _toggleConnectMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _connectMode = !_connectMode;
      _linkSourceId = null;
      if (_connectMode) {
        _canvasPanLocked = false;
        _draggingBlockId = null;
      }
    });
    if (_connectMode && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.plan_connect_hint),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleConnectTap(PlanBlock block, String columnId) {
    HapticFeedback.selectionClick();
    if (_linkSourceId == null) {
      setState(() => _linkSourceId = columnId);
      return;
    }
    if (_linkSourceId == columnId) {
      setState(() => _linkSourceId = null);
      return;
    }
    block.addLink(_linkSourceId!, columnId);
    setState(() => _linkSourceId = null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.plan_link_added),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<PlanDiagramNodeLayout> _paintOrder(List<PlanDiagramNodeLayout> nodes) {
    if (_draggingBlockId == null) return nodes;
    final list = List<PlanDiagramNodeLayout>.from(nodes);
    final idx = list.indexWhere((n) => n.column.id == _draggingBlockId);
    if (idx < 0) return nodes;
    final dragged = list.removeAt(idx);
    list.add(dragged);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final planBlock = context.read<PlanBlock>();
    final root = planBlock.rootLabel.watch(context);
    final columns = planBlock.columns.watch(context);
    final boardLinks = planBlock.links.watch(context);
    final visible = columns.where((c) => !c.hidden).toList();
    final viewportW = MediaQuery.sizeOf(context).width;
    final diagram = PlanDiagramLayout.compute(
      visibleColumns: visible,
      links: boardLinks,
      viewportWidth: viewportW,
    );

    _pruneNotesControllers(columns);

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boardColor = isDark
        ? cs.surfaceContainerLow.withValues(alpha: 0.92)
        : const Color(0xFFF3F4F6);
    final gridColor = isDark ? cs.onSurface : const Color(0xFF9CA3AF);
    final accent = EntryColors.projectBlue;
    final boardIsEmpty = diagram.nodes.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ProjectsPlanCanvas._horizontalPad,
            4,
            ProjectsPlanCanvas._horizontalPad,
            8,
          ),
          child: _PlanPageHeader(
            breadcrumb: l10n.plan_workspace_breadcrumb,
            title: root,
            accent: accent,
            onEditTitle: () => _editRootLabel(context, planBlock),
          ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                panEnabled: !_canvasPanLocked,
                scaleEnabled: !_canvasPanLocked,
                minScale: 0.55,
                maxScale: 1.8,
                boundaryMargin: const EdgeInsets.all(280),
                child: SizedBox(
                  width: diagram.boardWidth,
                  height: diagram.boardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: boardColor,
                          child: CustomPaint(
                            painter: GridLinePainter(
                              color: gridColor,
                              spacing: PlanDiagramLayout.grid,
                              opacity: isDark ? 0.08 : 0.18,
                            ),
                          ),
                        ),
                      ),
                      if (diagram.edges.isNotEmpty)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PlanDiagramEdgesPainter(
                              edges: diagram.edges,
                              color: cs.outline.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      if (boardIsEmpty)
                        Positioned(
                          left: PlanDiagramLayout.snap(
                            (diagram.boardWidth - 240) / 2,
                          ),
                          top: PlanDiagramLayout.snap(200),
                          width: 240,
                          child: _PlanDropZone(
                            label: l10n.plan_drop_steps,
                            actionLabel: l10n.plan_add_first_step,
                            onAdd: () => _addFirstScheduleStep(planBlock),
                            highlighted: true,
                            compact: true,
                          ),
                        )
                      else
                        for (final node in _paintOrder(diagram.nodes))
                          _CanvasPlanBlock(
                            key: ValueKey(node.column.id),
                            node: node,
                            board: diagram,
                            planBlock: planBlock,
                            accent: accent,
                            elevated: _draggingBlockId == node.column.id,
                            connectMode: _connectMode,
                            linkSelected: _linkSourceId == node.column.id,
                            onConnectTap: _connectMode
                                ? () => _handleConnectTap(
                                    planBlock,
                                    node.column.id,
                                  )
                                : null,
                            notesController: node.column.kind.isNotes
                                ? _notesControllerFor(node.column)
                                : null,
                            onHide: () => planBlock.hideBlock(node.column.id),
                            onAddStep: () => _addStep(planBlock, node.column),
                            onNotesChanged: node.column.kind.isNotes
                                ? (v) => planBlock.setColumnNotes(
                                    node.column.id,
                                    v,
                                  )
                                : null,
                            onDragStart: () {
                              if (_connectMode) return;
                              HapticFeedback.selectionClick();
                              setState(() {
                                _canvasPanLocked = true;
                                _draggingBlockId = node.column.id;
                              });
                            },
                            onDragEnd: () {
                              setState(() {
                                _canvasPanLocked = false;
                                _draggingBlockId = null;
                              });
                            },
                          ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: ProjectsPlanCanvas._shellFabClearance,
                child: _PlanFabRail(
                  accent: accent,
                  connectMode: _connectMode,
                  onEditTitle: () => _editRootLabel(context, planBlock),
                  onManageBlocks: () {
                    HapticFeedback.mediumImpact();
                    _showManageBlocks(context, planBlock);
                  },
                  onToggleConnect: _toggleConnectMode,
                  onAddStep: () => _addFirstScheduleStep(planBlock),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CanvasPlanBlock extends StatefulWidget {
  const _CanvasPlanBlock({
    super.key,
    required this.node,
    required this.board,
    required this.planBlock,
    required this.accent,
    required this.elevated,
    required this.onHide,
    required this.onAddStep,
    this.connectMode = false,
    this.linkSelected = false,
    this.onConnectTap,
    this.notesController,
    this.onNotesChanged,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final PlanDiagramNodeLayout node;
  final PlanDiagramBoardLayout board;
  final PlanBlock planBlock;
  final Color accent;
  final bool elevated;
  final VoidCallback onHide;
  final VoidCallback onAddStep;
  final bool connectMode;
  final bool linkSelected;
  final VoidCallback? onConnectTap;
  final TextEditingController? notesController;
  final ValueChanged<String>? onNotesChanged;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  @override
  State<_CanvasPlanBlock> createState() => _CanvasPlanBlockState();
}

class _CanvasPlanBlockState extends State<_CanvasPlanBlock> {
  Offset _dragDelta = Offset.zero;

  double get _left => widget.node.x + _dragDelta.dx;
  double get _top => widget.node.y + _dragDelta.dy;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left,
      top: _top,
      width: widget.node.width,
      height: widget.node.height,
      child: ProjectsPlanBlockCard(
        column: widget.node.column,
        accent: widget.accent,
        elevated: widget.elevated,
        connectMode: widget.connectMode,
        linkSelected: widget.linkSelected,
        onConnectTap: widget.onConnectTap,
        onHide: widget.onHide,
        onAddStep: widget.onAddStep,
        notesController: widget.notesController,
        onNotesChanged: widget.onNotesChanged,
        onDragStart: widget.connectMode ? null : (_) => widget.onDragStart(),
        onDragUpdate: widget.connectMode
            ? null
            : (details) {
          setState(() => _dragDelta += details.delta);
        },
        onDragEnd: widget.connectMode
            ? null
            : (_) {
          widget.planBlock.setBlockPosition(
            widget.node.column.id,
            _left,
            _top,
            boardWidth: widget.board.boardWidth,
            boardHeight: widget.board.boardHeight,
          );
          setState(() => _dragDelta = Offset.zero);
          widget.onDragEnd();
        },
      ),
    );
  }
}

class _PlanPageHeader extends StatelessWidget {
  const _PlanPageHeader({
    required this.breadcrumb,
    required this.title,
    required this.accent,
    required this.onEditTitle,
  });

  final String breadcrumb;
  final String title;
  final Color accent;
  final VoidCallback onEditTitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                breadcrumb,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontSize: 10,
                ),
              ),
            ),
            _HeaderIconButton(
              icon: Icons.calendar_month_outlined,
              accent: accent,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onEditTitle,
              icon: Icon(Icons.edit_outlined, size: 17, color: cs.onSurface),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
      ),
    );
  }
}

class _PlanDropZone extends StatelessWidget {
  const _PlanDropZone({
    required this.label,
    required this.actionLabel,
    required this.onAdd,
    this.highlighted = false,
    this.compact = false,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onAdd;
  final bool highlighted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 20 : 28,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? cs.primary.withValues(alpha: 0.35)
                  : cs.outlineVariant.withValues(alpha: 0.4),
            ),
            color: highlighted
                ? cs.primary.withValues(alpha: 0.04)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: compact ? 22 : 28,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11 : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                actionLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: cs.primary.withValues(alpha: 0.6),
                  fontSize: compact ? 11 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanFabRail extends StatelessWidget {
  const _PlanFabRail({
    required this.accent,
    required this.connectMode,
    required this.onEditTitle,
    required this.onManageBlocks,
    required this.onToggleConnect,
    required this.onAddStep,
  });

  final Color accent;
  final bool connectMode;
  final VoidCallback onEditTitle;
  final VoidCallback onManageBlocks;
  final VoidCallback onToggleConnect;
  final VoidCallback onAddStep;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _SmallPlanFab(
          heroTag: 'plan_edit_title',
          icon: Icons.edit_outlined,
          onPressed: onEditTitle,
        ),
        const SizedBox(height: 10),
        _SmallPlanFab(
          heroTag: 'plan_manage_blocks',
          icon: Icons.view_agenda_outlined,
          onPressed: onManageBlocks,
        ),
        const SizedBox(height: 10),
        _SmallPlanFab(
          heroTag: 'plan_connect_blocks',
          icon: Icons.device_hub_rounded,
          highlighted: connectMode,
          accent: accent,
          onPressed: onToggleConnect,
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'plan_add_step_main',
          backgroundColor: accent,
          foregroundColor: cs.surface,
          elevation: 4,
          highlightElevation: 6,
          onPressed: onAddStep,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ],
    );
  }
}

class _SmallPlanFab extends StatelessWidget {
  const _SmallPlanFab({
    required this.heroTag,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
    this.accent,
  });

  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ring = accent ?? cs.primary;
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: highlighted ? ring.withValues(alpha: 0.18) : cs.surfaceContainerHigh,
      foregroundColor: highlighted ? ring : cs.onSurface,
      onPressed: onPressed,
      child: Icon(icon, size: 20),
    );
  }
}
