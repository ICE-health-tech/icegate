import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';

class AnalysisDashboardPage extends StatelessWidget {
  const AnalysisDashboardPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "profile",
      destination: "/profile",
      size: size,
      icon: Icons.home,
      mainFunction: () async {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final scoreBlock = context.watch<ScoreBlock>();

      final totalXP = scoreBlock.totalXP.watch(context);

      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // --- GUEST BANNER ---
              if (context.watch<AuthBlock>().username.value == 'Guest')
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.tertiary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Guest Mode",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Text(
                                "Synchronize to save your progress.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            context.push('/login');
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text("Sync"),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- SECTION: ANALYSIS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analysis Center',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Icon(Icons.auto_graph_rounded, color: colorScheme.primary),
                ],
              ),
              const SizedBox(height: 16),
              _buildAnalysisSection(context, colorScheme, scoreBlock, totalXP),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAnalysisSection(
    BuildContext context,
    ColorScheme colorScheme,
    ScoreBlock scoreBlock,
    double totalXP,
  ) {
    final trendData = [0.4, 0.5, 0.45, 0.6, 0.55, 0.7, 0.85];
    final score = scoreBlock.score;
    final distributionData = {
      'Health': score.healthGlobalScore,
      'Finance': score.financialGlobalScore,
      'Social': score.socialGlobalScore,
      'Projects': score.careerGlobalScore,
    };

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/health/exercise/dashboard'),
          child: _buildAnalysisCard(
            context,
            title: "Health Analysis",
            subtitle: "Detailed wellness & activity report",
            icon: Icons.health_and_safety_rounded,
            color: Colors.green,
            content: Column(
              children: [
                SimpleLineChart(
                  data: trendData,
                  color: Colors.green,
                  height: 80,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "View Detailed Report",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnalysisCard(
          context,
          title: "Score Distribution",
          subtitle: "Sector balance",
          icon: Icons.pie_chart_rounded,
          color: Colors.blue,
          content: Row(
            children: [
              SimplePieChart(
                data: distributionData,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.orange,
                ],
                size: 80,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: distributionData.entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getColorForSector(e.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${e.value.toInt()}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAnalysisCard(
          context,
          title: "Total Life Score",
          subtitle: "Overall progress and alignment",
          icon: Icons.auto_awesome_rounded,
          color: Colors.amber,
          content: Column(
            children: [
              Text(
                "${totalXP.toInt()}",
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.amber,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You're becoming a legend!",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorForSector(String sector) {
    switch (sector) {
      case 'Health':
        return Colors.green;
      case 'Finance':
        return Colors.blue;
      case 'Social':
        return Colors.purple;
      case 'Projects':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAnalysisCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
