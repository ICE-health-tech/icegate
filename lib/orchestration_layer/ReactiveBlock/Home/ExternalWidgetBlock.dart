import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:signals/signals.dart';

class ExternalWidgetBlock {
  final listExternalWidgets = signal<List<ExternalWidgetData>>([]);
  StreamSubscription<List<ExternalWidgetData>>? _subscription;

  void refreshBlock(ExternalWidgetsDAO dao, String personID) {
    _subscription?.cancel();
    _subscription = dao.watchAllWidgets(personID).listen(
      (data) {
        listExternalWidgets.value = data;
      },
      onError: (e) =>
          debugPrint("ExternalWidgetBlock: Error watching widgets: $e"),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> deleteWidget(ExternalWidgetsDAO dao, String id) async {
    await dao.deleteWidget(id);
  }

  Future<void> renameWidget(
    ExternalWidgetsDAO dao,
    String widgetID,
    String newName,
  ) async {
    await dao.renameExternalWidget(widgetID, newName);
  }
}
