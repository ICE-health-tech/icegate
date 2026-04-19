import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/ui_layer/health_page/HealthMetricCard.dart';
import 'package:ice_gate/ui_layer/health_page/models/HealthMetric.dart';
import 'package:ice_gate/data_layer/Protocol/Health/HealthMetricsData.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/ui_layer/health_page/widgets/QuickActionButton.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
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
    _gridAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No retry logic needed here — initState schedules load via addPostFrameCallback.
    // didChangeAppLifecycleState handles app-resume reloads.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHealthData();
    }
  }

  Future<void> _loadHealthData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final today = DateTime.now();
      final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
      final data = await HealthMetricsData.getMetricsByDay(
        personId,
        today,
        context,
      );

      if (mounted) {
        setState(() {
          _healthMetrics = data;
          _isLoading = false;
        });
        _gridAnimationController.forward(from: 0.0);
      }
    } catch (e, stack) {
      // Log full stack so we can diagnose future issues
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
                  // Modern Transparent App Bar
                  SliverAppBar(
                    expandedHeight: 60,
                    collapsedHeight: 70,
                    pinned: true,
                    toolbarHeight: 70,
                    backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
                    elevation: 0,
                    centerTitle: false,
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.7),
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      _buildHeaderButton(
                        context,
                        icon: Icons.hub_rounded,
                        onPressed: () => context.push('/health/integrations'),
                      ),
                    ],
                  ),

                  // Greeting / Date Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                  _isLoading
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Watch((context) {
                          final healthBlock = context.read<HealthBlock>();
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

                          final List<HealthMetric>
                          displayMetrics = _healthMetrics.values.map((m) {
                            if (m.id == 'steps') {
                              return m.copyWith(
                                value: currentSteps.toString(),
                                progress: (currentSteps / STEP_GOAL).clamp(
                                  0.0,
                                  1.0,
                                ),
                              );
                            }
                            if (m.id == 'sleep') {
                              return m.copyWith(
                                value: currentSleep.toStringAsFixed(1),
                                progress: (currentSleep / SLEEP_GOAL).clamp(
                                  0.0,
                                  1.0,
                                ),
                              );
                            }
                            if (m.id == 'heart_rate') {
                              return m.copyWith(
                                value: currentHR > 0
                                    ? currentHR.toString()
                                    : m.value,
                              );
                            }
                            if (m.id == 'weight' && currentWeight > 0) {
                              return m.copyWith(
                                value: currentWeight.toStringAsFixed(1),
                              );
                            }
                            // Reactively update water card from the live signal.
                            // This ensures the card reflects real-time water_logs sum.
                            if (m.id == 'water' && currentWaterMl > 0) {
                              return m.copyWith(
                                value: currentWaterMl.toString(),
                                progress: (currentWaterMl / WATER_GOAL).clamp(
                                  0.0,
                                  1.0,
                                ),
                              );
                            }
                            // Reactively update exercise card from the live signal.
                            // Driven by _exerciseSubscription → SUM(exercise_logs.duration_minutes).
                            if (m.id == 'exercise' && currentExerciseMin > 0) {
                              return m.copyWith(
                                value: currentExerciseMin.toString(),
                                progress: (currentExerciseMin / EXERCISE_GOAL)
                                    .clamp(0.0, 1.0),
                              );
                            }
                            return m;
                          }).toList();

                          return SliverPadding(
                            padding: const EdgeInsets.all(16.0),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: compact ? 2 : 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: compact ? 0.92 : 1.1,
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
}
