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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.20),
                  tint.withValues(alpha: 0.85),
                  HealthMetricColors.glassElevated,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/social/skills'),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 20,
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
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l10n.mind_skills_session_subtitle,
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.88),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              icon: Icons.timer_outlined,
                              label: '${stats.sessions}',
                              accent: accent,
                            ),
                            _StatChip(
                              icon: Icons.schedule_rounded,
                              label: '${stats.minutes}m',
                              accent: accent,
                            ),
                            if (stats.topSkill != null)
                              _StatChip(
                                icon: Icons.star_rounded,
                                label: stats.topSkill!,
                                accent: accent,
                              ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/social/skills'),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            l10n.mind_skills_session_start.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              fontSize: 12,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
