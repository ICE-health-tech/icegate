import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/HealthInsightsRemoteService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cloud-backed daily steps trend (Supabase RPC). Hidden when offline / no data.
class HealthRemoteTrendCard extends StatefulWidget {
  const HealthRemoteTrendCard({super.key, this.days = 14});

  final int days;

  @override
  State<HealthRemoteTrendCard> createState() => _HealthRemoteTrendCardState();
}

class _HealthRemoteTrendCardState extends State<HealthRemoteTrendCard> {
  late final Future<List<HealthTrendPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = HealthInsightsRemoteService().fetchStepsTrend(days: widget.days);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (Supabase.instance.client.auth.currentSession == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<HealthTrendPoint>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _skeleton(colorScheme, textTheme);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final points = snapshot.data!;
        if (points.isEmpty) {
          return const SizedBox.shrink();
        }

        final maxSteps = points
            .map((p) => p.steps)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 1 << 30);
        final spots = <FlSpot>[];
        for (var i = 0; i < points.length; i++) {
          spots.add(FlSpot(i.toDouble(), points[i].steps.toDouble()));
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cloud · steps',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${widget.days}d',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxSteps * 1.1,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxSteps > 0 ? maxSteps / 4 : 1000,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: maxSteps > 0 ? maxSteps / 4 : 1000,
                          getTitlesWidget: (v, m) => Text(
                            v.toInt().toString(),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (i, m) {
                            final idx = i.toInt();
                            if (idx < 0 || idx >= points.length) {
                              return const SizedBox.shrink();
                            }
                            if (points.length > 7 && idx % 2 == 1) {
                              return const SizedBox.shrink();
                            }
                            final d = points[idx].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${d.month}/${d.day}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        left: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: colorScheme.primary,
                        belowBarData: BarAreaData(
                          show: true,
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (t) => colorScheme.inverseSurface,
                        getTooltipItems: (touched) {
                          return touched.map((e) {
                            final x = e.x.toInt();
                            if (x < 0 || x >= points.length) {
                              return null;
                            }
                            final p = points[x];
                            return LineTooltipItem(
                              '${p.date.month}/${p.date.day}\n'
                              '${p.steps} steps',
                              TextStyle(
                                color: colorScheme.onInverseSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).whereType<LineTooltipItem>().toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _skeleton(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cloud · steps',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
