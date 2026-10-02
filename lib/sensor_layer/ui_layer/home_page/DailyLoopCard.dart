import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/DailyLoopService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Home / canvas card: 4-pillar daily loop with streak + one-tap routes.
enum DailyLoopCardVariant { standard, canvasQuickAccess }

class DailyLoopCard extends StatefulWidget {
  const DailyLoopCard({
    super.key,
    this.variant = DailyLoopCardVariant.standard,
  });

  final DailyLoopCardVariant variant;

  @override
  State<DailyLoopCard> createState() => _DailyLoopCardState();
}

class _DailyLoopCardState extends State<DailyLoopCard> {
  int _streak = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLoop());
  }

  Future<void> _syncLoop() async {
    if (!mounted || _syncing) return;
    _syncing = true;
    try {
      final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
      if (personId.isEmpty) return;

      final health = context.read<HealthBlock>();
      final mind = context.read<MindBlock>();
      final finance = context.read<FinanceBlock>();
      final questBlock = context.read<QuestBlock>();
      final db = context.read<AppDatabase>();

      final newlyDone = await questBlock.syncDailyLoop(
        personId: personId,
        steps: health.todaySteps.value,
        focusMinutes: health.todayFocusMinutes.value,
        water: health.todayWater.value,
        calories: health.todayCaloriesConsumed.value,
        latestMood: mind.latestMoodLog.value,
        transactions: finance.transactions.value,
      );

      final streak = await DailyLoopService(db).readStreak(personId);
      if (!mounted) return;
      setState(() => _streak = streak);

      if (newlyDone.isNotEmpty && mounted) {
        final l10n = AppLocalizations.of(context)!;
        for (final q in newlyDone) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.notification_quest_completed_snack(
                  _labelForQuest(context, q.questType, q.title),
                  q.rewardExp ?? 15,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      _syncing = false;
    }
  }

  String _labelForQuest(BuildContext context, String? type, String? fallback) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      'daily_health' => l10n.daily_loop_health,
      'daily_finance' => l10n.daily_loop_finance,
      'daily_mind' => l10n.daily_loop_mind,
      'daily_projects' => l10n.daily_loop_projects,
      _ => fallback ?? l10n.project_note_untitled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Watch((context) {
      final quests = context.read<QuestBlock>().quests.value;
      final dailies = quests.where((q) => q.type == 'daily').toList()
        ..sort((a, b) {
          const order = [
            'daily_health',
            'daily_finance',
            'daily_mind',
            'daily_projects',
          ];
          return order
              .indexOf(a.questType ?? '')
              .compareTo(order.indexOf(b.questType ?? ''));
        });

      if (dailies.isEmpty) return const SizedBox.shrink();

      final done =
          dailies.where((q) => q.isCompleted == true).length;
      final total = dailies.length;
      final allDone = done >= total && total > 0;
      final progress = total > 0 ? done / total : 0.0;
      final canvasQuick =
          widget.variant == DailyLoopCardVariant.canvasQuickAccess;
      final accent = allDone
          ? HealthMetricColors.pillarYellow
          : HealthMetricColors.pillarGreen;

      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canvasQuick) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.28),
                        accent.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildHeaderTexts(
                    context,
                    l10n: l10n,
                    cs: cs,
                    allDone: allDone,
                  ),
                ),
                if (_streak > 0) _buildStreakBadge(context, l10n, cs),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _buildHeaderTexts(
                    context,
                    l10n: l10n,
                    cs: cs,
                    allDone: allDone,
                  ),
                ),
                if (_streak > 0) _buildStreakBadge(context, l10n, cs),
              ],
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: canvasQuick ? 6 : 5,
              backgroundColor: cs.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.daily_loop_progress(done, total),
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: canvasQuick ? 2.5 : 2.35,
            children: [
              for (var i = 0; i < dailies.length; i++)
                _LoopTile(
                  quest: dailies[i],
                  accent: HealthMetricColors.pillarAccentAt(i),
                  label: _labelForQuest(
                    context,
                    dailies[i].questType,
                    dailies[i].title,
                  ),
                  route: _routeForQuest(dailies[i].questType),
                  compact: canvasQuick,
                  onTap: () async {
                    await context.push(_routeForQuest(dailies[i].questType));
                    if (mounted) _syncLoop();
                  },
                ),
            ],
          ),
        ],
      );

      if (canvasQuick) {
        final faceTop =
            Color.lerp(cs.surface, accent, 0.16)!.withValues(alpha: 0.94);
        final faceMid = cs.surface.withValues(alpha: 0.82);
        final faceBottom =
            Color.lerp(cs.surface, accent, 0.24)!.withValues(alpha: 0.38);

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [faceTop, faceMid, faceBottom],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: accent.withValues(alpha: allDone ? 0.55 : 0.42),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  // Softer, wider glow for a premium look (no harsh edge).
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 28,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  // Ambient shadow — keep very subtle.
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: content,
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surface.withValues(alpha: isDark ? 0.55 : 0.92),
                cs.surfaceContainerHighest
                    .withValues(alpha: isDark ? 0.35 : 0.75),
              ],
            ),
            border: Border.all(
              color: allDone
                  ? HealthMetricColors.pillarYellow.withValues(alpha: 0.45)
                  : cs.outlineVariant.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: allDone
                ? [
                    BoxShadow(
                      color: HealthMetricColors.pillarYellow
                          .withValues(alpha: 0.14),
                      blurRadius: 30,
                      spreadRadius: -6,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      spreadRadius: -10,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      );
    });
  }

  Widget _buildHeaderTexts(
    BuildContext context, {
    required AppLocalizations l10n,
    required ColorScheme cs,
    required bool allDone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.daily_loop_title.toUpperCase(),
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.55),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          allDone ? l10n.daily_loop_complete : l10n.daily_loop_subtitle,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBadge(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HealthMetricColors.pillarYellow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HealthMetricColors.pillarYellow.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: HealthMetricColors.pillarYellow,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.daily_loop_streak(_streak),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _routeForQuest(String? type) => switch (type) {
        'daily_health' => '/health',
        'daily_finance' => '/finance',
        'daily_mind' => '/social',
        'daily_projects' => '/projects',
        _ => '/',
      };
}

class _LoopTile extends StatelessWidget {
  const _LoopTile({
    required this.quest,
    required this.accent,
    required this.label,
    required this.route,
    required this.onTap,
    this.compact = false,
  });

  final QuestData quest;
  final Color accent;
  final String label;
  final String route;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final done = quest.isCompleted == true;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 16 : 14),
            gradient: compact
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(cs.surface, accent, done ? 0.28 : 0.14)!
                          .withValues(alpha: 0.95),
                      cs.surface.withValues(alpha: 0.78),
                    ],
                  )
                : null,
            color: compact
                ? null
                : (done
                    ? accent.withValues(alpha: 0.22)
                    : accent.withValues(alpha: 0.08)),
            border: Border.all(
              color: done
                  ? accent.withValues(alpha: compact ? 0.62 : 0.55)
                  : accent.withValues(alpha: compact ? 0.32 : 0.22),
              width: compact ? 1.3 : 1,
            ),
            boxShadow: compact
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: done ? 0.18 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 10,
            vertical: compact ? 10 : 8,
          ),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 18,
                color: done ? accent : cs.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
