import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/health_page/Input/CameraFoodImport.dart';
import 'package:image_picker/image_picker.dart';

class CaloriesCard extends StatefulWidget {
  const CaloriesCard({super.key});

  @override
  State<CaloriesCard> createState() => _CaloriesCardState();
}

class _CaloriesCardState extends State<CaloriesCard> {
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
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  @override
  void dispose() {
    _caloriesController.dispose();
    _foodController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  int get netCalories => caloriesConsumed - caloriesBurned;
  int get remainingCalories =>
      (dailyGoal - netCalories).clamp(0, dailyGoal * 2);
  double get progressPercentage =>
      (netCalories / dailyGoal * 100).clamp(0, 150);
  int get totalEnergyExpenditure => bmr + caloriesBurned;

  String get calorieStatus {
    if (netCalories < dailyGoal * 0.8) return 'Under Goal';
    if (netCalories <= dailyGoal * 1.1) return 'On Track';
    return 'Over Goal';
  }

  Color get statusColor {
    if (netCalories < dailyGoal * 0.8) return Colors.orange;
    if (netCalories <= dailyGoal * 1.1) return Colors.green;
    return Colors.red;
  }

  void _addFood() {
    final calories = int.tryParse(_caloriesController.text);
    final proteinAmount = int.tryParse(_proteinController.text) ?? 0;
    final carbsAmount = int.tryParse(_carbsController.text) ?? 0;
    final fatAmount = int.tryParse(_fatController.text) ?? 0;

    if (calories != null && calories > 0) {
      setState(() {
        caloriesConsumed += calories;
        protein += proteinAmount;
        carbs += carbsAmount;
        fat += fatAmount;
        _caloriesController.clear();
        _foodController.clear();
        _proteinController.clear();
        _carbsController.clear();
        _fatController.clear();
      });
    }
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

  /// Open camera to take food photo
  Future<void> _openCamera() async {
    final XFile? result = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (context) => const CameraFoodImport()),
    );

    if (result != null) {
      // Image was captured/selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Photo captured! Add food details below.')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      // TODO: In future, integrate with food recognition API
      // For now, just show success message
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
          'Calorie Tracker',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Calorie Display Card
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
                      'Net Calories',
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
                      'Goal: $dailyGoal kcal',
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
                      '${progressPercentage.toStringAsFixed(0)}% of daily goal',
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
                    'Consumed',
                    caloriesConsumed,
                    Icons.restaurant,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBreakdownCard(
                    context,
                    'Burned',
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
                    'Remaining',
                    remainingCalories.toString(),
                    'kcal',
                    Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Burn',
                    totalEnergyExpenditure.toString(),
                    'kcal',
                    Icons.whatshot,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Add Food Section
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
                      'Log Food',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Camera button
                    OutlinedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Food Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _foodController,
                      decoration: InputDecoration(
                        labelText: 'Food name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.fastfood),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Calories',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.calculate),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addFood,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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
                    const SizedBox(height: 16),
                    // Macronutrient inputs
                    Text(
                      'Macronutrients (optional)',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _proteinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Protein (g)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.egg, color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _carbsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Carbs (g)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.grain,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _fatController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Fat (g)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.water_drop,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                      'Log Exercise',
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
                              labelText: 'Calories burned',
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
                      'Quick Add Exercise',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickExerciseChip('Walking 30min', 150),
                        _buildQuickExerciseChip('Running 30min', 300),
                        _buildQuickExerciseChip('Cycling 30min', 250),
                        _buildQuickExerciseChip('Swimming 30min', 350),
                        _buildQuickExerciseChip('Yoga 30min', 120),
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
            content: Text('Added $calories kcal burned'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
