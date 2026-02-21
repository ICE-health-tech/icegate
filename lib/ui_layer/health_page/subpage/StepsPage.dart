import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/ui_layer/health_page/services/HealthService.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> {
  void initPlatformState() {
    // Platform state now managed by HealthBlock via DataLayer
  }

  @override
  void dispose() {
    super.dispose();
  }

  // local methods replaced by signals

  @override
  void initState() {
    super.initState();

    // Fetch steps from Apple Health and sync to block
    HealthService.fetchStepCount().then((steps) {
      if (mounted) {
        context.read<HealthBlock>().updateSteps(steps);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final healthBlock = context.watch<HealthBlock>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background Decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Activity Tracker',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.grid_view_rounded,
                          color: colorScheme.primary,
                        ),
                        onPressed: () =>
                            context.push('/health/steps/dashboard'),
                        tooltip: 'Steps Dashboard',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Main Steps Display
                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 30,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Steps Taken',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Watch((context) {
                              final steps = healthBlock.todaySteps.value;
                              final dailyGoal = healthBlock.dailyStepGoal.value;
                              final progress = (steps / dailyGoal).clamp(
                                0.0,
                                1.0,
                              );

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background Ring
                                  SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 15,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.surfaceContainerHighest,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  // Progress Ring
                                  SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 15,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  // Inner Text
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        steps.toString(),
                                        style: textTheme.displayLarge?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 48,
                                          letterSpacing: -2,
                                        ),
                                      ),
                                      Text(
                                        '/ ${dailyGoal.toString()}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 30),
                            Watch((context) {
                              final steps = healthBlock.todaySteps.value;
                              final dailyGoal = healthBlock.dailyStepGoal.value;
                              final progressPct = (steps / dailyGoal * 100)
                                  .clamp(0.0, 100.0);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${progressPct.toStringAsFixed(0)}% Completed',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    'Daily Statistics',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 15) / 2;
                      return Watch((context) {
                        final steps = healthBlock.todaySteps.value;
                        final total = healthBlock.totalSteps.value;
                        final dailyGoal = healthBlock.dailyStepGoal.value;
                        final remaining = (dailyGoal - steps).clamp(
                          0,
                          dailyGoal,
                        );
                        final distance = steps * 0.0008;
                        final calories = (steps * 0.04).round();

                        return Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          children: [
                            _buildModernStatCard(
                              context,
                              'Total Steps',
                              total.toString(),
                              'steps',
                              Icons.workspace_premium_rounded,
                              cardWidth,
                            ),
                            _buildModernStatCard(
                              context,
                              'Remaining',
                              remaining.toString(),
                              'steps',
                              Icons.flag_rounded,
                              cardWidth,
                            ),
                            _buildModernStatCard(
                              context,
                              'Distance',
                              distance.toStringAsFixed(2),
                              'km',
                              Icons.route_rounded,
                              cardWidth,
                            ),
                            _buildModernStatCard(
                              context,
                              'Calories',
                              calories.toString(),
                              'kcal',
                              Icons.local_fire_department_rounded,
                              cardWidth,
                            ),
                            _buildModernStatCard(
                              context,
                              'Active Time',
                              '${(steps / 100).round()}',
                              'min',
                              Icons.timer_rounded,
                              cardWidth,
                            ),
                          ],
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    double width,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(height: 15),
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$label ($unit)',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
