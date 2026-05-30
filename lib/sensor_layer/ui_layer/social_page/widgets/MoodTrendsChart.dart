import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:intl/intl.dart';

class MoodTrendsChart extends StatelessWidget {
  final List<MindLogData> logs;

  const MoodTrendsChart({super.key, required this.logs});

  static const double _chartHeight = 200;

  /// Which x-indices get a bottom label (max ~4 labels to avoid overlap).
  static Set<int> _labelIndices(int n) {
    if (n <= 0) return {};
    if (n == 1) return {0};
    if (n == 2) return {0, 1};
    if (n == 3) return {0, 1, 2};
    if (n == 4) return {0, 1, 2, 3};
    return {
      0,
      ((n - 1) * 0.33).round(),
      ((n - 1) * 0.67).round(),
      n - 1,
    };
  }

  static String _axisLabel(MindLogData log) {
    final local = log.createdAt.toLocal();
    final now = DateTime.now();
    final dayLog = DateTime(local.year, local.month, local.day);
    final dayNow = DateTime(now.year, now.month, now.day);
    if (dayLog == dayNow) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('MM/dd').format(local);
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    final sortedLogs = List<MindLogData>.from(logs)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final recentLogs = sortedLogs.length > 14
        ? sortedLogs.sublist(sortedLogs.length - 14)
        : sortedLogs;

    final n = recentLogs.length;
    final labelAt = _labelIndices(n);
    final spots = recentLogs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.moodScore.toDouble());
    }).toList();

    final accentColors = recentLogs.map((l) => mindMoodAccent(l.moodScore)).toList();
    final lineGradientColors = accentColors.length >= 2
        ? accentColors
        : [accentColors.first, accentColors.first];

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: _chartHeight,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: LineChart(
          LineChartData(
            clipData: const FlClipData.all(),
            minX: 0,
            maxX: (n - 1).toDouble().clamp(0, double.infinity),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= n || !labelAt.contains(i)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _axisLabel(recentLogs[i]),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.2,
                          color: colorScheme.onSurface.withValues(
                            alpha: 0.88,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: 0.5,
            maxY: 5.5,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                gradient: LinearGradient(colors: lineGradientColors),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final idx = spot.x.round().clamp(0, n - 1);
                    final c = mindMoodAccent(recentLogs[idx].moodScore);
                    return FlDotCirclePainter(
                      radius: 5,
                      color: c,
                      strokeWidth: 2,
                      strokeColor: Colors.white.withValues(alpha: 0.85),
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      mindMoodSoft(recentLogs.last.moodScore),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
