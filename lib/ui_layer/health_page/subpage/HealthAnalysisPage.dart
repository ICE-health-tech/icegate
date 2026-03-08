import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

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
            'Health Analysis',
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
                "No health data found",
                Icons.health_and_safety_outlined,
              );
            }

            // --- DATA ANALYSIS ---
            final now = DateTime.now();
            // Find today's record (it should be first in DESC order, but let's be safe)
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
                : last7Days.fold(0.0, (sum, m) => sum + (m.steps ?? 0)) /
                      last7Days.length;

            double consistency = 0.0;
            if (last7Days.length > 1) {
              double variance =
                  last7Days.fold(
                    0.0,
                    (sum, m) => sum + math.pow((m.steps ?? 0) - avgSteps, 2),
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
                        ? "Active"
                        : "Normal",
                    intensity: (latest.exerciseMinutes ?? 0) > 45
                        ? "High"
                        : (latest.exerciseMinutes ?? 0) > 20
                        ? "Optimal"
                        : "Low",
                  ),
                  const SizedBox(height: 24),

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
                'PERFORMANCE ANALYSIS',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildAnalysisGridItem(
                context,
                'Efficiency',
                '${(efficiency * 100).toStringAsFixed(0)}%',
                Icons.bolt_rounded,
                Colors.amber,
              ),
              _buildAnalysisGridItem(
                context,
                'Consistency',
                consistency > 0.8
                    ? 'High'
                    : consistency > 0.5
                    ? 'Medium'
                    : 'Low',
                Icons.repeat_rounded,
                Colors.green,
              ),
              _buildAnalysisGridItem(
                context,
                'Metabolism',
                metabolism,
                Icons.speed_rounded,
                Colors.orange,
              ),
              _buildAnalysisGridItem(
                context,
                'Intensity',
                intensity,
                Icons.fitness_center_rounded,
                Colors.blue,
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
            'ACTIVITY BALANCE',
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
                  'Steps': stepsWeight.toDouble(),
                  'Exercise': exerciseWeight.toDouble(),
                  'Focus': focusWeight.toDouble(),
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
                      'Activity Balance',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stepsWeight > 60
                          ? 'You are moving a lot! Great step count.'
                          : 'Your workout distribution looks balanced today.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLegendRow(
                      colorScheme.primary,
                      'Steps',
                      '$stepsWeight%',
                      textTheme,
                    ),
                    const SizedBox(height: 4),
                    _buildLegendRow(
                      colorScheme.secondary,
                      'Exercise',
                      '$exerciseWeight%',
                      textTheme,
                    ),
                    const SizedBox(height: 4),
                    _buildLegendRow(
                      colorScheme.tertiary,
                      'Other',
                      '$otherWeight%',
                      textTheme,
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

  Widget _buildLegendRow(
    Color color,
    String label,
    String value,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendsCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required List<HealthMetricsLocal> last7Days,
  }) {
    final reversedList = last7Days.reversed.toList();
    final maxSteps = last7Days.isEmpty
        ? 1.0
        : last7Days
              .map((m) => m.steps ?? 0)
              .reduce((a, b) => math.max(a, b))
              .toDouble();

    final avgSteps = last7Days.isEmpty
        ? 0.0
        : last7Days.fold(0.0, (sum, m) => sum + (m.steps ?? 0)) /
              last7Days.length;
    final avgSleep = last7Days.isEmpty
        ? 0.0
        : last7Days.fold(0.0, (sum, m) => sum + (m.sleepHours ?? 0.0)) /
              last7Days.length;
    final avgHR = last7Days.isEmpty
        ? 0.0
        : last7Days.fold(0.0, (sum, m) => sum + (m.heartRate ?? 0)) /
              last7Days.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY TRENDS',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendStat(
                'Avg Steps',
                '${avgSteps.toInt()}',
                colorScheme,
                textTheme,
              ),
              _buildTrendStat(
                'Avg Sleep',
                '${avgSleep.toStringAsFixed(1)}h',
                colorScheme,
                textTheme,
              ),
              _buildTrendStat(
                'Avg HR',
                '${avgHR.toInt()} bpm',
                colorScheme,
                textTheme,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart based on real data
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: reversedList.map((m) {
              final label = [
                'M',
                'T',
                'W',
                'T',
                'F',
                'S',
                'S',
              ][m.date.weekday - 1];
              final ratio = ((m.steps ?? 0) / maxSteps).clamp(0.1, 1.0);
              return _buildBarDay(label, ratio, colorScheme);
            }).toList(),
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
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'INSIGHTS',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.trending_up_rounded,
            Colors.green,
            (latest.steps ?? 0) > avgSteps ? 'Above Average' : 'Keep Pushing',
            (latest.steps ?? 0) > avgSteps
                ? 'Your activity levels are higher than your 7-day average.'
                : 'Try to take a short walk to reach your daily average of ${avgSteps.toInt()} steps.',
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.bolt_rounded,
            Colors.amber,
            'Efficiency',
            (latest.steps ?? 0) >= STEP_GOAL
                ? 'Goal reached! You are highly efficient today.'
                : 'You are at ${((latest.steps ?? 0) / STEP_GOAL * 100).toStringAsFixed(0)}% of your daily goal.',
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.water_drop_rounded,
            Colors.cyan,
            'Hydration',
            'You\'re on track with your daily water intake goal!',
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

  Widget _buildAnalysisGridItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
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
}
