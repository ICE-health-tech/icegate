import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:ice_gate/ui_layer/health_page/subpage/LidarFoodScanner.dart';
import 'package:ice_gate/ui_layer/health_page/widgets/AddFoodModal.dart';

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesCardState();
}

class _CaloriesCardState extends State<CaloriesPage> {
  int caloriesBurned = 520;
  int caloriesConsumed = 1800;
  final int dailyGoal = 2000;
  final int bmr = 1600; // Basal Metabolic Rate

  // Macronutrient tracking
  int protein = 45; // grams
  int carbs = 180; // grams
  int fat = 50; // grams
  final int proteinGoal = 150; // grams
  final int carbsGoal = 250; // grams
  final int fatGoal = 70; // grams

  final TextEditingController _caloriesController = TextEditingController();
  // _foodController, _proteinController, etc removed as they are now in the modal

  @override
  void dispose() {
    _caloriesController.dispose();
    super.dispose();
  }

  int get netCalories => caloriesConsumed - caloriesBurned;
  int get remainingCalories =>
      (dailyGoal - netCalories).clamp(0, dailyGoal * 2);
  double get progressPercentage =>
      (netCalories / dailyGoal * 100).clamp(0, 150);
  int get totalEnergyExpenditure => bmr + caloriesBurned;

  String get calorieStatus {
    if (netCalories < dailyGoal * 0.8)
      return AppLocalizations.of(context)!.under_goal;
    if (netCalories <= dailyGoal * 1.1)
      return AppLocalizations.of(context)!.on_track;
    return AppLocalizations.of(context)!.over_goal;
  }

  Color get statusColor {
    if (netCalories < dailyGoal * 0.8) return Colors.orange;
    if (netCalories <= dailyGoal * 1.1) return Colors.green;
    return Colors.red;
  }

  void _onFoodAdded(Map<String, dynamic> data) {
    setState(() {
      // Data from modal is: {name, calories, protein, carbs, fat, image}
      // We can use the image if needed, for now just adding macros
      final cal = data['calories'] as int? ?? 0;
      final p = data['protein'] as int? ?? 0;
      final c = data['carbs'] as int? ?? 0;
      final f = data['fat'] as int? ?? 0;

      if (cal > 0) {
        caloriesConsumed += cal;
        protein += p;
        carbs += c;
        fat += f;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.added_food_msg(data['name'], cal),
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddFoodModal(onAdd: _onFoodAdded),
      ),
    );
  }

  void _addExercise() {
    final calories = int.tryParse(_caloriesController.text);
    if (calories != null && calories > 0) {
      setState(() {
        caloriesBurned += calories;
        _caloriesController.clear();
      });
    }
  }

  /// Open LiDAR scanner for food volume estimation
  Future<void> _openLidarScanner() async {
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.lidar_ios_only),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LidarFoodScanner()),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.lidar_completed),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.calorie_tracker,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () => context.push('/health/food/dashboard'),
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: AppLocalizations.of(context)!.nutrition_dashboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... Main Card ... (keep existing)
            Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.net_calories,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          netCalories.toString(),
                          style: textTheme.displayLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'kcal',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.goal_kcal(dailyGoal),
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 2),
                      ),
                      child: Text(
                        calorieStatus,
                        style: textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (netCalories / dailyGoal).clamp(0, 1),
                        minHeight: 12,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.percent_of_daily_goal(
                        progressPercentage.toStringAsFixed(0),
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Calorie Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownCard(
                    context,
                    AppLocalizations.of(context)!.consumed,
                    caloriesConsumed,
                    Icons.restaurant,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBreakdownCard(
                    context,
                    AppLocalizations.of(context)!.burned,
                    caloriesBurned,
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    AppLocalizations.of(context)!.remaining,
                    remainingCalories.toString(),
                    'kcal',
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    AppLocalizations.of(context)!.total_burn,
                    totalEnergyExpenditure.toString(),
                    'kcal',
                    Icons.whatshot,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions Section
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddFoodModal,
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.add_food),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openLidarScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(AppLocalizations.of(context)!.lidar_scan),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add Exercise Section
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.health_log_exercise,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.health_calories_burned_label,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.fitness_center),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addExercise,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ... Quick Add ... (keep existing)
            const SizedBox(height: 20),

            // Quick Add Exercises
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.health_quick_add_exercise,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickExerciseChip(
                          AppLocalizations.of(context)!.health_walking_30min,
                          150,
                        ),
                        _buildQuickExerciseChip(
                          AppLocalizations.of(context)!.health_running_30min,
                          300,
                        ),
                        _buildQuickExerciseChip(
                          AppLocalizations.of(context)!.health_cycling_30min,
                          250,
                        ),
                        _buildQuickExerciseChip(
                          AppLocalizations.of(context)!.health_swimming_30min,
                          350,
                        ),
                        _buildQuickExerciseChip(
                          AppLocalizations.of(context)!.health_yoga_30min,
                          120,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4.0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: textTheme.bodyMedium?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('kcal', style: textTheme.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.secondary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickExerciseChip(String label, int calories) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.add_circle_outline, size: 18),
      onPressed: () {
        setState(() {
          caloriesBurned += calories;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.added_calories_burned(calories),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
