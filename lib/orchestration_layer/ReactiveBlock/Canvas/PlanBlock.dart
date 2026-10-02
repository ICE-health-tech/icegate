import 'package:signals/signals.dart';

import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanBlockPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanDiagramLayout.dart';

class PlanBlock {
  PlanBlock({required ReadonlySignal<String?> personIdSignal})
    : _personIdSignal = personIdSignal {
    _bindPersonIdEffect();
  }

  final ReadonlySignal<String?> _personIdSignal;
  EffectCleanup? _effectCleanup;
  String? _loadedPersonId;
  String? _scopedProjectId;
  bool _activated = false;

  /// When set, plan data is loaded/saved per project (`plan_board_{person}_{project}`).
  String? get scopedProjectId => _scopedProjectId;

  final rootLabel = signal('My schedule');
  final columns = listSignal<PlanColumn>([]);
  final links = listSignal<PlanLink>([]);
  final focusNotes = signal('');
  final focusTags = listSignal<String>([]);

  void dispose() {
    _effectCleanup?.call();
  }

  /// Called by [HubRegistry] when the canvas hub opens.
  Future<void> activate() async {
    await activateForProject(null);
  }

  /// Load/save board scoped to [projectId], or global when null.
  Future<void> activateForProject(String? projectId) async {
    _scopedProjectId =
        projectId != null && projectId.trim().isNotEmpty ? projectId.trim() : null;
    if (!_activated) _activated = true;
    final id = _personIdSignal.value;
    if (id != null && id.isNotEmpty) {
      await _loadForPerson(id);
    }
  }

  void _bindPersonIdEffect() {
    _effectCleanup = effect(() {
      if (!_activated) return;
      final id = _personIdSignal.value;
      if (id != null && id.isNotEmpty && id != _loadedPersonId) {
        _loadForPerson(id);
      }
    });
  }

  Future<void> _loadForPerson(String personId) async {
    _loadedPersonId = personId;
    final board = await PlanBlockPrefs.load(
      personId,
      projectId: _scopedProjectId,
    );
    if (board != null) {
      rootLabel.value = board.rootLabel;
      focusNotes.value = board.focusNotes;
      focusTags.value = List<String>.from(board.focusTags);
      columns.value = _normalizeLoadedColumns(board);
      links.value = List<PlanLink>.from(board.links);
      await _persist();
      return;
    }
    rootLabel.value = 'My schedule';
    columns.value = [];
    links.value = [];
    focusNotes.value = '';
    focusTags.value = [];
    await _persist();
  }

  Future<void> _persist() async {
    final personId = _personIdSignal.value;
    if (personId == null || personId.isEmpty) return;
    await PlanBlockPrefs.save(
      personId,
      PlanBoard(
        rootLabel: rootLabel.value,
        columns: columns.value,
        focusNotes: focusNotes.value,
        focusTags: focusTags.value,
        links: links.value,
      ),
      projectId: _scopedProjectId,
    );
  }

  List<PlanColumn> _normalizeLoadedColumns(PlanBoard board) {
    final cols = board.columns
        .map((c) => c.copyWith(kind: c.kind.normalized))
        .toList();
    final hasNotesBlock = cols.any((c) => c.kind.isNotes);
    if (!hasNotesBlock &&
        (board.focusNotes.isNotEmpty || board.focusTags.isNotEmpty)) {
      cols.add(
        PlanColumn(
          id: IDGen.generateUuid(),
          title: 'Focus Notes',
          kind: PlanColumnKind.notes,
          notesBody: board.focusNotes,
          tags: List<String>.from(board.focusTags),
        ),
      );
    }
    final result = <PlanColumn>[];
    final visibleSoFar = <PlanColumn>[];
    for (final col in cols) {
      if (col.hidden) {
        result.add(col);
        continue;
      }
      final positioned = _ensureBlockPosition(col, visibleSoFar);
      result.add(positioned);
      visibleSoFar.add(positioned);
    }
    return result;
  }

  PlanColumn _ensureBlockPosition(
    PlanColumn column,
    List<PlanColumn> priorVisible,
  ) {
    if (column.hasPosition) return column;
    final slot = PlanDiagramLayout.autoSlot(priorVisible.length, priorVisible);
    return column.copyWith(posX: slot.x, posY: slot.y);
  }

  ({double x, double y}) _nextBlockPosition() {
    final prior = visibleColumns();
    return PlanDiagramLayout.autoSlot(prior.length, prior);
  }

  void moveBlock(
    String columnId,
    double x,
    double y, {
    double boardWidth = PlanDiagramLayout.minBoardWidth,
    double boardHeight = PlanDiagramLayout.minBoardHeight,
  }) {
    final idx = _columnIndex(columnId);
    if (idx < 0) return;
    final col = columns[idx];
    final m = PlanDiagramLayout.measure(col);
    columns[idx] = col.copyWith(
      posX: PlanDiagramLayout.clampX(x, m.width, boardWidth),
      posY: PlanDiagramLayout.clampY(y, m.height, boardHeight),
    );
  }

