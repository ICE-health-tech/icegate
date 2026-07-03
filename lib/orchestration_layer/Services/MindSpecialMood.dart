/// Earn-only mood reward (above the manual 1–5 picker).
abstract final class MindSpecialMood {
  static const int score = 6;
  static const String activityTag = 'special_mood';
  static const String focusTodosStreakTag = 'focus:todos_streak';

  static const String _dailyTaskPrefix = 'daily_task';

  static String dailyTaskActivity(String goalId) => '$_dailyTaskPrefix:$goalId';

  static List<String> dailyTaskCompleteActivities(String goalId) => [
    dailyTaskActivity(goalId),
    activityTag,
  ];

  static bool isSpecialMood(int moodScore) => moodScore >= score;
}
