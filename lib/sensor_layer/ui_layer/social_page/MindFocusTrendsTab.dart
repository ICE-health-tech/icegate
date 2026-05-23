import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindFocusTrendEditor.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindFocusTodosSection.dart';
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

  Future<void> _loadTrends(String personId) async {
    final list = await MindFocusTrendPrefs.load(personId);
    if (!mounted) return;
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

  MindFocusTrend _templateTrend(
    AppLocalizations l10n, {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mind_focus_title.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.mind_focus_subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_trends.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          l10n.mind_focus_empty,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _TemplateChip(
                          label: l10n.mind_focus_template_gym,
                          icon: Icons.fitness_center_rounded,
                          color: const Color(0xFF66BB6A),
                          onTap: () => _addFromTemplate(
                            _templateTrend(
                              l10n,
                              idSuffix: 'gym',
                              name: l10n.mind_focus_template_gym,
                              icon: Icons.fitness_center_rounded,
                              tokens: const ['act_exercise'],
                              color: 0xFF66BB6A,
                            ),
                            personId,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _TemplateChip(
                          label: l10n.mind_focus_template_learn,
                          icon: Icons.school_rounded,
                          color: const Color(0xFF42A5F5),
                          onTap: () => _addFromTemplate(
                            _templateTrend(
                              l10n,
                              idSuffix: 'learn',
                              name: l10n.mind_focus_template_learn,
                              icon: Icons.school_rounded,
                              tokens: const [
                                'act_learning',
                                'act_deep_work',
                                'act_reading',
                              ],
                              color: 0xFF42A5F5,
                            ),
                            personId,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _TemplateChip(
                          label: l10n.mind_focus_template_invest,
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFFFFB74D),
                          onTap: () => _addFromTemplate(
                            _templateTrend(
                              l10n,
                              idSuffix: 'invest',
                              name: l10n.mind_focus_template_invest,
                              icon: Icons.trending_up_rounded,
                              tokens: const ['act_finance', 'act_planning'],
                              color: 0xFFFFB74D,
                            ),
                            personId,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trend = _trends[index];
                      final selected = trend.id == activeFocusId;
                      final weekCount = _weekCount(trend, logs);
                      final goal = trend.weeklyGoal;
                      final progress = goal > 0
                          ? (weekCount / goal).clamp(0.0, 1.0)
                          : 0.0;
                      final avgMood = _weekAvgMood(trend, logs);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final socialBlock = context.read<SocialBlock>();
                              await socialBlock.setActiveFocusTrend(
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
                                  if (socialBlock.activeFocusTrend.peek()?.id ==
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
                                  if (socialBlock.activeFocusTrend.peek()?.id ==
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: selected
                                    ? trend.color.withValues(alpha: 0.12)
                                    : cs.surfaceContainerHighest.withValues(
                                        alpha: 0.35,
                                      ),
                                border: Border.all(
                                  color: selected
                                      ? trend.color.withValues(alpha: 0.6)
                                      : cs.outlineVariant.withValues(
                                          alpha: 0.3,
                                        ),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        MindFocusTrend.resolveIcon(
                                          trend.iconCodePoint,
                                        ),
                                        color: trend.color,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          trend.name,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$weekCount / $goal',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: trend.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: cs.surface.withValues(
                                        alpha: 0.5,
                                      ),
                                      color: trend.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.mind_focus_this_week,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (avgMood != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.sentiment_satisfied_alt,
                                          size: 16,
                                          color: mindMoodAccent(
                                            avgMood.round().clamp(1, 5),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.mind_focus_avg_mood(
                                            avgMood.toStringAsFixed(1),
                                          ),
                                          style: textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (selected) ...[
                                    const SizedBox(height: 12),
                                    _FocusDetailPanel(
                                      trend: trend,
                                      logs: logs,
                                      personId: personId,
                                      decodeActivities: _decodeActivities,
                                      logMatches: _logMatchesTrend,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _trends.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      MindFocusTrendEditor.show(
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
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.mind_focus_add),
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

class _TemplateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
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
        Text(
          l10n.mind_focus_select_hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.primary.withValues(alpha: 0.8),
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
        const SizedBox(height: 16),
        MindFocusTodosSection(trend: trend),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => MindLogEntryDialog.show(context),
          child: Text(l10n.mind_focus_log_now),
        ),
      ],
    );
  }
}
