import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

class HourlyActivityPage extends StatefulWidget {
  const HourlyActivityPage({super.key});

  @override
  State<HourlyActivityPage> createState() => _HourlyActivityPageState();
}

class _HourlyActivityPageState extends State<HourlyActivityPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final hourlyDao = context.watch<HourlyActivityLogDAO>();
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Hourly Activity', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: StreamBuilder<List<HourlyActivityLogData>>(
        stream: hourlyDao.watchHourlyLogs(personId, _selectedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDateHeader(colorScheme),
                ),
              ),
              if (logs.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(colorScheme),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSummaryGrid(logs, colorScheme),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildHourlyChart(logs, colorScheme),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildAnalysisCard(logs, colorScheme),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = logs[index];
                      return _buildLogTile(log, colorScheme);
                    },
                    childCount: logs.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildDateHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(_selectedDate),
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Icon(Icons.history_toggle_off_rounded, color: colorScheme.primary, size: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(List<HourlyActivityLogData> logs, ColorScheme colorScheme) {
    int totalSteps = logs.fold<int>(0, (sum, e) => sum + e.stepsCount);
    int totalCals = logs.fold<int>(0, (sum, e) => sum + (e.caloriesBurned ?? 0));
    double totalKm = logs.fold<double>(0.0, (sum, e) => sum + (e.distanceKm ?? 0.0));

    return Row(
      children: [
        _summaryItem('Steps', totalSteps.toString(), Icons.directions_walk, Colors.orange, colorScheme),
        const SizedBox(width: 12),
        _summaryItem('Kcal', totalCals.toString(), Icons.fireplace, Colors.red, colorScheme),
        const SizedBox(width: 12),
        _summaryItem('Km', totalKm.toStringAsFixed(2), Icons.map, Colors.blue, colorScheme),
      ],
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChart(List<HourlyActivityLogData> logs, ColorScheme colorScheme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hourly Distribution', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(24, (index) {
                final log = logs.firstWhere(
                  (l) => l.startTime.hour == index,
                  orElse: () => HourlyActivityLogData(
                    id: '',
                    personID: '',
                    startTime: DateTime.now(),
                    logDate: DateTime.now(),
                    stepsCount: 0,
                    distanceKm: 0.0,
                    caloriesBurned: 0,
                  ),
                );
                final heightFactor = (log.stepsCount / 2000).clamp(0.05, 1.0);
                
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: (120 * heightFactor).toDouble(),
                        decoration: BoxDecoration(
                          color: log.stepsCount > 0 ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (index % 4 == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('${index}h', style: const TextStyle(fontSize: 8)),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(List<HourlyActivityLogData> logs, ColorScheme colorScheme) {
    final analysis = _analyzeActivity(logs);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Activity Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(analysis, style: const TextStyle(color: Colors.white, height: 1.4)),
        ],
      ),
    );
  }

  String _analyzeActivity(List<HourlyActivityLogData> logs) {
    if (logs.isEmpty) return "No activity data available for analysis.";
    
    final peakHour = logs.reduce((a, b) => a.stepsCount > b.stepsCount ? a : b);
    final totalSteps = logs.fold<int>(0, (sum, e) => sum + e.stepsCount);
    
    if (totalSteps < 1000) return "A very sedentary day. Try to move at least 5 minutes every hour to boost metabolism.";
    
    String insight = "Your peak activity was at ${DateFormat('HH:mm').format(peakHour.startTime)} with ${peakHour.stepsCount} steps. ";
    
    final morningSteps = logs.where((l) => l.startTime.hour < 12).fold<int>(0, (sum, e) => sum + e.stepsCount);
    final eveningSteps = logs.where((l) => l.startTime.hour >= 12).fold<int>(0, (sum, e) => sum + e.stepsCount);
    
    if (morningSteps > eveningSteps) {
      insight += "You are a 'Morning Hunter', most active in the early hours. This is great for mental clarity.";
    } else {
      insight += "You tend to be more active in the afternoon/evening. Consider a short morning walk to balance your circadian rhythm.";
    }
    
    return insight;
  }

  Widget _buildLogTile(HourlyActivityLogData log, ColorScheme colorScheme) {
    if (log.stepsCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Text('${log.startTime.hour}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          title: Text('${log.stepsCount} steps', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${log.distanceKm.toStringAsFixed(2)} km • ${log.caloriesBurned} kcal'),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.outline),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bedtime_outlined, size: 64, color: colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No hourly logs for this day', style: TextStyle(color: colorScheme.outline)),
        ],
      ),
    );
  }
}
