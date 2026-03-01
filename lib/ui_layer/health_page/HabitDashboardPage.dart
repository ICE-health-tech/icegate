import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitDashboardPage extends StatelessWidget {
  const HabitDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final healthLogsDao = Provider.of<HealthLogsDAO>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFA2D136), // Lime Green from screenshot
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Grid of Habits
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 30,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.85,
                  children: [
                    HabitCircularItem(
                      icon: Icons.air_rounded,
                      title: "TẬP THỞ",
                      timeSuffix: "5:00",
                      showPlayButton: true,
                      onTap: () =>
                          _logExercise(context, healthLogsDao, "Breathing", 5),
                    ),
                    HabitCircularItem(
                      icon: Icons.water_drop_rounded,
                      title: "UỐNG NƯỚC",
                      timeSuffix: "250ml",
                      onTap: () => _logWater(context, healthLogsDao, 250),
                    ),
                    HabitCircularItem(
                      icon: Icons.fitness_center_rounded,
                      title: "TẬP GYM",
                      timeSuffix: "30:00",
                      showPlayButton: true,
                      onTap: () =>
                          _logExercise(context, healthLogsDao, "Gym", 30),
                    ),
                    HabitCircularItem(
                      icon: Icons.bed_rounded,
                      title: "NGỦ",
                      onTap: () => _logSleep(context, healthLogsDao),
                    ),
                    HabitCircularItem(
                      label: "TNL",
                      title: "TẮM NƯỚC LẠNH",
                      onTap: () => _logExercise(
                        context,
                        healthLogsDao,
                        "Cold Shower",
                        5,
                      ),
                    ),
                    HabitCircularItem(
                      label: "T",
                      title: "THIỀN",
                      onTap: () => _logExercise(
                        context,
                        healthLogsDao,
                        "Meditation",
                        10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Nav
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.settings, color: Colors.white70),
                  Row(
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 1 ? Colors.white : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logExercise(
    BuildContext context,
    HealthLogsDAO dao,
    String type,
    int minutes,
  ) async {
    try {
      await dao.insertExerciseLog(
        ExerciseLogsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: const Value(''),
          type: type,
          durationMinutes: minutes,
          timestamp: Value(DateTime.now()),
        ),
      );
      _showSuccess(context, "Logged $type activity!");
    } catch (e) {
      debugPrint("Error logging habit: $e");
    }
  }

  void _logWater(BuildContext context, HealthLogsDAO dao, int amount) async {
    try {
      await dao.insertWaterLog(
        WaterLogsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: Value(Supabase.instance.client.auth.currentUser!.id),
          amount: Value(amount),
          timestamp: Value(DateTime.now()),
        ),
      );
      _showSuccess(context, "Logged ${amount}ml of water!");
    } catch (e) {
      debugPrint("Error logging water: $e");
    }
  }

  void _logSleep(BuildContext context, HealthLogsDAO dao) async {
    try {
      // For simplicity, log a generic 8-hour sleep from yesterday to today
      final now = DateTime.now();
      await dao.insertSleepLog(
        SleepLogsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: const Value(''),
          startTime: now.subtract(const Duration(hours: 8)),
          endTime: Value(now),
          quality: const Value(4),
        ),
      );
      _showSuccess(context, "Logged sleep session!");
    } catch (e) {
      debugPrint("Error logging sleep: $e");
    }
  }

  void _showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF4A6115),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class HabitCircularItem extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String title;
  final String? timeSuffix;
  final bool showPlayButton;
  final VoidCallback onTap;

  const HabitCircularItem({
    super.key,
    this.icon,
    this.label,
    required this.title,
    this.timeSuffix,
    this.showPlayButton = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Circular Border
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4A6115), // Dark green border
                    width: 6,
                  ),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: Colors.white, size: 60)
                      : Text(
                          label ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              // Play Button Wrapper
              if (showPlayButton)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 35,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (timeSuffix != null)
                const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
              if (timeSuffix != null) const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (timeSuffix != null) const SizedBox(width: 4),
              if (timeSuffix != null)
                Text(
                  timeSuffix!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
