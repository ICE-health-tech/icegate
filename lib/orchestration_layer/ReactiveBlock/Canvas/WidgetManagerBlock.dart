import 'dart:convert';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class WidgetManagerBlock {
  final WidgetDAO? _widgetDao;
  final ReadonlySignal<String?> _personIdSignal;
  EffectCleanup? _effectCleanup;

  // 1. STATE
  final widgets = listSignal<InternalWidgetDragProtocol>([]);

  // Constructor
  WidgetManagerBlock({
    WidgetDAO? widgetDao,
    required ReadonlySignal<String?> personIdSignal,
  }) : _widgetDao = widgetDao,
       _personIdSignal = personIdSignal {
    // print("widgets: ${widgets.value}");
    if (widgets.value.isEmpty) {
      _initializeGrid();
    }

    // Use an effect to reactively load whenever the personId becomes available
    _effectCleanup = effect(() {
      final id = _personIdSignal.value;
      if (id != null && _widgetDao != null) {
        loadFromDatabase();
      }
    });
  }

  void dispose() {
    _effectCleanup?.call();
  }

  void _initializeGrid() {
    widgets.clear();
    final initialData = List.generate(
      15,
      (_) => InternalWidgetDragProtocol.empty(),
    );
    widgets.addAll(initialData);
  }

  void resetGrid() {
    _initializeGrid();
    _persistToDatabase();
  }

  // ==================================================
  // 2. PERSISTENCE
  // ==================================================
  Future<void> loadFromDatabase() async {
    final personId = _personIdSignal.value;
    if (_widgetDao == null || personId == null) return;

    try {
      final dbWidgets = await _widgetDao.getAllWidgets(personId);

      // Tạo một bản sao danh sách hiện tại (danh sách trống 15 phần tử)
      final List<InternalWidgetDragProtocol> nextGrid = List.generate(
        15,
        (_) => InternalWidgetDragProtocol.empty(),
      );

      for (final dbWidget in dbWidgets) {
        final index = dbWidget.displayOrder;
        if (index >= 0 && index < nextGrid.length) {
          try {
            final Map<String, dynamic> json = jsonDecode(
              dbWidget.configuration,
            );
            nextGrid[index] = InternalWidgetDragProtocol.fromJson(json);
          } catch (e) {
            print("Error decoding: $e");
          }
        }
      }

      // Cập nhật signal MỘT LẦN DUY NHẤT ở cuối
      // Dùng Future.microtask để đảm bảo không xung đột với chu kỳ build hiện tại
      Future.microtask(() {
        widgets.value = nextGrid;
      });
    } catch (e) {
      print("Error loading widgets from database: $e");
    }
  }

  bool _isSaving = false;
  bool _needsSaveAgain = false;

  Future<void> _persistToDatabase() async {
    final personId = _personIdSignal.value;
    if (_widgetDao == null || personId == null) return;

    if (_isSaving) {
      _needsSaveAgain = true;
      return;
    }

    _isSaving = true;
    _needsSaveAgain = false;

    try {
      await _widgetDao.saveAllWidgets(personId, widgets.value);
    } catch (e) {
      print("Error persisting widgets: $e");
    } finally {
      _isSaving = false;
      if (_needsSaveAgain) {
        _persistToDatabase();
      }
    }
  }

  // ==================================================
  // 3. ACTIONS (LOGIC)
  // ==================================================

  void reorderWidgets(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = widgets.removeAt(oldIndex);
    widgets.insert(newIndex, item);
    _persistToDatabase();
  }

  void swapContent(int indexA, int indexB) {
    if (indexA == indexB) return;
    if (!_isValidIndex(indexA) || !_isValidIndex(indexB)) return;

    final widgetA = widgets[indexA];
    final widgetB = widgets[indexB];

    widgets[indexA] = widgetB;
    widgets[indexB] = widgetA;

    _updateDependencies(widgetA);
    // Don't call persist here if it's called by the parent interaction handler
    // _persistToDatabase();
  }

  void mergeWidgets(int sourceIndex, int targetIndex) {
    if (sourceIndex == targetIndex) return;

    final source = widgets[sourceIndex];
    final target = widgets[targetIndex];

    final newTarget = target.copyWith(
      score: target.score + source.score,
      alias: "${target.alias}+",
    );

    widgets[targetIndex] = newTarget;
    widgets[sourceIndex] = InternalWidgetDragProtocol.empty();
    _persistToDatabase();
  }

  void addWidget(int index, InternalWidgetDragProtocol outSideWidget) {
    widgets[index] = outSideWidget;
    print("widgets: ${widgets.value}");
    print("Added widget: ${outSideWidget.alias}");
    _persistToDatabase();
  }

  void removeByIndex(int index) {
    widgets[index] = InternalWidgetDragProtocol.empty();
    _persistToDatabase();
  }

  void renameWidget(int index, String newName) {
    if (!_isValidIndex(index)) return;
    final widget = widgets[index];
    if (widget.isEmpty) return;

    widgets[index] = widget.copyWith(name: newName);
    _persistToDatabase();
  }

  void handleInteraction(int sourceIndex, int targetIndex) {
    if (!_isValidIndex(sourceIndex) || !_isValidIndex(targetIndex)) return;

    final source = widgets[sourceIndex];
    final target = widgets[targetIndex];

    if (target.isTarget && !source.isTarget) {
      final newTarget = target.copyWith(
        score: target.score + source.score,
        alias: "Consumed ${source.alias}",
      );

      widgets[targetIndex] = newTarget;
      widgets[sourceIndex] = InternalWidgetDragProtocol.empty();
    } else {
      swapContent(sourceIndex, targetIndex);
    }
    _persistToDatabase();
  }

  void _updateDependencies(InternalWidgetDragProtocol changedWidget) {
    if (changedWidget.score > 100) {
      for (int i = 0; i < widgets.length; i++) {
        if (widgets[i].widgetID == changedWidget.widgetID) continue;
        widgets[i] = widgets[i].copyWith(isStay: true);
      }
    }
  }

  bool _isValidIndex(int index) {
    return index >= 0 && index < widgets.length;
  }

  late final totalScore = computed(
    () => widgets.fold(0, (sum, item) => sum + item.score),
  );
  late final activeItemCount = computed(
    () => widgets.where((w) => !w.isEmpty).length,
  );
}
