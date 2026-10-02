part of '../Database.dart';

@DriftAccessor(tables: [
  JobWorkDaysTable,
  JobWorkDayPlansTable,
  JobTimeLogsTable,
  JobSubTasksTable,
])
class JobWorkTrackingDAO extends DatabaseAccessor<AppDatabase>
    with _$JobWorkTrackingDAOMixin {
  JobWorkTrackingDAO(super.db);

  DateTime _dayStart(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Calendar day in local time — use for UI sets (strip, streak).
  DateTime _localCalendarDay(DateTime d) {
    final local = d.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  (DateTime, DateTime) _dayRange(DateTime day) {
    final start = _dayStart(day);
    return (start, start.add(const Duration(days: 1)));
  }

  Future<void> _push(String table, Map<String, dynamic> payload,
      {bool isDelete = false}) {
    return db.pushToSupabase(
      table: table,
      payload: payload,
      isDelete: isDelete,
    );
  }

  Future<Set<DateTime>> workDaysForJob(
    String personId,
    String jobPositionId,
  ) async {
    final rows = await (select(jobWorkDaysTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId),
          ))
        .get();
    return rows.map((r) => _localCalendarDay(r.workDate)).toSet();
  }

  /// Days with any logged work: marked work-day or time-log minutes > 0.
  Future<Set<DateTime>> loggedWorkDaysForJob(
    String personId,
    String jobPositionId,
  ) async {
    final days = await workDaysForJob(personId, jobPositionId);
    final logs = await (select(jobTimeLogsTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId) &
                t.minutes.isBiggerThanValue(0),
          ))
        .get();
    return {
      ...days,
      for (final log in logs) _localCalendarDay(log.workDate),
    };
  }

  Future<bool> isWorkDay(
    String personId,
    String jobPositionId,
    DateTime day,
  ) async {
    final (start, end) = _dayRange(day);
    final row = await (select(jobWorkDaysTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId) &
                t.workDate.isBiggerOrEqualValue(start) &
                t.workDate.isSmallerThanValue(end),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> ensureWorkDay(
    String personId,
    String jobPositionId,
    DateTime day,
  ) async {
    if (await isWorkDay(personId, jobPositionId, day)) return;
    final id = IDGen.UUIDV7();
    final workDate = _dayStart(day);
    final companion = JobWorkDaysTableCompanion.insert(
      id: id,
      personId: personId,
      jobPositionId: jobPositionId,
      workDate: workDate,
    );
    await into(jobWorkDaysTable).insert(companion);
    await _push('job_work_days', {
      'id': id,
      'person_id': personId,
      'job_position_id': jobPositionId,
      'work_date': workDate.toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> toggleWorkDay(
    String personId,
    String jobPositionId,
    DateTime day,
  ) async {
    final (start, end) = _dayRange(day);
    final existing = await (select(jobWorkDaysTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId) &
                t.workDate.isBiggerOrEqualValue(start) &
                t.workDate.isSmallerThanValue(end),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(jobWorkDaysTable)..where((t) => t.id.equals(existing.id)))
          .go();
      await _push('job_work_days', {'id': existing.id}, isDelete: true);
      return;
    }
    await ensureWorkDay(personId, jobPositionId, day);
  }

  Future<int> planMinutesForDay(
    String personId,
    String jobPositionId,
    DateTime day,
  ) async {
    final (start, end) = _dayRange(day);
    final row = await (select(jobWorkDayPlansTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId) &
                t.workDate.isBiggerOrEqualValue(start) &
                t.workDate.isSmallerThanValue(end),
          )
          ..limit(1))
        .getSingleOrNull();
    return row?.plannedMinutes ?? 0;
  }

  Future<void> setPlanMinutes({
    required String personId,
    required String jobPositionId,
    required DateTime day,
    required int plannedMinutes,
  }) async {
    if (personId.isEmpty || jobPositionId.isEmpty || plannedMinutes < 0) return;
    final workDate = _dayStart(day);
    final (start, end) = _dayRange(day);
    final existing = await (select(jobWorkDayPlansTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId) &
                t.workDate.isBiggerOrEqualValue(start) &
                t.workDate.isSmallerThanValue(end),
          )
          ..limit(1))
        .getSingleOrNull();
    final now = DateTime.now().toUtc();
    if (existing != null) {
      await (update(jobWorkDayPlansTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        JobWorkDayPlansTableCompanion(
          plannedMinutes: Value(plannedMinutes),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _push('job_work_day_plans', {
        'id': existing.id,
        'person_id': personId,
        'job_position_id': jobPositionId,
        'work_date': workDate.toUtc().toIso8601String(),
        'planned_minutes': plannedMinutes,
        'updated_at': now.toIso8601String(),
      });
      return;
    }
    final id = IDGen.UUIDV7();
    await into(jobWorkDayPlansTable).insert(
      JobWorkDayPlansTableCompanion.insert(
        id: id,
        personId: personId,
        jobPositionId: jobPositionId,
        workDate: workDate,
        plannedMinutes: Value(plannedMinutes),
      ),
    );
    await _push('job_work_day_plans', {
      'id': id,
      'person_id': personId,
      'job_position_id': jobPositionId,
      'work_date': workDate.toUtc().toIso8601String(),
      'planned_minutes': plannedMinutes,
      'updated_at': now.toIso8601String(),
    });
  }

  Future<void> addActualMinutes({
    required String personId,
    required String jobPositionId,
    required DateTime day,
    required String taskCategory,
    required int minutes,
    String? notes,
  }) async {
    if (personId.isEmpty ||
        jobPositionId.isEmpty ||
        taskCategory.isEmpty ||
        minutes <= 0) {
      return;
    }
    final id = IDGen.UUIDV7();
    final workDate = _dayStart(day);
    final createdAt = DateTime.now();
    await into(jobTimeLogsTable).insert(
      JobTimeLogsTableCompanion.insert(
        id: id,
        personId: personId,
        jobPositionId: jobPositionId,
        workDate: workDate,
        taskCategory: taskCategory,
        minutes: minutes,
        notes: Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      ),
    );
    await _push('job_time_logs', {
      'id': id,
      'person_id': personId,
      'job_position_id': jobPositionId,
      'work_date': workDate.toUtc().toIso8601String(),
      'task_category': taskCategory,
      'minutes': minutes,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'created_at': createdAt.toUtc().toIso8601String(),
    });
  }

  Future<List<JobWorkTimeLogEntry>> timeLogsForJob({
    required String personId,
    required String jobPositionId,
  }) async {
    final rows = await (select(jobTimeLogsTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId) &
                t.minutes.isBiggerThanValue(0),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows
        .map(
          (r) => JobWorkTimeLogEntry(
            workDate: _localCalendarDay(r.workDate),
            loggedAt: r.createdAt.toLocal(),
            taskCategory: r.taskCategory,
            minutes: r.minutes,
            notes: r.notes,
          ),
        )
        .toList();
  }

  Future<Map<String, int>> actualBreakdownForDay({
    required String personId,
    required String jobPositionId,
    required DateTime day,
  }) async {
    final (start, end) = _dayRange(day);
    final rows = await (select(jobTimeLogsTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId) &
                t.workDate.isBiggerOrEqualValue(start) &
                t.workDate.isSmallerThanValue(end),
          ))
        .get();
    final map = <String, int>{};
    for (final row in rows) {
      map[row.taskCategory] = (map[row.taskCategory] ?? 0) + row.minutes;
    }
    return map;
  }

  Future<List<JobDayHistoryEntry>> historyForJob({
    required String personId,
    required String jobPositionId,
  }) async {
    final plans = await (select(jobWorkDayPlansTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId),
          ))
        .get();
    final logs = await (select(jobTimeLogsTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId),
          ))
        .get();

    final byDay = <DateTime, JobDayHistoryEntry>{};

    for (final p in plans) {
      final d = _dayStart(p.workDate.toLocal());
      byDay[d] = JobDayHistoryEntry(
        day: d,
        plannedMinutes: p.plannedMinutes,
        actualByCategory: {},
      );
    }
    for (final log in logs) {
      final d = _dayStart(log.workDate.toLocal());
      final prev = byDay[d];
      final breakdown = Map<String, int>.from(prev?.actualByCategory ?? {});
      breakdown[log.taskCategory] =
          (breakdown[log.taskCategory] ?? 0) + log.minutes;
      byDay[d] = JobDayHistoryEntry(
        day: d,
        plannedMinutes: prev?.plannedMinutes ?? 0,
        actualByCategory: breakdown,
      );
    }

    final entries = byDay.values
        .where((e) => e.plannedMinutes > 0 || e.totalActual > 0)
        .toList()
      ..sort((a, b) => b.day.compareTo(a.day));
    return entries;
  }

  Future<String> insertSubTask({
    required String personId,
    required String jobPositionId,
    required String name,
  }) async {
    final id = IDGen.UUIDV7();
    if (personId.isEmpty || jobPositionId.isEmpty || name.trim().isEmpty) {
      return id;
    }
    final createdAt = DateTime.now();
    await into(jobSubTasksTable).insert(
      JobSubTasksTableCompanion.insert(
        id: id,
        personId: personId,
        jobPositionId: jobPositionId,
        name: name.trim(),
      ),
    );
    await _push('job_sub_tasks', {
      'id': id,
      'person_id': personId,
      'job_position_id': jobPositionId,
      'name': name.trim(),
      'created_at': createdAt.toUtc().toIso8601String(),
    });
    return id;
  }

  Future<Map<String, String>> subTaskNamesForJob(
    String personId,
    String jobPositionId,
  ) async {
    final rows = await (select(jobSubTasksTable)
          ..where(
            (t) =>
                t.personId.equals(personId) &
                t.jobPositionId.equals(jobPositionId),
          ))
        .get();
    return {for (final r in rows) r.id: r.name};
  }

  Future<void> upsertWorkDayFromSupabase(Map<String, dynamic> r) async {
    await into(jobWorkDaysTable).insert(
      JobWorkDaysTableCompanion(
        id: Value(r['id'] as String),
        personId: Value(r['person_id'] as String),
        jobPositionId: Value(r['job_position_id'] as String),
        workDate: Value(DateTime.parse(r['work_date'].toString())),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> upsertPlanFromSupabase(Map<String, dynamic> r) async {
    await into(jobWorkDayPlansTable).insert(
      JobWorkDayPlansTableCompanion(
        id: Value(r['id'] as String),
        personId: Value(r['person_id'] as String),
        jobPositionId: Value(r['job_position_id'] as String),
        workDate: Value(DateTime.parse(r['work_date'].toString())),
        plannedMinutes: Value((r['planned_minutes'] as num?)?.toInt() ?? 0),
        updatedAt: Value(
          r['updated_at'] != null
              ? DateTime.parse(r['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> upsertTimeLogFromSupabase(Map<String, dynamic> r) async {
    await into(jobTimeLogsTable).insert(
      JobTimeLogsTableCompanion(
        id: Value(r['id'] as String),
        personId: Value(r['person_id'] as String),
        jobPositionId: Value(r['job_position_id'] as String),
        workDate: Value(DateTime.parse(r['work_date'].toString())),
        taskCategory: Value(r['task_category'] as String),
        minutes: Value((r['minutes'] as num?)?.toInt() ?? 0),
        notes: Value(r['notes'] as String?),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> upsertSubTaskFromSupabase(Map<String, dynamic> r) async {
    await into(jobSubTasksTable).insert(
      JobSubTasksTableCompanion(
        id: Value(r['id'] as String),
        personId: Value(r['person_id'] as String),
        jobPositionId: Value(r['job_position_id'] as String),
        name: Value(r['name'] as String? ?? ''),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.parse(r['created_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}
