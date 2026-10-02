import 'dart:convert';

import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailySummaryEmailFormatter.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/FinanceDailySummaryBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailyMailSummarySuggestions.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:ice_gate/l10n/app_localizations.dart';

/// Daily cross-domain snapshot for n8n (finance + health + mood + projects).
class DailySummaryPayloadBuilder {
  static double _progressPercent(num value, num goal) {
    if (goal <= 0) return 0;
    return (value / goal * 100).clamp(0, 100).toDouble();
  }

  static List<Map<String, dynamic>> _todayTransactions({
    required List<TransactionData> transactions,
    required DateTime day,
    Map<String, String>? categoryLabels,
    int limit = 15,
  }) {
    final dayTx = transactions
        .where((t) => FinanceDailySummaryBuilder.sameCalendarDay(
              t.transactionDate,
              day,
            ))
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return dayTx.take(limit).map((t) {
      return {
        'id': t.id,
        'type': t.type,
        'category': t.category,
        if (categoryLabels != null && categoryLabels[t.category] != null)
          'label': categoryLabels[t.category],
        'amount': t.amount,
        if (t.description != null && t.description!.trim().isNotEmpty)
          'description': t.description!.trim(),
        'date': t.transactionDate.toIso8601String(),
      };
    }).toList();
  }

  static List<String> _parseActivities(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {}
    return const [];
  }

