import 'package:flutter/material.dart';

/// Model class for macronutrient data
class MacronutrientData {
  final String name;
  final int current;
  final int goal;
  final Color color;
  final IconData icon;

  MacronutrientData({
    required this.name,
    required this.current,
    required this.goal,
    required this.color,
    required this.icon,
  });

  double get percentage => (current / goal * 100).clamp(0, 150);
  int get remaining => (goal - current).clamp(0, goal * 2);
  bool get isOverGoal => current > goal;
}

/// A reusable widget for displaying calorie breakdown metrics
/// Shows consumed, burned, or other calorie-related data with icon and color
class CaloriesBreakdownCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const CaloriesBreakdownCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 1),
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
}

/// A reusable widget for displaying calorie statistics
/// Shows metrics like remaining calories, total burn, etc.
class CaloriesStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const CaloriesStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
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
}

/// Main calorie display widget showing net calories with progress
class CaloriesMainDisplay extends StatelessWidget {
  final int netCalories;
  final int dailyGoal;
  final String calorieStatus;
  final Color statusColor;
  final double progressPercentage;

  const CaloriesMainDisplay({
    super.key,
    required this.netCalories,
    required this.dailyGoal,
    required this.calorieStatus,
    required this.statusColor,
    required this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Net Calories',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          // const SizedBox(height: 8),
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
              // const SizedBox(width: 8),
              Text(
                'kcal',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 8),
          Text(
            'Goal: $dailyGoal kcal',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // const SizedBox(height: 20),
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
          // const SizedBox(height: 8),
          Text(
            '${progressPercentage.toStringAsFixed(0)}% of daily goal',
            style: textTheme.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Widget for displaying macronutrient tracking (protein, carbs, fat)
class MacronutrientCard extends StatelessWidget {
  final MacronutrientData macro;

  const MacronutrientCard({super.key, required this.macro});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(macro.icon, color: macro.color, size: 24),
                const SizedBox(width: 8),
                Text(
                  macro.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: macro.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      macro.current.toString(),
                      style: textTheme.headlineSmall?.copyWith(
                        color: macro.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${macro.goal}g',
                      style: textTheme.bodyLarge?.copyWith(
                        color: macro.color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${macro.percentage.toStringAsFixed(0)}%',
                  style: textTheme.titleMedium?.copyWith(
                    color: macro.isOverGoal ? Colors.red : macro.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (macro.current / macro.goal).clamp(0, 1),
                minHeight: 10,
                backgroundColor: macro.color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  macro.isOverGoal ? Colors.red : macro.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              macro.isOverGoal
                  ? '${macro.current - macro.goal}g over goal'
                  : '${macro.remaining}g remaining',
              style: textTheme.bodySmall?.copyWith(
                color: macro.isOverGoal
                    ? Colors.red
                    : macro.color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Macronutrient summary widget showing all three macros in a compact view
class MacronutrientSummary extends StatelessWidget {
  final int protein;
  final int carbs;
  final int fat;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  const MacronutrientSummary({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      // padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Macronutrients',
          //   style: textTheme.titleLarge?.copyWith(
          //     fontWeight: FontWeight.bold,
          //     color: colorScheme.primary,
          //   ),
          // ),
          // const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroSummaryItem(
                context,
                'Protein',
                protein,
                proteinGoal,
                Colors.red,
              ),
              _buildMacroSummaryItem(
                context,
                'Carbs',
                carbs,
                carbsGoal,
                Colors.orange,
              ),
              _buildMacroSummaryItem(
                context,
                'Fat',
                fat,
                fatGoal,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
      // ),
    );
  }

  Widget _buildMacroSummaryItem(
    BuildContext context,
    String label,
    int current,
    int goal,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final percentage = (current / goal * 100).clamp(0, 100);

    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current/$goal',
          style: textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
        ),
        Text(
          'g',
          style: textTheme.bodySmall?.copyWith(color: color.withOpacity(0.6)),
        ),
      ],
    );
  }
}