  void setBlockPosition(
    String columnId,
    double x,
    double y, {
    double boardWidth = PlanDiagramLayout.minBoardWidth,
    double boardHeight = PlanDiagramLayout.minBoardHeight,
  }) {
    moveBlock(
      columnId,
      PlanDiagramLayout.snap(x),
      PlanDiagramLayout.snap(y),
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    );
    _persist();
  }

  PlanColumn _newColumn({
    required String title,
    required PlanColumnKind kind,
  }) {
    final pos = _nextBlockPosition();
    return PlanColumn(
      id: IDGen.generateUuid(),
      title: title,
      kind: kind,
      steps: kind.holdsSteps ? const [] : const [],
      posX: pos.x,
      posY: pos.y,
    );
  }

  List<PlanColumn> visibleColumns() =>
      columns.value.where((c) => !c.hidden).toList();

  void reorderVisibleBlocks(int oldIndex, int newIndex) {
    final visible = visibleColumns();
    if (oldIndex < 0 ||
        oldIndex >= visible.length ||
        newIndex < 0 ||
        newIndex >= visible.length) {
      return;
    }
    if (oldIndex < newIndex) newIndex -= 1;
    final item = visible.removeAt(oldIndex);
    visible.insert(newIndex, item);
    final hidden = columns.value.where((c) => c.hidden).toList();
    columns.value = [...visible, ...hidden];
    _persist();
  }

  static String _defaultTitleFor(PlanColumnKind kind) => switch (kind.normalized) {
    PlanColumnKind.schedule => 'Schedule',
    PlanColumnKind.notes => 'Focus Notes',
    PlanColumnKind.goals => 'Goals',
    PlanColumnKind.steps => 'Schedule',
  };

  /// Adds a new page block.
  void addBlock(PlanColumnKind kind, {String? title}) {
    final normalized = kind.normalized;
    final resolvedTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : _defaultTitleFor(normalized);
    columns.add(
      _newColumn(title: resolvedTitle, kind: normalized),
    );
    _persist();
  }

  void hideBlock(String columnId) {
    final idx = _columnIndex(columnId);
    if (idx < 0) return;
    columns[idx] = columns[idx].copyWith(hidden: true);
    _pruneLinksForColumn(columnId);
    _persist();
  }

  void showBlock(String columnId) {
    final idx = _columnIndex(columnId);
    if (idx < 0) return;
    final col = columns[idx];
    final positioned = col.hasPosition
        ? col
        : _ensureBlockPosition(col, visibleColumns());
    columns[idx] = positioned.copyWith(hidden: false);
    _persist();
  }

  void setColumnNotes(String columnId, String notes) {
    final idx = _columnIndex(columnId);
    if (idx < 0) return;
    columns[idx] = columns[idx].copyWith(notesBody: notes);
    _syncLegacyNotesFromColumns();
    _persist();
  }

  void _syncLegacyNotesFromColumns() {
    for (final col in columns.value) {
      if (col.kind.isNotes) {
        focusNotes.value = col.notesBody;
        focusTags.value = List<String>.from(col.tags);
        return;
      }
    }
    focusNotes.value = '';
    focusTags.value = [];
  }

  /// Creates a schedule block when the board has none yet.
  String ensureScheduleBlock({String title = 'Schedule'}) {
    final cols = columns.value;
    for (final col in cols) {
      if (col.kind == PlanColumnKind.schedule &&
          col.title.toLowerCase() == title.toLowerCase()) {
        if (col.hidden) {
          final idx = _columnIndex(col.id);
          columns[idx] = col.copyWith(hidden: false);
          _persist();
        }
        return col.id;
      }
    }
    for (final col in cols) {
      if (col.kind == PlanColumnKind.schedule) {
        if (col.hidden) {
          final idx = _columnIndex(col.id);
          columns[idx] = col.copyWith(hidden: false);
          _persist();
        }
        return col.id;
      }
    }
    final col = _newColumn(title: title, kind: PlanColumnKind.schedule);
    columns.value = [...cols, col];
    _persist();
    return col.id;
  }

  void addStepToSchedule({String title = 'New step'}) {
    addStep(ensureScheduleBlock(), title: title);
  }

  void setFocusNotes(String notes) {
    final notesIdx = columns.value.indexWhere(
      (c) => c.kind.isNotes && !c.hidden,
    );
    if (notesIdx >= 0) {
      columns[notesIdx] = columns[notesIdx].copyWith(notesBody: notes);
    }
    focusNotes.value = notes;
    _persist();
  }

