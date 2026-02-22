import 'package:flutter/material.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/SwipeablePage.dart';

class HealthAnalysisPage extends StatelessWidget {
  const HealthAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SwipeablePage(
      direction: SwipeablePageDirection.leftToRight,
      onSwipe: () => WidgetNavigatorAction.smartPop(context),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colorScheme.onSurface,
              size: 22,
            ),
            onPressed: () => WidgetNavigatorAction.smartPop(context),
          ),
          title: Text(
            'Health Analysis',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_graph_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PERFORMANCE ANALYSIS SECTION ---
              _buildPerformanceCard(context, colorScheme, textTheme),
              const SizedBox(height: 24),

              // --- ACTIVITY BALANCE SECTION ---
              _buildActivityBalanceCard(context, colorScheme, textTheme),
              const SizedBox(height: 24),

              // --- WEEKLY TRENDS SECTION ---
              _buildWeeklyTrendsCard(context, colorScheme, textTheme),
              const SizedBox(height: 24),

              // --- HEALTH INSIGHTS SECTION ---
              _buildInsightsCard(context, colorScheme, textTheme),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERFORMANCE ANALYSIS',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildAnalysisGridItem(
                context,
                'Efficiency',
                '92%',
                Icons.bolt_rounded,
                Colors.amber,
              ),
              _buildAnalysisGridItem(
                context,
                'Consistency',
                'High',
                Icons.repeat_rounded,
                Colors.green,
              ),
              _buildAnalysisGridItem(
                context,
                'Metabolism',
                'Active',
                Icons.speed_rounded,
                Colors.orange,
              ),
              _buildAnalysisGridItem(
                context,
                'Intensity',
                'Optimal',
                Icons.fitness_center_rounded,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBalanceCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVITY BALANCE',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SimplePieChart(
                data: {'Steps': 40, 'Exercise': 30, 'Other': 30},
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                  colorScheme.tertiary,
                ],
                size: 80,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Balance',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your workout distribution looks balanced today.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLegendRow(
                      colorScheme.primary,
                      'Steps',
                      '40%',
                      textTheme,
                    ),
                    const SizedBox(height: 4),
                    _buildLegendRow(
                      colorScheme.secondary,
                      'Exercise',
                      '30%',
                      textTheme,
                    ),
                    const SizedBox(height: 4),
                    _buildLegendRow(
                      colorScheme.tertiary,
                      'Other',
                      '30%',
                      textTheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(
    Color color,
    String label,
    String value,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendsCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WEEKLY TRENDS',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendStat('Avg Steps', '5,230', colorScheme, textTheme),
              _buildTrendStat('Avg Sleep', '7.2h', colorScheme, textTheme),
              _buildTrendStat('Avg HR', '72 bpm', colorScheme, textTheme),
            ],
          ),
          const SizedBox(height: 20),
          // Simple bar chart representation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBarDay('M', 0.6, colorScheme),
              _buildBarDay('T', 0.8, colorScheme),
              _buildBarDay('W', 0.5, colorScheme),
              _buildBarDay('T', 0.9, colorScheme),
              _buildBarDay('F', 0.7, colorScheme),
              _buildBarDay('S', 1.0, colorScheme),
              _buildBarDay('S', 0.4, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarDay(String label, double height, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 80 * height,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.2 + height * 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'INSIGHTS',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.trending_up_rounded,
            Colors.green,
            'Great Progress',
            'Your activity levels are 15% higher than last week.',
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.bedtime_rounded,
            Colors.indigo,
            'Sleep Quality',
            'Consider going to bed 30 minutes earlier for optimal recovery.',
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.water_drop_rounded,
            Colors.cyan,
            'Hydration',
            'You\'re on track with your daily water intake goal!',
            colorScheme,
            textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    Color color,
    String title,
    String description,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisGridItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
}
