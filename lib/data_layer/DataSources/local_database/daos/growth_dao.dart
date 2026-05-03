part of '../database.dart';

@DriftAccessor(tables: [MindLogsTable])
class MindLogsDAO extends DatabaseAccessor<AppDatabase>
    with _$MindLogsDAOMixin {
  MindLogsDAO(super.db);

  Stream<List<MindLogData>> watchLogsByPerson(String personId) {
    return (select(mindLogsTable)
          ..where((tbl) => tbl.personID.equals(personId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.logDate, mode: OrderingMode.desc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<MindLogData>> watchLogsByRange(
    String personId,
    DateTime start,
    DateTime end,
  ) {
    return (select(mindLogsTable)
          ..where(
            (tbl) =>
                tbl.personID.equals(personId) &
                tbl.logDate.isBiggerOrEqualValue(start) &
                tbl.logDate.isSmallerThanValue(end),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.logDate, mode: OrderingMode.desc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> insertLog(MindLogsTableCompanion entry) async {
    await into(mindLogsTable).insert(entry);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in mindLogsTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'mind_logs', payload: payload);
  }

  Future<void> deleteLog(String id) async {
    await (delete(mindLogsTable)..where((tbl) => tbl.id.equals(id))).go();
    // Direct delete from Supabase
    await db.pushToSupabase(
      table: 'mind_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

  /// Latest log by wall-clock time (same calendar day ties on [logDate] only).
  Stream<MindLogData?> watchLatestLog(String personId) {
    return (select(mindLogsTable)
          ..where((tbl) => tbl.personID.equals(personId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<MindLogData>> watchLogsByMood(String personId, int moodScore) {
    return (select(mindLogsTable)
          ..where(
            (tbl) =>
                tbl.personID.equals(personId) & tbl.moodScore.equals(moodScore),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.logDate, mode: OrderingMode.desc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<MindLogData>> watchAllLogs(String personId) {
    return (select(
      mindLogsTable,
    )..where((tbl) => tbl.personID.equals(personId))).watch();
  }

  Stream<List<MindLogData>> watchLogsByDay(String personId, DateTime date) {
    // Match [MindBlock.addMindLog]: logDate is local calendar midnight for that day.
    // Using DateTime.utc(y,m,d) here broke non-UTC zones (day bucket vs query range).
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(mindLogsTable)
          ..where(
            (tbl) =>
                tbl.personID.equals(personId) &
                tbl.logDate.isBetweenValues(startOfDay, endOfDay),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = MindLogsTableCompanion(
      id: Value(r['id'] as String),
      tenantID: Value(r['tenant_id'] as String?),
      personID: Value(r['person_id'] as String?),
      moodScore: Value(r['mood_score'] as int),
      moodEmoji: Value(r['mood_emoji'] as String?),
      activities: Value(
        r['activities'] is String
            ? r['activities'] as String
            : jsonEncode(r['activities']),
      ),
      note: Value(r['note'] as String?),
      logDate: Value(DateTime.parse(r['log_date'] as String)),
      createdAt: Value(DateTime.parse(r['created_at'] as String)),
    );
    await into(
      mindLogsTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }
}

@DriftAccessor(tables: [JournalActivityOptionsTable])
class JournalActivityOptionsDAO extends DatabaseAccessor<AppDatabase>
    with _$JournalActivityOptionsDAOMixin {
  JournalActivityOptionsDAO(super.db);

  Stream<List<JournalActivityOptionData>> watchForPerson(String personId) {
    return (select(journalActivityOptionsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.label, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<JournalActivityOptionData?> getById(String id) {
    return (select(journalActivityOptionsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// For resolving `act_user_ref:` tokens in UI.
  Future<Map<String, String>> labelMapForPerson(String personId) async {
    final rows = await (select(journalActivityOptionsTable)
          ..where((t) => t.personID.equals(personId)))
        .get();
    return Map<String, String>.fromEntries(
      rows.map((r) => MapEntry(r.id, r.label)),
    );
  }

  /// Inserts locally and pushes to Supabase. [id] must be pre-generated (e.g. UUID v7).
  Future<void> insertOption({
    required String id,
    required String personId,
    required String? tenantId,
    required String categoryKey,
    required String label,
  }) async {
    final now = DateTime.now().toUtc();
    final companion = JournalActivityOptionsTableCompanion.insert(
      id: id,
      tenantID: tenantId != null && tenantId.isNotEmpty
          ? Value(tenantId)
          : const Value.absent(),
      personID: Value(personId),
      categoryKey: categoryKey,
      label: label,
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await into(journalActivityOptionsTable).insert(companion);

    final Map<String, dynamic> payload = {};
    for (final col in journalActivityOptionsTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }
    await db.pushToSupabase(
      table: 'journal_activity_options',
      payload: payload,
    );
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = JournalActivityOptionsTableCompanion(
      id: Value(r['id'] as String),
      tenantID: Value(r['tenant_id'] as String?),
      personID: Value(r['person_id'] as String?),
      categoryKey: Value(r['category_key'] as String),
      label: Value(r['label'] as String),
      createdAt: Value(DateTime.parse(r['created_at'] as String)),
      updatedAt: Value(DateTime.parse(r['updated_at'] as String)),
    );
    await into(journalActivityOptionsTable).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
  }
}

@DriftAccessor(tables: [AchievementsTable])
class AchievementsDAO extends DatabaseAccessor<AppDatabase>
    with _$AchievementsDAOMixin {
  AchievementsDAO(super.db);

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(achievementsTable).insertOnConflictUpdate(
      AchievementsTableCompanion.insert(
        id: (r['id'] as String?) ?? '',
        tenantID: Value((r['tenant_id'] as String?) ?? DEFAULT_TENANT_ID),
        personID: Value(r['person_id'] as String?),
        title: (r['title'] as String?) ?? 'Untitled Achievement',
        description: Value(r['description'] as String?),
        domain: Value((r['domain'] as String?) ?? 'project'),
        meaningScore: Value(r['meaning_score'] as int?),
        impactScore: (r['impact_score'] as int?) ?? 0,
        moodPre: Value(r['mood_pre'] as String?),
        moodPost: Value(r['mood_post'] as String?),
        impactDescWho: (r['impact_desc_who'] as String?) ?? '',
        impactDescHow: (r['impact_desc_how'] as String?) ?? '',
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'] as String)
              : DateTime.now(),
        ),
      ),
    );
  }

  Future<int> insertAchievement(AchievementsTableCompanion entry) async {
    final res = await into(achievementsTable).insert(entry);

    // Sync to Supabase
    final payload = <String, dynamic>{};
    for (final col in achievementsTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }
    await db.pushToSupabase(table: 'achievements', payload: payload);

    return res;
  }

  Future<bool> updateAchievement(AchievementData entry) async {
    final res = await update(achievementsTable).replace(entry);

    // Sync to Supabase
    final payload = <String, dynamic>{};
    payload['id'] = entry.id;
    payload['tenant_id'] = entry.tenantID;
    payload['person_id'] = entry.personID;
    payload['title'] = entry.title;
    payload['description'] = entry.description;
    payload['domain'] = entry.domain;
    payload['meaning_score'] = entry.meaningScore;
    payload['impact_score'] = entry.impactScore;
    payload['mood_pre'] = entry.moodPre;
    payload['mood_post'] = entry.moodPost;
    payload['impact_desc_who'] = entry.impactDescWho;
    payload['impact_desc_how'] = entry.impactDescHow;
    payload['created_at'] = entry.createdAt.toIso8601String();

    await db.pushToSupabase(table: 'achievements', payload: payload);

    return res;
  }

  Stream<List<AchievementData>> watchAchievementsByPerson(String personId) {
    return (select(achievementsTable)..where((t) => t.personID.equals(personId)))
        .watch();
  }

  Future<void> deleteAchievement(String id) async {
    await (delete(achievementsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'achievements',
      payload: {'id': id},
      isDelete: true,
    );
  }

  /// Deletes all achievements for a given person from local DB.
  /// Also syncs each deletion to Supabase to keep cloud data consistent.
  Future<void> deleteAllAchievementsForPerson(String personId) async {
    // 1. Get all local achievements for this person first to sync deletion
    final localAchievements = await (select(
      achievementsTable,
    )..where((t) => t.personID.equals(personId))).get();

    // 2. Delete locally
    await (delete(
      achievementsTable,
    )..where((t) => t.personID.equals(personId))).go();

    // 3. Sync deletions to Supabase
    for (final achievement in localAchievements) {
      await db.pushToSupabase(
        table: 'achievements',
        payload: {'id': achievement.id},
        isDelete: true,
      );
    }
  }
}

@DriftAccessor(tables: [GoalsTable, HabitsTable, SkillsTable])
class GrowthDAO extends DatabaseAccessor<AppDatabase> with _$GrowthDAOMixin {
  GrowthDAO(super.db);

  Future<String> createGoal(GoalsTableCompanion goal) async {
    // 1. Generate your unique ID
    final String goalId = IDGen.UUIDV7();

    // 2. Create a new version of the goal including the generated ID
    final goalToInsert = goal.copyWith(
      id: Value(goalId), // Assuming your PK is named 'id' in the table
      // If your column is named goalID in the table, use that instead
    );

    // 3. Insert the new object
    await into(goalsTable).insert(goalToInsert);

    return goalId;
  }

  Stream<List<GoalData>> watchGoals(String personId) {
    return customSelect(
      'SELECT * FROM goals WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {goalsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => GoalData(
              id: row.data['id'] as String,
              goalID: row.data['goal_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
              title: (row.data['title'] as String?) ?? 'Untitled Task',
              description: row.data['description'] as String?,
              category: (row.data['category'] as String?) ?? 'personal',
              priority: (row.data['priority'] as int?) ?? 3,
              status: (row.data['status'] as String?) ?? 'active',
              targetDate: row.data['target_date'] != null
                  ? DateTime.tryParse(row.data['target_date'].toString())
                  : null,
              completionDate: row.data['completion_date'] != null
                  ? DateTime.tryParse(row.data['completion_date'].toString())
                  : null,
              progressPercentage:
                  (row.data['progress_percentage'] as int?) ?? 0,

              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              projectID: row.data['project_id'] as String?,
            ),
          )
          .toList();
    });
  }

  Stream<List<GoalData>> watchGoalsByProject(String projectID) {
    return customSelect(
      'SELECT * FROM goals WHERE project_id = ?',
      variables: [Variable.withString(projectID)],
      readsFrom: {goalsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => GoalData(
              id: row.data['id'] as String,
              goalID: row.data['goal_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? '',
              title: (row.data['title'] as String?) ?? 'Untitled Task',
              description: row.data['description'] as String?,
              category: (row.data['category'] as String?) ?? 'personal',
              priority: (row.data['priority'] as int?) ?? 3,
              status: (row.data['status'] as String?) ?? 'active',
              targetDate: row.data['target_date'] != null
                  ? DateTime.tryParse(row.data['target_date'].toString())
                  : null,
              completionDate: row.data['completion_date'] != null
                  ? DateTime.tryParse(row.data['completion_date'].toString())
                  : null,
              progressPercentage:
                  (row.data['progress_percentage'] as int?) ?? 0,
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              projectID: row.data['project_id'] as String?,
            ),
          )
          .toList();
    });
  }

  Future<void> updateGoalStatusByUuid(String id, String status) async {
    await (update(goalsTable)..where((t) => t.id.equals(id))).write(
      GoalsTableCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        completionDate: status == 'done'
            ? Value(DateTime.now())
            : const Value.absent(),
        progressPercentage: status == 'done'
            ? const Value(100)
            : const Value.absent(),
      ),
    );
  }

  Future<void> updateGoalStatusByIntId(String goalID, String status) async {
    await (update(goalsTable)..where((t) => t.goalID.equals(goalID))).write(
      GoalsTableCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        completionDate: status == 'done'
            ? Value(DateTime.now())
            : const Value.absent(),
        progressPercentage: status == 'done'
            ? const Value(100)
            : const Value.absent(),
      ),
    );
  }

  // Habits
  Future<void> createHabit(HabitsTableCompanion habit) async {
    await into(habitsTable).insert(habit);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in habitsTable.$columns) {
      final value = habit.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'habits', payload: payload);
  }

  Stream<List<HabitData>> watchHabits(String personId) {
    return customSelect(
      'SELECT * FROM habits WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {habitsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => HabitData(
              id: row.data['id'] as String,
              habitID: row.data['habit_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
              goalID: row.data['goal_id'] as String?,
              habitName: (row.data['habit_name'] as String?) ?? 'Untitled',
              description: row.data['description'] as String?,
              frequency: (row.data['frequency'] as String?) ?? 'daily',
              frequencyDetails: row.data['frequency_details'] as String?,
              targetCount: (row.data['target_count'] as int?) ?? 1,
              isActive:
                  (row.data['is_active'] == 1 || row.data['is_active'] == true),
              startedDate: row.data['started_date'] != null
                  ? DateTime.tryParse(row.data['started_date'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }

  // Skills
  Future<int> createSkill(SkillsTableCompanion skill) =>
      into(skillsTable).insert(skill);
  Stream<List<SkillData>> watchSkills(String personId) {
    return customSelect(
      'SELECT * FROM skills WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {skillsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => SkillData(
              id: row.data['id'] as String,
              skillID: row.data['skill_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
              skillName: (row.data['skill_name'] as String?) ?? 'Untitled',
              skillCategory: row.data['skill_category'] as String?,
              proficiencyLevel: SkillLevel.values.firstWhere(
                (e) => e.name == row.data['proficiency_level'],
                orElse: () => SkillLevel.beginner,
              ),
              yearsOfExperience: (row.data['years_of_experience'] as int?) ?? 0,
              description: row.data['description'] as String?,
              isFeatured:
                  (row.data['is_featured'] == 1 ||
                  row.data['is_featured'] == true),
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }
}
