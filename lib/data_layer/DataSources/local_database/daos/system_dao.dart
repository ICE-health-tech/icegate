part of '../Database.dart';

@DriftAccessor(tables: [FocusSessionsTable])
class FocusSessionsDAO extends DatabaseAccessor<AppDatabase>
    with _$FocusSessionsDAOMixin {
  FocusSessionsDAO(super.db);

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = FocusSessionsTableCompanion(
      id: Value(r['id'] as String),
      tenantID: Value(
        r['tenant_id'] as String? ?? DEFAULT_TENANT_ID,
      ),
      personID: Value(r['person_id'] as String?),
      projectID: Value(r['project_id'] as String?),
      taskID: Value(r['task_id'] as String?),
      startTime: Value(DateTime.parse(r['start_time'] as String)),
      endTime: Value(
        r['end_time'] != null ? DateTime.parse(r['end_time'] as String) : null,
      ),
      durationSeconds: Value(r['duration_seconds'] as int? ?? 0),
      status: Value(r['status'] as String? ?? 'completed'),
      sessionType: Value(r['session_type'] as String? ?? 'Focus'),
      createdAt: Value(DateTime.parse(r['created_at'] as String)),
      updatedAt: Value(
        r['updated_at'] != null
            ? DateTime.parse(r['updated_at'] as String)
            : DateTime.now(),
      ),
    );
    await into(
      focusSessionsTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertSession(FocusSessionsTableCompanion session) async {
    await into(focusSessionsTable).insert(session);

    final Map<String, dynamic> payload = {};
    for (final col in focusSessionsTable.$columns) {
      final value = session.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    await db.pushToSupabase(table: 'focus_sessions', payload: payload);
  }

  Stream<List<FocusSessionData>> watchSessionsByPerson(String personId) {
    return (select(
      focusSessionsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }

  Stream<List<FocusSessionData>> watchAllSessions() {
    return select(focusSessionsTable).watch();
  }

  Future<void> deleteSession(String id) async {
    await (delete(focusSessionsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'focus_sessions',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> patchSession(
    String id,
    FocusSessionsTableCompanion companion,
  ) async {
    await (update(
      focusSessionsTable,
    )..where((t) => t.id.equals(id))).write(companion);

    final Map<String, dynamic> payload = {'id': id};
    for (final col in focusSessionsTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    await db.pushToSupabase(table: 'focus_sessions', payload: payload);
  }
}

@DriftAccessor(tables: [QuotesTable])
class QuoteDAO extends DatabaseAccessor<AppDatabase> with _$QuoteDAOMixin {
  QuoteDAO(super.db);

  Future<void> insertQuote(QuotesTableCompanion entry) async {
    await into(quotesTable).insert(entry);

    final Map<String, dynamic> payload = {};
    for (final col in quotesTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    await db.pushToSupabase(table: 'quotes', payload: payload);
  }

  Future<bool> updateQuote(QuoteData entry) =>
      update(quotesTable).replace(entry);

  Future<int> deleteQuote(String id) =>
      (delete(quotesTable)..where((t) => t.id.equals(id))).go();

  Future<List<QuoteData>> getAllQuotes() async {
    final rows = await customSelect('SELECT * FROM quotes').get();
    return rows
        .map((row) {
          DateTime? createdAt;
          try {
            final val = row.data['created_at'];
            if (val is String) {
              createdAt = DateTime.parse(val);
            } else if (val is int) {
              createdAt = DateTime.fromMillisecondsSinceEpoch(val);
            }
          } catch (_) {}

          return QuoteData(
            id: row.data['id'] as String,
            tenantID: row.data['tenant_id'] as String? ?? DEFAULT_TENANT_ID,
            personID: row.data['person_id'] as String? ?? '',
            content: row.data['content'] as String? ?? '',
            author: row.data['author'] as String?,
            isActive:
                (row.data['is_active'] as int?) == 1 ||
                (row.data['is_active'] as bool?) == true,
            createdAt: createdAt ?? DateTime.now(),
          );
        })
        .cast<QuoteData>()
        .toList();
  }

  Stream<List<QuoteData>> watchAllQuotes() {
    return customSelect(
      'SELECT * FROM quotes',
      readsFrom: {quotesTable},
    ).watch().map((rows) {
      return rows
          .map(
            (row) => QuoteData(
              id: row.data['id'] as String,
              tenantID: row.data['tenant_id'] as String? ?? DEFAULT_TENANT_ID,
              personID: row.data['person_id'] as String? ?? '',
              content: row.data['content'] as String? ?? '',
              author: row.data['author'] as String?,
              isActive:
                  (row.data['is_active'] as int?) == 1 ||
                  (row.data['is_active'] as bool?) == true,
              createdAt: _parseDate(row.data['created_at']),
            ),
          )
          .cast<QuoteData>()
          .toList();
    });
  }

  DateTime _parseDate(dynamic val) {
    if (val is String) {
      try {
        return DateTime.parse(val);
      } catch (_) {}
    } else if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    return DateTime.now();
  }
}

@DriftAccessor(tables: [AiPromptsTable])
class AiPromptsDAO extends DatabaseAccessor<AppDatabase>
    with _$AiPromptsDAOMixin {
  AiPromptsDAO(super.db);

  Future<AiPromptData?> getPrompt(String personID, String model) {
    return (select(aiPromptsTable)
          ..where((t) => t.personID.equals(personID) & t.aiModel.equals(model)))
        .getSingleOrNull();
  }

  Future<void> savePrompt(String personID, String model, String prompt) async {
    final existing = await getPrompt(personID, model);
    if (existing != null) {
      final companion = AiPromptsTableCompanion(
        id: Value(existing.id),
        prompt: Value(prompt),
        updatedAt: Value(DateTime.now()),
      );
      await (update(
        aiPromptsTable,
      )..where((t) => t.id.equals(existing.id))).write(companion);

      await db.pushToSupabase(
        table: 'ai_prompts',
        payload: db.companionToMap(companion, aiPromptsTable),
      );
    } else {
      final id = IDGen.UUIDV7();
      final companion = AiPromptsTableCompanion.insert(
        id: id,
        personID: Value(personID),
        aiModel: model,
        prompt: prompt,
        updatedAt: Value(DateTime.now()),
      );
      await into(aiPromptsTable).insert(companion);

      await db.pushToSupabase(
        table: 'ai_prompts',
        payload: db.companionToMap(companion, aiPromptsTable),
      );
    }
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(aiPromptsTable).insert(
      AiPromptsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String),
        aiModel: Value(record['ai_model'] as String),
        prompt: Value(record['prompt'] as String),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}

@DriftAccessor(tables: [ConfigsTable])
class ConfigsDAO extends DatabaseAccessor<AppDatabase> with _$ConfigsDAOMixin {
  ConfigsDAO(super.db);

  Future<ConfigData?> getConfig(String personID, String key) {
    return (select(configsTable)
          ..where((t) => t.personID.equals(personID) & t.configKey.equals(key)))
        .getSingleOrNull();
  }

  Future<int> setConfig(String personID, String key, String value) async {
    final existing = await getConfig(personID, key);
    if (existing != null) {
      return (update(configsTable)..where(
            (t) => t.personID.equals(personID) & t.configKey.equals(key),
          ))
          .write(
            ConfigsTableCompanion(
              configValue: Value(value),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } else {
      return into(configsTable).insert(
        ConfigsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: Value(personID),
          configKey: key,
          configValue: value,
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}