  static Map<String, dynamic> _buildMoodSection({
    required MindBlock mind,
    required DateTime targetDay,
  }) {
    final log = mind.latestMoodLog.value;
    final isToday = log != null &&
        FinanceDailySummaryBuilder.sameCalendarDay(log.logDate, targetDay);

    return {
      'has_log_today': isToday,
      if (isToday) 'mood_score': log.moodScore,
      if (isToday) 'activities': _parseActivities(log.activities),
      if (isToday && log.note != null && log.note!.trim().isNotEmpty)
        'note': log.note!.trim(),
      if (isToday) 'logged_at': log.createdAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> _buildProjectsSection({
    required GrowthBlock growth,
    required ProjectBlock project,
    int listLimit = 8,
  }) {
    final projectGoals =
        growth.goals.value.where((g) => g.category == 'project').toList();
    final activeTasks =
        projectGoals.where((g) => g.status != 'done').toList();
    final doneTasks =
        projectGoals.where((g) => g.status == 'done').length;
    final allProjects = project.projects.value;
    final activeProjects = allProjects.where((p) => p.status == 0).toList();
    final doneProjects = allProjects.where((p) => p.status == 1).length;

    return {
      'projects_total': allProjects.length,
      'projects_active': activeProjects.length,
      'projects_done': doneProjects,
      'tasks_active': activeTasks.length,
      'tasks_done': doneTasks,
      'active_project_names':
          activeProjects.take(listLimit).map((p) => p.name).toList(),
      'active_task_titles':
          activeTasks.take(listLimit).map((g) => g.title).toList(),
    };
  }

  static List<Map<String, dynamic>> transactionsForDay({
    required List<TransactionData> transactions,
    required DateTime day,
    Map<String, String>? categoryLabels,
    int limit = 15,
  }) =>
      _todayTransactions(
        transactions: transactions,
        day: day,
        categoryLabels: categoryLabels,
        limit: limit,
      );

  static Map<String, dynamic> projectsSection({
    required GrowthBlock growth,
    required ProjectBlock project,
    int listLimit = 8,
  }) =>
      _buildProjectsSection(
        growth: growth,
        project: project,
        listLimit: listLimit,
      );

  static double progressPercent(num value, num goal) =>
      _progressPercent(value, goal);

  static Map<String, dynamic> build({
    required FinanceBlock finance,
    required HealthBlock health,
    required MindBlock mind,
    required GrowthBlock growth,
    required ProjectBlock project,
    required String personId,
    required String currency,
    required String locale,
    required String recipientEmail,
    String? recipientName,
    Map<String, String>? categoryLabels,
    DateTime? day,
    List<String>? suggestions,
  }) {
    final targetDay = (day ?? DateTime.now()).toLocal();
    final financePayload = FinanceDailySummaryBuilder.buildPayload(
      transactions: finance.transactions.value,
      personId: personId,
      currency: currency,
      locale: locale,
      recipientEmail: recipientEmail,
      categoryLabels: categoryLabels,
      day: targetDay,
    );

    final totals = financePayload['totals'] as Map<String, dynamic>;
    final byCategory =
        financePayload['by_category'] as List<Map<String, dynamic>>;
    final topCategory = byCategory.isNotEmpty ? byCategory.first : null;

    final weightKg = health.todayWeight.value > 0
        ? health.todayWeight.value
        : health.latestWeight.value;

    final steps = health.todaySteps.value;
    final stepGoal = health.dailyStepGoal.value;
    final waterMl = health.todayWater.value;
    final waterGoal = health.dailyWaterGoal.value;
    final sleepHours = health.todaySleep.value;
    final sleepGoal = health.dailySleepGoal.value;
    final kcalBurned = health.todayCaloriesBurned.value;
    final kcalConsumed = health.todayCaloriesConsumed.value;
    final kcalGoal = health.dailyKcalGoal.value;

    final healthSection = <String, dynamic>{
      'steps': steps,
      'step_goal': stepGoal,
      'steps_progress_percent': _progressPercent(steps, stepGoal),
      'sleep_hours': sleepHours,
      'sleep_goal': sleepGoal,
      'sleep_progress_percent': _progressPercent(sleepHours, sleepGoal),
      'heart_rate': health.todayHeartRate.value,
      'oxygen_saturation': health.todayOxygenSaturation.value,
      'water_ml': waterMl,
      'water_goal': waterGoal,
      'water_progress_percent': _progressPercent(waterMl, waterGoal),
      'calories_burned': kcalBurned,
      'calories_consumed': kcalConsumed,
      'calorie_goal': kcalGoal,
      'exercise_minutes': health.todayExerciseMinutes.value,
      'exercise_goal': health.dailyExerciseGoal.value,
      'exercise_progress_percent': _progressPercent(
        health.todayExerciseMinutes.value,
        health.dailyExerciseGoal.value,
      ),
      'focus_minutes': health.todayFocusMinutes.value,
      'focus_goal': health.dailyFocusGoal.value,
      'focus_progress_percent': _progressPercent(
        health.todayFocusMinutes.value,
        health.dailyFocusGoal.value,
      ),
      'weight_kg': weightKg,
    };

    final todayTx = _todayTransactions(
      transactions: finance.transactions.value,
      day: targetDay,
      categoryLabels: categoryLabels,
    );

    final financeSection = <String, dynamic>{
      'currency': currency,
      'totals': totals,
      'by_category': byCategory,
      'transaction_count': financePayload['transaction_count'],
      'today_transactions': todayTx,
      'net_worth': finance.totalBalance.value,
      'ath_balance': finance.athBalance.value,
      'drawdown_percent': finance.drawdown.value,
      'sharpe_ratio': finance.sharpeRatio.value,
      'monthly_income': finance.monthlyIncome.value,
      'monthly_spending': finance.monthlySpending.value,
      'monthly_net': finance.monthlyNetChange.value,
      'monthly_net_change_percent': finance.netChangePercent.value,
      'daily_delta': finance.dailyDelta.value,
      'total_savings': finance.totalSavings.value,
      'savings_rate_percent': finance.savingsRate.value,
      'spending_efficiency_percent': finance.spendingEfficiency.value,
      'monthly_burn_rate': finance.monthlyBurnRate.value,
      'monthly_budget_limit': finance.monthlyLimitEquivalent.value,
      'budget_usage_percent': finance.budgetUsagePercent.value,
      'remaining_budget': finance.remainingBudget.value,
      if (topCategory != null) 'top_expense_category': topCategory,
    };

    final moodSection = _buildMoodSection(mind: mind, targetDay: targetDay);
    final projectsSection =
        _buildProjectsSection(growth: growth, project: project);

    final l10n = lookupAppLocalizations(Locale(locale));
    final resolvedSuggestions = suggestions ??
        DailyMailSummarySuggestions.buildRules(
          l10n: l10n,
          finance: finance,
          health: health,
          mind: mind,
          growth: growth,
          day: targetDay,
        );

    final periodLabel =
        (financePayload['period'] as Map<String, dynamic>)['label'] as String;
    final formatted = DailySummaryEmailFormatter.buildFormattedFields(
      locale: locale,
      finance: finance,
      totals: totals,
      financeSection: financeSection,
      healthSection: healthSection,
      moodSection: moodSection,
      projectsSection: projectsSection,
      periodLabel: periodLabel,
      transactionCount: financePayload['transaction_count'] as int,
      todayTransactions: todayTx,
      subscriptionCount: finance.subscriptions.value.length,
      suggestions: resolvedSuggestions,
    );
    final emailSubject = DailySummaryEmailFormatter.buildSubject(
      locale: locale,
      periodLabel: periodLabel,
      recipientName: recipientName,
    );
    final emailBodyPlain = DailySummaryEmailFormatter.buildPlainText(
      locale: locale,
      f: formatted,
    );
    final emailBodyHtml = DailySummaryEmailFormatter.buildHtml(
      locale: locale,
      f: formatted,
    );

    final sentAt = DateTime.now().toUtc();

    return {
      ...financePayload,
      ...formatted,
      'schema_version': 5,
      'email_subject': emailSubject,
      'email_body_plain': emailBodyPlain,
      'email_body_html': emailBodyHtml,
      'report_type': 'daily_summary',
      'sent_at': sentAt.toIso8601String(),
      if (recipientName != null && recipientName.trim().isNotEmpty)
        'recipient_name': recipientName.trim(),
      'finance': financeSection,
      'health': healthSection,
      'mood': moodSection,
      'projects': projectsSection,
      'suggestions': resolvedSuggestions,
      'suggestions_text': resolvedSuggestions.isEmpty
          ? ''
          : resolvedSuggestions.map((s) => '• $s').join('\n'),
      // Flat keys for n8n email templates ($json.body.*).
      'finance_daily_income': totals['income'],
      'finance_daily_expense': totals['expense'],
      'finance_daily_net': totals['net'],
      'finance_net_worth': financeSection['net_worth'],
      'finance_ath_balance': financeSection['ath_balance'],
      'finance_drawdown_percent': financeSection['drawdown_percent'],
      'finance_monthly_income': financeSection['monthly_income'],
      'finance_monthly_spending': financeSection['monthly_spending'],
      'finance_monthly_net': financeSection['monthly_net'],
      'finance_daily_delta': financeSection['daily_delta'],
      'finance_total_savings': financeSection['total_savings'],
      'finance_savings_rate_percent': financeSection['savings_rate_percent'],
      'finance_top_category': topCategory?['label'] ?? topCategory?['category'],
      'finance_top_category_amount': topCategory?['amount'],
      'health_steps': healthSection['steps'],
      'health_step_goal': healthSection['step_goal'],
      'health_steps_progress_percent': healthSection['steps_progress_percent'],
      'health_sleep_hours': healthSection['sleep_hours'],
      'health_sleep_goal': healthSection['sleep_goal'],
      'health_heart_rate': healthSection['heart_rate'],
      'health_oxygen_saturation': healthSection['oxygen_saturation'],
      'health_water_ml': healthSection['water_ml'],
      'health_water_goal': healthSection['water_goal'],
      'health_calories_burned': healthSection['calories_burned'],
      'health_calories_consumed': healthSection['calories_consumed'],
      'health_exercise_minutes': healthSection['exercise_minutes'],
      'health_focus_minutes': healthSection['focus_minutes'],
      'health_weight_kg': healthSection['weight_kg'],
      'health_exercise_goal': healthSection['exercise_goal'],
      'health_focus_goal': healthSection['focus_goal'],
      'health_calorie_goal': healthSection['calorie_goal'],
      'health_exercise_progress_percent':
          healthSection['exercise_progress_percent'],
      'health_focus_progress_percent': healthSection['focus_progress_percent'],
      'mood_score': moodSection['mood_score'],
      'mood_has_log_today': moodSection['has_log_today'],
      'projects_total': projectsSection['projects_total'],
      'projects_active': projectsSection['projects_active'],
      'projects_done': projectsSection['projects_done'],
      'tasks_active': projectsSection['tasks_active'],
      'tasks_done': projectsSection['tasks_done'],
    };
  }
}
