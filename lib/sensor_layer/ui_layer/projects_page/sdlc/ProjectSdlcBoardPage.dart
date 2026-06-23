import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Project/SdlcPhase.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/TaskItem.dart';
import 'package:provider/provider.dart';

String sdlcPhaseTitle(AppLocalizations l10n, SdlcPhase phase) {
  switch (phase) {
    case SdlcPhase.planning:
      return l10n.project_sdlc_phase_planning_title;
    case SdlcPhase.design:
      return l10n.project_sdlc_phase_design_title;
    case SdlcPhase.implementation:
      return l10n.project_sdlc_phase_implementation_title;
    case SdlcPhase.testing:
      return l10n.project_sdlc_phase_testing_title;
    case SdlcPhase.deployment:
      return l10n.project_sdlc_phase_deployment_title;
    case SdlcPhase.maintenance:
      return l10n.project_sdlc_phase_maintenance_title;
  }
}

GoalProtocol _goalProtocolFromData(GoalData data) {
  return GoalProtocol(
    id: data.id,
    goalID: data.goalID ?? '',
    personID: data.personID ?? '',
    title: data.title,
    description: data.description,
    category: data.category,
    priority: data.priority,
    status: data.status,
    targetDate: data.targetDate,
    completionDate: data.completionDate,
    progressPercentage: data.progressPercentage,
    projectID: data.projectID,
  );
}

bool sdlcPrefersImmediateDrag(BuildContext context) {
  if (MediaQuery.sizeOf(context).width >= 600) return true;
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux =>
      true,
    _ => false,
  };
}

class ProjectSdlcBoardPage extends StatefulWidget {
  const ProjectSdlcBoardPage({super.key, required this.project});

  final ProjectProtocol project;

  @override
  State<ProjectSdlcBoardPage> createState() => _ProjectSdlcBoardPageState();
}

class _ProjectSdlcBoardPageState extends State<ProjectSdlcBoardPage> {
  final _overlayKey = GlobalKey();
  final _scrollController = ScrollController();
  final _dropZoneKeys = {
    for (final info in SdlcPhaseCodec.phases) info.phase: GlobalKey(),
  };

