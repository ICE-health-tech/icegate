part of '../Database.dart';

@DriftAccessor(tables: [InternalWidgetsTable])
class InternalWidgetsDAO extends DatabaseAccessor<AppDatabase>
    with _$InternalWidgetsDAOMixin {
  InternalWidgetsDAO(super.db);

  Future<int> insertWidget(InternalWidgetsTableCompanion entry) {
    return into(internalWidgetsTable).insert(entry);
  }

  Future<bool> updateWidget(InternalWidgetData entry) {
    return update(internalWidgetsTable).replace(entry);
  }

  Future<int> deleteWidget(String id) {
    return (delete(internalWidgetsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<InternalWidgetData>> watchAllWidgets(String personId) {
    return (select(internalWidgetsTable)..where((t) => t.personID.equals(personId))).watch();
  }

  Future<List<InternalWidgetData>> getAllActiveWidgets(String personId) {
    return (select(internalWidgetsTable)..where((t) => t.personID.equals(personId))).get();
  }
}
