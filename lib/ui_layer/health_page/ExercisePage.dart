import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final int _goalMinutes = 60;

  @override
  Widget build(BuildContext context) {
    final dao = context.watch<HealthLogsDAO>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
    return StreamBuilder<List<ExerciseLogData>>(
      stream: dao.watchDailyExerciseLogs(personId, DateTime.now()),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final totalMinutes = logs.fold<int>(
          0,
          (sum, log) => sum + log.durationMinutes,
        );
        double progress = (totalMinutes / _goalMinutes).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text(
              'Exercise Tracker',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () => context.push('/health/exercise/dashboard'),
                icon: const Icon(Icons.analytics_rounded, color: Colors.orange),
                tooltip: 'Exercise Analysis',
              ),
              IconButton(
                onPressed: () => context.go('/health/habits'),
                icon: const Icon(Icons.grid_view_rounded, color: Colors.orange),
                tooltip: 'Habit Dashboard',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Summary Ring
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 16,
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          color: Colors.orange,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 40,
                            color: Colors.orange,
                          ),
                          Text(
                            '$totalMinutes',
                            style: textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'MIN / $_goalMinutes MIN',
                            style: textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Routines & Habits Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Daily Routines",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/health/habits'),
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _activityQuickAction(
                        context,
                        "Breathing",
                        5,
                        Icons.air_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Gym",
                        30,
                        Icons.fitness_center_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Running",
                        20,
                        Icons.directions_run_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Yoga",
                        15,
                        Icons.self_improvement_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "CrossFit",
                        45,
                        Icons.bolt_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Pilates",
                        35,
                        Icons.accessibility_new_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Swimming",
                        30,
                        Icons.pool_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Cycling",
                        40,
                        Icons.directions_bike_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Meditation",
                        10,
                        Icons.spa_rounded,
                      ),
                      _activityQuickAction(
                        context,
                        "Strength",
                        50,
                        Icons.fitness_center_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // History View
                Text(
                  "Activity History",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                if (logs.isEmpty)
                  Center(
                    child: Text(
                      "No activities recorded yet.",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[logs.length - 1 - index];
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
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
                                    DateFormat('HH:mm').format(log.timestamp),
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "+${log.durationMinutes}m",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.orange,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddExerciseDialog(context, dao),
            label: const Text("Add Exercise"),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }

  Widget _activityQuickAction(
    BuildContext context,
    String type,
    int mins,
    IconData icon,
  ) {
    final focusBlock = context.read<FocusBlock>();
    return GestureDetector(
      onTap: () {
        Feedback.forTap(context);
        focusBlock.startExercise(type, mins);
        context.push('/health/focus');
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.orange, size: 30),
            const SizedBox(height: 8),
            Text(
              type,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              "${mins}m",
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, HealthLogsDAO dao) {
    final typeController = TextEditingController();
    final minsController = TextEditingController();
    final intensities = ['low', 'medium', 'high'];
    String selectedIntensity = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("CUSTOM ACTIVITY"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: "Activity Type (e.g. Gym)",
                ),
              ),
              TextField(
                controller: minsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Duration (min)"),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedIntensity,
                decoration: const InputDecoration(labelText: "Intensity"),
                items: intensities.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedIntensity = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () async {
                final type = typeController.text.isEmpty
                    ? "Exercise"
                    : typeController.text;
                final mins = int.tryParse(minsController.text) ?? 0;
                if (mins > 0) {
                  await dao.insertExerciseLog(
                    ExerciseLogsTableCompanion.insert(
                      id: IDGen.generateUuid(),
                      personID:
                          Supabase.instance.client.auth.currentUser?.id ?? "",
                      type: type,
                      durationMinutes: mins,
                      intensity: drift.Value(selectedIntensity),
                      timestamp: drift.Value(DateTime.now()),
                    ),
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("LOG ACTIVITY"),
            ),
          ],
        ),
      ),
    );
  }
}
