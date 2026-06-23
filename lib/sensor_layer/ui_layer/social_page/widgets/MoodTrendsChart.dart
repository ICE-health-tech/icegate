import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindLogInsights.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:intl/intl.dart';

class MoodTrendsChart extends StatelessWidget {
  final List<MindLogData> logs;

  /// When true, averages mood per calendar day before plotting.
  final bool groupByDay;

  const MoodTrendsChart({
    super.key,
    required this.logs,
    this.groupByDay = false,
  });

  static const double _chartHeight = 200;

  /// Absorbs horizontal drags so parent [TabBarView] / page swipes don't fire.
  static Widget _lockHorizontalSwipe(Widget child) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(),
          (HorizontalDragGestureRecognizer instance) {
            instance
              ..onStart = (_) {}
              ..onUpdate = (_) {}
              ..onEnd = (_) {};
          },
        ),
      },
      child: child,
    );
  }

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

  static String _axisLabel(MindLogData log, {required bool groupByDay}) {
    final local = log.logDate.toLocal();
    if (groupByDay) {
      return DateFormat('MM/dd').format(local);
    }
    final now = DateTime.now();
    final dayLog = DateTime(local.year, local.month, local.day);
    final dayNow = DateTime(now.year, now.month, now.day);
    if (dayLog == dayNow) {
      return DateFormat('HH:mm').format(log.createdAt.toLocal());
    }
    return DateFormat('MM/dd').format(local);
  }

  static int _moodScoreFromY(double y) => y.round().clamp(1, 6);

  /// fl_chart tints the whole stroke from one [gradient]; per-segment bars + dot layer
  /// keeps each day’s mood color visible.
  static List<LineChartBarData> _buildMoodColoredBars({
    required List<FlSpot> spots,
    required int n,
    required bool isDark,
    required Color mindAccent,
    required List<double> moodY,
  }) {
    final bars = <LineChartBarData>[];

    if (n >= 2) {
      for (var i = 0; i < n - 1; i++) {
        bars.add(
          LineChartBarData(
            spots: [spots[i], spots[i + 1]],
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: mindMoodAccent(_moodScoreFromY(moodY[i])),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    final avgY = moodY.reduce((a, b) => a + b) / n;
    bars.add(
      LineChartBarData(
        spots: spots,
        color: Colors.transparent,
        barWidth: 0,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final c = mindMoodAccent(_moodScoreFromY(spot.y));
            return FlDotCirclePainter(
              radius: 7,
              color: c,
              strokeWidth: 2,
              strokeColor: Colors.white.withValues(alpha: isDark ? 0.88 : 0.95),
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                mindMoodColorAt(avgY).withValues(alpha: 0.18),
                mindAccent.withValues(alpha: isDark ? 0.1 : 0.06),
              ),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );

    return bars;
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    final List<MindLogData> sortedLogs;
    final List<double> sortedMoodY;

    if (groupByDay) {
      sortedLogs = MindLogInsights.dailyMoodSeries(logs);
      sortedMoodY = MindLogInsights.dailyMoodAverages(logs);
    } else {
      sortedLogs = List<MindLogData>.from(logs)
        ..sort((a, b) => a.logDate.compareTo(b.logDate));
      sortedMoodY = sortedLogs.map((l) => l.moodScore.toDouble()).toList();
    }

    final window = MindLogInsights.moodChartDays;
    final recentLogs = sortedLogs.length > window
        ? sortedLogs.sublist(sortedLogs.length - window)
        : sortedLogs;
    final recentMoodY = sortedMoodY.length > window
        ? sortedMoodY.sublist(sortedMoodY.length - window)
        : sortedMoodY;

    final n = recentLogs.length;
    final labelAt = _labelIndices(n);
    final spots = List<FlSpot>.generate(
      n,
      (i) => FlSpot(i.toDouble(), recentMoodY[i]),
    );

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mindAccent = HealthMetricColors.homePillarAccent('mind');
    final glassBorder = HealthMetricColors.glassBorder(
      colorScheme,
      isDark: isDark,
      darkAlpha: 0.08,
    );
    final axisLabelColor = isDark
        ? HealthMetricColors.textEtchedStrong
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.78);
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : colorScheme.outlineVariant.withValues(alpha: 0.14);

    return _lockHorizontalSwipe(
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: _chartHeight,
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                    mindAccent.withValues(alpha: isDark ? 0.14 : 0.08),
                    HealthMetricColors.glassFill(
                      colorScheme,
                      isDark: isDark,
                      darkAlpha: 0.04,
                    ),
                  ),
                  HealthMetricColors.glassFill(
                    colorScheme,
                    isDark: isDark,
                    darkAlpha: 0.025,
                  ),
                  Colors.transparent,
                ],
                stops: const [0, 0.38, 1],
              ),
              border: Border.all(color: glassBorder),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x000F1E).withValues(
                    alpha: isDark ? 0.24 : 0.07,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                  child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: -0.35,
                  maxX: (n - 1 + 0.35).toDouble().clamp(0, double.infinity),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: gridColor,
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
                              _axisLabel(recentLogs[i], groupByDay: groupByDay),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.35,
                                color: axisLabelColor,
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
                  maxY: 6.5,
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: _buildMoodColoredBars(
                    spots: spots,
                    n: n,
                    isDark: isDark,
                    mindAccent: mindAccent,
                    moodY: recentMoodY,
                  ),
                ),
              ),
                ),
                // Ice top-edge highlight (uniform border required for radius).
                Positioned(
                  top: 0,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            HealthMetricColors.borderBright.withValues(
                              alpha: isDark ? 0.28 : 0.34,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
