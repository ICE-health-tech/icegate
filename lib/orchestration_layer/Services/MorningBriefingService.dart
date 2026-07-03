import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' show Locale;
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/MotivationEngine.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailyMailSummarySuggestions.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailySummaryEmailFormatter.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailySummaryPayloadBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/FinanceDailySummaryBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/MorningScheduleLoader.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleCalendarService.dart';

/// Yesterday recap (email format) + motivation for the morning briefing sheet.
class MorningBriefingSnapshot {
  const MorningBriefingSnapshot({
    required this.yesterday,
    required this.motivation,
    required this.sections,
    required this.headerLine,
    required this.todaySchedule,
  });

  final DateTime yesterday;
  final DailyMotivationResult motivation;
  final List<DailySummarySection> sections;
  final String headerLine;
  final MorningScheduleSnapshot todaySchedule;
}

/// Loads yesterday's cross-domain summary using the same formatter as daily emails.
class MorningBriefingService {
  MorningBriefingService(this._db);

  final AppDatabase _db;

  Future<MorningBriefingSnapshot> load({
    required String personId,
    required HealthBlock health,
    required FinanceBlock finance,
    required MindBlock mind,
    required GrowthBlock growth,
    required ProjectBlock project,
    required String currency,
    required String locale,
    required AppLocalizations l10n,
    Map<String, String>? categoryLabels,
    GoogleCalendarService? google,
    DeviceCalendarService? device,
  }) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final localeCode = locale.startsWith('vi') ? 'vi' : 'en';

    var steps = 0;
    var waterMl = 0;
    var exerciseMinutes = 0;
    var focusMinutes = 0;
    var heartRate = 0;
    var kcalBurned = 0;
    var kcalConsumed = 0;
    var sleepHours = 0.0;
    var weightKg = 0.0;
    var spo2 = 0.0;

    if (personId.isNotEmpty) {
      final metrics =
          await _db.healthMetricsDAO.getMetricsForDate(personId, yDay);
      steps = metrics?.steps ?? 0;
      sleepHours = metrics?.sleepHours ?? 0;
      heartRate = metrics?.heartRate ?? 0;
      spo2 = metrics?.oxygenSaturation ?? 0;
      kcalBurned = metrics?.caloriesBurned ?? 0;
      kcalConsumed = metrics?.caloriesConsumed ?? 0;
      weightKg = metrics?.weightKg ?? 0;
      waterMl = await _db.healthLogsDAO.getDailyWaterTotal(personId, yDay);
      exerciseMinutes =
          await _db.healthLogsDAO.getDailyExerciseTotal(personId, yDay);
      if (exerciseMinutes == 0) {
        exerciseMinutes = metrics?.exerciseMinutes ?? 0;
      }
      focusMinutes = await _focusMinutesForDay(personId, yDay);
      if (kcalConsumed == 0) {
        kcalConsumed = (await _db.healthMealDAO.getCaloriesByDate(yDay)).round();
      }
    }

    final motivation = MotivationEngine.evaluateDaily(
      DailyMotivationInput(
        steps: steps,
        stepGoal: health.dailyStepGoal.value,
        waterMl: waterMl,
        waterGoal: health.dailyWaterGoal.value,
        sleepHours: sleepHours,
        sleepGoal: health.dailySleepGoal.value,
        exerciseMinutes: exerciseMinutes,
        exerciseGoal: health.dailyExerciseGoal.value,
      ),
    );

    final financePayload = FinanceDailySummaryBuilder.buildPayload(
      transactions: finance.transactions.value,
      personId: personId,
      currency: currency,
      locale: localeCode,
      recipientEmail: '',
      day: yDay,
      categoryLabels: categoryLabels,
    );

    final totals = financePayload['totals'] as Map<String, dynamic>;
    final periodLabel =
        (financePayload['period'] as Map<String, dynamic>)['label'] as String;
    final dayTx = DailySummaryPayloadBuilder.transactionsForDay(
      transactions: finance.transactions.value,
      day: yDay,
      categoryLabels: categoryLabels,
    );

