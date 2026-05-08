import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/Constraint/HealthConstraint.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/widgets/health_remote_trend_card.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class HealthAnalysisPage extends StatelessWidget {
  const HealthAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authBlock = context.read<AuthBlock>();
    final personID = authBlock.user.value?['id'] as String?;

    if (personID == null) {
      return const Scaffold(
        body: Center(child: Text("User session not found")),
      );
    }

    final healthMetricsDao = context.watch<HealthMetricsDAO>();
    final healthBlock = context.watch<HealthBlock>();

    return SwipeablePage(
      direction: SwipeablePageDirection.leftToRight,
      onSwipe: () => WidgetNavigatorAction.smartPop(context),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80), // Dynamic Island Gap
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colorScheme.onSurface,
                        size: 22,
                      ),
                      onPressed: () => WidgetNavigatorAction.smartPop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.health_analysis_title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_graph_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<HealthMetricsLocal>>(
                  stream: healthMetricsDao.watchAllMetrics(personID),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allMetrics = snapshot.data!;
                    if (allMetrics.isEmpty) {
                      return _buildEmptyState(
                        context,
                        AppLocalizations.of(context)!.health_no_data,
                        Icons.health_and_safety_outlined,
                      );
                    }

                    // --- DATA ANALYSIS ---
                    final now = DateTime.now();
                    final todayKey =
                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                    final todayMetric = allMetrics.firstWhere(
                      (m) =>
                          "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}" ==
                          todayKey,
                      orElse: () => HealthMetricsLocal(
                        id: '',
                        date: now,
                        steps: 0,
                        caloriesBurned: 0,
                        caloriesConsumed: 0,
                        sleepHours: 0.0,
                        heartRate: 0,
                        waterGlasses: 0,
                        exerciseMinutes: 0,
                        focusMinutes: 0,
                        category: 'General',
                        updatedAt: now,
                        createdAt: DateTime.now(),
                      ),
                    );

                    final latest = todayMetric;
                    final last7Days = allMetrics.take(7).toList();

                    // Efficiency (Steps vs Goal)
                    final efficiency = ((latest.steps ?? 0) / STEP_GOAL).clamp(
                      0.0,
                      1.0,
                    );

                    // Consistency (Average variation in last 7 days)
                    double avgSteps = last7Days.isEmpty
                        ? 0.0
                        : last7Days.fold(
                                0.0,
                                (sum, m) => sum + (m.steps ?? 0),
                              ) /
                              last7Days.length;

                    double consistency = 0.0;
                    if (last7Days.length > 1) {
                      double variance =
                          last7Days.fold(
                            0.0,
                            (sum, m) =>
                                sum + math.pow((m.steps ?? 0) - avgSteps, 2),
                          ) /
                          last7Days.length;
                      consistency =
                          (1.0 -
                                  (math.sqrt(variance) /
                                      (avgSteps > 0 ? avgSteps : 1.0)))
                              .clamp(0.0, 1.0);
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- PERFORMANCE ANALYSIS SECTION ---
                          _buildPerformanceCard(
                            context,
                            colorScheme,
                            textTheme,
                            efficiency: efficiency,
                            consistency: consistency,
                            metabolism: (latest.caloriesBurned ?? 0) > 2000
                                ? AppLocalizations.of(
                                    context,
                                  )!.health_metabolism_active
                                : AppLocalizations.of(
                                    context,
                                  )!.health_metabolism_normal,
                            intensity: (latest.exerciseMinutes ?? 0) > 45
                                ? AppLocalizations.of(
                                    context,
                                  )!.health_intensity_high
                                : AppLocalizations.of(
                                    context,
                                  )!.health_intensity_moderate,
                          ),

                          const SizedBox(height: 32),
                          // --- ACTIVITY BALANCE SECTION ---
                          _buildActivityBalanceCard(
                            context,
                            colorScheme,
                            textTheme,
                            latest: latest,
                          ),
                          const SizedBox(height: 24),

                          // --- CALORIE & ENERGY SECTION ---
                          _buildCalorieBalanceCard(
                            context,
                            colorScheme,
                            textTheme,
                            latest: latest,
                          ),
                          const SizedBox(height: 24),

                          // --- HEART RATE SECTION ---
                          _buildHeartRateCard(
                            context,
                            colorScheme,
                            textTheme,
                            latest: latest,
                          ),
                          const SizedBox(height: 24),

                          // --- WEEKLY TRENDS SECTION ---
                          _buildWeeklyTrendsCard(
                            context,
                            colorScheme,
                            textTheme,
                            last7Days: last7Days,
                          ),
                          const SizedBox(height: 24),

                          // --- CLOUD TREND (Supabase RPC + fl_chart) ---
                          const HealthRemoteTrendCard(days: 7),
                          const SizedBox(height: 24),

                          // --- WEIGHT TREND SECTION ---
                          _buildWeightTrendCard(
                            context,
                            colorScheme,
                            textTheme,
                            healthBlock,
                          ),
                          const SizedBox(height: 24),

                          // --- WATER TREND SECTION ---
                          _buildWaterTrendCard(
                            context,
                            colorScheme,
                            textTheme,
                            healthBlock,
                          ),
                          const SizedBox(height: 24),

                          // --- HEALTH INSIGHTS SECTION ---
                          _buildInsightsCard(
                            context,
                            colorScheme,
                            textTheme,
                            latest: latest,
                            avgSteps: avgSteps,
                            last7Days: last7Days,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required double efficiency,
    required double consistency,
    required String metabolism,
    required String intensity,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.health_analysis_performance,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${(efficiency * 100).toInt()}%",
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTrendStat(
                  AppLocalizations.of(context)!.health_efficiency,
                  "${(efficiency * 100).toInt()}%",
                  colorScheme,
                  textTheme,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTrendStat(
                  AppLocalizations.of(context)!.health_consistency,
                  consistency > 0.8
                      ? AppLocalizations.of(context)!.health_consistency_high
                      : consistency > 0.5
                      ? AppLocalizations.of(context)!.health_consistency_medium
                      : AppLocalizations.of(context)!.health_consistency_low,
                  colorScheme,
                  textTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTrendStat(
                  AppLocalizations.of(context)!.health_metabolism,
                  metabolism,
                  colorScheme,
                  textTheme,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTrendStat(
                  AppLocalizations.of(context)!.health_intensity,
                  intensity,
                  colorScheme,
                  textTheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBalanceCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required HealthMetricsLocal latest,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.health_activity_balance,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.steps! > 8000
                          ? AppLocalizations.of(
                              context,
                            )!.health_balance_moving_much
                          : AppLocalizations.of(
                              context,
                            )!.health_balance_optimal,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required HealthMetricsLocal latest,
  }) {
    final hr = latest.heartRate ?? 0;
    String status = "NORMAL";
    Color hrColor = Colors.green;

    if (hr > 100) {
      status = "ELEVATED";
      hrColor = Colors.orange;
    } else if (hr > 140) {
      status = "HIGH";
      hrColor = Colors.red;
    } else if (hr < 50 && hr > 0) {
      status = "LOW";
      hrColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HEART RATE ANALYSIS",
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hrColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(
                    color: hrColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hr > 0 ? "$hr" : "--",
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "BPM",
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              _HeartPulseIcon(color: hrColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hr > 0
                ? "Your current heart rate is $status for your age and activity level."
                : "No heart rate data recorded for today.",
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieBalanceCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required HealthMetricsLocal latest,
  }) {
    final burned = latest.caloriesBurned ?? 0;
    final consumed = latest.caloriesConsumed ?? 0;
    final balance = consumed - burned;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ENERGY BALANCE",
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BURNED",
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$burned kcal",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CONSUMED",
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$consumed kcal",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final total = (burned + consumed).toDouble();
                  if (total == 0) return const SizedBox.shrink();
                  final burnedWidth = (burned / total) * constraints.maxWidth;
                  return Row(
                    children: [
                      Container(
                        height: 12,
                        width: burnedWidth,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                      ),
                      Container(
                        height: 12,
                        width: constraints.maxWidth - burnedWidth,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            balance <= 0
                ? "Deficit: ${balance.abs()} kcal. Great for weight management!"
                : "Surplus: $balance kcal. Focus on activity to balance.",
            style: textTheme.bodySmall?.copyWith(
              color: balance <= 0 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendsCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required List<HealthMetricsLocal> last7Days,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.health_weekly_trends,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: last7Days.take(7).toList().reversed.map((m) {
              final dayLabel = DateFormat('E').format(m.date).substring(0, 1);
              final height = (m.steps ?? 0) / STEP_GOAL;
              return _buildBarDay(
                dayLabel,
                height.clamp(0.1, 1.0),
                colorScheme,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildTrendStat(
                AppLocalizations.of(context)!.health_avg_steps,
                NumberFormat('#,###').format(
                  last7Days.fold<int>(0, (sum, m) => sum + (m.steps ?? 0)) /
                      (last7Days.isEmpty ? 1 : last7Days.length),
                ),
                colorScheme,
                textTheme,
              ),
              const SizedBox(width: 20),
              _buildTrendStat(
                "STREAK",
                "${_calculateStreak(last7Days)} DAYS",
                colorScheme,
                textTheme,
              ),
              const Spacer(),
              _buildTrendStat(
                AppLocalizations.of(context)!.health_avg_sleep,
                "${(last7Days.fold<double>(0, (sum, m) => sum + (m.sleepHours ?? 0)) / (last7Days.isEmpty ? 1 : last7Days.length)).toStringAsFixed(1)}h",
                colorScheme,
                textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateStreak(List<HealthMetricsLocal> metrics) {
    int streak = 0;
    for (var m in metrics) {
      if ((m.steps ?? 0) >= STEP_GOAL) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Widget _buildBarDay(String label, double height, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 80 * height,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.2 + height * 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required HealthMetricsLocal latest,
    required double avgSteps,
    required List<HealthMetricsLocal> last7Days,
  }) {
    final avgSleep = last7Days.isEmpty
        ? 0.0
        : last7Days.fold(0.0, (sum, m) => sum + (m.sleepHours ?? 0)) /
              last7Days.length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.health_insights_title,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          _buildInsightItem(
            Icons.trending_up_rounded,
            Colors.green,
            (latest.steps ?? 0) > avgSteps
                ? AppLocalizations.of(context)!.health_insight_above_avg
                : AppLocalizations.of(context)!.health_insight_keep_pushing,
            (latest.steps ?? 0) > avgSteps
                ? AppLocalizations.of(context)!.health_insight_activity_higher
                : AppLocalizations.of(
                    context,
                  )!.health_insight_activity_lower(avgSteps.toInt()),
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.bolt_rounded,
            Colors.amber,
            AppLocalizations.of(context)!.health_efficiency,
            (latest.steps ?? 0) >= STEP_GOAL
                ? AppLocalizations.of(context)!.health_insight_goal_reached
                : AppLocalizations.of(context)!.health_insight_goal_percent(
                    ((latest.steps ?? 0) / STEP_GOAL * 100).toStringAsFixed(0),
                  ),
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.water_drop_rounded,
            Colors.cyan,
            AppLocalizations.of(context)!.health_hydration_title,
            (latest.waterGlasses ?? 0) >= WATER_GOAL / 250
                ? "Hydration goal reached! Excellent work."
                : "Drink ${(WATER_GOAL / 250 - (latest.waterGlasses ?? 0)).toInt()} more glasses to reach your goal.",
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.bedtime_rounded,
            Colors.deepPurpleAccent,
            "SLEEP QUALITY",
            avgSleep < 7
                ? "Your weekly average is under 7h. Try to rest earlier tonight."
                : "Consistent sleep detected. Your recovery is optimal.",
            colorScheme,
            textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    Color color,
    String title,
    String description,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightTrendCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    HealthBlock healthBlock,
  ) {
    final weightHistory = healthBlock.dailyWeightLast30Days.watch(context);
    final trend = healthBlock.weightTrend.watch(context);

    if (weightHistory.isEmpty) return const SizedBox.shrink();

    final dataPoints = weightHistory.values.toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.health_metrics_weight,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      trend >= 0
                          ? "+${trend.toStringAsFixed(1)} kg ↑"
                          : "${trend.toStringAsFixed(1)} kg ↓",
                      style: textTheme.bodySmall?.copyWith(
                        color: trend <= 0 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: SimpleLineChart(
              data: dataPoints,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTrendCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    HealthBlock healthBlock,
  ) {
    final waterHistory = healthBlock.dailyWaterLast30Days.watch(context);
    final avgWater = healthBlock.averageWater7d.watch(context);

    if (waterHistory.isEmpty) return const SizedBox.shrink();

    final dataPoints = waterHistory.values.map((v) => v.toDouble()).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: Colors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.health_metrics_water,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      "${AppLocalizations.of(context)!.health_avg}: ${avgWater.toStringAsFixed(0)} ml",
                      style: textTheme.bodySmall?.copyWith(
                        color: avgWater >= 2000 ? Colors.cyan : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: SimpleLineChart(data: dataPoints, color: Colors.cyan),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStat(
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HeartPulseIcon extends StatefulWidget {
  final Color color;
  const _HeartPulseIcon({required this.color});

  @override
  _HeartPulseIconState createState() => _HeartPulseIconState();
}

class _HeartPulseIconState extends State<_HeartPulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(Icons.favorite_rounded, color: widget.color, size: 24),
    );
  }
}
