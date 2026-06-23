import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SkillCertificatePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillCatalog.dart';

enum SkillSessionScope { rollingDays, calendarMonth }

/// Skill session summary + entry to [MindSkillsPage].
class MindSkillsSessionCard extends StatelessWidget {
  final List<MindLogData> logs;
  final int days;
  final SkillSessionScope scope;

  const MindSkillsSessionCard({
    super.key,
    required this.logs,
    this.days = 7,
    this.scope = SkillSessionScope.rollingDays,
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
      topSkill =
          skillCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    return (sessions: sessions, minutes: minutes, topSkill: topSkill);
  }

  static DateTime _monthStart([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static String _canonicalSkillName(String raw) {
    final trimmed = raw.trim();
    for (final d in MindSkillCatalog.defaults) {
      if (MindSkillCatalog.namesMatch(d, trimmed)) return d;
    }
    return trimmed;
  }

  /// Skills practiced in the current calendar month, ranked by session count.
  static ({
    int sessions,
    int minutes,
    List<({String name, int sessions, int minutes})> skills,
  }) summarizeThisMonth(List<MindLogData> logs) {
    final monthStart = _monthStart();
    final skillSessions = <String, int>{};
    final skillMinutes = <String, int>{};
    var totalSessions = 0;
    var totalMinutes = 0;

    for (final log in logs) {
      final day = DateTime(
        log.logDate.year,
        log.logDate.month,
        log.logDate.day,
      );
      if (day.isBefore(monthStart)) continue;

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

      var logMinutes = 0;
      for (final a in acts.whereType<String>()) {
        if (!a.startsWith('learn:')) continue;
        final m = RegExp(r'learn:(\d+)m').firstMatch(a);
        if (m != null) {
          logMinutes += int.tryParse(m.group(1) ?? '0') ?? 0;
        }
      }

      totalSessions++;
      totalMinutes += logMinutes;

      for (final raw in skills) {
        final name = _canonicalSkillName(raw);
        skillSessions[name] = (skillSessions[name] ?? 0) + 1;
        if (logMinutes > 0) {
          skillMinutes[name] = (skillMinutes[name] ?? 0) + logMinutes;
        }
      }
    }

    final ranked = skillSessions.entries
        .map(
          (e) => (
            name: e.key,
            sessions: e.value,
            minutes: skillMinutes[e.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) {
        final bySessions = b.sessions.compareTo(a.sessions);
        if (bySessions != 0) return bySessions;
        return b.minutes.compareTo(a.minutes);
      });

    return (
      sessions: totalSessions,
      minutes: totalMinutes,
      skills: ranked,
    );
  }

  static Color accentForSkillName(String name) {
    final i = MindSkillCatalog.defaults.indexWhere(
      (d) => MindSkillCatalog.namesMatch(d, name),
    );
    final idx = i >= 0 ? i : name.hashCode.abs();
    return HealthMetricColors.pillarAccentAt(idx);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final mindAccent = HealthMetricColors.homePillarAccent('mind');
    final monthStats = scope == SkillSessionScope.calendarMonth
        ? summarizeThisMonth(logs)
        : null;
    final stats = monthStats == null
        ? summarize(logs, days: days)
        : (
            sessions: monthStats.sessions,
            minutes: monthStats.minutes,
            topSkill: monthStats.skills.isEmpty
                ? null
                : monthStats.skills.first.name,
          );
    final monthSkills = monthStats?.skills ?? const [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Container(
        decoration: _icePanel(cs, isDark: isDark, accent: mindAccent),
        child: Stack(
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
                      Colors.white.withValues(alpha: isDark ? 0.16 : 0.35),
                      Colors.white.withValues(alpha: isDark ? 0.03 : 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/social/skills'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: 34,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: mindAccent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.mind_skills_session_title.toUpperCase(),
                                  style: TextStyle(
                                    color: HealthMetricColors.mutedInk(
                                      cs,
                                      isDark: isDark,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.mind_skills_session_subtitle,
                                  style: TextStyle(
                                    color: HealthMetricColors.ink(
                                      cs,
                                      isDark: isDark,
                                    ).withValues(alpha: 0.88),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
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
                          scope == SkillSessionScope.calendarMonth
                              ? l10n.mind_skills_session_empty_month
                              : l10n.mind_skills_session_empty(days),
                          style: TextStyle(
                            color: HealthMetricColors.textEtched,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _IceMetricCell(
                                icon: Icons.bolt_rounded,
                                value: '${stats.sessions}',
                                isDark: isDark,
                                cs: cs,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _IceMetricCell(
                                icon: Icons.schedule_rounded,
                                value: '${stats.minutes}m',
                                isDark: isDark,
                                cs: cs,
                              ),
                            ),
                          ],
                        ),
                        if (scope == SkillSessionScope.calendarMonth &&
                            monthSkills.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          for (final skill in monthSkills) ...[
                            _SkillCategoryChip(
                              skillName: skill.name,
                              subtitle: l10n.mind_skills_session_skill_meta(
                                skill.sessions,
                                skill.minutes,
                              ),
                              accent: accentForSkillName(skill.name),
                              isDark: isDark,
                              cs: cs,
                              onTap: () => context.push(
                                Uri(
                                  path: '/social/skills',
                                  queryParameters: {
                                    'startSkills': skill.name,
                                    'autoStart': '0',
                                  },
                                ).toString(),
                              ),
                            ),
                            if (skill != monthSkills.last)
                              const SizedBox(height: 8),
                          ],
                        ] else if (stats.topSkill != null) ...[
                          const SizedBox(height: 10),
                          _SkillCategoryChip(
                            skillName: stats.topSkill!,
                            accent: accentForSkillName(stats.topSkill!),
                            isDark: isDark,
                            cs: cs,
                          ),
                        ],
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/social/skills'),
                          icon: const Icon(Icons.play_arrow_rounded, size: 21),
                          label: Text(
                            l10n.mind_skills_session_start.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: mindAccent.withValues(
                              alpha: isDark ? 0.92 : 1,
                            ),
                            foregroundColor: isDark
                                ? Colors.white
                                : const Color(0xFF0D1117),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _icePanel(
    ColorScheme cs, {
    required bool isDark,
    required Color accent,
  }) {
    final base = HealthMetricColors.shellPanel(
      cs,
      isDark: isDark,
      radius: 20,
      accent: accent.withValues(alpha: isDark ? 0.35 : 0.4),
    );
    if (!isDark) return base;
    return base.copyWith(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            HealthMetricColors.iceBgMid.withValues(alpha: 0.2),
            HealthMetricColors.shellIslandFill,
          ),
          HealthMetricColors.shellIslandFill,
        ],
      ),
    );
  }
}

class _IceMetricCell extends StatelessWidget {
  const _IceMetricCell({
    required this.icon,
    required this.value,
    required this.isDark,
    required this.cs,
  });

  final IconData icon;
  final String value;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: HealthMetricColors.glassFill(cs, isDark: isDark, darkAlpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HealthMetricColors.glassBorder(cs, isDark: isDark),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 15,
            color: HealthMetricColors.textEtchedStrong,
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: HealthMetricColors.ink(cs, isDark: isDark),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillCategoryChip extends StatelessWidget {
  const _SkillCategoryChip({
    required this.skillName,
    required this.accent,
    required this.isDark,
    required this.cs,
    this.subtitle,
    this.onTap,
  });

  final String skillName;
  final String? subtitle;
  final Color accent;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.16 : 0.12),
            HealthMetricColors.glassFill(
              cs,
              isDark: isDark,
              darkAlpha: 0.04,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.42 : 0.48),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              SkillCertificatePage.iconForSkill(skillName),
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skillName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: HealthMetricColors.ink(cs, isDark: isDark),
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: HealthMetricColors.mutedInk(cs, isDark: isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: chip,
      ),
    );
  }
}
