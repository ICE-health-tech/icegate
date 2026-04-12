import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:signals/signals.dart';

class InternalWidgetBlock {
  final listInternalWidgetHomePage = signal<List<InternalWidgetProtocol>>([]);
  final listInternalWidgetProjectsPage = signal<List<InternalWidgetProtocol>>(
    [],
  );

  StreamSubscription<List<InternalWidgetData>>? _homeSubscription;
  StreamSubscription<List<InternalWidgetData>>? _projectsSubscription;

  void updateListBlockFromDatabase(
    List<InternalWidgetProtocol> data,
    String scope,
  ) {
    if (scope == 'home') {
      listInternalWidgetHomePage.value = data;
    } else if (scope == 'projects') {
      listInternalWidgetProjectsPage.value = data;
    }
  }

  /// Sets up the reactive link between the Drift database and this Signals store.
  /// Any change in the 'internalWidgetTable' will trigger an update here.
  void refreshBlock(
    InternalWidgetsDAO internalWidgetDAO,
    String personID,
    String scope,
  ) {
    // 1. Cancel existing subscription for this scope
    if (scope == 'home') {
      _homeSubscription?.cancel();
    } else if (scope == 'projects') {
      _projectsSubscription?.cancel();
    }

    final newSubscription = internalWidgetDAO
        .watchScopedWidgets(personID, scope)
        .listen(
          (driftData) {
            final List<InternalWidgetProtocol> protocolData = driftData
                .map(
                  (driftElement) =>
                      InternalWidgetProtocol.adapterList(driftElement),
                )
                .toList();

            updateListBlockFromDatabase(protocolData, scope);
          },
          onError: (e, stackTrace) {
            debugPrint("InternalWidgetBlock ($scope): Error watching: $e");
          },
        );

    if (scope == 'home') {
      _homeSubscription = newSubscription;
    } else if (scope == 'projects') {
      _projectsSubscription = newSubscription;
    }
  }

  Future<void> deleteScopedWidget(
    InternalWidgetsDAO dao,
    String personID,
    String scope,
  ) async {
    await dao.deleteScopedWidgets(personID, scope);
  }

  Future<void> deleteWidget(InternalWidgetsDAO dao, String name) async {
    await dao.deleteInternalWidget(name);
  }

  Future<void> renameWidget(
    InternalWidgetsDAO dao,
    String oldName,
    String newName,
  ) async {
    await dao.renameInternalWidget(oldName, newName);
  }
}
