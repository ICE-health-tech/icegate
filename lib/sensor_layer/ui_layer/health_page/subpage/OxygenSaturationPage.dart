import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kSpo2TargetPrefsKey = 'health_spo2_target_percent';

class OxygenSaturationPage extends StatefulWidget {
  const OxygenSaturationPage({super.key});

  @override
  State<OxygenSaturationPage> createState() => _OxygenSaturationPageState();
}

class _OxygenSaturationPageState extends State<OxygenSaturationPage> {
  final _selectedDate = signal<DateTime>(DateTime.now());
  int _spo2Target = 95;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final t = p.getInt(_kSpo2TargetPrefsKey) ?? 95;
      if (!mounted) return;
      setState(() => _spo2Target = t.clamp(90, 100));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final healthBlock = context.read<HealthBlock>();
      healthBlock.syncOxygenSamples(_selectedDate.value);
    });
  }

  Future<void> _persistTarget(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSpo2TargetPrefsKey, value);
  }

  Future<void> _showTargetEditor(AppLocalizations l10n) async {
    int temp = _spo2Target;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.health_spo2_target_dialog_title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$temp%',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Slider(
                    min: 90,
                    max: 100,
                    divisions: 10,
                    value: temp.toDouble(),
                    label: '$temp%',
                    onChanged: (v) =>
                        setDialogState(() => temp = v.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.health_spo2_save),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved == true && mounted) {
      setState(() => _spo2Target = temp.clamp(90, 100));
      await _persistTarget(_spo2Target);
    }
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
    if (!context.mounted) return;
    if (picked != null && picked != _selectedDate.value) {
      _selectedDate.value = picked;
      context.read<HealthBlock>().syncOxygenSamples(_selectedDate.value);
    }
  }

  Color _ringColor(double v, int target, bool isDark) {
    if (v <= 0) {
      return isDark ? Colors.white24 : Colors.grey;
    }
    if (v >= target) return Colors.blue;
    if (v >= target - 3) return Colors.orange;
    return Colors.red;
  }

  String _motivationFor(AppLocalizations l10n, double v, int target) {
    if (v <= 0) return l10n.health_spo2_motivation_empty;
    if (v >= 98) return l10n.health_spo2_motivation_peak;
    if (v >= 96) return l10n.health_spo2_motivation_high;
    if (v >= target) return l10n.health_spo2_motivation_on_target;
    if (v >= target - 3) return l10n.health_spo2_motivation_near;
    return l10n.health_spo2_motivation_low;
  }

  @override
  Widget build(BuildContext context) {
    final healthLogsDAO = context.watch<HealthLogsDAO>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDateValue = _selectedDate.watch(context);
    final colorScheme = Theme.of(context).colorScheme;
    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('EEEE, d MMM', localeName);

    return StreamBuilder<List<OxygenSaturationLogData>>(
      stream: personId.isEmpty
          ? const Stream.empty()
          : healthLogsDAO.watchDailyOxygenLogs(personId, selectedDateValue),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final avgSaturation = logs.isEmpty
            ? 0.0
            : logs.map((l) => l.saturation).reduce((a, b) => a + b) /
                  logs.length;

        final latestLog = logs.isNotEmpty
            ? (logs.toList()
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
                  .first
            : null;

        final primary =
            (latestLog != null ? latestLog.saturation : avgSaturation);

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0A0A0A)
              : const Color(0xFFF8F9FA),
          body: Stack(
            children: [
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
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        l10n.health_spo2_page_title,
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
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNavButton(
                                Icons.chevron_left,
                                _previousDay,
                                isDark,
                              ),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Column(
                                  children: [
                                    Text(
                                      dateFormat.format(selectedDateValue),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(selectedDateValue) ==
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(DateTime.now()))
                                      Text(
                                        l10n.health_spo2_today,
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _buildNavButton(
                                Icons.chevron_right,
                                _nextDay,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Material(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showTargetEditor(l10n),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag_rounded,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        l10n.health_spo2_target_row(_spo2Target),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildMainDisplay(
                          l10n,
                          primary,
                          avgSaturation,
                          latestLog,
                          _spo2Target,
                          isDark,
                          colorScheme,
                        ),
                        const SizedBox(height: 24),
                        _buildMotivationCard(
                          l10n,
                          primary,
                          _spo2Target,
                          isDark,
                          colorScheme,
                        ),
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                l10n.health_spo2_chart_section.toUpperCase(),
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
                        _buildChart(isDark, logs, _spo2Target, l10n),
                        const SizedBox(height: 24),
                        _buildSummaryCards(l10n, isDark, logs),
                        const SizedBox(height: 32),
                        _buildEducationalCard(l10n, isDark),
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
      icon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey.shade400),
      onPressed: onPressed,
    );
  }

  Widget _buildMainDisplay(
    AppLocalizations l10n,
    double primary,
    double avg,
    OxygenSaturationLogData? latest,
    int target,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final ringColor = _ringColor(primary, target, isDark);
    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: primary > 0 ? primary / 100 : 0,
                  strokeWidth: 12,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    primary > 0 ? primary.toStringAsFixed(0) : '--',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    l10n.health_spo2_percent_unit,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (latest != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.health_spo2_latest(
                        DateFormat.Hm(
                          Localizations.localeOf(context).toString(),
                        ).format(latest.timestamp),
                      ),
                      style: TextStyle(
                        color: isDark
                            ? Colors.blue.withValues(alpha: 0.85)
                            : Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (_shouldShowDayAverage(latest, avg)) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.health_spo2_day_avg(avg.toStringAsFixed(0)),
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show day average when it differs from the headline reading.
  bool _shouldShowDayAverage(OxygenSaturationLogData? latest, double avg) {
    if (avg <= 0) return false;
    if (latest == null) return true;
    return (avg - latest.saturation).abs() >= 0.5;
  }

  Widget _buildMotivationCard(
    AppLocalizations l10n,
    double primary,
    int target,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final text = _motivationFor(l10n, primary, target);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.09),
              colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.04),
            ],
          ),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalCard(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.blue.withValues(alpha: 0.05)
              : Colors.blue.withValues(alpha: 0.03),
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
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.health_spo2_educational_title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.health_spo2_educational_body,
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

  Widget _buildChart(
    bool isDark,
    List<OxygenSaturationLogData> logs,
    int target,
    AppLocalizations l10n,
  ) {
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
              getTooltipColor: (group) =>
                  isDark ? Colors.grey[900]! : Colors.white,
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
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _getAggregatedBarGroups(logs, target),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: target.toDouble(),
                color: Colors.blue.withValues(alpha: 0.35),
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(color: Colors.blue, fontSize: 10),
                  labelResolver: (line) => l10n.health_spo2_target_line(target),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getAggregatedBarGroups(
    List<OxygenSaturationLogData> logs,
    int target,
  ) {
    final Map<int, List<double>> hourlyData = {};
    for (var log in logs) {
      final hour = log.timestamp.hour;
      hourlyData.putIfAbsent(hour, () => []).add(log.saturation);
    }

    return List.generate(24, (hour) {
      final hourLogs = hourlyData[hour] ?? [];
      final avg = hourLogs.isEmpty
          ? 0.0
          : hourLogs.reduce((a, b) => a + b) / hourLogs.length;

      Color rodColor;
      if (avg <= 0) {
        rodColor = Colors.transparent;
      } else if (avg >= target) {
        rodColor = Colors.blue;
      } else if (avg >= target - 3) {
        rodColor = Colors.orange;
      } else {
        rodColor = Colors.red;
      }

      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: avg > 0 ? avg : 0,
            color: rodColor,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCards(
    AppLocalizations l10n,
    bool isDark,
    List<OxygenSaturationLogData> logs,
  ) {
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
              l10n.health_spo2_summary_min,
              '${min.toStringAsFixed(0)}%',
              Icons.trending_down_rounded,
              Colors.orange,
              isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              l10n.health_spo2_summary_max,
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
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
