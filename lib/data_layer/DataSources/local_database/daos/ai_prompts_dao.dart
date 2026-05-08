part of '../Database.dart';

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

      await attachedDatabase.pushToSupabase(
        table: 'ai_prompts',
        payload: attachedDatabase.companionToMap(companion, aiPromptsTable),
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

      await attachedDatabase.pushToSupabase(
        table: 'ai_prompts',
        payload: attachedDatabase.companionToMap(companion, aiPromptsTable),
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
