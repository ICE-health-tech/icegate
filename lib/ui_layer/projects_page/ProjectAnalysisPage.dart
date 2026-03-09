import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ProjectAnalysisPage extends StatelessWidget {
  const ProjectAnalysisPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      size: size,
      icon: Icons.home,
      mainFunction: () {
        context.go("/");
        HapticFeedback.heavyImpact();
      },
      onLongPress: () {
        context.go("/");
        HapticFeedback.heavyImpact();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final projectBlock = context.watch<ProjectBlock>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'PROJECT ANALYSIS',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.list_alt_rounded),
                onPressed: () => context.go('/projects'),
                tooltip: 'Project List',
              ),
            ],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.go('/projects'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryGrid(context, growthBlock, projectBlock),
                  const SizedBox(height: 32),
                  _buildTrendsChart(context, growthBlock),
                  const SizedBox(height: 32),
                  _buildProjectPerformance(context, projectBlock, growthBlock),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    GrowthBlock growthBlock,
    ProjectBlock projectBlock,
  ) {
    return Watch((context) {
      final tasks = growthBlock.goals.value
          .where((g) => g.category == 'project' || g.projectID != null)
          .toList();
      final activeTasks = tasks.where((t) => t.status != 'done').length;
      final completedTasks = tasks.where((t) => t.status == 'done').length;
      final totalProjects = projectBlock.projects.value.length;

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
        children: [
          _SummaryCard(
            title: 'Active',
            value: activeTasks.toString(),
            icon: Icons.pending_actions_rounded,
            color: Colors.orangeAccent,
          ),
          _SummaryCard(
            title: 'Done',
            value: completedTasks.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: Colors.greenAccent,
          ),
          _SummaryCard(
            title: 'Projects',
            value: totalProjects.toString(),
            icon: Icons.folder_copy_rounded,
            color: Colors.blueAccent,
          ),
        ],
      );
    });
  }

  Widget _buildTrendsChart(BuildContext context, GrowthBlock growthBlock) {
    return Watch((context) {
      final now = DateTime.now();
      final last7Days = List.generate(
        7,
        (i) => now.subtract(Duration(days: 6 - i)),
      );

      final dataPoints = last7Days.map((date) {
        final count = growthBlock.goals.value.where((g) {
          if (g.status != 'done' || g.completionDate == null) return false;
          return g.completionDate!.year == date.year &&
              g.completionDate!.month == date.month &&
              g.completionDate!.day == date.day;
        }).length;
        return count.toDouble();
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAST 7 DAYS ACTIVITY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: SimpleLineChart(
              data: dataPoints,
              color: Theme.of(context).colorScheme.primary,
              height: 160,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildProjectPerformance(
    BuildContext context,
    ProjectBlock projectBlock,
    GrowthBlock growthBlock,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROJECT PERFORMANCE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Watch((context) {
          final projects = projectBlock.projects.value;
          if (projects.isEmpty) {
            return const Center(child: Text('No project data available'));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              final projectTasks = growthBlock.goals.value
                  .where((g) => g.projectID == project.projectID)
                  .toList();

              final completed = projectTasks
                  .where((t) => t.status == 'done')
                  .length;
              final total = projectTasks.length;
              final progress = total > 0 ? completed / total : 0.0;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            (project.color != null
                                    ? Color(int.parse(project.color!))
                                    : Colors.blue)
                                .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: project.color != null
                            ? Color(int.parse(project.color!))
                            : Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
