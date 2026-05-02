import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Health/HealthMetricsData.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/widgets/QuickActionButton.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/models/HealthMetric.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalBlock.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:drift/drift.dart' hide Column;

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "health",
      destination: "/health",
      mainFunction: () => context.go("/"),
      onLongPress: () => context.push('/health/analysis'),
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      size: size,
      icon: Icons.heart_broken,
      subButtons: [
        SubButton(
          icon: Icons.restaurant,
          backgroundColor: Colors.orange,
          onPressed: () {
            context.go('/health/food/comsume');
          },
        ),
        SubButton(
          icon: Icons.fitness_center,
          backgroundColor: Colors.red,
          onPressed: () => context.go('/health/exercise'),
        ),
        SubButton(
          icon: Icons.timer,
          backgroundColor: Colors.indigo,
          onPressed: () => context.go('/health/focus'),
        ),
        SubButton(
          icon: Icons.favorite,
          backgroundColor: Colors.pink,
          onPressed: () => context.go('/health/heart_rate'),
        ),
        SubButton(
          icon: Icons.water_drop,
          backgroundColor: Colors.cyan,
          onPressed: () {
            context.go('/health/water');
          },
        ),
      ],
    );
  }

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AppDatabase database;
  Map<String, HealthMetric> _healthMetrics = {};
  bool _isLoading = false;
  late bool compact;
  late AnimationController _gridAnimationController;

  /// Cached in [didChangeDependencies] so [dispose] can call
  /// [HealthBlock.stopRealtimeSync] without using a deactivated [context].
  HealthBlock? _healthBlock;

  @override
  void initState() {
    super.initState();
    database = context.read<AppDatabase>();
    WidgetsBinding.instance.addObserver(this);

    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Load after the first frame so AppLocalizations is fully resolved.
    // initState runs before the locale delegate provides AppLocalizations,
    // so calling it directly here would always get null locale and bail out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHealthData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthBlock?.stopRealtimeSync();
    _gridAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _healthBlock = context.read<HealthBlock>();
    // No retry logic needed here — initState schedules load via addPostFrameCallback.
    // didChangeAppLifecycleState handles app-resume reloads.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final healthBlock = context.read<HealthBlock>();
    if (state == AppLifecycleState.resumed) {
      _loadHealthData();
      healthBlock.startRealtimeSync();
    } else if (state == AppLifecycleState.paused) {
      healthBlock.stopRealtimeSync();
    }
  }

  Future<void> _loadHealthData() async {
    if (!mounted) return;

    final healthBlock = context.read<HealthBlock>();
    final hasData =
        healthBlock.hasInitialSync.value || _healthMetrics.isNotEmpty;

    // Only show full-page loading if we have absolutely no data yet
    if (!hasData) {
      setState(() => _isLoading = true);
    }

    try {
      final today = DateTime.now();
      final personId = Supabase.instance.client.auth.currentUser?.id ?? "";

      // 1. Fetch aggregated metrics from LOCAL DB first (Fast)
      // This ensures we show SOMETHING immediately if it exists
      final localData = await HealthMetricsData.getMetricsByDay(
        personId,
        today,
        context,
      );

      if (mounted) {
        final isInitialLoad = _healthMetrics.isEmpty;
        setState(() {
          _healthMetrics = localData;
          if (localData.isNotEmpty) _isLoading = false;
        });
        if (isInitialLoad && localData.isNotEmpty) {
          _gridAnimationController.forward(from: 0.0);
        }
      }

      // 2. Trigger fresh sync from Apple Health / Google Fit in background
      // This is "silent" and won't block the UI with a spinner
      try {
        await healthBlock.syncAllFromPlatform();
      } catch (e) {
        debugPrint('Background sync failed: $e');
      }

      // 3. Final refresh of local data after sync completes
      final syncedData = await HealthMetricsData.getMetricsByDay(
        personId,
        today,
        context,
      );

      if (mounted) {
        setState(() {
          _healthMetrics = syncedData;
          _isLoading = false;
        });
        // Start periodic "real-time" polling while on this page
        healthBlock.startRealtimeSync(interval: const Duration(seconds: 30));
      }
    } catch (e, stack) {
      debugPrint('Error loading health data: $e\n$stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logWeight(BuildContext context, HealthLogsDAO dao) async {
    final TextEditingController weightController = TextEditingController();
    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Log Weight"),
          content: TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: "Enter weight in kg",
              suffixText: "kg",
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight != null && weight > 0) {
                  final now = DateTime.now();
                  await dao.insertWeightLog(
                    WeightLogsTableCompanion.insert(
                      id: IDGen.generateUuid(),
                      personID: Value(personId),
                      weightKg: Value(weight),
                      timestamp: Value(now),
                      createdAt: Value(now),
                    ),
                  );
                  // Update the daily metrics record as well for trend tracking
                  await database.healthMetricsDAO.updateWeight(
                    personId,
                    now,
                    weight,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    compact = MediaQuery.of(context).size.width < 600;

    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        floatingActionButton: QuickActionButton(
          actions: [
            QuickAction(
              label: l10n.health_log_water,
              icon: Icons.water_drop,
              color: Colors.cyan,
              onTap: () => context.push('/health/water'),
            ),
            QuickAction(
              label: l10n.health_log_food,
              icon: Icons.restaurant,
              color: Colors.orange,
              onTap: () => context.push('/health/food/consume'),
            ),
            QuickAction(
              label: l10n.health_exercise,
              icon: Icons.fitness_center,
              color: Colors.red,
              onTap: () => context.push('/health/exercise'),
            ),
            QuickAction(
              label: l10n.health_focus,
              icon: Icons.timer,
              color: Colors.indigo,
              onTap: () => context.push('/health/focus'),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background aesthetics
            Positioned(
              top: -60,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.02),
                ),
              ),
            ),

            RefreshIndicator(
              onRefresh: _loadHealthData,
              displacement: 40,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // 0. Top spacing to clear the floating header
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),

                  // 1. Greeting / Date Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d',
                                ).format(DateTime.now()),
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              // const SizedBox(height: 4),
                              _buildHeaderButton(
                                context,
                                icon: Icons.hub_rounded,
                                onPressed: () =>
                                    context.push('/health/integrations'),
                              ),
                            ],
                          ),

                          Text(
                            "Your health at a glance.",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interactive Weight Tracking Section

                  // Health Metrics Grid
                  _isLoading && _healthMetrics.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : Watch((context) {
                          final healthBlock = context.read<HealthBlock>();
                          final envBlock = context.read<EnvironmentalBlock>();
                          final envData = envBlock.currentData.value;
                          final envLoading = envBlock.isLoading.value;

                          final currentSteps = healthBlock.todaySteps.value;
                          final currentSleep = healthBlock.todaySleep.value;
                          final currentHR = healthBlock.todayHeartRate.value;

                          final currentWeight = healthBlock.latestWeight.value;
                          print("current weight: $currentWeight");
                          final currentWaterMl = healthBlock.todayWater.value;

                          // todayExerciseMinutes is the SUM of exercise_logs.duration_minutes for today.
                          // Updated reactively by _exerciseSubscription whenever an exercise is logged.
                          final currentExerciseMin =
                              healthBlock.todayExerciseMinutes.value;

                          final currentCaloriesBurned =
                              healthBlock.todayCaloriesBurned.value;

                          final List<HealthMetric>
                          displayMetrics = _healthMetrics.values.map((m) {
                            if (m.id == 'steps') {
                              return m.copyWith(
                                value: currentSteps.toString(),
                                isLoading: healthBlock.isStepsLoading.value,
                                progress:
                                    (currentSteps /
                                            healthBlock.dailyStepGoal.value)
                                        .clamp(0.0, 1.0),
                              );
                            }
                            if (m.id == 'sleep') {
                              return m.copyWith(
                                value: currentSleep.toStringAsFixed(1),
                                isLoading: healthBlock.isSleepLoading.value,
                                progress:
                                    (currentSleep /
                                            healthBlock.dailySleepGoal.value)
                                        .clamp(0.0, 1.0),
                              );
                            }
                            if (m.id == 'heart_rate') {
                              return m.copyWith(
                                value: currentHR > 0
                                    ? currentHR.toString()
                                    : m.value,
                                isLoading: healthBlock.isHeartRateLoading.value,
                              );
                            }

                            if (m.id == 'weight' && currentWeight > 0) {
                              return m.copyWith(
                                value: currentWeight.toStringAsFixed(1),
                                isLoading: healthBlock.isWeightLoading.value,
                              );
                            }
                            // Reactively update water card from the live signal.
                            // This ensures the card reflects real-time water_logs sum.
                            if (m.id == 'water' && currentWaterMl > 0) {
                              return m.copyWith(
                                value: currentWaterMl.toString(),
                                isLoading: healthBlock.isWaterLoading.value,
                                progress:
                                    (currentWaterMl /
                                            healthBlock.dailyWaterGoal.value)
                                        .clamp(0.0, 1.0),
                              );
                            }
                            // Reactively update exercise card from the live signal.
                            // Driven by _exerciseSubscription → SUM(exercise_logs.duration_minutes).
                            if (m.id == 'exercise' && currentExerciseMin > 0) {
                              return m.copyWith(
                                value: currentExerciseMin.toString(),
                                isLoading: healthBlock.isExerciseLoading.value,
                                progress:
                                    (currentExerciseMin /
                                            healthBlock.dailyExerciseGoal.value)
                                        .clamp(0.0, 1.0),
                              );
                            }
                            if (m.id == 'food') {
                              return m.copyWith(
                                value: healthBlock.todayCaloriesConsumed.value.toString(),
                                isLoading: healthBlock.isCaloriesConsumedLoading.value,
                              );
                            }
                            if (m.id == 'calories') {
                              return m.copyWith(
                                value: currentCaloriesBurned.toString(),
                                isLoading:
                                    healthBlock.isCaloriesBurnedLoading.value,
                                progress:
                                    (currentCaloriesBurned /
                                            healthBlock.dailyKcalGoal.value)
                                        .clamp(0.0, 1.0),
                              );
                            }
                            if (m.id == 'oxygen_saturation') {
                              final currentOxygen =
                                  healthBlock.todayOxygenSaturation.value;
                              return m.copyWith(
                                value: currentOxygen > 0
                                    ? currentOxygen.toStringAsFixed(1)
                                    : m.value,
                                isLoading: healthBlock.isOxygenLoading.value,
                              );
                            }
                            return m;
                          }).toList();

                          // Add Environmental Metrics
                          if (envData != null) {
                            displayMetrics.add(HealthMetric(
                              id: 'weather',
                              name: l10n.health_weather,
                              value: '${envData.temperature.toStringAsFixed(1)}°C',
                              icon: _getWeatherIcon(envData.weatherCode),
                              color: Colors.amber,
                              unit: envData.weatherDescription,
                              subtitle: l10n.health_temperature_subtitle,
                              isLoading: envLoading,
                              source: 'Open-Meteo',
                              sourceIcon: Icons.cloud_queue_rounded,
                            ));

                            displayMetrics.add(HealthMetric(
                              id: 'air_quality',
                              name: l10n.health_air_quality,
                              value: envData.aqi.toString(),
                              icon: Icons.air_rounded,
                              color: _getAQIColor(envData.aqi),
                              unit: l10n.health_aqi_unit,
                              subtitle: envData.aqiStatus,
                              isLoading: envLoading,
                              source: 'Open-Meteo',
                              sourceIcon: Icons.eco_rounded,
                            ));
                          }

                          return SliverPadding(
                            padding: const EdgeInsets.all(16.0),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: compact ? 2 : 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: compact ? 0.88 : 1.1,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final animation =
                                    Tween<double>(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(
                                        parent: _gridAnimationController,
                                        curve: Interval(
                                          (1 / displayMetrics.length) * index,
                                          1.0,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                    );

                                return FadeTransition(
                                  opacity: animation,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      20 * (1.0 - animation.value),
                                    ),
                                    child: HealthMetricCard(
                                      metrics: displayMetrics[index],
                                    ),
                                  ),
                                );
                              }, childCount: displayMetrics.length),
                            ),
                          );
                        }),

                  // Bottom padding to avoid FAB overlap
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: colorScheme.onSurface),
      ),
      onPressed: onPressed,
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.wb_cloudy_rounded;
    if (code <= 48) return Icons.foggy;
    if (code <= 57) return Icons.grain_rounded;
    if (code <= 67) return Icons.umbrella_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    if (code <= 82) return Icons.beach_access_rounded;
    if (code <= 99) return Icons.thunderstorm_rounded;
    return Icons.cloud_circle_rounded;
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }
}
