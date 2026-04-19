import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
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
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colorScheme.onSurface,
              size: 22,
            ),
            onPressed: () => WidgetNavigatorAction.smartPop(context),
          ),
          title: Text(
            AppLocalizations.of(context)!.health_analysis_title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
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
        body: StreamBuilder<List<HealthMetricsLocal>>(
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
            final efficiency = ((latest.steps ?? 0) / STEP_GOAL).clamp(0.0, 1.0);

            // Consistency (Average variation in last 7 days)
            double avgSteps = last7Days.isEmpty
                ? 0.0
                : last7Days.fold(0.0, (sum, m) => sum + (m.steps ?? 0)) /
                    last7Days.length;

            double consistency = 0.0;
            if (last7Days.length > 1) {
              double variance = last7Days.fold(
                    0.0,
                    (sum, m) => sum + math.pow((m.steps ?? 0) - avgSteps, 2),
                  ) /
                  last7Days.length;
              consistency = (1.0 -
                      (math.sqrt(variance) / (avgSteps > 0 ? avgSteps : 1.0)))
                  .clamp(0.0, 1.0);
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        ? AppLocalizations.of(context)!.health_metabolism_active
                        : AppLocalizations.of(context)!
                            .health_metabolism_normal,
                    intensity: (latest.exerciseMinutes ?? 0) > 45
                        ? AppLocalizations.of(context)!.health_intensity_high
                        : AppLocalizations.of(context)!
                            .health_intensity_moderate,
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

                  // --- WEEKLY TRENDS SECTION ---
                  _buildWeeklyTrendsCard(
                    context,
                    colorScheme,
                    textTheme,
                    last7Days: last7Days,
                  ),
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
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
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
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTrendStat(
                  AppLocalizations.of(context)!.health_consistency,
                  consistency > 0.8
                      ? AppLocalizations.of(context)!.health_consistency_high
                      : consistency > 0.5
                          ? AppLocalizations.of(context)!
                              .health_consistency_medium
                          : AppLocalizations.of(context)!
                              .health_consistency_low,
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
                color: colorScheme.outlineVariant.withOpacity(0.5),
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
    final stepsPoints = (latest.steps ?? 0) / STEPS_PER_POINT;
    final exercisePoints = (latest.exerciseMinutes ?? 0) / EXERCISE_PER_POINT;
    final focusPoints = (latest.focusMinutes ?? 0) / FOCUS_MINUTES_PER_POINT;
    final waterPoints = (latest.waterGlasses ?? 0) >= WATER_GOAL
        ? WATER_BONUS_POINTS.toDouble()
        : 0.0;

    final totalPoints =
        stepsPoints + exercisePoints + focusPoints + waterPoints;

    final stepsWeight = totalPoints > 0
        ? (stepsPoints / totalPoints * 100).round()
        : 0;
    final exerciseWeight = totalPoints > 0
        ? (exercisePoints / totalPoints * 100).round()
        : 0;
    final focusWeight = totalPoints > 0
        ? (focusPoints / totalPoints * 100).round()
        : 0;
    final otherWeight = (100 - stepsWeight - exerciseWeight - focusWeight)
        .clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
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
              SimplePieChart(
                data: {
                  AppLocalizations.of(context)!.health_metrics_steps:
                      stepsWeight.toDouble(),
                  AppLocalizations.of(context)!.health_metrics_exercise:
                      exerciseWeight.toDouble(),
                  AppLocalizations.of(context)!.health_metrics_focus:
                      focusWeight.toDouble(),
                  'Other': otherWeight.toDouble(),
                },
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                  colorScheme.tertiary,
                ],
                size: 80,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.steps! > 8000
                          ? AppLocalizations.of(context)!.health_balance_moving_much
                          : AppLocalizations.of(context)!.health_balance_optimal,
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
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
              return _buildBarDay(dayLabel, height.clamp(0.1, 1.0), colorScheme);
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

  Widget _buildBarDay(String label, double height, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 80 * height,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.2 + height * 0.6),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
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
                : AppLocalizations.of(context)!
                    .health_insight_activity_lower(avgSteps.toInt()),
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
            AppLocalizations.of(context)!.health_hydration_track_msg,
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
            color: color.withOpacity(0.1),
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
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
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

    final dataPoints = weightHistory.values.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
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
                  color: colorScheme.primary.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
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
                  color: Colors.cyan.withOpacity(0.1),
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
            child: SimpleLineChart(
              data: dataPoints,
              color: Colors.cyan,
            ),
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
            color: colorScheme.onSurfaceVariant.withOpacity(0.2),
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
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
