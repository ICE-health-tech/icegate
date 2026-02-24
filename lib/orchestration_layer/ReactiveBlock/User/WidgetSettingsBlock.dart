import 'dart:async';
import 'package:signals/signals.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/data_layer/Protocol/User/WidgetProtocols.dart';

class WidgetSettingsBlock {
  final widgets = listSignal<WidgetProtocol>([]);

  StreamSubscription? _widgetsSubscription;

  void updateWidgets(List<WidgetProtocol> data) => widgets.value = data;

  void init(WidgetDAO dao, String personID) {
    _widgetsSubscription?.cancel();
    _widgetsSubscription = dao.watchWidgets(personID).listen((data) {
      updateWidgets(
        data
            .map(
              (e) => WidgetProtocol(
                widgetID: e.personWidgetID??0,
                personID: e.personID,
                widgetName: e.widgetName,
                widgetType: e.widgetType,
                configuration: e.configuration,
                displayOrder: e.displayOrder,
                isActive: e.isActive,
                role: e.role.name,
              ),
            )
            .toList(),
      );
    });
  }

  void dispose() {
    _widgetsSubscription?.cancel();
  }
}
