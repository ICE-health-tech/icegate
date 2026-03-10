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
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: colorScheme.surface.withOpacity(0.4),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_fullscreen_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.goal_target_evolution,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Tactical Background Overlay
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.15 : 0.08,
              child: Image.asset(
                'assets/tactical_bg.png',
                fit: BoxFit.cover,
                color: isDark ? null : colorScheme.primary.withOpacity(0.5),
                colorBlendMode: isDark ? BlendMode.dst : BlendMode.srcATop,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.05),
                  colorScheme.surface,
                ],
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Window Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        isDark ? 0.4 : 0.7,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.05),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.goal_mission,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.radar_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.goal_mission_desc,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Goal Sliders
                        _buildGoalSlider(
                          context: context,
                          label: AppLocalizations.of(context)!.goal_step_target,

                          icon: Icons.directions_run_rounded,
                          color: colorScheme.primary,
                          valueSignal: healthBlock.dailyStepGoal,
                          min: 2000,
                          max: 30000,
                          divisions: 56,
                        ),

                        const SizedBox(height: 48),

                        _buildGoalSlider(
                          context: context,
                          label: AppLocalizations.of(
                            context,
                          )!.goal_calorie_limit,
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF3D00),
                          valueSignal: healthBlock.dailyKcalGoal,
                          min: 1200,
                          max: 5000,
                          divisions: 38,
                          suffix: " ${AppLocalizations.of(context)!.unit_kcal}",
                        ),

                        const SizedBox(height: 48),

                        _buildGoalSlider(
                          context: context,
                          label: AppLocalizations.of(
                            context,
                          )!.goal_water_target,
                          icon: Icons.water_drop_rounded,
                          color: Colors.blueAccent,
                          valueSignal: healthBlock.dailyWaterGoal,
                          min: 500,
                          max: 5000,
                          divisions: 45,
                          suffix: " ${AppLocalizations.of(context)!.unit_ml}",
                        ),

                        const SizedBox(height: 48),

                        _buildGoalSlider(
                          context: context,
                          label: AppLocalizations.of(
                            context,
                          )!.goal_focus_target,
                          icon: Icons.timer_rounded,
                          color: Colors.purpleAccent,
                          valueSignal: healthBlock.dailyFocusGoal,
                          min: 10,
                          max: 480,
                          divisions: 47,
                          suffix: " ${AppLocalizations.of(context)!.unit_min}",
                        ),

                        const SizedBox(height: 48),

                        _buildGoalSlider(
                          context: context,
                          label: AppLocalizations.of(
                            context,
                          )!.goal_exercise_target,
                          icon: Icons.fitness_center_rounded,
                          color: Colors.orangeAccent,
                          valueSignal: healthBlock.dailyExerciseGoal,
                          min: 10,
                          max: 180,
                          divisions: 17,
                          suffix: " ${AppLocalizations.of(context)!.unit_min}",
                        ),

                        const SizedBox(height: 48),

                        _buildDoubleGoalSlider(
                          context: context,
                          label: AppLocalizations.of(
                            context,
                          )!.goal_sleep_target,
                          icon: Icons.bedtime_rounded,
                          color: Colors.indigoAccent,
                          valueSignal: healthBlock.dailySleepGoal,
                          min: 4.0,
                          max: 12.0,
                          divisions: 16,
                          suffix:
                              " ${AppLocalizations.of(context)!.unit_hours}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tactical Tip Card
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSlider({
    required BuildContext context,
    required String label,
    // required String jpLabel,
    required IconData icon,
    required Color color,
    required Signal<int> valueSignal,
    required double min,
    required double max,
    required int divisions,
    String suffix = "",
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Watch((context) {
      final value = valueSignal.value.toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  "${value.toInt()}$suffix",
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              activeTrackColor: color,
              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.1),
              thumbColor: colorScheme.onSurface,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 10,
              ),
              overlayColor: color.withOpacity(0.2),
              valueIndicatorColor: color,
              valueIndicatorTextStyle: TextStyle(
                color: colorScheme.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (newValue) {
                if (newValue != value) {
                  HapticFeedback.selectionClick();
                  valueSignal.value = newValue.toInt();
                }
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDoubleGoalSlider({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Signal<double> valueSignal,
    required double min,
    required double max,
    required int divisions,
    String suffix = "",
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Watch((context) {
      final value = valueSignal.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  "${value.toStringAsFixed(1)}$suffix",
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              activeTrackColor: color,
              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.1),
              thumbColor: colorScheme.onSurface,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 10,
              ),
              overlayColor: color.withOpacity(0.2),
              valueIndicatorColor: color,
              valueIndicatorTextStyle: TextStyle(
                color: colorScheme.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (newValue) {
                if (newValue != value) {
                  HapticFeedback.selectionClick();
                  valueSignal.value = newValue;
                }
              },
            ),
          ),
        ],
      );
    });
  }
}
