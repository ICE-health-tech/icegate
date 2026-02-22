import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:signals/signals.dart';

class InternalWidgetBlock {
  final listInternalWidgetHomePage = signal<List<InternalWidgetProtocol>>([]);

  StreamSubscription<List<InternalWidgetData>>? _widgetSubscription;

  void updateListBlockFromDatabase(List<InternalWidgetProtocol> data) {
    listInternalWidgetHomePage.value = data;
  }

  /// Sets up the reactive link between the Drift database and this Signals store.
  /// Any change in the 'internalWidgetTable' will trigger an update here.
  void refreshBlock(InternalWidgetsDAO internalWidgetDAO) {
    // 1. Cancel any existing subscription to prevent leaks
    _widgetSubscription?.cancel();
    print(
      "DUYLONG Internal widget: ${internalWidgetDAO.getInternalWidgetByName("Health")}",
    );
    _widgetSubscription = internalWidgetDAO.watchAllWidgets().listen(
      (driftData) {
        // print("Mapping element: ${driftData.first.name}, Image: ${driftData.first.imageUrl}");
        final List<InternalWidgetProtocol> protocolData = driftData
            .map(
              (driftElement) =>
                  InternalWidgetProtocol.adapterList(driftElement),
            )
            .toList();

        // 4. Update the signal

        updateListBlockFromDatabase(protocolData);
      },
      onError: (e, stackTrace) {
        debugPrint("InternalWidgetBlock: Error watching widgets: $e");
        debugPrint("Stack trace: $stackTrace");
      },
    );
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
