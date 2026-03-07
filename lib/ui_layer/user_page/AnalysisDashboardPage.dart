import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';

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
      final level = scoreBlock.globalLevel.watch(context);
      final progress = scoreBlock.levelProgress.watch(context);
      final rank = scoreBlock.rankTitle.watch(context);

      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => WidgetNavigatorAction.smartPop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.auto_graph_rounded, color: colorScheme.primary),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- GUEST BANNER ---
              if (context.watch<AuthBlock>().username.value == 'Guest')
                _buildGuestBanner(colorScheme, context),

              // --- TITLE ---
              Text(
                'Overview',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),

              // --- SECTOR GRID ---
              _buildSectorGrid(context, scoreBlock),
              const SizedBox(height: 32),

              // --- BALANCE CHART ---
              _buildBalanceSection(context, scoreBlock),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGuestBanner(ColorScheme colorScheme, BuildContext context) {
    return Padding(
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: colorScheme.primary),
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
              onPressed: () => context.push('/login'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Sync"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    int level,
    String rank,
    double progress,
    double totalXP,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LEVEL $level",
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.7),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    rank,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: colorScheme.onPrimary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(progress * 100).toInt()}% to level ${level + 1}",
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Total XP: ${totalXP.toInt()}",
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectorGrid(BuildContext context, ScoreBlock scoreBlock) {
    final score = scoreBlock.score;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85, // Adjusted for breakdown text
      children: [
        Watch(
          (context) => _buildSectorCard(
            context,
            title: "HEALTH",
            value: score.healthGlobalScore.toInt().toString(),
            icon: Icons.favorite_rounded,
            color: Colors.green,
            breakdown: scoreBlock.healthBreakdown.value,
            onTap: () => context.push('/health/dashboard'),
          ),
        ),
        Watch(
          (context) => _buildSectorCard(
            context,
            title: "FINANCE",
            value: score.financialGlobalScore.toInt().toString(),
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.blue,
            breakdown: scoreBlock.financeBreakdown.value,
            onTap: () => context.push('/finance/dashboard'),
          ),
        ),
        Watch(
          (context) => _buildSectorCard(
            context,
            title: "SOCIAL",
            value: score.socialGlobalScore.toInt().toString(),
            icon: Icons.people_alt_rounded,
            color: Colors.purple,
            breakdown: scoreBlock.socialBreakdown.value,
            onTap: () => context.push('/social/dashboard'),
          ),
        ),
        Watch(
          (context) => _buildSectorCard(
            context,
            title: "PROJECTS",
            value: score.careerGlobalScore.toInt().toString(),
            icon: Icons.rocket_launch_rounded,
            color: Colors.orange,
            breakdown: scoreBlock.projectsBreakdown.value,
            onTap: () => context.push('/projects/dashboard'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectorCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Map<String, double> breakdown,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Fallback for non-zero scores with empty breakdowns (e.g. at startup)
    final displayBreakdown = Map<String, double>.from(breakdown);
    if (displayBreakdown.isEmpty && (double.tryParse(value) ?? 0) > 0) {
      displayBreakdown['Base'] = double.tryParse(value) ?? 0;
    }

    IconData _getBreakdownIcon(String key) {
      switch (key.toLowerCase()) {
        case 'steps':
          return Icons.directions_walk_rounded;
        case 'diet':
          return Icons.restaurant_rounded;
        case 'exercise':
          return Icons.fitness_center_rounded;
        case 'focus':
          return Icons.timer_rounded;
        case 'water':
          return Icons.water_drop_rounded;
        case 'sleep':
          return Icons.bedtime_rounded;
        case 'contacts':
          return Icons.person_rounded;
        case 'affection':
          return Icons.favorite_rounded;
        case 'quests':
          return Icons.auto_awesome_rounded;
        case 'accounts':
          return Icons.savings_rounded;
        case 'assets':
          return Icons.inventory_2_rounded;
        case 'tasks':
          return Icons.task_alt_rounded;
        case 'projects':
          return Icons.rocket_rounded;
        case 'system':
          return Icons.history_rounded;
        default:
          return Icons.adjust_rounded;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            const Divider(height: 16, thickness: 0.5),
            ...displayBreakdown.entries
                .where((e) => e.value != 0)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Icon(
                          _getBreakdownIcon(e.key),
                          size: 10,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          e.value > 0
                              ? "+${e.value.toInt()}"
                              : e.value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: e.value > 0 ? color : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context, ScoreBlock scoreBlock) {
    final score = scoreBlock.score;
    final distributionData = {
      'Health': score.healthGlobalScore,
      'Finance': score.financialGlobalScore,
      'Social': score.socialGlobalScore,
      'Projects': score.careerGlobalScore,
    };

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SCORE BALANCE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SimplePieChart(
                data: distributionData,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.orange,
                ],
                size: 120,
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: distributionData.entries.map((e) {
                    final percent =
                        (e.value /
                                distributionData.values.fold(
                                  0.1,
                                  (sum, val) => sum + val,
                                ) *
                                100)
                            .toInt();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getColorForSector(e.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "$percent%",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
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
}
