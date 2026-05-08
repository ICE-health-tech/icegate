part of '../Database.dart';

/// DAO for managing external widgets (plugins) in the local database.
/// Handles CRUD operations and Supabase sync for the ExternalWidgetsTable.
@DriftAccessor(tables: [ExternalWidgetsTable])
class ExternalWidgetsDAO extends DatabaseAccessor<AppDatabase>
    with _$ExternalWidgetsDAOMixin {
  ExternalWidgetsDAO(super.db);

  /// Upserts a single record from Supabase into the local ExternalWidgetsTable.
  /// Used during sync-down to merge remote changes into the local DB.
  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(externalWidgetsTable).insertOnConflictUpdate(
      ExternalWidgetsTableCompanion.insert(
        id: r['id'] as String,
        tenantID: Value(r['tenant_id'] as String?),
        widgetID: Value(r['widget_id'] as String?),
        personID: Value(r['person_id'] as String?),
        name: Value(r['name'] as String?),
        alias: Value(r['alias'] as String?),
        protocol: Value(r['protocol'] as String?),
        host: Value(r['host'] as String?),
        url: Value(r['url'] as String?),
        imageUrl: Value(r['image_url'] as String?),
        dateAdded: Value(r['date_added'] as String?),
      ),
    );
  }

  /// Generates a random alphanumeric alias string of the given length.
  /// Used to create unique short identifiers for widgets.
  String _generateRandomAlias(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Creates a new widget entry from an ExternalWidgetProtocol definition.
  /// Generates unique IDs/alias, inserts locally, then pushes to Supabase.
  Future<int> insertNewWidget({
    required ExternalWidgetProtocol externalWidgetProtocol,
    required String personID,
  }) async {
    final id = IDGen.UUIDV7();
    final widgetID = IDGen.UUIDV7();
    final alias = _generateRandomAlias(8);
    final now = DateTime.now().toIso8601String();

    // Build the companion object with all fields populated
    final entry = ExternalWidgetsTableCompanion.insert(
      id: id,
      personID: Value(personID),
      name: Value(
        externalWidgetProtocol.name.isEmpty
            ? 'Unnamed Widget'
            : externalWidgetProtocol.name,
      ),
      alias: Value(alias),
      widgetID: Value(widgetID),
      host: Value(externalWidgetProtocol.host),
      protocol: Value(externalWidgetProtocol.protocol),
      dateAdded: Value(now),
      url: Value(externalWidgetProtocol.url),
      imageUrl: Value(externalWidgetProtocol.imageUrl),
    );

    // Insert into local database
    final res = await into(attachedDatabase.externalWidgetsTable).insert(entry);

    // Push to Supabase for cloud sync
    attachedDatabase.pushToSupabase(
      table: 'external_widgets',
      payload: {
        'id': id,
        'person_id': personID,
        'widget_id': widgetID,
        'name': externalWidgetProtocol.name.isEmpty
            ? 'Unnamed Widget'
            : externalWidgetProtocol.name,
        'alias': alias,
        'host': externalWidgetProtocol.host,
        'protocol': externalWidgetProtocol.protocol,
        'url': externalWidgetProtocol.url,
        'image_url': externalWidgetProtocol.imageUrl,
        'date_added': now,
      },
    );

    return res;
  }

  /// Deletes a widget by ID from local DB and syncs the deletion to Supabase.
  Future<int> deleteWidget(String id) async {
    final res = await (delete(
      attachedDatabase.externalWidgetsTable,
    )..where((tbl) => tbl.id.equals(id))).go();

    // Sync deletion to Supabase
    attachedDatabase.pushToSupabase(
      table: 'external_widgets',
      payload: {'id': id},
      isDelete: true,
    );

    return res;
  }

  /// Renames an external widget by its widgetID. Updates locally then syncs.
  Future<int> renameExternalWidget(String widgetID, String newName) async {
    // Look up the widget to get its primary ID for Supabase sync
    final widgetQuery = select(externalWidgetsTable)
      ..where((tbl) => tbl.widgetID.equals(widgetID));
    final widget = await widgetQuery.getSingleOrNull();

    final res =
        await (update(externalWidgetsTable)
              ..where((tbl) => tbl.widgetID.equals(widgetID)))
            .write(ExternalWidgetsTableCompanion(name: Value(newName)));

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'external_widgets',
        payload: {'id': widget.id, 'name': newName},
      );
    }

    return res;
  }

  /// Watches all widgets for a given person, including those with null personID.
  /// Uses customSelect to handle the OR NULL condition.
  Stream<List<ExternalWidgetData>> watchAllWidgets(String personID) {
    return customSelect(
      'SELECT * FROM external_widgets WHERE person_id = ? OR person_id IS NULL',
      variables: [Variable.withString(personID)],
      readsFrom: {externalWidgetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => ExternalWidgetData(
              id: row.data['id']?.toString() ?? '',
              tenantID: row.data['tenant_id']?.toString(),
              personID: row.data['person_id']?.toString(),
              widgetID: row.data['widget_id']?.toString(),
              name: row.data['name']?.toString(),
              alias: row.data['alias']?.toString(),
              protocol: row.data['protocol']?.toString(),
              host: row.data['host']?.toString(),
              url: row.data['url']?.toString(),
              imageUrl: row.data['image_url']?.toString(),
              dateAdded: row.data['date_added']?.toString(),
            ),
          )
          .toList();
    });
  }

  /// Returns all active widgets for a person (one-shot query, not reactive).
  Future<List<ExternalWidgetData>> getAllActiveWidgets(String personId) {
    return (select(externalWidgetsTable)
          ..where((t) => t.personID.equals(personId)))
        .get();
  }
}
