import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/UIConstants.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/mind_activity_tokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MoodTrendsChart.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/mind_mood_palette.dart';

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
      backgroundColor: Colors.transparent,
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
          builder: (context, noteSnapshot) {
            final notes = noteSnapshot.data ?? [];
            
            return StreamBuilder<List<MindLogData>>(
              stream: mindBlock.watchMindLogsRange(personId, 30),
              builder: (context, logSnapshot) {
                final logs = logSnapshot.data ?? [];
                
                // Calculate average sentiment (1 to 5) and convert to % (0% to 100%)
                double sentiment = 0.0;
                if (logs.isNotEmpty) {
                  final avgScore = logs.fold<double>(0.0, (sum, log) => sum + log.moodScore) / logs.length;
                  sentiment = ((avgScore - 1) / 4) * 100;
                }

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
                              AppLocalizations.of(context)!.mind_insights_title.toUpperCase(),
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.mind_insights_subtitle,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // _buildMonthlyReflectionCard(context, personId),
                            const SizedBox(height: 24),
                            _buildSummaryCard(context, notes, sentiment),
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
          },
        );
      }),
    );
  }

  Widget _buildRecentLogsList(BuildContext context, MindBlock mindBlock, String personId) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<JournalActivityOptionData>>(
      stream: context
          .read<AppDatabase>()
          .journalActivityOptionsDAO
          .watchForPerson(personId),
      builder: (context, optSnap) {
        final optMap = <String, String>{
          for (final o in optSnap.data ?? []) o.id: o.label,
        };
        final l10n = AppLocalizations.of(context)!;

        return StreamBuilder<List<MindLogData>>(
          stream: mindBlock.watchMindLogsRange(personId, 3), // Show last 3 days
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.todays_reflections.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...logs.take(5).map((log) {
                  final mood = mindMoodAccent(log.moodScore);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          mood.withValues(alpha: 0.14),
                          colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                        ],
                      ),
                      border: Border.all(color: mood.withValues(alpha: 0.4)),
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
                                    MindActivityTokens.formatActivitiesJson(
                                      l10n,
                                      log.activities,
                                      optMap,
                                    ),
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMMM d, yyyy • HH:mm')
                                        .format(log.createdAt.toLocal()),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
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
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
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
            Text(
              AppLocalizations.of(context)!.daily_step_distribution.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                                : colorScheme.primary.withValues(alpha: 0.3),
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

  Widget _buildSummaryCard(BuildContext context, List<ProjectNoteData> notes, double sentiment) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, notes.length.toString(), AppLocalizations.of(context)!.stat_entries.toUpperCase()),
          _buildStatItem(context, _countImages(notes).toString(), AppLocalizations.of(context)!.stat_images.toUpperCase()),
          _buildStatItem(context, "${sentiment.toStringAsFixed(0)}%", AppLocalizations.of(context)!.stat_sentiment.toUpperCase()),
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
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
          Text(
            AppLocalizations.of(context)!.weekly_mood_trend.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<MindLogData>>(
              stream: mindBlock.watchMindLogsRange(personId, 7),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.no_records_last_7_days,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
          Text(
            AppLocalizations.of(context)!.frequent_activities.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, int>>(
            future: mindBlock.getTopActivitiesForMood(personId, 5), // High energy activities
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(AppLocalizations.of(context)!.track_patterns_msg, 
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)));
              }
              final activities = snapshot.data!.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activities.take(6).map((e) => Chip(
                  label: Text("${e.key} (${e.value})"),
                  backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
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
    int imageCount = 0;
    for (final note in notes) {
      if (note.content.contains('![')) {
        // Count how many ![ occurrences are in the text
        imageCount += '!['.allMatches(note.content).length;
      }
    }
    return imageCount;
  }

  Widget _buildMonthlyReflectionCard(BuildContext context, String personId) {
    final colorScheme = Theme.of(context).colorScheme;
    final socialBlock = context.read<SocialBlock>();
    final achievementsDao = context.read<AchievementsDAO>();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.monthly_reflection.toUpperCase(),
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
          StreamBuilder<List<AchievementData>>(
            stream: achievementsDao.watchAchievementsByPerson(personId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final achievements = snapshot.data ?? [];
              final reflection = socialBlock.generateReflection(achievements);
              
              return Text(
                reflection,
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
