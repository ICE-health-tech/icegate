import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StepsDashboardPage extends StatelessWidget {
  const StepsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final healthMetricsDao = context.watch<HealthMetricsDAO>();
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
        stream: healthMetricsDao.watchAllMetrics(
          Supabase.instance.client.auth.currentUser?.id ?? "",
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final metrics = snapshot.data ?? [];
          if (metrics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    size: 60,
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No step history found',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Weekly Overview Chart (Simple)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildSimpleChart(
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

              const SliverPadding(padding: EdgeInsets.only(top: 32)),

              // History list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8,
                  ),
                  child: Text(
                    'History',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final metric = metrics[index];
                  return _buildStepHistoryItem(context, metric);
                }, childCount: metrics.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleChart(
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
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST 7 DAYS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recentMetrics.map((m) {
              final heightFactor = ((m.steps ?? 0) / maxSteps).clamp(0.1, 1.0);
              return Column(
                children: [
                  Container(
                    width: 25,
                    height: 120 * heightFactor,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('E').format(m.date).substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
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
            'Average',
            avgSteps.toString(),
            'steps',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSmallStat(
            context,
            'Total Dist.',
            totalDistance.toStringAsFixed(1),
            'km',
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
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(metric.date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(metric.date),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.run_circle, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Text(
                (metric.steps ?? 0).toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
