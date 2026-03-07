import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ExerciseAnalysisPage extends StatelessWidget {
  const ExerciseAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final healthLogsDao = context.watch<HealthLogsDAO>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Exercise Analysis',
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
      body: StreamBuilder<List<ExerciseLogData>>(
        stream: healthLogsDao.watchDailyExerciseLogs(
          Supabase.instance.client.auth.currentUser?.id ?? "",
          DateTime.now().subtract(const Duration(days: 30)),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 60,
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exercise history found',
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
              // Weekly Duration Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildDurationChart(context, logs),
                ),
              ),

              // Distribution & Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildIntensityDistribution(context, logs),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActivityTypeDistribution(context, logs),
                      ),
                    ],
                  ),
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
                  final log = logs[logs.length - 1 - index];
                  return _buildExerciseHistoryItem(context, log);
                }, childCount: logs.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDurationChart(BuildContext context, List<ExerciseLogData> logs) {
    // Group logs by date for the last 7 days
    final Map<String, double> dailyMinutes = {};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      dailyMinutes[dateStr] = 0;
    }

    for (var log in logs) {
      final dateStr = DateFormat('yyyy-MM-dd').format(log.timestamp);
      if (dailyMinutes.containsKey(dateStr)) {
        dailyMinutes[dateStr] = dailyMinutes[dateStr]! + log.durationMinutes;
      }
    }

    final data = dailyMinutes.values.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY MINUTES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.orange,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          SimpleLineChart(data: data, color: Colors.orange, height: 120),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dailyMinutes.keys.map((dateStr) {
              final date = DateFormat('yyyy-MM-dd').parse(dateStr);
              return Text(
                DateFormat('E').format(date).substring(0, 1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityDistribution(
    BuildContext context,
    List<ExerciseLogData> logs,
  ) {
    final Map<String, double> intensityCount = {
      'low': 0,
      'medium': 0,
      'high': 0,
    };

    for (var log in logs) {
      final intensity = log.intensity.toLowerCase();
      if (intensityCount.containsKey(intensity)) {
        intensityCount[intensity] = intensityCount[intensity]! + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Intensity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SimplePieChart(
            data: intensityCount,
            colors: const [Colors.green, Colors.orange, Colors.red],
            size: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTypeDistribution(
    BuildContext context,
    List<ExerciseLogData> logs,
  ) {
    final Map<String, double> typeCount = {};

    for (var log in logs) {
      typeCount[log.type] = (typeCount[log.type] ?? 0) + 1;
    }

    // Sort and take top 3
    final sortedTypes = typeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<String, double> topTypes = Map.fromEntries(sortedTypes.take(3));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Type',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SimplePieChart(
            data: topTypes,
            colors: const [Colors.blue, Colors.purple, Colors.teal],
            size: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHistoryItem(BuildContext context, ExerciseLogData log) {
    final colorScheme = Theme.of(context).colorScheme;
    Color intensityColor;
    switch (log.intensity.toLowerCase()) {
      case 'high':
        intensityColor = Colors.red;
        break;
      case 'low':
        intensityColor = Colors.green;
        break;
      default:
        intensityColor = Colors.orange;
    }

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
                log.type,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat('MMM d, HH:mm').format(log.timestamp),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: intensityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.intensity.toUpperCase(),
                  style: TextStyle(
                    color: intensityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${log.durationMinutes}m',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
