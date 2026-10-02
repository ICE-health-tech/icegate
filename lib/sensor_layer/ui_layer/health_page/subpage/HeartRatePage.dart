import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import 'package:intl/intl.dart';

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({super.key});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  int currentHeartRate = 0;
  final List<double?> chartData = List.generate(
    288,
    (_) => null,
    growable: true,
  );
  int _rawMax = 0;
  int _rawMin = 0;
  bool _isLoading = true;
  StreamSubscription? _hrLogsSubscription;
  String _selectedTab = 'Day';
  String _selectedSubTab = 'Heart rate';

  @override
  void initState() {
    super.initState();
    // Initial load and listen to signals
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupHrSubscription();
      // Start periodic "real-time" polling while on this page
      context.read<HealthBlock>().startRealtimeSync(
        interval: const Duration(seconds: 30),
      );
    });
  }

  void _setupHrSubscription() {
    final dao = context.read<HealthLogsDAO>();
    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
    if (personId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _hrLogsSubscription = dao
        .watchDailyHeartRateLogs(personId, DateTime.now())
        .listen(
          (logs) {
            if (mounted) {
              _processLogs(logs);
            }
          },
          onError: (e) {
            debugPrint("HeartRatePage: Error in HR stream: $e");
            if (mounted) setState(() => _isLoading = false);
          },
        );

    // Fallback: If no data after 5 seconds, stop loading
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        debugPrint("HeartRatePage: Loading timeout reached.");
        setState(() => _isLoading = false);
      }
    });
  }

  void _processLogs(List<HeartRateLogData> logs) {
    if (logs.isEmpty) {
      setState(() {
        _isLoading = false;
        currentHeartRate = 0;
        chartData.fillRange(0, 288, null);
        _rawMax = 0;
        _rawMin = 0;
      });
      return;
    }

    // 1. Calculate raw stats for absolute accuracy
    int tempMax = 0;
    int tempMin = 999;
    for (var log in logs) {
      if (log.bpm > tempMax) tempMax = log.bpm;
      if (log.bpm < tempMin) tempMin = log.bpm;
    }

    final sortedLogs = List<HeartRateLogData>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 2. Build time-normalized chart data (24 hours / 5 minutes = 288 points)
    final List<double?> newChartData = List.filled(288, null);

    for (var log in sortedLogs) {
      final minutesSinceMidnight =
          log.timestamp.hour * 60 + log.timestamp.minute;
      final bucketIndex = (minutesSinceMidnight ~/ 5).clamp(0, 287);

      // Preservation strategy: If multiple readings exist, take the HIGHEST
      // to ensure spikes are visible on the line chart.
      final currentBucketValue = newChartData[bucketIndex];
      if (currentBucketValue == null || log.bpm > currentBucketValue) {
        newChartData[bucketIndex] = log.bpm.toDouble();
      }
    }

    try {
      setState(() {
        currentHeartRate = sortedLogs.last.bpm;
        chartData.clear();
        chartData.addAll(newChartData);
        _rawMax = tempMax;
        _rawMin = tempMin == 999 ? 0 : tempMin;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error updating HR UI: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    context.read<HealthBlock>().stopRealtimeSync();
    _hrLogsSubscription?.cancel();
    super.dispose();
  }

  int get averageHeartRate {
    final validData = chartData.whereType<double>();
    if (validData.isEmpty) return 0;
    return (validData.reduce((a, b) => a + b) / validData.length).round();
  }

  int get maxHeartRate => _rawMax;
  int get minHeartRate => _rawMin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Selector (Day, Week, Month, Year)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['Day', 'Week', 'Month', 'Year'].map((tab) {
                            final isSelected = _selectedTab == tab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = tab),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.surfaceContainerHighest
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      tab,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: isSelected
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date Display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('MMM d (EEE)').format(DateTime.now()),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Range/Value Display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  chartData.whereType<double>().isEmpty
                                      ? '--'
                                      : '$minHeartRate–$maxHeartRate',
                                  style: textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'bpm',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Heart rate range',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Chart Area
                      Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Stack(
                          children: [
                            // Grid lines (simplified)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                5,
                                (index) => Divider(
                                  height: 1,
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            // Axis labels (simplified)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: ['220', '170', '120', '70', '20'].map(
                                  (label) {
                                    return Text(
                                      label,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                            // The actual chart
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 25,
                                bottom: 20,
                              ),
                              child: chartData.whereType<double>().length >= 2
                                  ? SimpleLineChart(
                                      data: chartData,
                                      color: Colors.redAccent,
                                      height: 180,
                                    )
                                  : Center(
                                      child: Text(
                                        'No data for today',
                                        style: textTheme.bodySmall,
                                      ),
                                    ),
                            ),
                            // Time labels
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 30,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: ['00:00', '06:00', '12:00', '18:00']
                                    .map((time) {
                                      return Text(
                                        time,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                          fontSize: 10,
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sub-tabs (Heart rate, HRV)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: ['Heart rate', 'HRV'].map((tab) {
                              final isSelected = _selectedSubTab == tab;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedSubTab = tab),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.surface
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                      border: isSelected
                                          ? Border.all(
                                              color: colorScheme.outlineVariant
                                                  .withValues(alpha: 0.2),
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        tab,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            _healthStatItem(
                              context,
                              'Heart rate range',
                              chartData.whereType<double>().isEmpty
                                  ? '--'
                                  : '$minHeartRate–$maxHeartRate',
                              'bpm',
                            ),
                            _healthStatItem(
                              context,
                              'Resting heart rate',
                              minHeartRate > 0 ? minHeartRate.toString() : '--',
                              'bpm',
                            ),
                            _healthStatItem(
                              context,
                              'High heart rate alert',
                              '--',
                              'times',
                            ),
                            _healthStatItem(
                              context,
                              'Low heart rate alert',
                              '--',
                              'times',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _healthStatItem(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
