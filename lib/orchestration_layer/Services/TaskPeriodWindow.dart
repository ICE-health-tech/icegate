import 'package:ice_gate/orchestration_layer/Services/MailServices/FinanceDailySummaryBuilder.dart';

/// Time windows for focus tasks — aligned with finance recurring intervals.
enum TaskPeriod {
  daily,
  weekly,
  monthly,
}

abstract final class TaskPeriodWindow {
  static const timeScopedCategories = {'daily', 'weekly', 'monthly'};

  static String categoryFor(TaskPeriod period) => switch (period) {
    TaskPeriod.daily => 'daily',
    TaskPeriod.weekly => 'weekly',
    TaskPeriod.monthly => 'monthly',
  };

  static TaskPeriod? periodForCategory(String? category) => switch (category) {
    'daily' => TaskPeriod.daily,
    'weekly' => TaskPeriod.weekly,
    'monthly' => TaskPeriod.monthly,
    _ => null,
  };

  static bool isTimeScopedCategory(String? category) =>
      timeScopedCategories.contains(category);

  static DateTime dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Monday-start week (finance / planning cadence).
  static DateTime weekStart(DateTime value) {
    final day = dateOnly(value);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime monthStart(DateTime value) {
    final day = dateOnly(value);
    return DateTime(day.year, day.month, 1);
  }

  static DateTime anchorFor(TaskPeriod period, DateTime reference) {
    final now = dateOnly(reference);
    return switch (period) {
      TaskPeriod.daily => now,
      TaskPeriod.weekly => weekStart(now),
      TaskPeriod.monthly => monthStart(now),
    };
  }

  /// Stable prefs / cache key suffix per window (not calendar day only).
  static String windowKeySuffix(TaskPeriod period, DateTime reference) {
    final anchor = anchorFor(period, reference);
    return switch (period) {
      TaskPeriod.daily =>
        '${anchor.year}${anchor.month.toString().padLeft(2, '0')}${anchor.day.toString().padLeft(2, '0')}',
      TaskPeriod.weekly =>
        'w${anchor.year}${anchor.month.toString().padLeft(2, '0')}${anchor.day.toString().padLeft(2, '0')}',
      TaskPeriod.monthly =>
        'm${anchor.year}${anchor.month.toString().padLeft(2, '0')}',
    };
  }

  static bool isInCurrentWindow({
    required String? category,
    required DateTime? targetDate,
    DateTime? reference,
  }) {
    if (!isTimeScopedCategory(category) || targetDate == null) return false;
    final now = reference ?? DateTime.now();
    final anchor = dateOnly(targetDate.toLocal());
    return switch (category) {
      'daily' => FinanceDailySummaryBuilder.sameCalendarDay(anchor, now),
      'weekly' => weekStart(anchor) == weekStart(now),
      'monthly' =>
        anchor.year == dateOnly(now).year && anchor.month == dateOnly(now).month,
      _ => false,
    };
  }
}

/// Optional `skill:<name>` first line in goal / recurring-income [description].
abstract final class TaskGoalSkillCodec {
  static const _prefix = 'skill:';

  static String encode({String? skillName, required String description}) {
    final desc = description.trim();
    final skill = skillName?.trim();
    if (skill == null || skill.isEmpty) return desc;
    return desc.isEmpty ? '$_prefix$skill' : '$_prefix$skill\n$desc';
  }

  static String? decode(String? description) {
    if (description == null || description.isEmpty) return null;
    for (final line in description.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith(_prefix)) {
        final name = trimmed.substring(_prefix.length).trim();
        if (name.isNotEmpty) return name;
      }
    }
    return null;
  }

  static String displayLabel(String? description) {
    if (description == null || description.isEmpty) return '';
    final lines = description.split('\n');
    if (lines.isEmpty) return description.trim();
    final first = lines.first.trim();
    if (first.startsWith(_prefix)) {
      final user = lines.skip(1).join('\n').trim();
      return user.isNotEmpty ? user : first.substring(_prefix.length).trim();
    }
    return description.trim();
  }
}