  bool _dragActive = false;
  bool _boardPointerDown = false;
  bool _syncing = false;
  GoalProtocol? _draggingTask;
  SdlcPhase? _hoverPhase;
  Offset? _dragGlobalPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sync(showSnackBar: false));
    });
  }

  Future<void> _sync({bool showSnackBar = true}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await Future.wait([
        context.read<ProjectBlock>().syncFromCloud(),
        context.read<GrowthBlock>().sync(),
      ]);
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.project_sync_success),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.project_sync_failed(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  SdlcPhase? _phaseAtGlobal(Offset global) {
    SdlcPhase? hit;
    var bestArea = double.infinity;
    for (final info in SdlcPhaseCodec.phases) {
      final box =
          _dropZoneKeys[info.phase]?.currentContext?.findRenderObject()
              as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.contains(global)) continue;
      final area = rect.width * rect.height;
      if (area < bestArea) {
        bestArea = area;
        hit = info.phase;
      }
    }
    return hit;
  }

  void _beginDrag(GoalProtocol task) {
    if (task.status == 'done') return;
    setState(() {
      _dragActive = true;
      _draggingTask = task;
      _hoverPhase = SdlcPhaseCodec.fromCategory(task.category);
    });
    HapticFeedback.selectionClick();
  }

  void _handleDragMove(Offset global) {
    setState(() {
      _dragGlobalPosition = global;
      _hoverPhase = _phaseAtGlobal(global);
    });
  }

  void _clearDragState() {
    if (!_dragActive &&
        !_boardPointerDown &&
        _draggingTask == null &&
        _hoverPhase == null &&
        _dragGlobalPosition == null) {
      return;
    }
    setState(() {
      _dragActive = false;
      _boardPointerDown = false;
      _draggingTask = null;
      _hoverPhase = null;
      _dragGlobalPosition = null;
    });
  }

  void _onBoardPressDown() {
    if (_boardPointerDown) return;
    setState(() => _boardPointerDown = true);
  }

  void _onBoardPressUpWithoutDrag() {
    if (!_boardPointerDown) return;
    setState(() => _boardPointerDown = false);
  }

  Future<void> _finishDrag(GrowthBlock growthBlock) async {
    final task = _draggingTask;
    final target = _hoverPhase;
    _clearDragState();
    if (task == null || target == null) return;
    if (SdlcPhaseCodec.fromCategory(task.category) == target) return;
    await _onTaskDropped(context, growthBlock, task, target);
  }

  Future<void> _onTaskDropped(
    BuildContext context,
    GrowthBlock growthBlock,
    GoalProtocol task,
    SdlcPhase targetPhase,
  ) async {
    if (SdlcPhaseCodec.fromCategory(task.category) == targetPhase) return;
    await growthBlock.updateGoalSdlcPhase(task.id, targetPhase);
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.project_sdlc_task_moved(sdlcPhaseTitle(l10n, targetPhase)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget? _buildDragOverlay(BuildContext context, double cardWidth) {
    if (!_dragActive || _draggingTask == null || _dragGlobalPosition == null) {
      return null;
    }
    final overlayBox =
        _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null) return null;

    final local = overlayBox.globalToLocal(_dragGlobalPosition!);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final sourcePhase = _draggingTask == null
        ? null
        : SdlcPhaseCodec.fromCategory(_draggingTask!.category);
    final showTargetBadge =
        _hoverPhase != null &&
        sourcePhase != null &&
        _hoverPhase != sourcePhase;
    final targetLabel =
        showTargetBadge ? sdlcPhaseTitle(l10n, _hoverPhase!) : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (targetLabel != null)
          Positioned(
            left: 16,
            right: 16,
            top: 8,
            child: IgnorePointer(
              child: Center(
                child: Material(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary, width: 1.5),
                    ),
                    child: Text(
                      l10n.projects_calendar_drag_move_to(targetLabel),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: (local.dx - cardWidth / 2).clamp(8.0, overlayBox.size.width - cardWidth - 8),
          top: (local.dy - 24).clamp(8.0, overlayBox.size.height - 80),
          width: cardWidth,
          child: IgnorePointer(
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              color: cs.surface,
              child: _SdlcTaskCard(
                task: _draggingTask!,
                onTap: () {},
                dragging: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final immediateDrag = sdlcPrefersImmediateDrag(context);
    final projectLinkId = ProjectBlock.linkId(widget.project);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.project_sdlc_board_title),
            Text(
              widget.project.name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: l10n.integrations_sync_now,
              icon: const Icon(Icons.sync_rounded),
              onPressed: () => unawaited(_sync()),
            ),
          IconButton(
            tooltip: l10n.project_add_task_title,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddTaskDialog(context, growthBlock),
          ),
        ],
      ),
      body: StreamBuilder<List<GoalData>>(
        stream: context.read<AppDatabase>().growthDAO.watchSdlcGoalsForProject(
          projectLinkId,
        ),
        builder: (context, taskSnap) {
        final allTasks =
            (taskSnap.data ?? const []).map(_goalProtocolFromData).toList();
        final activeTasks =
            allTasks.where((t) => t.status != 'done').toList();

        List<GoalProtocol> tasksInPhase(SdlcPhase phase) {
          final phaseTasks = allTasks
              .where(
                (t) => SdlcPhaseCodec.fromCategory(t.category) == phase,
              )
              .toList();
          phaseTasks.sort((a, b) {
            if (a.status == 'done' && b.status != 'done') return 1;
            if (a.status != 'done' && b.status == 'done') return -1;
            return 0;
          });
          return phaseTasks;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PurposeCard(
                text: widget.project.description?.trim().isNotEmpty == true
                    ? widget.project.description!.trim()
                    : l10n.project_sdlc_default_purpose,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PhaseStatsRow(tasks: activeTasks),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useFullWidth = constraints.maxWidth >= 720;
                  final columnWidth = useFullWidth
                      ? (constraints.maxWidth - 32 - 10 * 5) / 6
                      : 252.0;
                  final cardWidth = columnWidth - 16;

                  List<_SdlcPhaseColumn> buildColumns() {
                    return [
                      for (final info in SdlcPhaseCodec.phases)
                        _SdlcPhaseColumn(
                          width: columnWidth,
                          info: info,
                          dropZoneKey: _dropZoneKeys[info.phase]!,
                          tasks: tasksInPhase(info.phase),
                          isDropHovered:
                              _dragActive &&
                              _hoverPhase == info.phase &&
                              _draggingTask != null &&
                              SdlcPhaseCodec.fromCategory(
                                    _draggingTask!.category,
                                  ) !=
                                  info.phase,
                          draggingTaskId: _draggingTask?.id,
                          scrollLocked: _dragActive || _boardPointerDown,
                          immediateDrag: immediateDrag,
                          onAdd: () => _showAddTaskDialog(
                            context,
                            growthBlock,
                            initialPhase: info.phase,
                          ),
                          onTaskTap: (task) =>
                              _showTaskSheet(context, growthBlock, task),
                          onPressDown: _onBoardPressDown,
                          onPressUpWithoutDrag: _onBoardPressUpWithoutDrag,
                          onDragStarted: _beginDrag,
                          onDragMove: _handleDragMove,
                          onDragFinished: () => _finishDrag(growthBlock),
                          onDragCancelled: _clearDragState,
                        ),
                    ];
                  }

                  Widget boardContent({required bool scrollHorizontally}) {
                    final columns = buildColumns();
                    final row = Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          scrollHorizontally
                              ? SizedBox(width: columnWidth, child: columns[i])
                              : Expanded(child: columns[i]),
                        ],
                      ],
                    );

                    if (scrollHorizontally) {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        physics: (_dragActive || _boardPointerDown)
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: row,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: row,
                    );
                  }

                  final dragOverlay = _buildDragOverlay(context, cardWidth);

                  return Stack(
                    key: _overlayKey,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: boardContent(
                          scrollHorizontally: !useFullWidth,
                        ),
                      ),
                      if (dragOverlay != null)
                        Positioned.fill(
                          child: IgnorePointer(child: dragOverlay),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    GrowthBlock growthBlock, {
    SdlcPhase initialPhase = SdlcPhase.implementation,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var phase = initialPhase;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.project_sdlc_add_task_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: l10n.project_task_title_hint),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: l10n.description_optional,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SdlcPhase>(
                initialValue: phase,
                decoration: InputDecoration(
                  labelText: l10n.project_sdlc_move_phase,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: SdlcPhaseCodec.phases
                    .map(
                      (info) => DropdownMenuItem(
                        value: info.phase,
                        child: Text(sdlcPhaseTitle(l10n, info.phase)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => phase = v);
                },
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
                  descriptionController.text.trim(),
                  projectID: ProjectBlock.linkId(widget.project),
                  category: SdlcPhaseCodec.toCategory(phase),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showTaskSheet(
    BuildContext context,
    GrowthBlock growthBlock,
    GoalProtocol task,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: task.title);
    final descriptionController =
        TextEditingController(text: task.description ?? '');
    var phase = SdlcPhaseCodec.fromCategory(task.category);
    final isDone = task.status == 'done';

    try {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.tooltip_edit,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  enabled: !isDone,
                  decoration: InputDecoration(
                    labelText: l10n.project_task_title_hint,
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  enabled: !isDone,
                  decoration: InputDecoration(
                    labelText: l10n.description_optional,
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SdlcPhase>(
                  value: phase,
                  decoration: InputDecoration(
                    labelText: l10n.project_sdlc_move_phase,
                    border: const OutlineInputBorder(),
                  ),
                  items: SdlcPhaseCodec.phases
                      .map(
                        (info) => DropdownMenuItem(
                          value: info.phase,
                          child: Text(sdlcPhaseTitle(l10n, info.phase)),
                        ),
                      )
                      .toList(),
                  onChanged: isDone
                      ? null
                      : (v) => setState(() => phase = v!),
                ),
                const SizedBox(height: 16),
                if (!isDone)
                  FilledButton.icon(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      await growthBlock.updateGoalDetails(
                        task.id,
                        title: title,
                        description: descriptionController.text.trim(),
                      );
                      if (SdlcPhaseCodec.fromCategory(task.category) != phase) {
                        await growthBlock.updateGoalSdlcPhase(task.id, phase);
                      }
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.projects_calendar_save),
                  ),
                if (!isDone) const SizedBox(height: 8),
                Row(
                  children: [
                    if (!isDone)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) return;
                            await growthBlock.updateGoalDetails(
                              task.id,
                              title: title,
                              description: descriptionController.text.trim(),
                            );
                            if (SdlcPhaseCodec.fromCategory(task.category) !=
                                phase) {
                              await growthBlock.updateGoalSdlcPhase(
                                task.id,
                                phase,
                              );
                            }
                            await growthBlock.completeGoal(task.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l10n.project_complete_label),
                        ),
                      ),
                    if (!isDone) const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.task_delete_tooltip,
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        if (context.mounted) {
                          await confirmDeleteTask(
                            context,
                            growthBlock,
                            task,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }
}

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: colorScheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _PhaseStatsRow extends StatelessWidget {
  const _PhaseStatsRow({required this.tasks});

  final List<GoalProtocol> tasks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final info in SdlcPhaseCodec.phases) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                l10n.project_sdlc_phase_stat(
                  info.number,
                  tasks
                      .where(
                        (t) =>
                            SdlcPhaseCodec.fromCategory(t.category) == info.phase,
                      )
                      .length,
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SdlcPhaseColumn extends StatelessWidget {
  const _SdlcPhaseColumn({
    required this.width,
    required this.info,
    required this.dropZoneKey,
    required this.tasks,
    required this.isDropHovered,
    required this.draggingTaskId,
    required this.scrollLocked,
    required this.immediateDrag,
    required this.onAdd,
    required this.onTaskTap,
    required this.onPressDown,
    required this.onPressUpWithoutDrag,
    required this.onDragStarted,
    required this.onDragMove,
    required this.onDragFinished,
    required this.onDragCancelled,
  });

  final double width;
  final SdlcPhaseInfo info;
  final GlobalKey dropZoneKey;
  final List<GoalProtocol> tasks;
  final bool isDropHovered;
  final String? draggingTaskId;
  final bool scrollLocked;
  final bool immediateDrag;
  final VoidCallback onAdd;
  final ValueChanged<GoalProtocol> onTaskTap;
  final VoidCallback onPressDown;
  final VoidCallback onPressUpWithoutDrag;
  final ValueChanged<GoalProtocol> onDragStarted;
  final ValueChanged<Offset> onDragMove;
  final Future<void> Function() onDragFinished;
  final VoidCallback onDragCancelled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final title = sdlcPhaseTitle(l10n, info.phase);
    final hint = _phaseHint(l10n, info.phase);
    final dragHint = immediateDrag
        ? l10n.projects_calendar_drag_hint_desktop
        : l10n.projects_calendar_drag_hint_mobile;

    return Column(
      key: dropZoneKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'P${info.number}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$hint · ${tasks.length}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.project_sdlc_add_to_phase,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onAdd,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDropHovered
                  ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDropHovered
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isDropHovered ? 2 : 1,
              ),
            ),
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      isDropHovered
                          ? l10n.project_sdlc_drop_here
                          : l10n.project_sdlc_column_empty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isDropHovered ? FontWeight.w700 : FontWeight.w500,
                        color: isDropHovered
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: scrollLocked
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final isDone = task.status == 'done';
                      if (isDone) {
                        return Semantics(
                          label: task.title,
                          child: GestureDetector(
                            onTap: () => onTaskTap(task),
                            child: _SdlcTaskCard(
                              task: task,
                              onTap: () => onTaskTap(task),
                              isDone: true,
                            ),
                          ),
                        );
                      }
                      final isGhost =
                          draggingTaskId != null && draggingTaskId == task.id;
                      return Semantics(
                        label: task.title,
                        hint: dragHint,
                        child: _MovableSdlcTaskCard(
                          immediateDrag: immediateDrag,
                          task: task,
                          isGhost: isGhost,
                          onTap: () => onTaskTap(task),
                          onPressDown: onPressDown,
                          onPressUpWithoutDrag: onPressUpWithoutDrag,
                          onDragStarted: () => onDragStarted(task),
                          onDragMove: onDragMove,
                          onDragFinished: onDragFinished,
                          onDragCancelled: onDragCancelled,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _phaseHint(AppLocalizations l10n, SdlcPhase phase) {
    switch (phase) {
      case SdlcPhase.planning:
        return l10n.project_sdlc_phase_planning_hint;
      case SdlcPhase.design:
        return l10n.project_sdlc_phase_design_hint;
      case SdlcPhase.implementation:
        return l10n.project_sdlc_phase_implementation_hint;
      case SdlcPhase.testing:
        return l10n.project_sdlc_phase_testing_hint;
      case SdlcPhase.deployment:
        return l10n.project_sdlc_phase_deployment_hint;
      case SdlcPhase.maintenance:
        return l10n.project_sdlc_phase_maintenance_hint;
    }
  }
}

class _MovableSdlcTaskCard extends StatefulWidget {
  const _MovableSdlcTaskCard({
    required this.immediateDrag,
    required this.task,
    required this.isGhost,
    required this.onTap,
    required this.onPressDown,
    required this.onPressUpWithoutDrag,
    required this.onDragStarted,
    required this.onDragMove,
    required this.onDragFinished,
    required this.onDragCancelled,
  });

  final bool immediateDrag;
  final GoalProtocol task;
  final bool isGhost;
  final VoidCallback onTap;
  final VoidCallback onPressDown;
  final VoidCallback onPressUpWithoutDrag;
  final VoidCallback onDragStarted;
  final ValueChanged<Offset> onDragMove;
  final Future<void> Function() onDragFinished;
  final VoidCallback onDragCancelled;

  @override
  State<_MovableSdlcTaskCard> createState() => _MovableSdlcTaskCardState();
}

class _MovableSdlcTaskCardState extends State<_MovableSdlcTaskCard> {
  static const _dragThreshold = 4.0;

  bool _dragging = false;
  bool _hovering = false;
  Offset? _pointerDownGlobal;

  Future<void> _endDrag() async {
    if (!_dragging) return;
    _dragging = false;
    await widget.onDragFinished();
  }

  void _resetPointer() {
    _pointerDownGlobal = null;
    _dragging = false;
  }

  Widget _card({required bool ghost}) {
    final card = _SdlcTaskCard(task: widget.task, onTap: widget.onTap);
    if (!ghost) return card;
    // Keep full card height while dragging — shrinking the placeholder can drop pointer events.
    return Opacity(
      opacity: 0.3,
      child: IgnorePointer(child: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final block = _card(ghost: widget.isGhost);

    if (widget.immediateDrag) {
      return MouseRegion(
        cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: _hovering && !_dragging && !widget.isGhost
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                )
              : null,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (widget.isGhost) return;
              _pointerDownGlobal = event.position;
              _dragging = false;
              widget.onPressDown();
            },
            onPointerMove: (event) {
              if (_pointerDownGlobal == null) return;
              if (!_dragging) {
                final delta = event.position - _pointerDownGlobal!;
                if (delta.distance < _dragThreshold) return;
                _dragging = true;
                widget.onDragStarted();
              }
              widget.onDragMove(event.position);
            },
            onPointerUp: (_) {
              if (_dragging) {
                unawaited(_endDrag());
              } else if (!widget.isGhost) {
                widget.onTap();
                widget.onPressUpWithoutDrag();
              } else {
                widget.onPressUpWithoutDrag();
              }
              _resetPointer();
            },
            onPointerCancel: (_) {
              if (_dragging) {
                widget.onDragCancelled();
              } else {
                widget.onPressUpWithoutDrag();
              }
              _resetPointer();
            },
            child: block,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) {
        if (widget.isGhost) return;
        _dragging = true;
        widget.onPressDown();
        HapticFeedback.selectionClick();
        widget.onDragStarted();
      },
      onLongPressMoveUpdate: (details) =>
          widget.onDragMove(details.globalPosition),
      onLongPressEnd: (_) {
        unawaited(_endDrag());
        widget.onPressUpWithoutDrag();
      },
      onLongPressCancel: () {
        _dragging = false;
        widget.onDragCancelled();
        widget.onPressUpWithoutDrag();
      },
      onTap: widget.isGhost ? null : widget.onTap,
      child: block,
    );
  }
}

class _SdlcTaskCard extends StatelessWidget {
  const _SdlcTaskCard({
    required this.task,
    required this.onTap,
    this.dragging = false,
    this.isDone = false,
  });

  final GoalProtocol task;
  final VoidCallback onTap;
  final bool dragging;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = task.status == 'done' || this.isDone;

    Widget card = Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: dragging
                ? colorScheme.primary
                : isDone
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDone)
              Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              )
            else
              Icon(
                Icons.check_rounded,
                size: 18,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? colorScheme.onSurface.withValues(alpha: 0.45)
                          : null,
                    ),
                  ),
                  if (task.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(
                          alpha: isDone ? 0.35 : 0.55,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!isDone) return card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
        child: Opacity(opacity: 0.88, child: card),
      ),
    );
  }
}
