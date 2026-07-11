part of '../Database.dart';

@DriftAccessor(tables: [DevQuickTabsTable])
class DevQuickTabsDAO extends DatabaseAccessor<AppDatabase>
    with _$DevQuickTabsDAOMixin {
  DevQuickTabsDAO(super.db);

  Future<List<DevQuickTabData>> listForPerson(String personId) {
    return (select(devQuickTabsTable)
          ..where((t) => t.personId.equals(personId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<DevQuickTabData?> readForPerson(String personId, String id) {
    return (select(devQuickTabsTable)
          ..where((t) => t.personId.equals(personId) & t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<DevQuickTabData> insertTab(DevQuickTabsTableCompanion companion) async {
    await into(devQuickTabsTable).insert(companion);
    final id = companion.id.value;
    final row = await (select(devQuickTabsTable)..where((t) => t.id.equals(id)))
        .getSingle();
    await db.pushToSupabase(
      table: 'dev_quick_tabs',
      payload: _payloadFromRow(row),
    );
    return row;
  }

  Future<DevQuickTabData?> updateTab(DevQuickTabData row) async {
    final ok = await update(devQuickTabsTable).replace(row);
    if (!ok) return null;
    await db.pushToSupabase(
      table: 'dev_quick_tabs',
      payload: _payloadFromRow(row),
    );
    return row;
  }

  Future<bool> deleteTab(String personId, String id) async {
    final deleted = await (delete(devQuickTabsTable)
          ..where((t) => t.personId.equals(personId) & t.id.equals(id)))
        .go();
    if (deleted == 0) return false;
    await db.pushToSupabase(
      table: 'dev_quick_tabs',
      payload: {'id': id},
      isDelete: true,
    );
    return true;
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(devQuickTabsTable).insert(
      DevQuickTabsTableCompanion(
        id: Value(record['id'] as String),
        personId: Value(record['person_id'] as String),
        title: Value(record['title'] as String? ?? ''),
        fullUrl: Value(record['full_url'] as String? ?? ''),
        remoteUrl: Value(record['remote_url'] as String? ?? ''),
        sortOrder: Value(record['sort_order'] is int ? record['sort_order'] as int : 0),
        isPinned: Value(record['is_pinned'] as bool? ?? false),
        username: Value(record['username'] as String? ?? ''),
        password: Value(record['password'] as String? ?? ''),
        passkey: Value(record['passkey'] as String? ?? ''),
        loginType: Value(record['login_type'] as String? ?? 'html_form'),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  static Map<String, dynamic> _payloadFromRow(DevQuickTabData row) {
    return {
      'id': row.id,
      'person_id': row.personId,
      'title': row.title,
      'full_url': row.fullUrl,
      'remote_url': row.remoteUrl,
      'sort_order': row.sortOrder,
      'is_pinned': row.isPinned,
      'username': row.username,
      'password': row.password,
      'passkey': row.passkey,
      'login_type': row.loginType,
      'created_at': row.createdAt.toUtc().toIso8601String(),
      'updated_at': row.updatedAt.toUtc().toIso8601String(),
    };
  }
}
