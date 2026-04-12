import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/ui_layer/health_page/services/HealthService.dart';
import 'package:ice_gate/ui_layer/UIConstants.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';

class StepsPage extends StatefulWidget {
  const StepsPage({super.key});

  @override
  State<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends State<StepsPage> with SingleTickerProviderStateMixin {
  final ScrollController _hourlyChartController = ScrollController();
  late AnimationController _fadeController;
  int? _selectedHour;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController.forward();

    final healthBlock = context.read<HealthBlock>();

    // 1. Fetch today's steps & hourly data
    HealthService.fetchStepCount().then((steps) {
      if (mounted) {
        healthBlock.updateSteps(steps);
      }
    });
    
    HealthService.fetchHourlyStepsForDay(DateTime.now()).then((hourly) {
      if (mounted) {
        healthBlock.updateHourlySteps(hourly);
      }
    });

    // 2. Sync last 7 days automatically in background
    healthBlock.syncHistory(HealthService.fetchStepsForDay);

    // Auto-scroll to current hour after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hourlyChartController.hasClients) {
        final currentHour = DateTime.now().hour;
        final barWidth = UIConstants.getChartBarWidth(context);
        // Each bar container has width (barWidth + 14) and horizontal margin 10 (total 20)
        final barTotalWidth = barWidth + 34; 
        final screenWidth = MediaQuery.of(context).size.width;
        
        final scrollPosition = (barTotalWidth * currentHour) + (barTotalWidth / 2) - (screenWidth / 2);
        
        _hourlyChartController.animateTo(
          scrollPosition.clamp(0, _hourlyChartController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _hourlyChartController.dispose();
    _fadeController.dispose();
    super.dispose();
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
          // Background Aesthetic Gradients
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildRoundButton(
                            context,
                            icon: Icons.arrow_back_ios_new,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Column(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.health_activity_tracker,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, MMM d').format(DateTime.now()),
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildRoundButton(
                                context,
                                icon: Icons.sync_rounded,
                                color: colorScheme.primary,
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text("Syncing health data..."), duration: Duration(seconds: 1)),
                                  );
                                  
                                  // 1. Specifically sync today's steps first
                                  await healthBlock.syncTodaySteps(HealthService.fetchStepCount);
                                  
                                  // 2. Then sync the rest of history
                                  await healthBlock.syncHistory(HealthService.fetchStepsForDay);
                                  
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text("Sync complete!"), duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildRoundButton(
                                context,
                                icon: Icons.grid_view_rounded,
                                color: colorScheme.secondary,
                                onPressed: () => context.push('/health/steps/dashboard'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main Steps Ring
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: _buildStepProgressRing(context, healthBlock),
                      ),
                    ),
                  ),

                  // Hourly Chart
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: _buildRobustHourlyChart(context, healthBlock),
                    ),
                  ),

                  // Stats Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        AppLocalizations.of(context)!.health_daily_statistics,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    sliver: Watch((context) {
                      final steps = healthBlock.todaySteps.value;
                      final total = healthBlock.totalSteps.value;
                      final dailyGoal = healthBlock.dailyStepGoal.value;
                      final remaining = (dailyGoal - steps).clamp(0, dailyGoal);
                      final distance = steps * 0.0008;
                      final calories = (steps * 0.04).round();
                      final activeMin = (steps / 100).round();

                      return SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildListDelegate([
                          _buildRobustStatCard(
                            context,
                            label: AppLocalizations.of(context)!.health_lifetime_total,
                            value: total.toString(),
                            unit: 'steps',
                            icon: Icons.auto_awesome_rounded,
                            color: Colors.amber,
                          ),
                          _buildRobustStatCard(
                            context,
                            label: AppLocalizations.of(context)!.health_remaining,
                            value: remaining.toString(),
                            unit: 'steps',
                            icon: Icons.flag_circle_rounded,
                            color: Colors.blue,
                          ),
                          _buildRobustStatCard(
                            context,
                            label: AppLocalizations.of(context)!.health_distance,
                            value: distance.toStringAsFixed(2),
                            unit: 'km',
                            icon: Icons.directions_run_rounded,
                            color: Colors.green,
                          ),
                          _buildRobustStatCard(
                            context,
                            label: AppLocalizations.of(context)!.health_calories,
                            value: calories.toString(),
                            unit: 'kcal',
                            icon: Icons.local_fire_department_rounded,
                            color: Colors.orange,
                          ),
                          _buildRobustStatCard(
                            context,
                            label: AppLocalizations.of(context)!.health_active_time,
                            value: activeMin.toString(),
                            unit: 'min',
                            icon: Icons.timer_rounded,
                            color: Colors.purple,
                          ),
                        ]),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(BuildContext context, {required IconData icon, required VoidCallback onPressed, Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color ?? colorScheme.onSurface),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildStepProgressRing(BuildContext context, HealthBlock healthBlock) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Watch((context) {
      final steps = healthBlock.todaySteps.value;
      final dailyGoal = healthBlock.dailyStepGoal.value;
      final progress = (steps / dailyGoal).clamp(0.0, 1.0);
      final progressPct = (progress * 100).toInt();

      return Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Styled Rings
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 20,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                strokeCap: StrokeCap.round,
              ),
            ),
            SizedBox(
              width: 220,
              height: 220,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.elasticOut,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 20,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            // Inner Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  steps.toString(),
                  style: textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 42,
                    letterSpacing: -2,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "OF $dailyGoal GOAL",
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$progressPct%",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRobustHourlyChart(BuildContext context, HealthBlock healthBlock) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final containerHeight = UIConstants.getChartContainerHeight(context) + 40;
    final barMaxHeight = UIConstants.getChartBarMaxHeight(context)*0.8;
    final barWidth = UIConstants.getChartBarWidth(context);

    return Watch((context) {
      final hourly = healthBlock.hourlySteps.value;
      if (hourly.isEmpty) return const SizedBox.shrink();

      final maxSteps = hourly.values.fold<int>(1, (max, val) => val > max ? val : max);
      final currentHour = DateTime.now().hour;

      return ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: containerHeight + 20,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.035),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.015),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
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
                          "HOURLY ACTIVITY",
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Peak: $maxSteps steps",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedHour != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_rounded, color: colorScheme.primary, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              "${_selectedHour}:00 - ${hourly[_selectedHour] ?? 0}",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                                                      fontSize: UIConstants.getResponsiveFontSize(context, factor: 0.02, min: 6.0, max: 10.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hourlyChartController,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(24, (index) {
                        final steps = hourly[index] ?? 0;
                        final isCurrentHour = index == currentHour;
                        final isSelected = _selectedHour == index;
                        
                        // Robust height calculation
                        final barHeight = (steps == 0) 
                            ? 6.0 
                            : (math.pow(steps / maxSteps, 0.4) * barMaxHeight).clamp(6.0, barMaxHeight);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedHour = _selectedHour == index ? null : index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: barWidth + 16,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Step Count label
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: (steps > 0 || isSelected) ? 1.0 : 0.0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      steps.toString(),
                                      style: TextStyle(
                                        fontSize: UIConstants.getResponsiveFontSize(context, factor: 0.02, min: 6.0, max: 10.0),
                                        fontWeight: FontWeight.w900,
                                        color: isCurrentHour || isSelected 
                                            ? colorScheme.primary 
                                            : colorScheme.onSurface.withOpacity(0.35),
                                      ),
                                    ),
                                  ),
                                ),
                                // const Spacer(),
                                // Bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.elasticOut,
                                  width: barWidth + (isSelected ? 8 : 0),
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: isCurrentHour || isSelected
                                        ? [
                                            colorScheme.primary,
                                            colorScheme.primary.withOpacity(0.4),
                                          ]
                                        : [
                                            colorScheme.onSurface.withOpacity(0.04),
                                            colorScheme.onSurface.withOpacity(0.12),
                                          ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: (isCurrentHour || isSelected) ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.35),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      )
                                    ] : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Hour Label
                                Text(
                                  "${index}h",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isCurrentHour || isSelected 
                                        ? colorScheme.primary 
                                        : colorScheme.onSurface.withOpacity(0.3),
                                    fontWeight: isCurrentHour || isSelected ? FontWeight.w900 : FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRobustStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
