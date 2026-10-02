import 'package:flutter/foundation.dart';

import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/PlanBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';

/// Hub keys for lazy block initialization.
abstract final class HubId {
  static const growth = 'growth';
  static const projects = 'projects';
  static const canvas = 'canvas';
}

/// Defers heavy [ReactiveBlock] init until a hub route is opened.
class HubRegistry {
  HubRegistry({
    required this.database,
    required this.growthBlock,
    required this.projectBlock,
    required this.planBlock,
    required this.widgetManagerBlock,
    required this.internalWidgetBlock,
  });

  final AppDatabase database;
  final GrowthBlock growthBlock;
  final ProjectBlock projectBlock;
  final PlanBlock planBlock;
  final WidgetManagerBlock widgetManagerBlock;
  final InternalWidgetBlock internalWidgetBlock;

  final Set<String> _ready = {};
  final Map<String, Future<void>> _inFlight = {};
  String? _personId;

  String? get personId => _personId;

  void bindPerson(String personId) {
    if (personId.isEmpty) return;
    if (_personId == personId) return;
    _personId = personId;
    _ready.clear();
    _inFlight.clear();
    debugPrint('HubRegistry: bound person $personId');
  }

  bool isReady(String hub) => _ready.contains(hub);

  /// Maps a route path to the hub that must be loaded first.
  static String? hubForPath(String path) {
    if (path.startsWith('/canvas')) return HubId.canvas;
    if (path.startsWith('/projects')) return HubId.projects;
    if (path.startsWith('/social')) return HubId.growth;
    return null;
  }

  Future<void> ensure(String hub) {
    if (_ready.contains(hub)) return Future.value();
    return _inFlight.putIfAbsent(hub, () async {
      try {
        await _activateHub(hub);
        _ready.add(hub);
        debugPrint('HubRegistry: hub ready — $hub');
      } catch (e, st) {
        debugPrint('HubRegistry: hub $hub failed — $e\n$st');
        rethrow;
      } finally {
        _inFlight.remove(hub);
      }
    });
  }

  Future<void> _activateHub(String hub) async {
    final personId = _personId;
    if (personId == null || personId.isEmpty) {
      debugPrint('HubRegistry: skip $hub — no personId');
      return;
    }

    switch (hub) {
      case HubId.growth:
        growthBlock.init(database.growthDAO, personId);
      case HubId.projects:
        await ensure(HubId.growth);
        projectBlock.init(database.projectsDAO, personId);
        await planBlock.activate();
        internalWidgetBlock.refreshBlock(
          database.internalWidgetsDAO,
          personId,
          'projects',
        );
      case HubId.canvas:
        await widgetManagerBlock.activate();
      default:
        debugPrint('HubRegistry: unknown hub $hub');
    }
  }
}
