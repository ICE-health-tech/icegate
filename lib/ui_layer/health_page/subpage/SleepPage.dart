import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:intl/intl.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  TimeOfDay bedTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int quality = 4;

  @override
  Widget build(BuildContext context) {
    final dao = context.watch<HealthLogsDAO>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final healthBlock = context.watch<HealthBlock>();

    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
    return StreamBuilder<List<SleepLogData>>(
      stream: dao.watchSleepLogs(personId),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final lastLog = logs.isNotEmpty ? logs.last : null;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Sleep Tracker'),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HealthKit Sleep Data
                Watch((context) {
                  final healthSleep = healthBlock.todaySleep.value;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.apple, color: Colors.indigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "HealthKit Sleep",
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              Text(
                                "Last 24h from Apple Health",
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${healthSleep.toStringAsFixed(1)}h",
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Top Hero Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.surfaceContainerHighest,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.nightlight_round,
                        size: 48,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 16),
                      if (lastLog != null) ...[
                        Text(
                          "Last Session",
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${lastLog.endTime != null ? lastLog.endTime!.difference(lastLog.startTime).inHours : '0'} hrs",
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.indigo,
                          ),
                        ),
                        Text(
                          "Quality: ${'⭐' * lastLog.quality}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ] else
                        const Text("No sleep sessions recorded yet."),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  "Log Sleep",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Time Picks
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        context,
                        "Bedtime",
                        bedTime,
                        Icons.bedtime,
                        (t) => setState(() => bedTime = t),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        context,
                        "Wake up",
                        wakeTime,
                        Icons.sunny,
                        (t) => setState(() => wakeTime = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quality Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Quality", style: textTheme.titleMedium),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () => setState(() => quality = index + 1),
                          icon: Icon(
                            index < quality
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveSleep(context, dao),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: const Text(
                      "Save Session",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // History
                if (logs.isNotEmpty) ...[
                  Text(
                    "History",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[logs.length - 1 - index];
                      final duration = log.endTime != null
                          ? log.endTime!.difference(log.startTime)
                          : const Duration();
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bed_rounded, color: Colors.indigo),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${duration.inHours}h ${duration.inMinutes % 60}m",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d').format(log.startTime),
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text("⭐" * log.quality),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    TimeOfDay time,
    IconData icon,
    Function(TimeOfDay) onPicked,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSleep(BuildContext context, HealthLogsDAO dao) async {
    final now = DateTime.now();
    // Simple naive duration calculation for Demo
    DateTime start = DateTime(
      now.year,
      now.month,
      now.day,
      bedTime.hour,
      bedTime.minute,
    );
    DateTime end = DateTime(
      now.year,
      now.month,
      now.day,
      wakeTime.hour,
      wakeTime.minute,
    );
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));

    await dao.insertSleepLog(
      SleepLogsTableCompanion.insert(
        id: IDGen.generateUuid(),
        personID: drift.Value(Supabase.instance.client.auth.currentUser?.id ?? ""),
        startTime: start,
        endTime: drift.Value(end),
        quality: drift.Value(quality),
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sleep session saved!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
