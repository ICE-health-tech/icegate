import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindFocusTrendEditor.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindFocusTodosSection.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindSkillsSessionCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindLogEntryDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MindFocusTrendsTab extends StatefulWidget {
  const MindFocusTrendsTab({super.key});

  @override
  State<MindFocusTrendsTab> createState() => _MindFocusTrendsTabState();
}

class _MindFocusTrendsTabState extends State<MindFocusTrendsTab> {
  List<MindFocusTrend> _trends = [];
  String? _loadedPersonId;
  int _loadedRevision = -1;

  DateTime get _weekStart {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  double _bottomClearance(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wideMac =
        defaultTargetPlatform == TargetPlatform.macOS && width >= 560;
    return wideMac ? 72 : 104;
  }

  double _horizontalPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 32;
    return 20;
  }

  Future<void> _loadTrends(String personId) async {
    final list = await MindFocusTrendPrefs.load(personId);
    if (!mounted) return;
    final socialBlock = context.read<SocialBlock>();
    final active = socialBlock.activeFocusTrend.peek();
    if (active != null && !list.any((t) => t.id == active.id)) {
      await socialBlock.setActiveFocusTrend(null, personId: personId);
    }
    setState(() {
      _loadedPersonId = personId;
      _trends = list;
    });
  }

  Future<void> _persistTrends(String personId) async {
    await MindFocusTrendPrefs.save(personId, _trends);
    if (mounted) context.read<SocialBlock>().notifyFocusTrendsChanged();
  }

