class JobDayHistoryEntry {
  const JobDayHistoryEntry({
    required this.day,
    required this.plannedMinutes,
    required this.actualByCategory,
  });

  final DateTime day;
  final int plannedMinutes;
  final Map<String, int> actualByCategory;

  int get totalActual =>
      actualByCategory.values.fold<int>(0, (a, b) => a + b);
}

/// One row from [job_time_logs] for history UI.
class JobWorkTimeLogEntry {
  const JobWorkTimeLogEntry({
    required this.workDate,
    required this.loggedAt,
    required this.taskCategory,
    required this.minutes,
    this.notes,
  });

  final DateTime workDate;
  final DateTime loggedAt;
  final String taskCategory;
  final int minutes;
  final String? notes;
}
