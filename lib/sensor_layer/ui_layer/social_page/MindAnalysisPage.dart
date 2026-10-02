import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'dart:convert';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementBuilderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/DomainAnalysisChart.dart';

class MindAnalysisPage extends StatelessWidget {
  const MindAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final personBlock = context.read<PersonBlock>();
    final achievementsDAO = context.read<AchievementsDAO>();
    final mindBlock = context.read<MindBlock>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Watch((context) {
          final personId = personBlock.currentPersonID.value;
          if (personId == null || personId.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // 1. Deep Base Background
              Container(color: colorScheme.surface),

              // 2. Tactical Grid Background
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.3 : 0.1,
                  child: CustomPaint(
                    painter: TacticalGridPainter(
                      color: colorScheme.primary,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

              // 3. Ambient Glows
              Positioned(
                top: -100,
                right: -100,
                child: _buildAmbientGlow(colorScheme.primary, 300),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: _buildAmbientGlow(colorScheme.secondary, 250),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                      child: _buildTopPillBar(context),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          StreamBuilder<List<AchievementData>>(
                            stream: achievementsDAO.watchAchievementsByPerson(
                              personId,
                            ),
                            builder: (context, achSnap) {
                              if (!achSnap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              return StreamBuilder<List<MindLogData>>(
                                stream: mindBlock.watchMindLogsRange(
                                  personId,
                                  30,
                                ),
                                builder: (context, logSnap) {
                                  final achievements = achSnap.data!;
                                  final logs = logSnap.data ?? [];

                                  return ListView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    children: [
                                      _buildGlassCard(
                                        context,
                                        title: 'INSIGHTS DASHBOARD',
                                        icon: Icons.auto_graph_rounded,
                                        trailing: IconButton(
                                          tooltip: 'Log achievement',
                                          icon: const Icon(
                                            Icons.add_circle_outline_rounded,
                                            size: 22,
                                          ),
                                          onPressed: () =>
                                              AchievementBuilderDialog.show(
                                            context,
                                          ),
                                        ),
                                        child: _buildInsightsRows(
                                          context,
                                          achievements: achievements,
                                          mindLogs: logs,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      _buildMindJournalCard(
                                        context,
                                        personId: personId,
                                      ),
                                      const SizedBox(height: 18),
                                      _buildMoodTelemetry(context, personId),
                                      const SizedBox(height: 18),
                                      _buildSkillsTelemetry(
                                        context,
                                        personId,
                                      ),
                                      const SizedBox(height: 100),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          MindSkillsView(
                            showBackground: false,
                            popOnSave: false,
                            onSessionLogged: () {
                              DefaultTabController.of(context).animateTo(0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Session logged — check Achievements tab.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTopPillBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = HealthMetricColors.pillarViolet;
    final tabController = DefaultTabController.of(context);
    const islandHeight = 52.0;
    const islandRadius = islandHeight / 2;
    final islandFill = isDark
        ? HealthMetricColors.shellIslandFill
        : colorScheme.surfaceContainerHigh.withValues(alpha: 0.98);
    final outerBorder = isDark
        ? HealthMetricColors.borderBright.withValues(alpha: 0.9)
        : colorScheme.outlineVariant.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final activeIndex = tabController.index;
        return Container(
          height: islandHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(islandRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.09),
                        islandFill,
                      ),
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.03),
                        islandFill,
                      ),
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.05),
                        islandFill,
                      ),
                    ]
                  : [
                      Color.alphaBlend(
                        colorScheme.onSurface.withValues(alpha: 0.05),
                        islandFill,
                      ),
                      Color.alphaBlend(
                        colorScheme.onSurface.withValues(alpha: 0.02),
                        islandFill,
                      ),
                      Color.alphaBlend(
                        colorScheme.onSurface.withValues(alpha: 0.04),
                        islandFill,
                      ),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(color: outerBorder),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 14,
                right: 14,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (isDark ? Colors.white : colorScheme.onSurface)
                            .withValues(alpha: isDark ? 0.18 : 0.08),
                        (isDark ? Colors.white : colorScheme.onSurface)
                            .withValues(alpha: isDark ? 0.04 : 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        WidgetNavigatorAction.smartPop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MindAnalysisSegmentTab(
                              index: 0,
                              activeIndex: activeIndex,
                              icon: Icons.emoji_events_rounded,
                              label: 'ACHIEVEMENTS',
                              accent: accent,
                              onTap: () => _selectTab(context, 0),
                            ),
                            const SizedBox(width: 6),
                            _MindAnalysisSegmentTab(
                              index: 1,
                              activeIndex: activeIndex,
                              icon: Icons.auto_awesome_rounded,
                              label: 'SKILLS',
                              accent: accent,
                              onTap: () => _selectTab(context, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CircleIconButton(
                      icon: Icons.bar_chart_rounded,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.read<SocialBlock>().activeTab.value = 3;
                        context.go('/social');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectTab(BuildContext context, int index) {
    final controller = DefaultTabController.of(context);
    if (controller.index == index) return;
    HapticFeedback.selectionClick();
    controller.animateTo(index);
  }

  Widget _buildInsightsRows(
    BuildContext context, {
    required List<AchievementData> achievements,
    required List<MindLogData> mindLogs,
  }) {
    final monthStart = achievementMonthStart();
    final monthlyAchievements = achievements
        .where((a) => !a.createdAt.isBefore(monthStart))
        .toList();
    final domainCounts = buildAchievementDomainCounts(
      achievements: achievements,
      mindLogs: mindLogs,
      since: monthStart,
    );

    final monthLogs = mindLogs
        .where((l) => !l.logDate.isBefore(monthStart))
        .toList();
    final skillSessions = countSkillSessionsInRange(monthLogs);

    final totalFeats = monthlyAchievements.length + skillSessions;
    final maxCount = domainCounts.values.fold<int>(
      1,
      (prev, v) => v > prev ? v : prev,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Reflection: $totalFeats feats recorded this month.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (totalFeats == 0) ...[
          const SizedBox(height: 14),
          Text(
            'Log an achievement or complete a skill session to populate this chart.',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 18),
        for (var i = 0; i < kAchievementDomains.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _InsightRow(
            label: kAchievementDomainLabels[kAchievementDomains[i]]!,
            value: domainCounts[kAchievementDomains[i]]!,
            max: maxCount,
          ),
        ],
      ],
    );
  }

  Widget _buildSkillsTelemetry(BuildContext context, String personId) {
    final mindBlock = context.read<MindBlock>();

    return StreamBuilder<List<MindLogData>>(
      stream: mindBlock.watchMindLogsRange(personId, 14),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) return const SizedBox.shrink();

        final skillCounts = <String, int>{};
        int sessions = 0;
        int minutes = 0;

        for (final log in logs) {
          List<dynamic> acts;
          try {
            acts = jsonDecode(log.activities) as List<dynamic>;
          } catch (_) {
            continue;
          }

          final skills = acts
              .whereType<String>()
              .where((a) => a.startsWith('skill:'))
              .map((a) => a.substring('skill:'.length))
              .toList();
          if (skills.isEmpty) continue;

          sessions++;
          for (final s in skills) {
            skillCounts[s] = (skillCounts[s] ?? 0) + 1;
          }

          for (final a in acts.whereType<String>()) {
            if (!a.startsWith('learn:')) continue;
            final m = RegExp(r'learn:(\d+)m').firstMatch(a);
            if (m != null) {
              minutes += int.tryParse(m.group(1) ?? '0') ?? 0;
            }
          }
        }

        if (sessions == 0) {
          return _buildGlassCard(
            context,
            title: 'SKILL TELEMETRY (14D)',
            icon: Icons.auto_awesome_rounded,
            child: Text(
              'No skill sessions yet. Open the Skills tab, pick a skill, and tap Log session.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          );
        }

        final entries = skillCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = entries.take(6).toList();
        final maxCount = entries.isEmpty ? 1 : entries.first.value;

        return _buildGlassCard(
          context,
          title: 'SKILL TELEMETRY (14D)',
          icon: Icons.auto_awesome_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sessions: $sessions  •  Minutes: $minutes',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              for (final e in top) ...[
                _InsightRow(
                  label: e.key,
                  value: e.value,
                  max: maxCount,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodTelemetry(BuildContext context, String personId) {
    final mindBlock = context.read<MindBlock>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<MindLogData>>(
      stream: mindBlock.watchMindLogsByDay(personId, DateTime.now()),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) return const SizedBox.shrink();

        final recentLog = logs.first;
        final moodValue = recentLog.moodScore.toDouble();

        return _buildGlassCard(
          context,
          title: 'COGNITIVE VITALITY',
          icon: Icons.monitor_heart_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getMoodEmoji(recentLog.moodScore),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT COGNITIVE POLARITY',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          _getMoodLabel(recentLog.moodScore).toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStabilityGauge(
                context,
                'Stability Deviation',
                moodValue / 5.0,
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (jsonDecode(recentLog.activities) as List)
                      .map(
                        (a) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            a.toString().toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
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
        return '🔥';
      default:
        return '😐';
    }
  }

  String _getMoodLabel(int score) {
    switch (score) {
      case 1:
        return 'Critically Low';
      case 2:
        return 'Below Nominal';
      case 3:
        return 'Stable';
      case 4:
        return 'Optimal';
      case 5:
        return 'Peak Performance';
      default:
        return 'Neutral';
    }
  }

  Widget _buildStabilityGauge(
    BuildContext context,
    String label,
    double value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'Monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientGlow(Color color, double size) {
    final clampedSize = size.clamp(0.0, double.infinity);
    return Container(
      width: clampedSize,
      height: clampedSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: (clampedSize / 2).clamp(0.0, double.infinity),
            spreadRadius: (clampedSize / 4).clamp(0.0, double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMindJournalCard(BuildContext context, {required String personId}) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/social/journal'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history_edu_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MIND JOURNAL',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<ProjectNoteData>>(
                      stream: context
                          .read<ProjectNoteDAO>()
                          .watchNotesByCategory(personId, 'social'),
                      builder: (context, snapshot) {
                        final notes = snapshot.data ?? [];
                        final note = notes.isNotEmpty
                            ? (List<ProjectNoteData>.from(notes)..sort(
                                (a, b) =>
                                    b.updatedAt.compareTo(a.updatedAt),
                              ))
                                .first
                            : null;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note?.title ?? 'START YOUR MIND JOURNAL',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note != null
                                  ? _getPreviewText(note.content)
                                  : 'Record mental strategies and emotional milestones.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .where((op) => op is Map && op.containsKey('insert'))
            .map((op) => op['insert'])
            .join('')
            .trim();
      }
    } catch (_) {}
    return content.trim();
  }
}

class _MindAnalysisSegmentTab extends StatelessWidget {
  const _MindAnalysisSegmentTab({
    required this.index,
    required this.activeIndex,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final int index;
  final int activeIndex;
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == activeIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final activeInk = isDark ? accent : colorScheme.onSurface;
    final inactiveInk = colorScheme.onSurfaceVariant.withValues(
      alpha: isDark ? 0.55 : 0.72,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? accent.withValues(alpha: 0.15)
                  : colorScheme.primary.withValues(alpha: 0.1))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? (isDark
                    ? accent.withValues(alpha: 0.35)
                    : colorScheme.primary.withValues(alpha: 0.32))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : colorScheme.outlineVariant.withValues(alpha: 0.35)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeInk : inactiveInk,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: activeInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final baseFill = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final pressedFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final border = isDark
        ? Colors.white.withValues(alpha: _pressed ? 0.22 : 0.14)
        : colorScheme.outlineVariant.withValues(alpha: _pressed ? 0.9 : 0.7);
    final iconColor = isDark
        ? const Color(0xF2FFFFFF)
        : colorScheme.onSurface.withValues(alpha: 0.85);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onTap: widget.onPressed,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _pressed ? pressedFill : baseFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Icon(widget.icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;

  const _InsightRow({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final v = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(
                const Color(0xFF8FD3FF).withValues(alpha: 0.95),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 18,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'Monospace',
            ),
          ),
        ),
      ],
    );
  }
}