  List<String> _decodeActivities(String json) {
    try {
      final raw = jsonDecode(json);
      if (raw is List) return raw.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  bool _logMatchesTrend(MindLogData log, MindFocusTrend trend) {
    final acts = _decodeActivities(log.activities);
    if (acts.isEmpty || trend.activityTokens.isEmpty) return false;
    return acts.any(trend.activityTokens.contains);
  }

  int _weekCount(MindFocusTrend trend, List<MindLogData> logs) {
    return logs
        .where(
          (l) =>
              !l.createdAt.isBefore(_weekStart) && _logMatchesTrend(l, trend),
        )
        .length;
  }

  double? _weekAvgMood(MindFocusTrend trend, List<MindLogData> logs) {
    final matched = logs
        .where(
          (l) =>
              !l.createdAt.isBefore(_weekStart) && _logMatchesTrend(l, trend),
        )
        .toList();
    if (matched.isEmpty) return null;
    return matched.fold<double>(0, (s, l) => s + l.moodScore) / matched.length;
  }

  MindFocusTrend _templateTrend({
    required String idSuffix,
    required String name,
    required IconData icon,
    required List<String> tokens,
    required int color,
  }) {
    return MindFocusTrend(
      id: 'template_$idSuffix',
      name: name,
      iconCodePoint: icon.codePoint,
      activityTokens: tokens,
      weeklyGoal: 3,
      colorArgb: color,
    );
  }

  Future<void> _addFromTemplate(
    MindFocusTrend template,
    String personId,
  ) async {
    HapticFeedback.lightImpact();
    final created = template.copyWith(id: IDGen.UUIDV7());
    setState(() {
      _trends = [..._trends, created];
    });
    await _persistTrends(personId);
    if (!mounted) return;
    await context.read<SocialBlock>().setActiveFocusTrend(
      created,
      personId: personId,
    );
  }

  Future<void> _openNewTrendEditor(String personId) async {
    await MindFocusTrendEditor.show(
      context,
      onSave: (trend) async {
        setState(() {
          _trends = [..._trends, trend];
        });
        await _persistTrends(personId);
        if (!context.mounted) return;
        await context.read<SocialBlock>().setActiveFocusTrend(
          trend,
          personId: personId,
        );
      },
    );
  }

  List<({String label, IconData icon, Color color, MindFocusTrend trend})>
  _templates(AppLocalizations l10n) {
    return [
      (
        label: l10n.mind_focus_template_gym,
        icon: Icons.fitness_center_rounded,
        color: HealthMetricColors.pillarGreen,
        trend: _templateTrend(
          idSuffix: 'gym',
          name: l10n.mind_focus_template_gym,
          icon: Icons.fitness_center_rounded,
          tokens: const ['act_exercise'],
          color: 0xFF66BB6A,
        ),
      ),
      (
        label: l10n.mind_focus_template_learn,
        icon: Icons.school_rounded,
        color: HealthMetricColors.pillarBlue,
        trend: _templateTrend(
          idSuffix: 'learn',
          name: l10n.mind_focus_template_learn,
          icon: Icons.school_rounded,
          tokens: const ['act_learning', 'act_deep_work', 'act_reading'],
          color: 0xFF42A5F5,
        ),
      ),
      (
        label: l10n.mind_focus_template_invest,
        icon: Icons.trending_up_rounded,
        color: HealthMetricColors.pillarYellow,
        trend: _templateTrend(
          idSuffix: 'invest',
          name: l10n.mind_focus_template_invest,
          icon: Icons.trending_up_rounded,
          tokens: const ['act_finance', 'act_planning'],
          color: 0xFFFFB74D,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = cs.brightness == Brightness.dark;
    final accent = HealthMetricColors.homePillarAccent('mind');
    final hPad = _horizontalPad(context);

    return Watch((context) {
      final personId = context.read<PersonBlock>().currentPersonID.value;
      final revision = context.read<SocialBlock>().focusTrendsRevision.value;
      final activeFocusId =
          context.read<SocialBlock>().activeFocusTrend.value?.id;
      if (personId != null &&
          personId.isNotEmpty &&
          (personId != _loadedPersonId || revision != _loadedRevision)) {
        _loadedRevision = revision;
        _loadTrends(personId);
      }
      if (personId == null || personId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return StreamBuilder<List<MindLogData>>(
        stream: context.read<MindBlock>().watchMindLogsRange(personId, 30),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          final templates = _templates(l10n);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
                  child: _FocusIntroCard(
                    accent: accent,
                    isDark: isDark,
                    title: l10n.mind_focus_title,
                    subtitle: l10n.mind_focus_subtitle,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: MindSkillsSessionCard(logs: logs),
              ),
              if (_trends.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
                    child: Text(
                      l10n.mind_focus_empty,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      physics: const BouncingScrollPhysics(),
                      itemCount: templates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final t = templates[index];
                        return _FocusTemplateTile(
                          label: t.label,
                          icon: t.icon,
                          color: t.color,
                          isDark: isDark,
                          onTap: () => _addFromTemplate(t.trend, personId),
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.mind_focus_title.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        Text(
                          '${_trends.length}',
                          style: textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad - 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final trend = _trends[index];
                        final selected = trend.id == activeFocusId;
                        final weekCount = _weekCount(trend, logs);
                        final goal = trend.weeklyGoal;
                        final progress =
                            goal > 0 ? (weekCount / goal).clamp(0.0, 1.0) : 0.0;
                        final avgMood = _weekAvgMood(trend, logs);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FocusTrendCard(
                            trend: trend,
                            selected: selected,
                            isDark: isDark,
                            weekCount: weekCount,
                            goal: goal,
                            progress: progress,
                            avgMood: avgMood,
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await context
                                  .read<SocialBlock>()
                                  .setActiveFocusTrend(
                                    selected ? null : trend,
                                    personId: personId,
                                  );
                            },
                            onLongPress: () {
                              MindFocusTrendEditor.show(
                                context,
                                existing: trend,
                                onSave: (updated) async {
                                  setState(() {
                                    final i = _trends.indexWhere(
                                      (t) => t.id == trend.id,
                                    );
                                    if (i >= 0) _trends[i] = updated;
                                  });
                                  await _persistTrends(personId);
                                  final socialBlock =
                                      context.read<SocialBlock>();
                                  if (socialBlock
                                          .activeFocusTrend
                                          .peek()
                                          ?.id ==
                                      trend.id) {
                                    await socialBlock.setActiveFocusTrend(
                                      updated,
                                      personId: personId,
                                    );
                                  }
                                },
                                onDelete: () async {
                                  final socialBlock =
                                      context.read<SocialBlock>();
                                  if (socialBlock
                                          .activeFocusTrend
                                          .peek()
                                          ?.id ==
                                      trend.id) {
                                    await socialBlock.setActiveFocusTrend(
                                      null,
                                      personId: personId,
                                    );
                                  }
                                  setState(() {
                                    _trends.removeWhere(
                                      (t) => t.id == trend.id,
                                    );
                                  });
                                  await _persistTrends(personId);
                                },
                              );
                            },
                            detail: selected
                                ? _FocusDetailPanel(
                                    trend: trend,
                                    logs: logs,
                                    personId: personId,
                                    decodeActivities: _decodeActivities,
                                    logMatches: _logMatchesTrend,
                                  )
                                : null,
                          ),
                        );
                      },
                      childCount: _trends.length,
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    16,
                    hPad,
                    _bottomClearance(context) + 16,
                  ),
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openNewTrendEditor(personId),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.mind_focus_add),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _FocusIntroCard extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final String title;
  final String subtitle;

  const _FocusIntroCard({
    required this.accent,
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: HealthMetricColors.shellPanel(
        cs,
        isDark: isDark,
        radius: 22,
        accent: accent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.center_focus_strong_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: cs.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusTemplateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FocusTemplateTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 128,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: HealthMetricColors.shellPanel(
              cs,
              isDark: isDark,
              radius: 18,
              accent: color,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: cs.onSurface.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusTrendCard extends StatelessWidget {
  final MindFocusTrend trend;
  final bool selected;
  final bool isDark;
  final int weekCount;
  final int goal;
  final double progress;
  final double? avgMood;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget? detail;

  const _FocusTrendCard({
    required this.trend,
    required this.selected,
    required this.isDark,
    required this.weekCount,
    required this.goal,
    required this.progress,
    required this.avgMood,
    required this.onTap,
    required this.onLongPress,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: HealthMetricColors.shellPanel(
            cs,
            isDark: isDark,
            radius: 20,
            accent: selected ? trend.color : null,
          ).copyWith(
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: trend.color.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: trend.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        MindFocusTrend.resolveIcon(trend.iconCodePoint),
                        color: trend.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trend.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.mind_focus_this_week,
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _WeekProgressRing(
                      progress: progress,
                      color: trend.color,
                      label: '$weekCount/$goal',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: cs.surface.withValues(alpha: 0.45),
                    color: trend.color,
                  ),
                ),
                if (avgMood != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        size: 16,
                        color: mindMoodAccent(avgMood!.round().clamp(1, 5)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!
                            .mind_focus_avg_mood(avgMood!.toStringAsFixed(1)),
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (detail != null) ...[
                  const SizedBox(height: 14),
                  detail!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final String label;

  const _WeekProgressRing({
    required this.progress,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3.5,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusDetailPanel extends StatelessWidget {
  final MindFocusTrend trend;
  final List<MindLogData> logs;
  final String personId;
  final List<String> Function(String) decodeActivities;
  final bool Function(MindLogData, MindFocusTrend) logMatches;

  const _FocusDetailPanel({
    required this.trend,
    required this.logs,
    required this.personId,
    required this.decodeActivities,
    required this.logMatches,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final matched = logs.where((l) => logMatches(l, trend)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = matched.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.mind_focus_select_hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.primary.withValues(alpha: 0.85),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Text(
            l10n.mind_focus_no_logs_yet,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...recent.map((log) {
            final acts = decodeActivities(log.activities);
            final labels = acts
                .map((t) => MindActivityTokens.presetLabel(l10n, t))
                .join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: mindMoodAccent(log.moodScore),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.MMMd().add_Hm().format(
                            log.createdAt.toLocal(),
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (labels.isNotEmpty)
                          Text(
                            labels,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        MindFocusTodosSection(trend: trend),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => MindLogEntryDialog.show(context),
            child: Text(l10n.mind_focus_log_now),
          ),
        ),
      ],
    );
  }
}
