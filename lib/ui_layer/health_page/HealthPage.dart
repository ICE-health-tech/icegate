import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/health_page/HealthMetricCard.dart';
import 'package:ice_shield/ui_layer/health_page/models/HealthMetric.dart';
import 'package:ice_shield/data_layer/Protocol/Health/HealthMetricsData.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:ice_shield/ui_layer/health_page/widgets/QuickActionButton.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_shield/ui_layer/health_page/services/HealthService.dart';

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
            context.go('/health/food/dashboard');
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

class _HealthPageState extends State<HealthPage> with WidgetsBindingObserver {
  late AppDatabase database;
  Map<String, HealthMetric> _healthMetrics = {};
  bool _isLoading = false;
  late bool compact;

  @override
  void initState() {
    super.initState();
    database = context.read<AppDatabase>();
    WidgetsBinding.instance.addObserver(this);
    _loadHealthData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      }
    } catch (e) {
      debugPrint('Error loading health data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    compact = MediaQuery.of(context).size.width < 600;

    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        floatingActionButton: QuickActionButton(
          actions: [
            QuickAction(
              label: 'Log Water',
              icon: Icons.water_drop,
              color: Colors.cyan,
              onTap: () => context.push('/health/water'),
            ),
            QuickAction(
              label: 'Log Food',
              icon: Icons.restaurant,
              color: Colors.orange,
              onTap: () => context.push('/health/food/dashboard'),
            ),
            QuickAction(
              label: 'Exercise',
              icon: Icons.fitness_center,
              color: Colors.red,
              onTap: () => context.push('/health/exercise'),
            ),
            QuickAction(
              label: 'Focus',
              icon: Icons.timer,
              color: Colors.indigo,
              onTap: () => context.push('/health/focus'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadHealthData,
          displacement: 40,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Premium Header
              SliverAppBar(
                expandedHeight: 80,
                collapsedHeight: 70,
                pinned: true,
                toolbarHeight: 70,
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leadingWidth: 0,
                leading: const SizedBox.shrink(),
                actions: [
                
                  IconButton(
                    icon: const Icon(Icons.home_rounded, size: 30),
                    onPressed: () {
                      WidgetNavigatorAction.smartPop(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view, size: 30),
                    onPressed: () => context.go('/canvas'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 30),
                    onPressed: () => context.go('/settings'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Insights',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Health Metrics Grid
              _isLoading
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Watch((context) {
                      // Obtain the block once. Since it's not a signal, use read().
                      // The Watch() widget will track individual signals inside the block.
                      final healthBlock = context.read<HealthBlock>();
                      final currentSteps = healthBlock.todaySteps.value;

                      // Construct reactive metrics list for today
                      final stepGoal = STEP_GOAL;
                      final currentSleep = healthBlock.todaySleep.value;
                      final currentHR = healthBlock.todayHeartRate.value;

                      // Create a local copy/list to avoid mutating _healthMetrics during build
                      final List<HealthMetric> displayMetrics = _healthMetrics
                          .values
                          .map((m) {
                            if (m.id == 'steps') {
                              return m.copyWith(
                                value: currentSteps.toString(),
                                progress: (currentSteps / stepGoal).clamp(
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
                            return m;
                          })
                          .toList();

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: compact ? 2 : 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: compact ? 0.95 : 1.2,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return HealthMetricCard(
                              metrics: displayMetrics[index],
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
      ),
    );
  }
}
