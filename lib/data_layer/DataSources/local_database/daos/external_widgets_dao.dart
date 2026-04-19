part of '../Database.dart';

@DriftAccessor(tables: [ExternalWidgetsTable])
class ExternalWidgetsDAO extends DatabaseAccessor<AppDatabase>
    with _$ExternalWidgetsDAOMixin {
  ExternalWidgetsDAO(super.db);

  Future<int> insertWidget(ExternalWidgetsTableCompanion entry) {
    return into(externalWidgetsTable).insert(entry);
  }

  Future<bool> updateWidget(ExternalWidgetData entry) {
    return update(externalWidgetsTable).replace(entry);
  }

  Future<int> deleteWidget(String id) {
    return (delete(externalWidgetsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ExternalWidgetData>> watchAllWidgets(String personId) {
    return (select(externalWidgetsTable)..where((t) => t.personID.equals(personId))).watch();
  }

  Future<List<ExternalWidgetData>> getAllActiveWidgets(String personId) {
    return (select(externalWidgetsTable)..where((t) => t.personID.equals(personId))).get();
  }
}
