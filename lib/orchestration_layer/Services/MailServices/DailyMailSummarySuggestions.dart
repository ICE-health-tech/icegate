import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailyMailSummaryAiService.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/FinanceDailySummaryBuilder.dart';

/// AI-backed tips for daily email reports (rules fallback when agent is offline).
class DailyMailSummarySuggestions {
  /// Compact snapshot for the LLM agent.
  static Map<String, dynamic> buildContext({
    required FinanceBlock finance,
    required HealthBlock health,
    required MindBlock mind,
    required GrowthBlock growth,
    DateTime? day,
  }) {
    final targetDay = (day ?? DateTime.now()).toLocal();

    double dayIncome = 0;
    double dayExpense = 0;
    var txToday = 0;
    for (final t in finance.transactions.value) {
      if (!FinanceDailySummaryBuilder.sameCalendarDay(
        t.transactionDate,
        targetDay,
      )) {
        continue;
      }
      txToday++;
      switch (t.type) {
        case 'income':
          dayIncome += t.amount;
          break;
        case 'expense':
        case 'investment':
          dayExpense += t.amount;
          break;
      }
    }

    final moodLog = mind.latestMoodLog.value;
    final moodToday = moodLog != null &&
        FinanceDailySummaryBuilder.sameCalendarDay(moodLog.logDate, targetDay);

    final tasksActive = growth.goals.value
        .where((g) => g.category == 'project' && g.status != 'done')
        .length;

    return {
      'day': targetDay.toIso8601String(),
      'finance': {
        'day_income': dayIncome,
        'day_expense': dayExpense,
        'day_net': dayIncome - dayExpense,
        'transactions_today': txToday,
        'net_worth': finance.totalBalance.value,
        'monthly_income': finance.monthlyIncome.value,
        'monthly_spending': finance.monthlySpending.value,
        'monthly_net': finance.monthlyNetChange.value,
        'budget_usage_percent': finance.budgetUsagePercent.value,
        'remaining_budget': finance.remainingBudget.value,
        'total_savings': finance.totalSavings.value,
        'savings_rate_percent': finance.savingsRate.value,
      },
      'health': {
        'steps': health.todaySteps.value,
        'step_goal': health.dailyStepGoal.value,
        'sleep_hours': health.todaySleep.value,
        'sleep_goal': health.dailySleepGoal.value,
        'water_ml': health.todayWater.value,
        'water_goal': health.dailyWaterGoal.value,
        'focus_minutes': health.todayFocusMinutes.value,
        'focus_goal': health.dailyFocusGoal.value,
        'exercise_minutes': health.todayExerciseMinutes.value,
        'calories_burned': health.todayCaloriesBurned.value,
      },
      'mood': {
        'logged_today': moodToday,
        if (moodToday) 'score': moodLog.moodScore,
      },
      'projects': {
        'tasks_active': tasksActive,
      },
    };
  }

  /// Rule-based fallback when AI agent is unavailable.
  static List<String> buildRules({
    required AppLocalizations l10n,
    required FinanceBlock finance,
    required HealthBlock health,
    required MindBlock mind,
    required GrowthBlock growth,
    DateTime? day,
    int max = 5,
  }) {
    final targetDay = (day ?? DateTime.now()).toLocal();
    final suggestions = <String>[];

    double dayIncome = 0;
    double dayExpense = 0;
    var txToday = 0;
    for (final t in finance.transactions.value) {
      if (!FinanceDailySummaryBuilder.sameCalendarDay(
        t.transactionDate,
        targetDay,
      )) {
        continue;
      }
      txToday++;
      switch (t.type) {
        case 'income':
          dayIncome += t.amount;
          break;
        case 'expense':
        case 'investment':
          dayExpense += t.amount;
          break;
      }
    }

    final dayNet = dayIncome - dayExpense;
    if (dayNet < 0) {
      suggestions.add(l10n.mail_suggestion_negative_net);
    }
    if (txToday == 0) {
      suggestions.add(l10n.mail_suggestion_no_transactions);
    }

    final budgetUsage = finance.budgetUsagePercent.value;
    if (budgetUsage >= 80) {
      suggestions.add(
        l10n.mail_suggestion_budget_high(budgetUsage.toStringAsFixed(0)),
      );
    }

    final monthlyIncome = finance.monthlyIncome.value;
    final monthlySpending = finance.monthlySpending.value;
    if (monthlyIncome > 0 && monthlySpending > monthlyIncome) {
      suggestions.add(l10n.mail_suggestion_monthly_deficit);
    }

    final stepGoal = health.dailyStepGoal.value;
    final steps = health.todaySteps.value;
    if (stepGoal > 0 && steps / stepGoal < 0.5) {
      suggestions.add(
        l10n.mail_suggestion_steps_low(
          (steps / stepGoal * 100).clamp(0, 100).toStringAsFixed(0),
        ),
      );
    }

    final waterGoal = health.dailyWaterGoal.value;
    final water = health.todayWater.value;
    if (waterGoal > 0 && water / waterGoal < 0.5) {
      suggestions.add(l10n.mail_suggestion_water_low);
    }

    final sleepGoal = health.dailySleepGoal.value;
    final sleep = health.todaySleep.value;
    if (sleepGoal > 0 && sleep < sleepGoal * 0.85) {
      suggestions.add(l10n.mail_suggestion_sleep_low);
    }

    final focusGoal = health.dailyFocusGoal.value;
    final focus = health.todayFocusMinutes.value;
    if (focusGoal > 0 && focus / focusGoal < 0.4) {
      suggestions.add(l10n.mail_suggestion_focus_low);
    }

    final moodLog = mind.latestMoodLog.value;
    final moodToday = moodLog != null &&
        FinanceDailySummaryBuilder.sameCalendarDay(moodLog.logDate, targetDay);
    if (!moodToday) {
      suggestions.add(l10n.mail_suggestion_log_mood);
    }

    final tasksActive = growth.goals.value
        .where((g) => g.category == 'project' && g.status != 'done')
        .length;
    if (tasksActive >= 5) {
      suggestions.add(l10n.mail_suggestion_tasks_many('$tasksActive'));
    }

    return suggestions.take(max).toList();
  }

  /// AI first, then [buildRules] if the agent is missing or fails.
  static Future<DailyMailSummarySuggestionsResult> resolveAsync({
    required AppLocalizations l10n,
    required FinanceBlock finance,
    required HealthBlock health,
    required MindBlock mind,
    required GrowthBlock growth,
    required String localeCode,
    DateTime? day,
    int max = 5,
  }) async {
    final context = buildContext(
      finance: finance,
      health: health,
      mind: mind,
      growth: growth,
      day: day,
    );

    final ai = await DailyMailSummaryAiService.fetchSuggestions(
      summaryContext: context,
      locale: localeCode,
      max: max,
    );
    if (ai.isNotEmpty) {
      return DailyMailSummarySuggestionsResult(
        suggestions: ai.take(max).toList(),
        source: DailyMailSummarySuggestionSource.ai,
      );
    }

    return DailyMailSummarySuggestionsResult(
      suggestions: buildRules(
        l10n: l10n,
        finance: finance,
        health: health,
        mind: mind,
        growth: growth,
        day: day,
        max: max,
      ),
      source: DailyMailSummarySuggestionSource.rules,
    );
  }
}

enum DailyMailSummarySuggestionSource { ai, rules }

class DailyMailSummarySuggestionsResult {
  const DailyMailSummarySuggestionsResult({
    required this.suggestions,
    required this.source,
  });

  final List<String> suggestions;
  final DailyMailSummarySuggestionSource source;
}
