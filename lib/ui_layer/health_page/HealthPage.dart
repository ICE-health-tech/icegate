import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';

import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/health_page/HealthMetricCard.dart';
import 'package:ice_shield/ui_layer/health_page/models/HealthMetric.dart';
import 'package:ice_shield/data_layer/Protocol/Health/HealthMetricsData.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:ice_shield/ui_layer/health_page/widgets/QuickActionButton.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/AnalysisCharts.dart';

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
  List<HealthMetricsLocal> _weeklyMetrics = [];
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
      final data = await HealthMetricsData.getMetricsByDay(today, context);

      // Fetch weekly metrics for trends analysis (default to person 1)
      // Use catchError and timeout for robustness
      final weeklyData = await database.healthMetricsDAO
          .watchAllMetrics(1)
          .first
          .timeout(const Duration(seconds: 1), onTimeout: () => [])
          .catchError((e) => <HealthMetricsLocal>[]);
      // Take top 7 (most recent) and reverse to chronological order for chart
      final last7Days = weeklyData.take(7).toList().reversed.toList();

      if (mounted) {
        setState(() {
          _healthMetrics = data;
          _weeklyMetrics = last7Days;
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
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: compact ? 2 : 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: compact ? 0.95 : 1.2,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return HealthMetricCard(
                            metrics: _healthMetrics.values.elementAt(index),
                          );
                        }, childCount: _healthMetrics.length),
                      ),
                    ),

              // Bottom padding to avoid FAB overlap
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendsSection(ColorScheme colorScheme, TextTheme textTheme) {
    // Data for the line chart
    final stepHistory = _weeklyMetrics.map((m) => m.steps.toDouble()).toList();
    if (stepHistory.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Trends',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1.5,
            ),
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
                        'ACTIVITY OVERVIEW',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Steps history (7d)',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SimpleLineChart(
                data: stepHistory,
                color: colorScheme.primary,
                height: 100,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7 days ago',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Today',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTrendStat(
                    'AVG STEPS',
                    '${(stepHistory.reduce((a, b) => a + b) / stepHistory.length).round()}',
                    colorScheme,
                    textTheme,
                  ),
                  _buildTrendStat(
                    'PEAK',
                    '${stepHistory.reduce(math.max).round()}',
                    colorScheme,
                    textTheme,
                  ),
                  _buildTrendStat(
                    'ACTIVE DAYS',
                    '${stepHistory.where((s) => s > 5000).length}/7',
                    colorScheme,
                    textTheme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisGridCard(ColorScheme colorScheme, TextTheme textTheme) {
    return GestureDetector(
      onTap: () => context.push('/health/analysis'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(28.0),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.auto_graph_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Analysis',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View detailed health insights & trends',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendStat(
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryCard(ColorScheme colorScheme, TextTheme textTheme) {
    // Count completed goals
    int completed = 0;
    int total = 0;
    for (var metric in _healthMetrics.values) {
      if (metric.progress != null) {
        total++;
        if (metric.progress! >= 1.0) {
          completed++;
        }
      }
    }

    String motivationText;
    IconData motivationIcon;
    if (total == 0 || _isLoading) {
      motivationText = 'Keep moving! You\'re doing great today.';
      motivationIcon = Icons.auto_awesome;
    } else if (completed == total) {
      motivationText = 'All $total goals completed! You\'re on fire! 🔥';
      motivationIcon = Icons.emoji_events_rounded;
    } else if (completed > 0) {
      motivationText = '$completed of $total goals done. Keep pushing! 💪';
      motivationIcon = Icons.trending_up_rounded;
    } else {
      motivationText = 'Start tracking your health goals for today!';
      motivationIcon = Icons.flag_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(motivationIcon, color: colorScheme.onPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'DAILY SUMMARY',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completed/$total',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            motivationText,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0,
                minHeight: 6,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
