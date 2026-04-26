import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'dart:ui';

class GoalConfigurationWidget extends StatelessWidget {
  const GoalConfigurationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final healthBlock = context.read<HealthBlock>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Deep Base Background
          Container(
            color: isDark ? const Color(0xFF0A0A0E) : const Color(0xFFF0F2F5),
          ),

          // 2. Animated/Static Tactical Grid Background
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.3 : 0.1,
              child: CustomPaint(
                painter: TacticalGridPainter(
                  color: colorScheme.primary,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          // 3. Ambient Glows
          Positioned(
            top: -100,
            right: -100,
            child: _buildAmbientGlow(colorScheme.primary, 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildAmbientGlow(colorScheme.secondary, 250),
          ),

          // 4. Main Glassmorphic Scrollable Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurface,
                      size: 32,
                    ),
                  ),
                  expandedHeight: 120,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    centerTitle: false,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.goal_target_evolution.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.goal_mission,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildGlassCard(
                          context,
                          child: Column(
                            children: [
                              _buildTacticalSlider(
                                context,
                                label: AppLocalizations.of(context)!.goal_step_target,
                                icon: Icons.directions_run_rounded,
                                color: colorScheme.primary,
                                valueSignal: healthBlock.dailyStepGoal,
                                min: 2000,
                                max: 30000,
                                divisions: 56,
                              ),
                              const Divider(height: 60, thickness: 0.5, indent: 10, endIndent: 10),
                              _buildTacticalSlider(
                                context,
                                label: AppLocalizations.of(context)!.goal_calorie_limit,
                                icon: Icons.local_fire_department_rounded,
                                color: const Color(0xFFFF4E00),
                                valueSignal: healthBlock.dailyKcalGoal,
                                min: 1200,
                                max: 5000,
                                divisions: 38,
                                suffix: " ${AppLocalizations.of(context)!.unit_kcal}",
                              ),
                              const Divider(height: 60, thickness: 0.5, indent: 10, endIndent: 10),
                              _buildTacticalSlider(
                                context,
                                label: AppLocalizations.of(context)!.goal_water_target,
                                icon: Icons.water_drop_rounded,
                                color: const Color(0xFF00B2FF),
                                valueSignal: healthBlock.dailyWaterGoal,
                                min: 500,
                                max: 5000,
                                divisions: 45,
                                suffix: " ${AppLocalizations.of(context)!.unit_ml}",
                              ),
                              const Divider(height: 60, thickness: 0.5, indent: 10, endIndent: 10),
                              _buildTacticalSlider(
                                context,
                                label: AppLocalizations.of(context)!.goal_focus_target,
                                icon: Icons.timer_rounded,
                                color: const Color(0xFFAD00FF),
                                valueSignal: healthBlock.dailyFocusGoal,
                                min: 10,
                                max: 480,
                                divisions: 47,
                                suffix: " ${AppLocalizations.of(context)!.unit_min}",
                              ),
                              const Divider(height: 60, thickness: 0.5, indent: 10, endIndent: 10),
                              _buildTacticalSlider(
                                context,
                                label: AppLocalizations.of(context)!.goal_exercise_target,
                                icon: Icons.fitness_center_rounded,
                                color: const Color(0xFFFFD600),
                                valueSignal: healthBlock.dailyExerciseGoal,
                                min: 10,
                                max: 180,
                                divisions: 17,
                                suffix: " ${AppLocalizations.of(context)!.unit_min}",
                              ),
                              const Divider(height: 60, thickness: 0.5, indent: 10, endIndent: 10),
                              _buildDoubleTacticalSlider(
                                context,
                                label: AppLocalizations.of(context)!.goal_sleep_target,
                                icon: Icons.bedtime_rounded,
                                color: const Color(0xFF5D5FEF),
                                valueSignal: healthBlock.dailySleepGoal,
                                min: 4.0,
                                max: 12.0,
                                divisions: 16,
                                suffix: " ${AppLocalizations.of(context)!.unit_hours}",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTacticalSlider(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Signal<int> valueSignal,
    required double min,
    required double max,
    required int divisions,
    String suffix = "",
  }) {
    return Watch((context) {
      final value = valueSignal.value.toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                "${value.toInt()}$suffix",
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCustomSlider(context, value, min, max, divisions, color, (val) {
            valueSignal.value = val.toInt();
          }),
        ],
      );
    });
  }

  Widget _buildDoubleTacticalSlider(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Signal<double> valueSignal,
    required double min,
    required double max,
    required int divisions,
    String suffix = "",
  }) {
    return Watch((context) {
      final value = valueSignal.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                "${value.toStringAsFixed(1)}$suffix",
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCustomSlider(context, value, min, max, divisions, color, (val) {
            valueSignal.value = val;
          }),
        ],
      );
    });
  }

  Widget _buildCustomSlider(
    BuildContext context,
    double value,
    double min,
    double max,
    int divisions,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: color,
        inactiveTrackColor: color.withOpacity(0.1),
        thumbColor: Colors.white,
        thumbShape: TacticalThumbShape(color: color),
        overlayColor: color.withOpacity(0.2),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: (val) {
          if (val != value) {
            HapticFeedback.selectionClick();
            onChanged(val);
          }
        },
      ),
    );
  }
}

class TacticalThumbShape extends SliderComponentShape {
  final Color color;
  const TacticalThumbShape({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Outer Glow
    final Paint glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 12, glowPaint);

    // Main Thumb Circle
    final Paint mainPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, mainPaint);

    // Accent Ring
    final Paint ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 8, ringPaint);

    // Center Tactical Dot
    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, dotPaint);
  }
}

class TacticalGridPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  TacticalGridPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Small cross markers at intersections
    final markerPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1;
    
    for (double i = spacing; i < size.width; i += spacing * 4) {
      for (double j = spacing; j < size.height; j += spacing * 4) {
        canvas.drawLine(Offset(i - 4, j), Offset(i + 4, j), markerPaint);
        canvas.drawLine(Offset(i, j - 4), Offset(i, j + 4), markerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

