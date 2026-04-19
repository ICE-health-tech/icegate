import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

class StepsDashboardPage extends StatelessWidget {
  const StepsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final healthMetricsDao = context.watch<HealthMetricsDAO>();
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Steps Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<HealthMetricsLocal>>(
        stream: healthMetricsDao.watchAllMetrics(personId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawMetrics = snapshot.data ?? [];
          if (rawMetrics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    size: 80,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No step history found',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try syncing your data from the activity tracker.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Aggregate metrics by day
          final Map<String, HealthMetricsLocal> aggregated = {};
          for (var m in rawMetrics) {
            final key =
                "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}";
            if (aggregated.containsKey(key)) {
              final existing = aggregated[key]!;
              aggregated[key] = existing.copyWith(
                steps: Value((existing.steps ?? 0) + (m.steps ?? 0)),
                caloriesBurned: Value(
                  (existing.caloriesBurned ?? 0) + (m.caloriesBurned ?? 0),
                ),
              );
            } else {
              aggregated[key] = m;
            }
          }

          final metrics = aggregated.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Weekly Overview Chart (Modern)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildModernWeeklyChart(
                    context,
                    metrics.take(7).toList().reversed.toList(),
                  ),
                ),
              ),

              // Statistics summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildStatsGrid(context, metrics),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 40)),

              // History list header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Detailed History',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.only(top: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final metric = metrics[index];
                    return _buildStepHistoryItem(context, metric);
                  }, childCount: metrics.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernWeeklyChart(
    BuildContext context,
    List<HealthMetricsLocal> recentMetrics,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxSteps = recentMetrics.fold<int>(
      1,
      (max, m) => (m.steps ?? 0) > max ? (m.steps ?? 0) : max,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY OVERVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: colorScheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recentMetrics.map((m) {
              final steps = m.steps ?? 0;
              final heightFactor = (steps / maxSteps).clamp(0.05, 1.0);
              final isToday = DateFormat('yyyy-MM-dd').format(m.date) == 
                              DateFormat('yyyy-MM-dd').format(DateTime.now());

              return Column(
                children: [
                  if (steps > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        steps > 999 ? '${(steps / 1000).toStringAsFixed(1)}k' : steps.toString(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                          color: isToday ? colorScheme.secondary : colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 15),
                  if (steps > 0 && steps == maxSteps)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TOP',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 140 * heightFactor,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isToday 
                          ? [colorScheme.secondary, colorScheme.secondary.withValues(alpha: 0.7)]
                          : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isToday ? [
                        BoxShadow(
                          color: colorScheme.secondary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    DateFormat('E').format(m.date).substring(0, 1),
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                      fontSize: 12,
                      color: isToday ? colorScheme.secondary : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    List<HealthMetricsLocal> metrics,
  ) {
    final totalSteps = metrics.fold<int>(0, (sum, m) => sum + (m.steps ?? 0));
    final avgSteps = metrics.isEmpty
        ? 0
        : (totalSteps / metrics.length).round();
    final totalDistance = totalSteps * 0.0008; // km

    return Row(
      children: [
        Expanded(
          child: _buildSmallStat(
            context,
            'Daily Average',
            avgSteps.toString(),
            'steps',
            Icons.auto_graph_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallStat(
            context,
            'Total Distance',
            totalDistance.toStringAsFixed(1),
            'km',
            Icons.explore_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(icon, size: 16, color: colorScheme.primary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepHistoryItem(
    BuildContext context,
    HealthMetricsLocal metric,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = DateFormat('yyyy-MM-dd').format(metric.date) == 
                    DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isToday ? colorScheme.primaryContainer.withValues(alpha: 0.3) : colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isToday 
            ? colorScheme.primary.withValues(alpha: 0.2) 
            : colorScheme.outlineVariant.withValues(alpha: 0.1)
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday ? colorScheme.primary : colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isToday ? Icons.today_rounded : Icons.calendar_today_rounded,
                  color: isToday ? colorScheme.onPrimary : colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? "Today" : DateFormat('EEEE').format(metric.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(metric.date),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (metric.steps ?? 0).toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: isToday ? colorScheme.primary : colorSurface(context, metric.steps ?? 0),
                  letterSpacing: -1,
                ),
              ),
              Text(
                'steps',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color colorSurface(BuildContext context, int steps) {
    if (steps > 10000) return Colors.green;
    if (steps > 5000) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.onSurface;
  }
}
