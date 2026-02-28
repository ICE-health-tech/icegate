import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/GameConst.dart';

/// ProjectPoint — Configurable point system for projects & tasks.
///
/// All point values are defined as static constants at the top
/// for easy migration and tuning. Just change the constants below.
class ProjectPoint {
  // ─────────────────────────────────────────────────
  // 🔧 CONFIGURABLE POINT VALUES — Edit these to tune
  // ─────────────────────────────────────────────────

  // Task Points
  static const double taskBase = TASK_SCORE_INCREMENT;
  static const double taskHalfwayBonus = 1.0; // > 50% tasks done
  static const double taskAllDoneBonus = 3.0; // 100% tasks done

  // Project Points
  static const double projectBase = PROJECT_SCORE_INCREMENT;
  static const double projectManyTasksBonus = 2.0; // >= 5 tasks
  static const double projectLotsTasksBonus = 3.0; // >= 10 tasks
  static const double projectDocBonus = 2.0; // >= 3 notes
  static const double projectWeekBonus = 2.0; // >= 7 days active
  static const double projectMonthBonus = 5.0; // >= 30 days active

  // Daily Activity Points
  static const double daily1Task = 1.0;
  static const double daily3Tasks = 2.0;
  static const double daily5Tasks = 3.0;

  // Finance Points
  static const double savingsBase = 1.0;
  static const double savingsMilestone100 = 2.0;
  static const double savingsMilestone1000 = 5.0;

  // ─────────────────────────────────────────────────
  // 📊 POINT SUMMARY TABLE
  // ─────────────────────────────────────────────────
  //
  // Action                    | Points
  // ─────────────────────────────────────────────────
  // Complete a task           | 2 base + up to 4 bonus
  // Complete a project        | 50 base + up to 14 bonus
  // Daily 1 task              | +1
  // Daily 3 tasks             | +2 (total 3)
  // Daily 5 tasks             | +3 (total 6)
  // Add to savings            | 1 base + milestones
  // ─────────────────────────────────────────────────

  /// Calculate bonus points for completing a task
  static double calculateTaskBonus(int completedTasks, int totalTasks) {
    double bonus = taskBase;

    // Streak bonus: extra point if more than half done
    if (totalTasks > 0 && completedTasks >= (totalTasks / 2)) {
      bonus += taskHalfwayBonus;
    }

    // Completion bonus: extra points if all tasks done
    if (totalTasks > 0 && completedTasks >= totalTasks) {
      bonus += taskAllDoneBonus;
    }

    return bonus;
  }

  /// Calculate bonus points for completing a project
  static double calculateProjectBonus(
    int totalTasks,
    int totalNotes,
    int daysActive,
  ) {
    double bonus = projectBase;

    // Effort bonus: more tasks = more points
    if (totalTasks >= 5) bonus += projectManyTasksBonus;
    if (totalTasks >= 10) bonus += projectLotsTasksBonus;

    // Documentation bonus for having notes
    if (totalNotes >= 3) bonus += projectDocBonus;

    // Dedication bonus for long-running projects
    if (daysActive >= 7) bonus += projectWeekBonus;
    if (daysActive >= 30) bonus += projectMonthBonus;

    return bonus;
  }

  /// Calculate daily activity bonus
  static double calculateDailyBonus(int tasksCompletedToday) {
    double bonus = 0;
    if (tasksCompletedToday >= 1) bonus += daily1Task;
    if (tasksCompletedToday >= 3) bonus += daily3Tasks;
    if (tasksCompletedToday >= 5) bonus += daily5Tasks;
    return bonus;
  }

  /// Calculate savings bonus
  static double calculateSavingsBonus(double totalSaved) {
    double bonus = savingsBase;
    if (totalSaved >= 100) bonus += savingsMilestone100;
    if (totalSaved >= 1000) bonus += savingsMilestone1000;
    return bonus;
  }

  /// Get a human-readable summary of all point values
  static Map<String, double> get pointTable => {
    'Task (base)': taskBase,
    'Task (halfway bonus)': taskHalfwayBonus,
    'Task (all done bonus)': taskAllDoneBonus,
    'Project (base)': projectBase,
    'Project (5+ tasks)': projectManyTasksBonus,
    'Project (10+ tasks)': projectLotsTasksBonus,
    'Project (3+ notes)': projectDocBonus,
    'Project (7+ days)': projectWeekBonus,
    'Project (30+ days)': projectMonthBonus,
    'Daily (1 task)': daily1Task,
    'Daily (3 tasks)': daily3Tasks,
    'Daily (5 tasks)': daily5Tasks,
    'Savings (base)': savingsBase,
    'Savings (100+)': savingsMilestone100,
    'Savings (1000+)': savingsMilestone1000,
  };
}
