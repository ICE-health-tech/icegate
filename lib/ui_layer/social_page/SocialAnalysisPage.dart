import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/ui_layer/UIConstants.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SocialAnalysisPage extends StatelessWidget {
  const SocialAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final personBlock = context.read<PersonBlock>();
    final healthBlock = context.read<HealthBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: StreamBuilder<List<ProjectNoteData>>(
        stream: context.read<ProjectNoteDAO>().watchNotesByCategory(
              personId,
              'social',
            ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!;
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "MIND INSIGHTS",
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Analysis of your journal entries",
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSummaryCard(context, notes),
                      const SizedBox(height: 24),
                      _buildStepsDistribution(context, healthBlock),
                      const SizedBox(height: 24),
                      _buildMoodChart(context),
                      const SizedBox(height: 24),
                      _buildWordCloudPlaceholder(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepsDistribution(BuildContext context, HealthBlock healthBlock) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final containerHeight = UIConstants.getChartContainerHeight(context);
    final barMaxHeight = UIConstants.getChartBarMaxHeight(context);
    final barWidth = UIConstants.getChartBarWidth(context);

    return Watch((context) {
      final hourly = healthBlock.hourlySteps.value;
      final maxSteps = hourly.values.fold<int>(1, (max, val) => val > max ? val : max);
      final currentHour = DateTime.now().hour;

      return Container(
        height: containerHeight,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "DAILY STEP DISTRIBUTION",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Spacer(),
            SizedBox(
              height: barMaxHeight + 20, // Add space for labels
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 24,
                itemBuilder: (context, index) {
                  final steps = hourly[index] ?? 0;
                  final height = (steps / maxSteps * barMaxHeight).clamp(4.0, barMaxHeight);
                  final isCurrent = index == currentHour;

                  return Container(
                    width: barWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: barWidth,
                          height: height,
                          decoration: BoxDecoration(
                            color: isCurrent 
                                ? colorScheme.primary 
                                : colorScheme.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(barWidth / 2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${index}h",
                          style: TextStyle(
                            fontSize: barWidth < 15 ? 8 : 10,
                            color: isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryCard(BuildContext context, List<ProjectNoteData> notes) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, notes.length.toString(), "ENTRIES"),
          _buildStatItem(context, _countImages(notes).toString(), "IMAGES"),
          _buildStatItem(context, "85%", "SENTIMENT"),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MOOD TREND",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final height = 40.0 + (index * 15 % 80);
              return Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["M", "T", "W", "T", "F", "S", "S"]
                .map((d) => Text(d, style: TextStyle(fontSize: 10)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCloudPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOP KEYWORDS",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const Expanded(
            child: Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text("Health")),
                  Chip(label: Text("Productivity")),
                  Chip(label: Text("Social")),
                  Chip(label: Text("Coding")),
                  Chip(label: Text("Peace")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countImages(List<ProjectNoteData> notes) {
    // Basic placeholder logic
    return notes.length; 
  }
}
