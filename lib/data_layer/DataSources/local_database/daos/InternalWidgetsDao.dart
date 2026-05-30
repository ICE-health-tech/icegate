part of '../Database.dart';

@DriftAccessor(tables: [InternalWidgetsTable])
class InternalWidgetsDAO extends DatabaseAccessor<AppDatabase>
    with _$InternalWidgetsDAOMixin {
  InternalWidgetsDAO(super.db);

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(internalWidgetsTable).insertOnConflictUpdate(
      InternalWidgetsTableCompanion.insert(
        id: r['id'] as String,
        tenantID: Value(r['tenant_id'] as String?),
        widgetID: Value(r['widget_id'] as String?),
        personID: Value(r['person_id'] as String?),
        name: Value(r['name'] as String?),
        url: Value(r['url'] as String?),
        dateAdded: Value(r['date_added'] as String?),
        imageUrl: Value(r['image_url'] as String?),
        alias: Value(r['alias'] as String?),
        scope: Value(r['scope'] as String?),
      ),
    );
  }

  Future<InternalWidgetData?> getInternalWidgetByName(String name) {
    return (select(internalWidgetsTable)
          ..where((table) => table.name.equals(name))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<InternalWidgetData>> getInternaListWidgetByListName(
    List<String> listName,
  ) {
    return (select(
      internalWidgetsTable,
    )..where((tbl) => tbl.name.isIn(listName))).get();
  }

  Future<List<InternalWidgetData>> getScopedWidgets(
    String personID,
    String scope,
  ) {
    return (select(internalWidgetsTable)..where(
          (tbl) =>
              (tbl.personID.equals(personID) | tbl.personID.isNull()) &
              tbl.scope.equals(scope),
        ))
        .get();
  }

  Stream<List<InternalWidgetData>> watchScopedWidgets(
    String personID,
    String scope,
  ) {
    return (select(internalWidgetsTable)..where(
          (tbl) =>
              (tbl.personID.equals(personID) | tbl.personID.isNull()) &
              tbl.scope.equals(scope),
        ))
        .watch();
  }

  Stream<List<InternalWidgetData>> watchAllWidgets(String personID) {
    return (select(internalWidgetsTable)..where(
          (tbl) => tbl.personID.equals(personID) | tbl.personID.isNull(),
        ))
        .watch();
  }

  Future<void> deleteScopedWidgets(String personID, String scope) {
    return (delete(internalWidgetsTable)..where(
          (tbl) => tbl.personID.equals(personID) & tbl.scope.equals(scope),
        ))
        .go();
  }

  Future<int> insertInternalWidget({
    String? id,
    String? widgetID,
    required String personID,
    required String name,
    required String alias,
    required String url,
    String? imageUrl,
    String? scope,
  }) async {
    final idToUse = id ?? IDGen.UUIDV7();
    final widgetIdToUse = widgetID ?? IDGen.UUIDV7();
    final img = imageUrl ?? "assets/internalwidget/default_plugin.png";
    final now = DateTime.now().toIso8601String();

    final res = await into(internalWidgetsTable).insert(
      InternalWidgetsTableCompanion.insert(
        id: idToUse,
        widgetID: Value(widgetIdToUse),
        personID: Value(personID),
        name: Value(name),
        alias: Value(alias),
        url: Value(url),
        imageUrl: Value(img),
        scope: Value(scope),
        dateAdded: Value(now),
      ),
    );

    attachedDatabase.pushToSupabase(
      table: 'internal_widgets',
      payload: {
        'id': idToUse,
        'widget_id': widgetIdToUse,
        'person_id': personID,
        'name': name,
        'alias': alias,
        'url': url,
        'image_url': img,
        'scope': scope,
        'date_added': now,
      },
    );

    return res;
  }

  Future<int> deleteInternalWidget(String name) async {
    final widget = await getInternalWidgetByName(name);
    final res = await (delete(
      internalWidgetsTable,
    )..where((t) => t.name.equals(name))).go();

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'internal_widgets',
        payload: {'id': widget.id},
        isDelete: true,
      );
    }
    return res;
  }

  Future<int> deleteInternalWidgetById(String rowId) async {
    final widget = await (select(internalWidgetsTable)
          ..where((t) => t.id.equals(rowId))
          ..limit(1))
        .getSingleOrNull();
    final res = await (delete(internalWidgetsTable)
          ..where((t) => t.id.equals(rowId)))
        .go();

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'internal_widgets',
        payload: {'id': widget.id},
        isDelete: true,
      );
    }
    return res;
  }

  Future<int> renameInternalWidget(String oldName, String newName) async {
    final widget = await getInternalWidgetByName(oldName);
    final res =
        await (update(internalWidgetsTable)
              ..where((t) => t.name.equals(oldName)))
            .write(InternalWidgetsTableCompanion(name: Value(newName)));

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'internal_widgets',
        payload: {'id': widget.id, 'name': newName},
      );
    }
    return res;
  }

  Future<int> updateInternalWidgetUrl(String alias, String newUrl) async {
    final widget = await getInternalWidgetByAlias(alias);
    final res =
        await (update(internalWidgetsTable)
              ..where((t) => t.alias.equals(alias)))
            .write(InternalWidgetsTableCompanion(url: Value(newUrl)));

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'internal_widgets',
        payload: {'id': widget.id, 'url': newUrl},
      );
    }
    return res;
  }

  Future<InternalWidgetData?> getInternalWidgetByAlias(String alias) {
    return (select(internalWidgetsTable)
          ..where((table) => table.alias.equals(alias))
          ..limit(1))
        .getSingleOrNull();
  }
}
