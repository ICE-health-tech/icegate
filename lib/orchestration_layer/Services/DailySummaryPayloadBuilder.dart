import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/FinanceDailySummaryBuilder.dart';

/// Daily cross-domain snapshot for n8n (finance + health), same sources as in-app blocks.
class DailySummaryPayloadBuilder {
  static Map<String, dynamic> build({
    required FinanceBlock finance,
    required HealthBlock health,
    required String personId,
    required String currency,
    required String locale,
    required String recipientEmail,
    Map<String, String>? categoryLabels,
    DateTime? day,
  }) {
    final financePayload = FinanceDailySummaryBuilder.buildPayload(
      transactions: finance.transactions.value,
      personId: personId,
      currency: currency,
      locale: locale,
      recipientEmail: recipientEmail,
      categoryLabels: categoryLabels,
      day: day,
    );

    final weightKg = health.todayWeight.value > 0
        ? health.todayWeight.value
        : health.latestWeight.value;

    final healthSection = <String, dynamic>{
      'steps': health.todaySteps.value,
      'step_goal': health.dailyStepGoal.value,
      'sleep_hours': health.todaySleep.value,
      'sleep_goal': health.dailySleepGoal.value,
      'heart_rate': health.todayHeartRate.value,
      'oxygen_saturation': health.todayOxygenSaturation.value,
      'water_ml': health.todayWater.value,
      'water_goal': health.dailyWaterGoal.value,
      'calories_burned': health.todayCaloriesBurned.value,
      'calories_consumed': health.todayCaloriesConsumed.value,
      'exercise_minutes': health.todayExerciseMinutes.value,
      'focus_minutes': health.todayFocusMinutes.value,
      'weight_kg': weightKg,
    };

    final financeSection = <String, dynamic>{
      'currency': currency,
      'totals': financePayload['totals'],
      'by_category': financePayload['by_category'],
      'transaction_count': financePayload['transaction_count'],
      'net_worth': finance.totalBalance.value,
      'monthly_income': finance.monthlyIncome.value,
      'monthly_spending': finance.monthlySpending.value,
      'monthly_net': finance.monthlyNetChange.value,
      'daily_delta': finance.dailyDelta.value,
      'total_savings': finance.totalSavings.value,
    };

    return {
      ...financePayload,
      'schema_version': 2,
      'report_type': 'daily_summary',
      'finance': financeSection,
      'health': healthSection,
      // Flat keys for n8n email templates ($json.body.*).
      'finance_net_worth': financeSection['net_worth'],
      'finance_monthly_income': financeSection['monthly_income'],
      'finance_monthly_spending': financeSection['monthly_spending'],
      'finance_monthly_net': financeSection['monthly_net'],
      'finance_daily_delta': financeSection['daily_delta'],
      'finance_total_savings': financeSection['total_savings'],
      'health_steps': healthSection['steps'],
      'health_step_goal': healthSection['step_goal'],
      'health_sleep_hours': healthSection['sleep_hours'],
      'health_water_ml': healthSection['water_ml'],
      'health_calories_burned': healthSection['calories_burned'],
      'health_calories_consumed': healthSection['calories_consumed'],
      'health_exercise_minutes': healthSection['exercise_minutes'],
      'health_focus_minutes': healthSection['focus_minutes'],
      'health_weight_kg': healthSection['weight_kg'],
    };
  }
}
