import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/UIConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindLogInsights.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MoodTrendsChart.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SocialAnalysisPage extends StatelessWidget {
  const SocialAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final personBlock = context.read<PersonBlock>();
    final mindBlock = context.read<MindBlock>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Watch((context) {
        final personId = personBlock.currentPersonID.value;
        if (personId == null || personId.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<ProjectNoteData>>(
          stream: context
              .read<ProjectNoteDAO>()
              .watchNotesByCategory(personId, 'social'),
          builder: (context, notesSnap) {
            return StreamBuilder<List<MindLogData>>(
              stream: mindBlock.watchMindLogsRange(
                personId,
                MindLogInsights.insightsSummaryDays,
              ),
              builder: (context, logSnapshot) {
                final mindLogs = MindLogInsights.moodChartLogs(
                  logSnapshot.data ?? const [],
                );
                final journalNotes = notesSnap.data ?? const [];
                final mergedSummary = MindLogInsights.mergeNotesWithMindLogs(
                  mindLogs: mindLogs,
                  journalNotes: journalNotes,
                  days: MindLogInsights.insightsSummaryDays,
                );
                final mergedMood = MindLogInsights.mergeNotesWithMindLogs(
                  mindLogs: mindLogs,
                  journalNotes: journalNotes,
                  days: MindLogInsights.moodChartDays,
                );
                final summary = MindLogInsights.summarize(mergedSummary);
                final skills = MindLogInsights.skillSummary(
                  mindLogs,
                  days: MindLogInsights.insightsSummaryDays,
                );

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mind_insights_title.toUpperCase(),
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.mind_insights_subtitle,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMonthlyReflectionCard(context, personId),
                        const SizedBox(height: 20),
                        _buildSummaryCard(context, summary),
                        const SizedBox(height: 20),
                        _buildQuickLinks(context, l10n),
                        const SizedBox(height: 20),
                        _buildHourlyLogsChart(context, mindLogs, l10n),
                        const SizedBox(height: 20),
                        _buildMoodChart(context, mergedMood, l10n),
                        const SizedBox(height: 20),
                        _buildActivitiesSection(context, mindBlock, personId),
                        const SizedBox(height: 20),
                        _buildSkillSection(context, skills, l10n),
                        const SizedBox(height: 20),
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

  Widget _buildQuickLinks(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<SocialBlock>().activeTab.value = 0;
            },
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(l10n.mind_insights_open_notes),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/social/skills'),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: Text(l10n.mind_insights_open_skills),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ({int logCount, int activeDays, double avgMood}) summary,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final moodLabel = summary.logCount == 0
        ? '—'
        : '${summary.avgMood.toStringAsFixed(1)}/5';

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
          _buildStatItem(
            context,
            '${summary.logCount}',
            l10n.stat_mind_logs.toUpperCase(),
          ),
          _buildStatItem(
            context,
            '${summary.activeDays}',
            l10n.stat_active_days.toUpperCase(),
          ),
          _buildStatItem(
            context,
            moodLabel,
            l10n.stat_avg_mood.toUpperCase(),
          ),
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
          textAlign: TextAlign.center,
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

  Widget _buildHourlyLogsChart(
    BuildContext context,
    List<MindLogData> logs,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final containerHeight = UIConstants.getChartContainerHeight(context);
    final barMaxHeight = UIConstants.getChartBarMaxHeight(context);
    final barWidth = UIConstants.getChartBarWidth(context);
    final hourly = MindLogInsights.hourlyLogsToday(logs);
    final maxCount = hourly.values.fold<int>(1, (m, v) => v > m ? v : m);
    final currentHour = DateTime.now().hour;
    final todayTotal = hourly.values.fold<int>(0, (s, v) => s + v);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.journal_hourly_logs.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              if (todayTotal > 0)
                Text(
                  '$todayTotal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (todayTotal == 0)
            Center(
              child: Text(
                l10n.track_patterns_msg,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            SizedBox(
              height: barMaxHeight + 20,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: 24,
                itemBuilder: (context, index) {
                  final count = hourly[index] ?? 0;
                  final height = count == 0
                      ? 4.0
                      : (count / maxCount * barMaxHeight)
                          .clamp(6.0, barMaxHeight);
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
                            color: count == 0
                                ? colorScheme.outlineVariant.withValues(
                                    alpha: 0.35,
                                  )
                                : (isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.primary.withValues(
                                        alpha: 0.45,
                                      )),
                            borderRadius: BorderRadius.circular(barWidth / 2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${index}h',
                          style: TextStyle(
                            fontSize: barWidth < 15 ? 8 : 10,
                            color: isCurrent
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
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
  }

  Widget _buildMoodChart(
    BuildContext context,
    List<MindLogData> mergedMood,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (mergedMood.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: HealthMetricColors.shellPanel(
          colorScheme,
          isDark: isDark,
          radius: 22,
          accent: HealthMetricColors.pillarViolet,
        ),
        child: Text(
          l10n.track_patterns_msg,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: HealthMetricColors.shellPanel(
        colorScheme,
        isDark: isDark,
        radius: 22,
        accent: HealthMetricColors.pillarViolet,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mood_trends_title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          MoodTrendsChart(logs: mergedMood, groupByDay: true),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(
    BuildContext context,
    MindBlock mindBlock,
    String personId,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<JournalActivityOptionData>>(
      stream: context
          .read<AppDatabase>()
          .journalActivityOptionsDAO
          .watchForPerson(personId),
      builder: (context, optSnap) {
        final optMap = <String, String>{
          for (final o in optSnap.data ?? []) o.id: o.label,
        };

        return StreamBuilder<List<MindLogData>>(
          stream: mindBlock.watchMindLogsRange(personId, 30),
          builder: (context, logSnap) {
            final logs = MindLogInsights.moodChartLogs(logSnap.data ?? const []);
            final counts = MindLogInsights.activityLabelCounts(
              logs,
              l10n,
              optMap,
            );
            final sorted = counts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

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
                    l10n.frequent_activities.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (sorted.isEmpty)
                    Text(
                      l10n.track_patterns_msg,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sorted.take(8).map((e) {
                        return Chip(
                          label: Text('${e.key} (${e.value})'),
                          backgroundColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkillSection(
    BuildContext context,
    ({
      int sessions,
      int minutes,
      String? topSkill,
      int topStreak,
    }) skills,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    final accent = HealthMetricColors.homePillarAccent('mind');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mind_insights_skill_title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          if (skills.sessions == 0)
            Text(
              l10n.track_patterns_msg,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            )
          else ...[
            Text(
              l10n.mind_insights_skill_summary(
                skills.sessions,
                skills.minutes,
              ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            if (skills.topSkill != null && skills.topStreak > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.mind_insights_top_skill_streak(
                  skills.topSkill!,
                  skills.topStreak,
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                context.read<SocialBlock>().activeTab.value = 1;
              },
              icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
              label: Text(l10n.mind_focus_title),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogsList(
    BuildContext context,
    MindBlock mindBlock,
    String personId,
  ) {
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
          stream: mindBlock.watchMindLogsRange(personId, 3),
          builder: (context, snapshot) {
            final logs = MindLogInsights.moodChartLogs(
              snapshot.data ?? const [],
            );
            if (logs.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todays_reflections.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
                          colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.4,
                          ),
                        ],
                      ),
                      border: Border.all(color: mood.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getMoodEmoji(log.moodScore),
                              style: const TextStyle(fontSize: 18),
                            ),
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
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
      case 1:
        return '😫';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '🤩';
      default:
        return '😐';
    }
  }

  Widget _buildMonthlyReflectionCard(BuildContext context, String personId) {
    final colorScheme = Theme.of(context).colorScheme;
    final socialBlock = context.read<SocialBlock>();
    final achievementsDao = context.read<AchievementsDAO>();

    return StreamBuilder<List<AchievementData>>(
      stream: achievementsDao.watchAchievementsByPerson(personId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final achievements = snapshot.data ?? [];
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final recent = achievements
            .where((a) => a.createdAt.isAfter(thirtyDaysAgo))
            .toList();
        if (recent.isEmpty) return const SizedBox.shrink();

        final reflection = socialBlock.generateReflection(achievements);

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
                    AppLocalizations.of(context)!
                        .monthly_reflection
                        .toUpperCase(),
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
              Text(
                reflection,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
