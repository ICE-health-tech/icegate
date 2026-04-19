import 'dart:ui';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> with SingleTickerProviderStateMixin {
  late AnimationController _timerAnimationController;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthBlock = context.watch<HealthBlock>();
    final focusBlock = context.watch<FocusBlock>();
    final colorScheme = Theme.of(context).colorScheme;
    
    final dailyGoal = healthBlock.dailyExerciseGoal.watch(context);
    final currentMinutes = healthBlock.todayExerciseMinutes.watch(context);
    final progress = (currentMinutes / dailyGoal).clamp(0.0, 1.0);

    final isRunning = focusBlock.isRunning.watch(context);
    final isExerciseActive = focusBlock.isExerciseMode.watch(context);

    return Scaffold(
      backgroundColor: Colors.black, // Immersive base
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('EXERCISE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/health/exercise/dashboard'),
            icon: const Icon(Icons.analytics_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: _AmbientGlow(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _AmbientGlow(color: Colors.blue.withValues(alpha: 0.1)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Main Progress / Live Timer Section
                  if (isExerciseActive && isRunning)
                    _buildLiveTimerCard(context, focusBlock, healthBlock, colorScheme)
                  else
                    _buildProgressCard(context, currentMinutes, dailyGoal, progress, colorScheme),

                  const SizedBox(height: 32),
                  _buildQuickActions(context, focusBlock),
                  const SizedBox(height: 32),
                  _buildHistorySection(context, healthBlock),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (isExerciseActive && isRunning) 
        ? null 
        : FloatingActionButton.extended(
            onPressed: () => _showCustomManualAdd(context, healthBlock),
            label: const Text("Log Manual", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            icon: const Icon(Icons.add_task_rounded),
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int current, int goal, double progress, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: Colors.orangeAccent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$current',
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: -2),
                      ),
                      Text(
                        'of $goal min'.toUpperCase(),
                        style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => _showGoalEditDialog(context, goal),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text('Adjust Goal', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 12)),
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

  Widget _buildLiveTimerCard(BuildContext context, FocusBlock focusBlock, HealthBlock healthBlock, ColorScheme colorScheme) {
    final type = focusBlock.exerciseType.watch(context);
    final isStopwatch = focusBlock.isStopwatchMode.watch(context);
    final elapsed = focusBlock.stopwatchElapsedSeconds.watch(context);
    final remaining = focusBlock.remainingTime.watch(context);

    String timerText = isStopwatch ? _formatDuration(elapsed) : _formatDuration(remaining);

    final estimatedKcal = healthBlock.estimateCalories(
      type, 
      isStopwatch ? (elapsed ~/ 60) : (remaining ~/ 60), 
      'medium'
    );

    return AnimatedBuilder(
      animation: _timerAnimationController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08 + (0.04 * _timerAnimationController.value)),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text(
                        type.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    timerText,
                    style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Colors.white, letterSpacing: -2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${estimatedKcal.toInt()} KCAL BURNED',
                    style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _timerAction(Icons.stop_rounded, "FINISH", Colors.redAccent, () {
                        focusBlock.stopTimer();
                      }),
                      const SizedBox(width: 40),
                      _timerAction(Icons.pause_rounded, "PAUSE", Colors.orangeAccent, () {
                        focusBlock.pauseTimer();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _timerAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        ClipOval(
          child: Material(
            color: color.withValues(alpha: 0.1),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(icon, size: 36, color: color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildQuickActions(BuildContext context, FocusBlock focusBlock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("START ACTIVITY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _activityCard(context, focusBlock, "Running", Icons.directions_run_rounded, Colors.orangeAccent),
              _activityCard(context, focusBlock, "Gym", Icons.fitness_center_rounded, Colors.blueAccent),
              _activityCard(context, focusBlock, "Yoga", Icons.self_improvement_rounded, Colors.purpleAccent),
              _activityCard(context, focusBlock, "Cycling", Icons.directions_bike_rounded, Colors.greenAccent),
              _activityCard(context, focusBlock, "Swimming", Icons.pool_rounded, Colors.cyanAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityCard(BuildContext context, FocusBlock focusBlock, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _showStartOption(context, focusBlock, title, icon),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 36),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStartOption(BuildContext context, FocusBlock focusBlock, String title, IconData icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 20)),
            const SizedBox(height: 40),
            _modeOption(Icons.timer_outlined, "LIVE STOPWATCH", "Count up until you finish", () {
              focusBlock.startStopwatchExercise(title);
              Navigator.pop(context);
            }),
            const SizedBox(height: 16),
            _modeOption(Icons.hourglass_bottom_rounded, "FIXED GOAL", "Count down from 30 minutes", () {
              focusBlock.startExercise(title, 30);
              Navigator.pop(context);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _modeOption(IconData icon, String title, String sub, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(24),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Icon(icon, color: Colors.orangeAccent, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.white38)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, HealthBlock healthBlock) {
    final dao = context.read<HealthLogsDAO>();
    final personId = context.read<PersonBlock>().information.value.profiles.id ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ACTIVITY HISTORY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 16),
        StreamBuilder<List<ExerciseLogData>>(
          stream: dao.watchDailyExerciseLogs(personId, DateTime.now()),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.white10),
                      const SizedBox(height: 16),
                      const Text("NO ACTIVITIES RECORDED", style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[logs.length - 1 - index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
                                Text(
                                  DateFormat('HH:mm').format(log.timestamp),
                                  style: const TextStyle(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Text("+${log.durationMinutes}m", 
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orangeAccent, fontSize: 20, letterSpacing: -1)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showGoalEditDialog(BuildContext context, int currentGoal) {
    final controller = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("SET GOAL"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: "minutes"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? currentGoal;
              context.read<HealthBlock>().updateExerciseGoal(val);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  void _showCustomManualAdd(BuildContext context, HealthBlock healthBlock) {
    final typeController = TextEditingController();
    final minsController = TextEditingController();
    String intensity = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("LOG MANUAL ACTIVITY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 24),
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: "Activity Type",
                  hintText: "e.g. Boxing, HIIT",
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Duration (min)",
                  filled: true,
                  fillColor: Colors.orange.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final type = typeController.text.trim();
                    final mins = int.tryParse(minsController.text.trim()) ?? 0;
                    if (type.isNotEmpty && mins > 0) {
                      final personId = context.read<PersonBlock>().information.value.profiles.id ?? "";
                      final logsDao = context.read<HealthLogsDAO>();
                      final healthDao = context.read<HealthMetricsDAO>();
                      
                      await logsDao.insertExerciseLog(
                        ExerciseLogsTableCompanion.insert(
                          id: IDGen.UUIDV7(),
                          personID: drift.Value(personId),
                          type: type,
                          durationMinutes: mins,
                          intensity: drift.Value(intensity),
                          timestamp: drift.Value(DateTime.now()),
                        ),
                      );
                      // Update health metrics manually for legacy support
                      await healthDao.insertOrUpdateMetrics(
                        HealthMetricsTableCompanion(
                          personID: drift.Value(personId),
                          date: drift.Value(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)),
                          exerciseMinutes: drift.Value(mins),
                          updatedAt: drift.Value(DateTime.now()),
                        ),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("LOG ACTIVITY", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  const _AmbientGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}
