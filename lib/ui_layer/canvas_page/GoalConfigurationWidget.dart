import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
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
                    "TARGET EVOLUTION",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    "ターゲット進化",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.settings_input_component_rounded,
                    color: colorScheme.primary,
                  ),
                ),
              ],
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
                                  "MISSION",
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "PROTOCOL [7-X]",
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
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
                          "Configure your physical parameters to ensure optimal AI synchronization and field performance.",
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
                          label: "STEP TARGET",
                    
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
                          label: "CALORIE LIMIT",
                       
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF3D00),
                          valueSignal: healthBlock.dailyKcalGoal,
                          min: 1200,
                          max: 5000,
                          divisions: 38,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tactical Tip Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Consistent parameter settings enhance predictive accuracy for energy expenditure analysis.",
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  value.toInt().toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
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
}
