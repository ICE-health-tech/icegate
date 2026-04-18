import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:intl/intl.dart';

class MoodTrendsChart extends StatelessWidget {
  final List<MindLogData> logs;

  const MoodTrendsChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    // Sort logs by date
    final sortedLogs = List<MindLogData>.from(logs)
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    // Get last 7 days or all if less
    final recentLogs = sortedLogs.length > 14 
        ? sortedLogs.sublist(sortedLogs.length - 14) 
        : sortedLogs;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 180, // Provide finite constraints for fl_chart
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recentLogs.length) return const SizedBox.shrink();
                  if (index % 3 != 0 && index != recentLogs.length - 1) return const SizedBox.shrink();
                  
                  final date = recentLogs[index].logDate;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: TextStyle(
                        fontSize: 9,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                reservedSize: 22,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0.5,
          maxY: 5.5,
          lineBarsData: [
            LineChartBarData(
              spots: recentLogs.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.moodScore.toDouble());
              }).toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary,
                ],
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: colorScheme.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.2),
                    colorScheme.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