    final healthSection = <String, dynamic>{
      'steps': steps,
      'step_goal': health.dailyStepGoal.value,
      'steps_progress_percent':
          DailySummaryPayloadBuilder.progressPercent(steps, health.dailyStepGoal.value),
      'sleep_hours': sleepHours,
      'sleep_goal': health.dailySleepGoal.value,
      'sleep_progress_percent': DailySummaryPayloadBuilder.progressPercent(
        sleepHours,
        health.dailySleepGoal.value,
      ),
      'heart_rate': heartRate,
      'oxygen_saturation': spo2,
      'water_ml': waterMl,
      'water_goal': health.dailyWaterGoal.value,
      'water_progress_percent': DailySummaryPayloadBuilder.progressPercent(
        waterMl,
        health.dailyWaterGoal.value,
      ),
      'calories_burned': kcalBurned,
      'calories_consumed': kcalConsumed,
      'calorie_goal': health.dailyKcalGoal.value,
      'exercise_minutes': exerciseMinutes,
      'exercise_goal': health.dailyExerciseGoal.value,
      'exercise_progress_percent': DailySummaryPayloadBuilder.progressPercent(
        exerciseMinutes,
        health.dailyExerciseGoal.value,
      ),
      'focus_minutes': focusMinutes,
      'focus_goal': health.dailyFocusGoal.value,
      'focus_progress_percent': DailySummaryPayloadBuilder.progressPercent(
        focusMinutes,
        health.dailyFocusGoal.value,
      ),
      'weight_kg': weightKg,
    };

    final financeSection = <String, dynamic>{
      'net_worth': finance.totalBalance.value,
      'drawdown_percent': finance.drawdown.value,
      'monthly_income': finance.monthlyIncome.value,
      'monthly_spending': finance.monthlySpending.value,
      'monthly_net': finance.monthlyNetChange.value,
      'daily_delta': finance.dailyDelta.value,
      'total_savings': finance.totalSavings.value,
      'savings_rate_percent': finance.savingsRate.value,
      'budget_usage_percent': finance.budgetUsagePercent.value,
      'remaining_budget': finance.remainingBudget.value,
    };

    final moodSection = await _moodSectionForDay(personId: personId, day: yDay);
    final projectsSection = DailySummaryPayloadBuilder.projectsSection(
      growth: growth,
      project: project,
    );

    final suggestions = DailyMailSummarySuggestions.buildRules(
      l10n: lookupAppLocalizations(Locale(localeCode)),
      finance: finance,
      health: health,
      mind: mind,
      growth: growth,
      day: yDay,
    );

    final formatted = DailySummaryEmailFormatter.buildFormattedFields(
      locale: localeCode,
      finance: finance,
      totals: totals,
      financeSection: financeSection,
      healthSection: healthSection,
      moodSection: moodSection,
      projectsSection: projectsSection,
      periodLabel: periodLabel,
      transactionCount: financePayload['transaction_count'] as int,
      todayTransactions: dayTx,
      subscriptionCount: finance.subscriptions.value.length,
      suggestions: suggestions,
    );

    final sections =
        DailySummaryEmailFormatter.buildSections(locale: localeCode, f: formatted);

    final todaySchedule = google != null && device != null
        ? await MorningScheduleLoader.loadToday(
            db: _db,
            personId: personId,
            google: google,
            device: device,
          )
        : const MorningScheduleSnapshot(
            items: [],
            hasCalendarSource: false,
          );

    return MorningBriefingSnapshot(
      yesterday: yDay,
      motivation: motivation,
      sections: sections,
      headerLine: sections.first.title,
      todaySchedule: todaySchedule,
    );
  }

  Future<Map<String, dynamic>> _moodSectionForDay({
    required String personId,
    required DateTime day,
  }) async {
    if (personId.isEmpty) return const {'has_log_today': false};

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final logs = await (_db.select(_db.mindLogsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.logDate.isBetweenValues(start, end),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.createdAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .get();

    if (logs.isEmpty) return const {'has_log_today': false};

    final log = logs.first;
    return {
      'has_log_today': true,
      'mood_score': log.moodScore,
      'activities': _parseActivities(log.activities),
      if (log.note != null && log.note!.trim().isNotEmpty)
        'note': log.note!.trim(),
    };
  }

  static List<String> _parseActivities(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<int> _focusMinutesForDay(String personId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final sessions = await (_db.select(_db.focusSessionsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.startTime.isBetweenValues(start, end),
          ))
        .get();
    return sessions.fold<int>(
      0,
      (sum, s) => sum + (s.durationSeconds ~/ 60),
    );
  }
}
