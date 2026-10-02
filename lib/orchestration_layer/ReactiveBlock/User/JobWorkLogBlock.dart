import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Models/JobDayHistoryEntry.dart';
import 'package:ice_gate/orchestration_layer/Models/JobTaskType.dart';

export 'package:ice_gate/orchestration_layer/Models/JobDayHistoryEntry.dart';

/// Plan + track minutes per job / day (Drift + Supabase).
class JobWorkLogBlock {
  JobWorkLogBlock({required JobWorkTrackingDAO dao}) : _dao = dao;

  final JobWorkTrackingDAO _dao;

  _ActiveJobSession? _session;

  bool get hasActiveSession => _session != null;

  String? get activeJobId => _session?.jobId;

  JobWorkTask? get activeTask => _session?.task;

  int elapsedMinutes() {
    final s = _session;
    if (s == null) return 0;
    return DateTime.now().difference(s.startedAt).inMinutes;
  }

  Future<Set<DateTime>> workDaysForJob(String personId, String jobId) {
    return _dao.workDaysForJob(personId, jobId);
  }

  Future<Set<DateTime>> loggedDaysForJob(String personId, String jobId) {
    return _dao.loggedWorkDaysForJob(personId, jobId);
  }

  Future<void> toggleWorkDay(
    String personId,
    String jobId,
    DateTime day,
  ) {
    return _dao.toggleWorkDay(personId, jobId, day);
  }

  static int streakFor(Set<DateTime> workDays) {
    if (workDays.isEmpty) return 0;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    late DateTime cursor;
    if (workDays.contains(today)) {
      cursor = today;
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      if (!workDays.contains(yesterday)) return 0;
      cursor = yesterday;
    }
    var streak = 0;
    while (workDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<JobDayTimeSummary> summaryForDay({
    required String personId,
    required String jobId,
    required DateTime day,
  }) async {
    final planned = await _dao.planMinutesForDay(personId, jobId, day);
    final actual = await _dao.actualBreakdownForDay(
      personId: personId,
      jobPositionId: jobId,
      day: day,
    );
    return JobDayTimeSummary(
      plannedMinutes: planned,
      actualByCategory: actual,
    );
  }

  Future<List<JobDayHistoryEntry>> historyForJob({
    required String personId,
    required String jobId,
  }) {
    return _dao.historyForJob(
      personId: personId,
      jobPositionId: jobId,
    );
  }

  Future<List<JobWorkTimeLogEntry>> timeLogsForJob({
    required String personId,
    required String jobId,
  }) {
    return _dao.timeLogsForJob(
      personId: personId,
      jobPositionId: jobId,
    );
  }

  Future<Map<String, String>> subTaskNamesForJob(
    String personId,
    String jobId,
  ) {
    return _dao.subTaskNamesForJob(personId, jobId);
  }

  Future<String> insertSubTask({
    required String personId,
    required String jobId,
    required String name,
  }) {
    return _dao.insertSubTask(
      personId: personId,
      jobPositionId: jobId,
      name: name,
    );
  }

  Future<void> startWork({
    required String personId,
    required String jobId,
    required DateTime day,
    required JobWorkTask task,
    required int plannedMinutes,
  }) async {
    if (personId.isEmpty || jobId.isEmpty) return;
    final dateOnly = DateTime(day.year, day.month, day.day);
    await _prepareWorkDay(
      personId: personId,
      jobId: jobId,
      day: dateOnly,
      plannedMinutes: plannedMinutes,
    );
    _session = _ActiveJobSession(
      personId: personId,
      jobId: jobId,
      day: dateOnly,
      task: task,
      plannedMinutes: plannedMinutes,
      startedAt: DateTime.now(),
    );
  }

  /// Record minutes now without starting a live timer session.
  Future<void> logImmediately({
    required String personId,
    required String jobId,
    required DateTime day,
    required JobWorkTask task,
    required int minutes,
    String? notes,
  }) async {
    if (personId.isEmpty || jobId.isEmpty || minutes <= 0) return;
    final dateOnly = DateTime(day.year, day.month, day.day);
    await _prepareWorkDay(
      personId: personId,
      jobId: jobId,
      day: dateOnly,
      plannedMinutes: minutes,
    );
    await _dao.addActualMinutes(
      personId: personId,
      jobPositionId: jobId,
      day: dateOnly,
      taskCategory: task.categoryKey,
      minutes: minutes,
      notes: notes,
    );
  }

  Future<void> _prepareWorkDay({
    required String personId,
    required String jobId,
    required DateTime day,
    required int plannedMinutes,
  }) async {
    await _dao.ensureWorkDay(personId, jobId, day);
    if (plannedMinutes > 0) {
      await _dao.setPlanMinutes(
        personId: personId,
        jobPositionId: jobId,
        day: day,
        plannedMinutes: plannedMinutes,
      );
    }
  }

  Future<int> stopWork({String? notes, int? minutesOverride}) async {
    final s = _session;
    if (s == null) return 0;
    final minutes = minutesOverride ??
        DateTime.now().difference(s.startedAt).inMinutes;
    if (minutes > 0) {
      await _dao.addActualMinutes(
        personId: s.personId,
        jobPositionId: s.jobId,
        day: s.day,
        taskCategory: s.task.categoryKey,
        minutes: minutes,
        notes: notes,
      );
    }
    _session = null;
    return minutes;
  }

  void cancelWork() {
    _session = null;
  }
}

class JobDayTimeSummary {
  const JobDayTimeSummary({
    required this.plannedMinutes,
    required this.actualByCategory,
  });

  final int plannedMinutes;
  final Map<String, int> actualByCategory;

  int get totalActual =>
      actualByCategory.values.fold<int>(0, (sum, m) => sum + m);
}

class _ActiveJobSession {
  _ActiveJobSession({
    required this.personId,
    required this.jobId,
    required this.day,
    required this.task,
    required this.plannedMinutes,
    required this.startedAt,
  });

  final String personId;
  final String jobId;
  final DateTime day;
  final JobWorkTask task;
  final int plannedMinutes;
  final DateTime startedAt;
}
