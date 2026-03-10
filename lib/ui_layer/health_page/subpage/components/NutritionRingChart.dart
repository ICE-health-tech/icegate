import 'dart:math' as math;
import 'package:flutter/material.dart';

class NutritionRingChart extends StatelessWidget {
  final double calories;
  final double calorieGoal;
  final double protein;
  final double carbs;
  final double fat;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  const NutritionRingChart({
    super.key,
    required this.calories,
    required this.calorieGoal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.proteinGoal = 150,
    this.carbsGoal = 250,
    this.fatGoal = 70,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 220,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _NutritionRingPainter(
              progressCalories: (calories / calorieGoal).clamp(0, 1),
              progressProtein: (protein / proteinGoal).clamp(0, 1),
              progressCarbs: (carbs / carbsGoal).clamp(0, 1),
              progressFat: (fat / fatGoal).clamp(0, 1),
              proteinColor: Colors.orange,
              carbsColor: Colors.blue,
              fatColor: Colors.pink,
              baseColor: colorScheme.onPrimary.withValues(alpha: 0.1),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${calories.toInt()}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'kcal consumed',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Goal: ${calorieGoal.toInt()}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionRingPainter extends CustomPainter {
  final double progressCalories;
  final double progressProtein;
  final double progressCarbs;
  final double progressFat;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatColor;
  final Color baseColor;

  _NutritionRingPainter({
    required this.progressCalories,
    required this.progressProtein,
    required this.progressCarbs,
    required this.progressFat,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 1. Calories Ring (Main Outer)
    final caloriePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 7, caloriePaint);

    final calorieProgressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7),
      -math.pi / 2,
      2 * math.pi * progressCalories,
      false,
      calorieProgressPaint,
    );

    // 2. Protein Ring
    _drawMetricRing(canvas, center, radius - 30, progressProtein, proteinColor);

    // 3. Carbs Ring
    _drawMetricRing(canvas, center, radius - 50, progressCarbs, carbsColor);

    // 4. Fat Ring
    _drawMetricRing(canvas, center, radius - 70, progressFat, fatColor);
  }

  void _drawMetricRing(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
    Color color,
  ) {
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
