import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Daily health goal sliders styled like [FinanceDailyReportPage] for embedding in [HealthPage].
class HealthGoalConfigurationPanel extends StatelessWidget {
  const HealthGoalConfigurationPanel({
    super.key,
    this.showExtendedGoals = true,
    this.showHeader = true,
  });

  final bool showExtendedGoals;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final healthBlock = context.read<HealthBlock>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text(
            l10n.goal_target_evolution.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white54,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.goal_mission,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.goal_mission_desc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white38,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: EntryColors.glassBorder.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                _GoalSliderRow(
                  label: l10n.goal_step_target,
                  icon: Icons.directions_run_rounded,
                  color: EntryColors.primaryIceBlue,
                  valueSignal: healthBlock.dailyStepGoal,
                  min: 2000,
                  max: 30000,
                  divisions: 56,
                ),
                const SizedBox(height: 12),
                _GoalSliderRow(
                  label: l10n.goal_calorie_limit,
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent,
                  valueSignal: healthBlock.dailyKcalGoal,
                  min: 1200,
                  max: 5000,
                  divisions: 38,
                  suffix: ' ${l10n.unit_kcal}',
                ),
                const SizedBox(height: 12),
                _GoalSliderRow(
                  label: l10n.goal_water_target,
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF00B2FF),
                  valueSignal: healthBlock.dailyWaterGoal,
                  min: 500,
                  max: 5000,
                  divisions: 45,
                  suffix: ' ${l10n.unit_ml}',
                ),
                const SizedBox(height: 12),
                _GoalSliderRow(
                  label: l10n.goal_focus_target,
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFAD00FF),
                  valueSignal: healthBlock.dailyFocusGoal,
                  min: 10,
                  max: 480,
                  divisions: 47,
                  suffix: ' ${l10n.unit_min}',
                ),
                if (showExtendedGoals) ...[
                  const SizedBox(height: 12),
                  _GoalSliderRow(
                    label: l10n.goal_exercise_target,
                    icon: Icons.fitness_center_rounded,
                    color: const Color(0xFFFFD600),
                    valueSignal: healthBlock.dailyExerciseGoal,
                    min: 10,
                    max: 180,
                    divisions: 17,
                    suffix: ' ${l10n.unit_min}',
                  ),
                  const SizedBox(height: 12),
                  _DoubleGoalSliderRow(
                    label: l10n.goal_sleep_target,
                    icon: Icons.bedtime_rounded,
                    color: const Color(0xFF5D5FEF),
                    valueSignal: healthBlock.dailySleepGoal,
                    min: 4.0,
                    max: 12.0,
                    divisions: 16,
                    suffix: ' ${l10n.unit_hours}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalSliderRow extends StatelessWidget {
  const _GoalSliderRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.valueSignal,
    required this.min,
    required this.max,
    required this.divisions,
    this.suffix = '',
  });

  final String label;
  final IconData icon;
  final Color color;
  final Signal<int> valueSignal;
  final double min;
  final double max;
  final int divisions;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final value = valueSignal.value.toDouble();
      return _GoalGlassTile(
        label: label,
        icon: icon,
        color: color,
        valueLabel: '${value.toInt()}$suffix',
        child: _GoalSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          color: color,
          onChanged: (val) => valueSignal.value = val.toInt(),
        ),
      );
    });
  }
}

class _DoubleGoalSliderRow extends StatelessWidget {
  const _DoubleGoalSliderRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.valueSignal,
    required this.min,
    required this.max,
    required this.divisions,
    this.suffix = '',
  });

  final String label;
  final IconData icon;
  final Color color;
  final Signal<double> valueSignal;
  final double min;
  final double max;
  final int divisions;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final value = valueSignal.value;
      return _GoalGlassTile(
        label: label,
        icon: icon,
        color: color,
        valueLabel: '${value.toStringAsFixed(1)}$suffix',
        child: _GoalSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          color: color,
          onChanged: (val) => valueSignal.value = val,
        ),
      );
    });
  }
}

class _GoalGlassTile extends StatelessWidget {
  const _GoalGlassTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.valueLabel,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String valueLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: color.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Text(
                    valueLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSlider extends StatelessWidget {
  const _GoalSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.color,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: color,
        inactiveTrackColor: color.withValues(alpha: 0.15),
        thumbColor: Colors.white,
        overlayColor: color.withValues(alpha: 0.12),
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
