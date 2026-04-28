import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';

class OxygenSaturationPage extends StatefulWidget {
  const OxygenSaturationPage({super.key});

  @override
  State<OxygenSaturationPage> createState() => _OxygenSaturationPageState();
}

class _OxygenSaturationPageState extends State<OxygenSaturationPage> {
  final _selectedDate = signal<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    // Initial sync for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final healthBlock = context.read<HealthBlock>();
      healthBlock.syncOxygenSamples(_selectedDate.value);
    });
  }

  void _previousDay() {
    _selectedDate.value = _selectedDate.value.subtract(const Duration(days: 1));
    context.read<HealthBlock>().syncOxygenSamples(_selectedDate.value);
  }

  void _nextDay() {
    final nextDay = _selectedDate.value.add(const Duration(days: 1));
    if (nextDay.isBefore(DateTime.now())) {
      _selectedDate.value = nextDay;
      context.read<HealthBlock>().syncOxygenSamples(_selectedDate.value);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate.value) {
      _selectedDate.value = picked;
      context.read<HealthBlock>().syncOxygenSamples(_selectedDate.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthBlock = context.watch<HealthBlock>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDateValue = _selectedDate.watch(context);
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<OxygenSaturationLogData>>(
      stream: healthBlock.watchOxygenLogs(selectedDateValue),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final avgSaturation = logs.isEmpty
            ? 0.0
            : logs.map((l) => l.saturation).reduce((a, b) => a + b) /
                  logs.length;
        
        final latestLog = logs.isNotEmpty 
            ? (logs.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp))).first 
            : null;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
          body: Stack(
            children: [
              // Background Gradient
              if (isDark)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          const Color(0xFF2196F3).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              CustomScrollView(
                slivers: [
                  // Custom Header
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Oxy máu (SpO₂)',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Date Selector
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNavButton(Icons.chevron_left, _previousDay, isDark),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('EEEE, d MMM').format(selectedDateValue),
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (DateFormat('yyyy-MM-dd').format(selectedDateValue) ==
                                        DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                      Text(
                                        'Hôm nay',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _buildNavButton(Icons.chevron_right, _nextDay, isDark),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // Main Value Circle
                        _buildMainDisplay(avgSaturation, latestLog, isDark),

                        const SizedBox(height: 40),

                        // Info Section Label
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                "BIỂU ĐỒ TRONG NGÀY",
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Chart
                        _buildChart(isDark, logs),
                        
                        const SizedBox(height: 24),

                        // Summary Info
                        _buildSummaryCards(isDark, logs),
                        
                        const SizedBox(height: 32),

                        // Educational Card
                        _buildEducationalCard(isDark),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, bool isDark) {
    return IconButton(
      icon: Icon(
        icon,
        color: isDark ? Colors.white38 : Colors.grey.shade400,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildMainDisplay(double avg, OxygenSaturationLogData? latest, bool isDark) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: avg > 0 ? avg / 100 : 0,
              strokeWidth: 12,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                avg >= 95 ? Colors.blue : (avg >= 90 ? Colors.orange : Colors.red),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                avg > 0 ? avg.toStringAsFixed(0) : '--',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
              Text(
                '% SpO₂',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (latest != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Gần nhất: ${DateFormat('HH:mm').format(latest.timestamp)}',
                  style: TextStyle(
                    color: isDark ? Colors.blue.withValues(alpha: 0.6) : Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.blue.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin về SpO₂',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Độ bão hòa oxy trong máu (SpO₂) bình thường thường nằm trong khoảng 95-100%. Các phép đo này chỉ mang tính tham khảo và không thay thế cho tư vấn y tế chuyên nghiệp.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(bool isDark, List<OxygenSaturationLogData> logs) {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 24, left: 12, top: 10, bottom: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 80,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? Colors.grey[900]! : Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)}%',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const hours = [0, 4, 8, 12, 16, 20];
                  if (hours.contains(value.toInt())) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${value.toInt()}:00',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 5 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _getAggregatedBarGroups(logs),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 95,
                color: Colors.blue.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(color: Colors.blue, fontSize: 10),
                  labelResolver: (line) => 'Mục tiêu 95%',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getAggregatedBarGroups(List<OxygenSaturationLogData> logs) {
    final Map<int, List<double>> hourlyData = {};
    for (var log in logs) {
      final hour = log.timestamp.hour;
      hourlyData.putIfAbsent(hour, () => []).add(log.saturation);
    }

    return List.generate(24, (hour) {
      final hourLogs = hourlyData[hour] ?? [];
      final avg = hourLogs.isEmpty ? 0.0 : hourLogs.reduce((a, b) => a + b) / hourLogs.length;

      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: avg > 0 ? avg : 0,
            color: avg >= 95 ? Colors.blue : (avg >= 90 ? Colors.orange : (avg > 0 ? Colors.red : Colors.transparent)),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCards(bool isDark, List<OxygenSaturationLogData> logs) {
    if (logs.isEmpty) return const SizedBox();

    final saturations = logs.map((e) => e.saturation).toList();
    final min = saturations.reduce((a, b) => a < b ? a : b);
    final max = saturations.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Thấp nhất',
              '${min.toStringAsFixed(0)}%',
              Icons.trending_down_rounded,
              Colors.orange,
              isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Cao nhất',
              '${max.toStringAsFixed(0)}%',
              Icons.trending_up_rounded,
              Colors.green,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
