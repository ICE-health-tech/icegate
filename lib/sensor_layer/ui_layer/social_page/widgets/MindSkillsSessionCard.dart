import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';

/// 7-day skill session summary + entry to [MindSkillsPage].
class MindSkillsSessionCard extends StatelessWidget {
  final List<MindLogData> logs;
  final int days;

  const MindSkillsSessionCard({
    super.key,
    required this.logs,
    this.days = 7,
  });

  static ({int sessions, int minutes, String? topSkill}) summarize(
    List<MindLogData> logs, {
    int days = 7,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final skillCounts = <String, int>{};
    var sessions = 0;
    var minutes = 0;

    for (final log in logs) {
      if (log.logDate.isBefore(cutoff)) continue;
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

    String? topSkill;
    if (skillCounts.isNotEmpty) {
      topSkill = skillCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    return (sessions: sessions, minutes: minutes, topSkill: topSkill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accent = HealthMetricColors.homePillarAccent('mind');
    final tint = HealthMetricColors.homePillarCardTint('mind');
    final stats = summarize(logs, days: days);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.14),
                  tint,
                  HealthMetricColors.glassElevated,
                ],
                stops: const [0.0, 0.28, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border(
                top: BorderSide(
                  color: HealthMetricColors.borderBright.withValues(alpha: 0.85),
                ),
                left: BorderSide(color: HealthMetricColors.cardBorder),
                right: BorderSide(color: HealthMetricColors.cardBorder),
                bottom: BorderSide(color: HealthMetricColors.cardBorder),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/social/skills'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.mind_skills_session_title.toUpperCase(),
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.mind_skills_session_subtitle,
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.82),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (stats.sessions == 0)
                        Text(
                          l10n.mind_skills_session_empty(days),
                          style: TextStyle(
                            color: HealthMetricColors.textEtched,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        )
                      else
                        Text(
                          l10n.mind_skills_session_stats(
                            stats.sessions,
                            stats.minutes,
                            stats.topSkill ?? '—',
                          ),
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/social/skills'),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text(
                            l10n.mind_skills_session_start.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              fontSize: 12,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent.withValues(alpha: 0.88),
                            foregroundColor: cs.brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF0D1117),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
