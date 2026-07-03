part of '../Database.dart';

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

    // PostgREST: jsonb expects decoded JSON; date column expects YYYY-MM-DD.
    final activities = payload['activities'];
    if (activities is String && activities.isNotEmpty) {
      try {
        payload['activities'] = jsonDecode(activities);
      } catch (_) {}
    }
    final logDate = payload['log_date'];
    if (logDate is DateTime) {
      final d = logDate.toLocal();
      payload['log_date'] =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (payload['mood_emoji'] == null && payload['mood_score'] is int) {
      payload['mood_emoji'] = _mindLogEmoji(payload['mood_score'] as int);
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'mind_logs', payload: payload);
  }

  static String _mindLogEmoji(int score) {
    switch (score) {
      case 1:
        return '😫';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '🤩';
      default:
        return '😐';
    }
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
        projectID: Value(r['project_id'] as String?),
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
    payload['project_id'] = entry.projectID;
    payload['created_at'] = entry.createdAt.toIso8601String();

    await db.pushToSupabase(table: 'achievements', payload: payload);

    return res;
  }

  Stream<List<AchievementData>> watchAchievementsByPerson(String personId) {
    return (select(achievementsTable)..where((t) => t.personID.equals(personId)))
        .watch();
  }

  Future<List<AchievementData>> getAchievementsByPerson(String personId) {
    return (select(achievementsTable)..where((t) => t.personID.equals(personId)))
        .get();
  }

  Future<AchievementData?> getAchievementById(String id) {
    return (select(achievementsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Local-only upsert for photo stories pulled from `achievement_story_sync`.
  Future<void> upsertPhotoStoryLocal({
    required String id,
    required String personId,
    required String title,
    required String localImagePath,
    required DateTime createdAt,
    String? projectId,
  }) async {
    await into(achievementsTable).insertOnConflictUpdate(
      AchievementsTableCompanion(
        id: Value(id),
        personID: Value(personId),
        title: Value(title),
        localImagePath: Value(localImagePath),
        projectID: projectId != null ? Value(projectId) : const Value.absent(),
        domain: const Value('project'),
        meaningScore: const Value(6),
        impactScore: const Value(5),
        impactDescWho: const Value('You'),
        impactDescHow: const Value(''),
        createdAt: Value(createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
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

  /// Supabase `goals.project_id` FK references `projects.id` (PK), not `projects.project_id`.
  Future<String?> _resolveCloudProjectId(String? projectRef) async {
    if (projectRef == null || projectRef.isEmpty) return null;

    final byPk = await db
        .customSelect(
          'SELECT id FROM projects WHERE id = ? LIMIT 1',
          variables: [Variable.withString(projectRef)],
          readsFrom: {db.projectsTable},
        )
        .getSingleOrNull();
    if (byPk != null) return byPk.read<String>('id');

    final byLegacy = await db
        .customSelect(
          'SELECT id FROM projects WHERE project_id = ? LIMIT 1',
          variables: [Variable.withString(projectRef)],
          readsFrom: {db.projectsTable},
        )
        .getSingleOrNull();
    return byLegacy?.read<String>('id');
  }

  Future<String> createGoal(GoalsTableCompanion goal) async {
    final String goalId = IDGen.UUIDV7();
    String? normalizedProjectId;
    if (goal.projectID.present && goal.projectID.value != null) {
      normalizedProjectId =
          await _resolveCloudProjectId(goal.projectID.value);
    }

    final goalToInsert = goal.copyWith(
      id: Value(goalId),
      goalID: goal.goalID.present ? goal.goalID : Value(goalId),
      projectID: normalizedProjectId != null
          ? Value(normalizedProjectId)
          : goal.projectID,
    );

    await into(goalsTable).insert(goalToInsert);
    await _pushGoalById(goalId);

    return goalId;
  }

  Future<void> upsertFromSupabaseGoal(Map<String, dynamic> r) async {
    await into(goalsTable).insert(
      GoalsTableCompanion(
        id: Value(r['id'] as String),
        tenantID: Value(r['tenant_id'] as String?),
        goalID: Value(r['goal_id'] as String?),
        personID: Value(r['person_id'] as String?),
        title: Value(r['title'] as String? ?? 'Untitled Task'),
        description: Value(r['description'] as String?),
        category: Value(r['category'] as String? ?? 'personal'),
        priority: Value((r['priority'] as num?)?.toInt() ?? 3),
        status: Value(r['status'] as String? ?? 'active'),
        targetDate: r['target_date'] != null
            ? Value(DateTime.parse(r['target_date'].toString()))
            : const Value.absent(),
        completionDate: r['completion_date'] != null
            ? Value(DateTime.parse(r['completion_date'].toString()))
            : const Value.absent(),
        progressPercentage:
            Value((r['progress_percentage'] as num?)?.toInt() ?? 0),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'].toString())
              : DateTime.now(),
        ),
        updatedAt: Value(
          r['updated_at'] != null
              ? DateTime.parse(r['updated_at'].toString())
              : DateTime.now(),
        ),
        projectID: Value(r['project_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> syncGoalsFromCloud(String personId) async {
    await db.syncTableDown('goals', personId);
  }

  /// Pushes every local goal for [personId] (repairs tasks created before cloud push existed).
  Future<void> pushAllGoalsToCloud(String personId) async {
    final rows = await customSelect(
      'SELECT id FROM goals WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {goalsTable},
    ).get();
    for (final row in rows) {
      final id = row.read<String>('id');
      await _pushGoalById(id);
    }
  }

  Future<void> _pushGoalById(String id) async {
    final row = await (select(goalsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    final cloudProjectId = await _resolveCloudProjectId(row.projectID);
    if (cloudProjectId != row.projectID && cloudProjectId != null) {
      await (update(goalsTable)..where((t) => t.id.equals(id))).write(
        GoalsTableCompanion(projectID: Value(cloudProjectId)),
      );
    }

    final latest = await (select(goalsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (latest == null) return;

    await db.pushToSupabase(
      table: 'goals',
      payload: {
        'id': latest.id,
        'tenant_id': latest.tenantID,
        'goal_id': latest.goalID ?? latest.id,
        'person_id': latest.personID,
        'title': latest.title,
        'description': latest.description,
        'category': latest.category,
        'priority': latest.priority,
        'status': latest.status,
        'target_date': latest.targetDate?.toUtc().toIso8601String(),
        'completion_date': latest.completionDate?.toUtc().toIso8601String(),
        'progress_percentage': latest.progressPercentage,
        'created_at': latest.createdAt.toUtc().toIso8601String(),
        'updated_at': latest.updatedAt.toUtc().toIso8601String(),
        'project_id': cloudProjectId,
      },
    );
  }

  List<GoalData> _mapGoalSelectRows(List<QueryRow> rows, {String? personId}) {
    return rows
        .where((row) => row.data['id'] != null)
        .map(
          (row) => GoalData(
            id: row.data['id'] as String,
            goalID: row.data['goal_id'] as String?,
            personID: (row.data['person_id'] as String?) ?? personId ?? '',
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
            progressPercentage: (row.data['progress_percentage'] as int?) ?? 0,
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
  }

  Stream<List<GoalData>> watchGoals(String personId) {
    return customSelect(
      'SELECT * FROM goals WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {goalsTable},
    ).watch().map((rows) => _mapGoalSelectRows(rows, personId: personId));
  }

  /// SDLC board: only goals tagged `sdlc:*` for one project.
  Stream<List<GoalData>> watchSdlcGoalsForProject(String projectID) {
    return customSelect(
      "SELECT * FROM goals WHERE project_id = ? AND category LIKE 'sdlc:%'",
      variables: [Variable.withString(projectID)],
      readsFrom: {goalsTable},
    ).watch().map((rows) => _mapGoalSelectRows(rows));
  }

  Stream<List<GoalData>> watchGoalsByProject(String projectID) {
    return customSelect(
      'SELECT * FROM goals WHERE project_id = ?',
      variables: [Variable.withString(projectID)],
      readsFrom: {goalsTable},
    ).watch().map((rows) => _mapGoalSelectRows(rows));
  }

  Future<void> deleteGoalByUuid(String id) async {
    await (delete(goalsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'goals',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> updateGoalStatusByUuid(String id, String status) async {
    await (update(goalsTable)..where((t) => t.id.equals(id))).write(
      GoalsTableCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now().toUtc()),
        completionDate: status == 'done'
            ? Value(DateTime.now().toUtc())
            : const Value.absent(),
        progressPercentage: status == 'done'
            ? const Value(100)
            : const Value.absent(),
      ),
    );
    await _pushGoalById(id);
  }

  Future<void> updateGoalCategoryByUuid(String id, String category) async {
    await (update(goalsTable)..where((t) => t.id.equals(id))).write(
      GoalsTableCompanion(
        category: Value(category),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pushGoalById(id);
  }

  Future<void> updateGoalDetailsByUuid(
    String id, {
    required String title,
    required String description,
  }) async {
    await (update(goalsTable)..where((t) => t.id.equals(id))).write(
      GoalsTableCompanion(
        title: Value(title),
        description: Value(description),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pushGoalById(id);
  }

  Future<void> updateGoalProjectIdByUuid(String id, String? projectRef) async {
    String? normalized;
    if (projectRef != null && projectRef.isNotEmpty) {
      normalized = await _resolveCloudProjectId(projectRef);
    }
    await (update(goalsTable)..where((t) => t.id.equals(id))).write(
      GoalsTableCompanion(
        projectID: projectRef == null || projectRef.isEmpty
            ? const Value(null)
            : Value(normalized ?? projectRef),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pushGoalById(id);
  }

  Future<void> updateGoalTargetDateByUuid(String id, DateTime? targetDate) async {
    await (update(goalsTable)..where((t) => t.id.equals(id))).write(
      GoalsTableCompanion(
        targetDate: targetDate == null
            ? const Value(null)
            : Value(targetDate.toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pushGoalById(id);
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
  static String projectSkillCategory(String projectId) => 'project:$projectId';

  static SkillLevel skillLevelForPracticePoints(int xp) {
    if (xp >= 500) return SkillLevel.expert;
    if (xp >= 250) return SkillLevel.advanced;
    if (xp >= 100) return SkillLevel.intermediate;
    return SkillLevel.beginner;
  }

  Future<int> createSkill(SkillsTableCompanion skill) async {
    final inserted = await into(skillsTable).insert(skill);
    final id = skill.id.present ? skill.id.value : null;
    if (id != null && id.isNotEmpty) {
      await _pushSkillById(id);
    }
    return inserted;
  }

  Future<void> deleteSkillByUuid(String id) async {
    await (delete(skillsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'skills',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> updateSkillName(String id, String skillName) async {
    final trimmed = skillName.trim();
    if (trimmed.isEmpty) return;
    await (update(skillsTable)..where((t) => t.id.equals(id))).write(
      SkillsTableCompanion(
        skillName: Value(trimmed),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pushSkillById(id);
  }

  Future<void> updateSkillCertificateDetails({
    required String id,
    String? description,
    DateTime? createdAt,
  }) async {
    await (update(skillsTable)..where((t) => t.id.equals(id))).write(
      SkillsTableCompanion(
        description: description != null
            ? Value(
                description.trim().isEmpty ? null : description.trim(),
              )
            : const Value.absent(),
        createdAt: createdAt != null
            ? Value(createdAt.toUtc())
            : const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pushSkillById(id);
  }

  Future<void> addSkillPracticePoints(String id, int delta) async {
    if (delta <= 0) return;
    final row = await (select(skillsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    final newXp = row.point + delta;
    await (update(skillsTable)..where((t) => t.id.equals(id))).write(
      SkillsTableCompanion(
        point: Value(newXp),
        proficiencyLevel: Value(skillLevelForPracticePoints(newXp)),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pushSkillById(id);
  }

  Future<void> upsertFromSupabaseSkill(Map<String, dynamic> r) async {
    final featured = r['is_featured'];
    final isFeatured = featured == true ||
        featured == 1 ||
        featured == 'true' ||
        featured == 't';
    await into(skillsTable).insert(
      SkillsTableCompanion(
        id: Value(r['id'] as String),
        tenantID: Value(r['tenant_id'] as String?),
        skillID: Value(r['skill_id'] as String?),
        personID: Value(r['person_id'] as String?),
        skillName: Value(r['skill_name'] as String? ?? 'Untitled'),
        skillCategory: Value(r['skill_category'] as String?),
        proficiencyLevel: Value(
          SkillLevel.values.firstWhere(
            (e) => e.name == (r['proficiency_level'] as String?),
            orElse: () => SkillLevel.beginner,
          ),
        ),
        point: Value((r['point'] as num?)?.toInt() ?? 0),
        achievedPoints: Value((r['achieved_points'] as num?)?.toInt() ?? 0),
        eventID: Value(r['event_id'] as String?),
        description: Value(r['description'] as String?),
        isFeatured: Value(isFeatured),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'].toString())
              : DateTime.now(),
        ),
        updatedAt: Value(
          r['updated_at'] != null
              ? DateTime.parse(r['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> syncSkillsFromCloud(String personId) async {
    await db.syncTableDown('skills', personId);
  }

  Future<void> pushAllSkillsToCloud(String personId) async {
    await _dedupeLocalSkills(personId);
    final rows = await customSelect(
      'SELECT id FROM skills WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {skillsTable},
    ).get();
    for (final row in rows) {
      await _pushSkillById(row.read<String>('id'));
    }
  }

  String _skillBusinessKey(String name, String? category) =>
      '${name.trim().toLowerCase()}|${category ?? ''}';

  /// Collapse duplicate local rows before cloud push (same person + name + category).
  Future<void> _dedupeLocalSkills(String personId) async {
    final rows = await (select(skillsTable)
          ..where((t) => t.personID.equals(personId)))
        .get();
    final groups = <String, List<SkillData>>{};
    for (final row in rows) {
      final key = _skillBusinessKey(row.skillName, row.skillCategory);
      groups.putIfAbsent(key, () => []).add(row);
    }
    for (final group in groups.values) {
      if (group.length <= 1) continue;
      group.sort((a, b) {
        final byPoints = b.point.compareTo(a.point);
        if (byPoints != 0) return byPoints;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      final keep = group.first;
      var mergedPoints = keep.point;
      var mergedAchieved = keep.achievedPoints;
      for (final dup in group.skip(1)) {
        mergedPoints += dup.point;
        mergedAchieved += dup.achievedPoints;
        await (delete(skillsTable)..where((t) => t.id.equals(dup.id))).go();
      }
      if (mergedPoints != keep.point || mergedAchieved != keep.achievedPoints) {
        await (update(skillsTable)..where((t) => t.id.equals(keep.id))).write(
          SkillsTableCompanion(
            point: Value(mergedPoints),
            achievedPoints: Value(mergedAchieved),
            proficiencyLevel: Value(
              skillLevelForPracticePoints(mergedPoints),
            ),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
    }
  }

  Future<String?> _findRemoteSkillId(
    String personId,
    String skillName,
    String? skillCategory,
  ) async {
    try {
      final targetKey = _skillBusinessKey(skillName, skillCategory);
      final rows = await Supabase.instance.client
          .from('skills')
          .select('id, skill_name, skill_category')
          .eq('person_id', personId);
      for (final remote in rows) {
        final name = (remote['skill_name'] as String?) ?? '';
        final category = remote['skill_category'] as String?;
        if (_skillBusinessKey(name, category) == targetKey) {
          return remote['id'] as String?;
        }
      }
    } catch (e) {
      debugPrint('GrowthDao: remote skill lookup skipped: $e');
    }
    return null;
  }

  Future<void> _pushSkillById(String id) async {
    final row = await (select(skillsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    final personId = row.personID;
    if (personId == null || personId.isEmpty) return;

    var targetId = row.id;
    final remoteId = await _findRemoteSkillId(
      personId,
      row.skillName,
      row.skillCategory,
    );
    final localDuplicateOfRemote =
        remoteId != null && remoteId != row.id;

    if (localDuplicateOfRemote) {
      targetId = remoteId;
    }

    final payload = {
      'id': targetId,
      'tenant_id': row.tenantID,
      'skill_id': row.skillID ?? targetId,
      'person_id': personId,
      'skill_name': row.skillName.trim(),
      'skill_category': row.skillCategory,
      'proficiency_level': row.proficiencyLevel.name,
      'point': row.point,
      'achieved_points': row.achievedPoints,
      if (row.eventID != null) 'event_id': row.eventID,
      'description': row.description,
      'is_featured': row.isFeatured,
      'created_at': row.createdAt.toUtc().toIso8601String(),
      'updated_at': row.updatedAt.toUtc().toIso8601String(),
    };

    await db.pushToSupabase(table: 'skills', payload: payload);

    if (localDuplicateOfRemote) {
      await (delete(skillsTable)..where((t) => t.id.equals(row.id))).go();
      await upsertFromSupabaseSkill(payload);
    }
  }

  Stream<List<SkillData>> watchProjectSkills(
    String personId,
    String projectId,
  ) {
    final tag = projectSkillCategory(projectId);
    return customSelect(
      'SELECT * FROM skills WHERE person_id = ? AND skill_category = ? ORDER BY updated_at DESC',
      variables: [Variable.withString(personId), Variable.withString(tag)],
      readsFrom: {skillsTable},
    ).watch().map((rows) => _mapSkillRows(rows, personId));
  }

  Stream<List<SkillData>> watchSkills(String personId) {
    return customSelect(
      'SELECT * FROM skills WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {skillsTable},
    ).watch().map((rows) => _mapSkillRows(rows, personId));
  }

  List<SkillData> _mapSkillRows(List<QueryRow> rows, String personId) {
    return rows
        .where((row) => row.data['id'] != null)
        .map(
          (row) => SkillData(
            id: row.data['id'] as String,
            tenantID: row.data['tenant_id'] as String?,
            skillID: row.data['skill_id'] as String?,
            personID: (row.data['person_id'] as String?) ?? personId,
            skillName: (row.data['skill_name'] as String?) ?? 'Untitled',
            skillCategory: row.data['skill_category'] as String?,
            proficiencyLevel: SkillLevel.values.firstWhere(
              (e) => e.name == row.data['proficiency_level'],
              orElse: () => SkillLevel.beginner,
            ),
            point: (row.data['point'] as num?)?.toInt() ?? 0,
            achievedPoints:
                (row.data['achieved_points'] as num?)?.toInt() ?? 0,
            eventID: row.data['event_id'] as String?,
            description: row.data['description'] as String?,
            isFeatured:
                (row.data['is_featured'] == 1 || row.data['is_featured'] == true),
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
  }
}

@DriftAccessor(tables: [EventsTable])
class EventsDAO extends DatabaseAccessor<AppDatabase> with _$EventsDAOMixin {
  EventsDAO(super.db);

  Stream<List<EventData>> watchEventsByPerson(String personId) {
    return watchEventsInRange(
      personId,
      DateTime.fromMillisecondsSinceEpoch(0),
      DateTime.utc(9999),
    );
  }

  Stream<List<EventData>> watchEventsInRange(
    String personId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return (select(eventsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.occurredAt.isBiggerOrEqualValue(rangeStart) &
                t.occurredAt.isSmallerOrEqualValue(rangeEnd),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.occurredAt,
              mode: OrderingMode.desc,
            ),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<EventData>> watchEventsSince(String personId, DateTime since) {
    return (select(eventsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.occurredAt.isBiggerOrEqualValue(since),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.occurredAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<EventData?> getEventById(String id) {
    return (select(eventsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<EventData>> listEventsForPerson(String personId) {
    return listEventsForPersonInRange(
      personId,
      DateTime.fromMillisecondsSinceEpoch(0),
      DateTime.utc(9999),
    );
  }

  Future<List<EventData>> listEventsForPersonInRange(
    String personId,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return (select(eventsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.occurredAt.isBiggerOrEqualValue(rangeStart) &
                t.occurredAt.isSmallerOrEqualValue(rangeEnd),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.occurredAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(eventsTable).insertOnConflictUpdate(
      EventsTableCompanion.insert(
        id: (r['id'] as String?) ?? '',
        tenantID: Value((r['tenant_id'] as String?) ?? DEFAULT_TENANT_ID),
        personID: (r['person_id'] as String?) ?? '',
        name: (r['name'] as String?) ?? (r['title'] as String?) ?? 'Untitled',
        description: Value(r['description'] as String?),
        urlImage: Value(r['url_image'] as String?),
        urlVideo: Value(r['url_video'] as String?),
        occurredAt: Value(
          r['occurred_at'] != null
              ? DateTime.parse(r['occurred_at'].toString())
              : DateTime.now(),
        ),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'].toString())
              : DateTime.now(),
        ),
        updatedAt: Value(
          r['updated_at'] != null
              ? DateTime.parse(r['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
    );
  }

  Future<String> insertEvent(EventsTableCompanion entry) async {
    await into(eventsTable).insert(entry, mode: InsertMode.insertOrReplace);
    final payload = <String, dynamic>{};
    for (final col in eventsTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        var v = value.value;
        if (v is DateTime) {
          v = v.toUtc().toIso8601String();
        }
        payload[col.name] = v;
      }
    }
    await db.pushToSupabase(table: 'events', payload: payload);
    return payload['id'] as String;
  }

  Future<void> updateLoggedEvent({
    required String id,
    required String name,
    required DateTime occurredAt,
    String? description,
  }) async {
    final now = DateTime.now();
    await (update(eventsTable)..where((t) => t.id.equals(id))).write(
      EventsTableCompanion(
        name: Value(name),
        description: Value(description),
        occurredAt: Value(occurredAt.toUtc()),
        updatedAt: Value(now),
      ),
    );
    final row = await getEventById(id);
    if (row != null) {
      await db.pushToSupabase(
        table: 'events',
        payload: {
          'id': row.id,
          'person_id': row.personID,
          'name': name,
          'description': description,
          'occurred_at': occurredAt.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
        },
      );
    }
  }

  Future<void> deleteLoggedEvent(String id) async {
    await (delete(eventsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(table: 'events', payload: {'id': id}, isDelete: true);
  }

  Future<void> syncEventsFromCloud(
    String personId, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    await db.syncTableDown(
      'events',
      personId,
      occurredAfter: rangeStart,
      occurredBefore: rangeEnd,
    );
  }
}

@DriftAccessor(tables: [EventSkillsTable, SkillsTable])
class EventSkillsDAO extends DatabaseAccessor<AppDatabase>
    with _$EventSkillsDAOMixin {
  EventSkillsDAO(super.db);

  Stream<List<EventSkillData>> watchLinksForPerson(String personId) {
    return (select(eventSkillsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<List<EventSkillData>> linksForEvent(String eventId) {
    return (select(eventSkillsTable)
          ..where((t) => t.eventRowID.equals(eventId)))
        .get();
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(eventSkillsTable).insertOnConflictUpdate(
      EventSkillsTableCompanion.insert(
        id: (r['id'] as String?) ?? '',
        tenantID: Value((r['tenant_id'] as String?) ?? DEFAULT_TENANT_ID),
        personID: Value(r['person_id'] as String?),
        eventRowID: (r['event_id'] as String?) ?? '',
        skillRowID: (r['skill_id'] as String?) ?? '',
        earningPoint: Value((r['earning_point'] as num?)?.toInt() ?? 0),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'].toString())
              : DateTime.now(),
        ),
      ),
    );
  }

  /// Inserts junction row and bumps [SkillsTable.point] + last [event_id].
  Future<void> linkEventToSkill({
    required String personId,
    required String eventId,
    required String skillId,
    required int earningPoint,
    String? tenantId,
  }) async {
    if (earningPoint <= 0) return;
    final linkId = IDGen.UUIDV7();
    final now = DateTime.now().toUtc();

    await into(eventSkillsTable).insert(
      EventSkillsTableCompanion.insert(
        id: linkId,
        tenantID: Value(tenantId ?? DEFAULT_TENANT_ID),
        personID: Value(personId),
        eventRowID: eventId,
        skillRowID: skillId,
        earningPoint: Value(earningPoint),
        createdAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );

    await db.pushToSupabase(
      table: 'event_skills',
      payload: {
        'id': linkId,
        'tenant_id': tenantId ?? DEFAULT_TENANT_ID,
        'person_id': personId,
        'event_id': eventId,
        'skill_id': skillId,
        'earning_point': earningPoint,
        'created_at': now.toIso8601String(),
      },
    );

    final skill = await (select(skillsTable)..where((t) => t.id.equals(skillId)))
        .getSingleOrNull();
    if (skill == null) return;

    final newPoints = skill.point + earningPoint;
    await (update(skillsTable)..where((t) => t.id.equals(skillId))).write(
      SkillsTableCompanion(
        point: Value(newPoints),
        proficiencyLevel: Value(GrowthDAO.skillLevelForPracticePoints(newPoints)),
        eventID: Value(eventId),
        updatedAt: Value(now),
      ),
    );

    await db.pushToSupabase(
      table: 'skills',
      payload: {
        'id': skill.id,
        'tenant_id': skill.tenantID,
        'skill_id': skill.skillID ?? skill.id,
        'person_id': skill.personID,
        'skill_name': skill.skillName,
        'skill_category': skill.skillCategory,
        'proficiency_level': GrowthDAO.skillLevelForPracticePoints(newPoints).name,
        'point': newPoints,
        'achieved_points': skill.achievedPoints,
        'event_id': eventId,
        'description': skill.description,
        'is_featured': skill.isFeatured,
        'created_at': skill.createdAt.toUtc().toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
    );
  }

  Future<void> syncEventSkillsFromCloud(String personId) async {
    await db.syncTableDown('event_skills', personId);
  }
}
