import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/ui_layer/UIConstants.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/MoodTrendsChart.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';

class SocialAnalysisPage extends StatelessWidget {
  const SocialAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final personBlock = context.read<PersonBlock>();
    final healthBlock = context.read<HealthBlock>();
    final mindBlock = context.read<MindBlock>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Watch((context) {
        final personId = personBlock.currentPersonID.value;
        if (personId == null || personId.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<ProjectNoteData>>(
          stream: context.read<ProjectNoteDAO>().watchNotesByCategory(
                personId,
                'social',
              ),
          builder: (context, snapshot) {
            final notes = snapshot.data ?? [];
            
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
                        _buildMonthlyReflectionCard(context, personId),
                        const SizedBox(height: 24),
                        _buildSummaryCard(context, notes),
                        const SizedBox(height: 24),
                        _buildStepsDistribution(context, healthBlock),
                        const SizedBox(height: 24),
                        _buildMoodChart(context, mindBlock, personId),
                        const SizedBox(height: 24),
                        _buildWordCloud(context, mindBlock, personId),
                        const SizedBox(height: 24),
                        _buildRecentLogsList(context, mindBlock, personId),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildRecentLogsList(BuildContext context, MindBlock mindBlock, String personId) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<MindLogData>>(
      stream: mindBlock.watchMindLogsByDay(personId, DateTime.now()),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TODAY'S REFLECTIONS",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...logs.take(5).map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_getMoodEmoji(log.moodScore), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (jsonDecode(log.activities) as List).join(", "),
                                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('MMMM d, yyyy • HH:mm').format(log.logDate),
                                style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (log.note != null && log.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        log.note!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _getMoodEmoji(int score) {
    switch (score) {
      case 1: return "😫";
      case 2: return "😔";
      case 3: return "😐";
      case 4: return "😊";
      case 5: return "🤩";
      default: return "😐";
    }
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

  Widget _buildMoodChart(BuildContext context, MindBlock mindBlock, String personId) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 220,
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
            "WEEKLY MOOD TREND",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<MindLogData>>(
              stream: mindBlock.watchMindLogsByDay(personId, DateTime.now()),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      "No records yet",
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  );
                }
                return MoodTrendsChart(logs: logs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCloud(BuildContext context, MindBlock mindBlock, String personId) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
            "FREQUENT ACTIVITIES",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, int>>(
            future: mindBlock.getTopActivitiesForMood(personId, 5), // High energy activities
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text("Track more logs to see patterns", 
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withOpacity(0.5)));
              }
              final activities = snapshot.data!.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activities.take(6).map((e) => Chip(
                  label: Text("${e.key} (${e.value})"),
                  backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                  side: BorderSide.none,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  int _countImages(List<ProjectNoteData> notes) {
    // Basic placeholder logic
    return notes.length; 
  }

  Widget _buildMonthlyReflectionCard(BuildContext context, String personId) {
    final colorScheme = Theme.of(context).colorScheme;
    final socialBlock = context.read<SocialBlock>();
    final achievementsDao = context.read<AchievementsDAO>();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                "MONTHLY REFLECTION",
                style: TextStyle(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: socialBlock.getMonthlyReflection(achievementsDao, personId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text("Error generating reflection: \${snapshot.error}");
              }
              return Text(
                snapshot.data ?? "No reflection generated.",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
