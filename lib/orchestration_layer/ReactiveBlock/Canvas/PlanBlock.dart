import 'package:signals/signals.dart';

import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanBlockPrefs.dart';

class PlanBlock {
  PlanBlock({required ReadonlySignal<String?> personIdSignal})
    : _personIdSignal = personIdSignal {
    _bindPersonIdEffect();
  }

  final ReadonlySignal<String?> _personIdSignal;
  EffectCleanup? _effectCleanup;
  String? _loadedPersonId;
  bool _activated = false;

  final rootLabel = signal('My schedule');
  final columns = listSignal<PlanColumn>([]);

  void dispose() {
    _effectCleanup?.call();
  }

  /// Called by [HubRegistry] when the canvas hub opens.
  Future<void> activate() async {
    if (_activated) return;
    _activated = true;
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
    final board = await PlanBlockPrefs.load(personId);
    if (board != null && board.columns.isNotEmpty) {
      rootLabel.value = board.rootLabel;
      columns.value = List<PlanColumn>.from(board.columns);
      return;
    }
    rootLabel.value = 'My schedule';
    columns.value = [
      PlanColumn(id: IDGen.generateUuid(), title: 'Schedule', steps: const []),
    ];
    await _persist();
  }

  Future<void> _persist() async {
    final personId = _personIdSignal.value;
    if (personId == null || personId.isEmpty) return;
    await PlanBlockPrefs.save(
      personId,
      PlanBoard(rootLabel: rootLabel.value, columns: columns.value),
    );
  }

  void setRootLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    rootLabel.value = trimmed;
    _persist();
  }

  void addColumn({String title = 'New column'}) {
    columns.add(PlanColumn(id: IDGen.generateUuid(), title: title, steps: []));
    _persist();
  }

  void removeColumn(String columnId) {
    if (columns.length <= 1) return;
    columns.removeWhere((c) => c.id == columnId);
    _persist();
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
    final stepIdx = fromCol.steps.indexWhere((s) => s.id == stepId);
    if (stepIdx < 0) return;
    final step = fromCol.steps[stepIdx];

    final nextFromSteps = List<PlanStep>.from(fromCol.steps)..removeAt(stepIdx);
    columns[fromIdx] = fromCol.copyWith(steps: nextFromSteps);

    final toCol = columns[toIdx];
    final nextToSteps = List<PlanStep>.from(toCol.steps);
    final target = insertIndex?.clamp(0, nextToSteps.length) ?? nextToSteps.length;
    nextToSteps.insert(target, step);
    columns[toIdx] = toCol.copyWith(steps: nextToSteps);
    _persist();
  }

  int _columnIndex(String columnId) =>
      columns.value.indexWhere((c) => c.id == columnId);
}