  void setRootLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    rootLabel.value = trimmed;
    _persist();
  }

  void addColumn({String title = 'New column'}) {
    addBlock(PlanColumnKind.schedule, title: title);
  }

  void removeColumn(String columnId) {
    columns.removeWhere((c) => c.id == columnId);
    _pruneLinksForColumn(columnId);
    _syncLegacyNotesFromColumns();
    _persist();
  }

  /// User-drawn software-flow arrow from [fromColumnId] → [toColumnId].
  void addLink(String fromColumnId, String toColumnId) {
    if (fromColumnId == toColumnId) return;
    final exists = links.value.any(
      (l) => l.fromColumnId == fromColumnId && l.toColumnId == toColumnId,
    );
    if (exists) return;
    if (_columnIndex(fromColumnId) < 0 || _columnIndex(toColumnId) < 0) return;
    links.add(
      PlanLink(
        id: IDGen.generateUuid(),
        fromColumnId: fromColumnId,
        toColumnId: toColumnId,
      ),
    );
    _persist();
  }

  void removeLink(String linkId) {
    links.removeWhere((l) => l.id == linkId);
    _persist();
  }

  void _pruneLinksForColumn(String columnId) {
    links.value = links.value
        .where(
          (l) => l.fromColumnId != columnId && l.toColumnId != columnId,
        )
        .toList();
  }

  void updateColumnTitle(String columnId, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final idx = _columnIndex(columnId);
    if (idx < 0) return;
    columns[idx] = columns[idx].copyWith(title: trimmed);
    _persist();
  }

  void reorderColumns(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= columns.length ||
        newIndex < 0 ||
        newIndex >= columns.length) {
      return;
    }
    if (oldIndex < newIndex) newIndex -= 1;
    final item = columns.removeAt(oldIndex);
    columns.insert(newIndex, item);
    _persist();
  }

  void addStep(String columnId, {String title = 'New step'}) {
    final idx = _columnIndex(columnId);
    if (idx < 0) return;
    final col = columns[idx];
    if (!col.kind.holdsSteps) return;
    final step = PlanStep(id: IDGen.generateUuid(), title: title);
    columns[idx] = col.copyWith(steps: [...col.steps, step]);
    _persist();
  }

  void updateStep(String columnId, PlanStep step) {
    final colIdx = _columnIndex(columnId);
    if (colIdx < 0) return;
    final col = columns[colIdx];
    final stepIdx = col.steps.indexWhere((s) => s.id == step.id);
    if (stepIdx < 0) return;
    final next = List<PlanStep>.from(col.steps);
    next[stepIdx] = step;
    columns[colIdx] = col.copyWith(steps: next);
    _persist();
  }

  void removeStep(String columnId, String stepId) {
    final colIdx = _columnIndex(columnId);
    if (colIdx < 0) return;
    final col = columns[colIdx];
    columns[colIdx] = col.copyWith(
      steps: col.steps.where((s) => s.id != stepId).toList(),
    );
    _persist();
  }

  void reorderStepInColumn(String columnId, int oldIndex, int newIndex) {
    final colIdx = _columnIndex(columnId);
    if (colIdx < 0) return;
    final col = columns[colIdx];
    if (oldIndex < 0 ||
        oldIndex >= col.steps.length ||
        newIndex < 0 ||
        newIndex > col.steps.length) {
      return;
    }
    if (oldIndex < newIndex) newIndex -= 1;
    final next = List<PlanStep>.from(col.steps);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    columns[colIdx] = col.copyWith(steps: next);
    _persist();
  }

  void moveStepToColumn({
    required String stepId,
    required String fromColumnId,
    required String toColumnId,
    int? insertIndex,
  }) {
    if (fromColumnId == toColumnId) return;
    final fromIdx = _columnIndex(fromColumnId);
    final toIdx = _columnIndex(toColumnId);
    if (fromIdx < 0 || toIdx < 0) return;

    final fromCol = columns[fromIdx];
    final toCol = columns[toIdx];
    if (!fromCol.kind.holdsSteps || !toCol.kind.holdsSteps) return;

    final stepIdx = fromCol.steps.indexWhere((s) => s.id == stepId);
    if (stepIdx < 0) return;
    final step = fromCol.steps[stepIdx];

    final nextFromSteps = List<PlanStep>.from(fromCol.steps)..removeAt(stepIdx);
    columns[fromIdx] = fromCol.copyWith(steps: nextFromSteps);

    final nextToSteps = List<PlanStep>.from(toCol.steps);
    final target = insertIndex?.clamp(0, nextToSteps.length) ?? nextToSteps.length;
    nextToSteps.insert(target, step);
    columns[toIdx] = toCol.copyWith(steps: nextToSteps);
    _persist();
  }

  int _columnIndex(String columnId) =>
      columns.value.indexWhere((c) => c.id == columnId);
}
