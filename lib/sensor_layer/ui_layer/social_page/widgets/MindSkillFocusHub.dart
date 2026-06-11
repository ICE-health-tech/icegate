import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/link_layer/skills/skill_practice_streak.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SkillCertificatePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/mind_skill_catalog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindSkillsSessionCard.dart';
import 'package:provider/provider.dart';

/// Gamified skill focus hub (weekly / monthly focus + skill tree + certificates).
class MindSkillFocusHub extends StatelessWidget {
  const MindSkillFocusHub({super.key, required this.logs});

  final List<MindLogData> logs;

  static int accentIndex(String name) {
    final i = MindSkillCatalog.defaults.indexWhere(
      (d) => MindSkillCatalog.namesMatch(d, name),
    );
    return i >= 0 ? i : name.hashCode.abs();
  }

  static Color accentFor(String name) =>
      HealthMetricColors.pillarAccentAt(accentIndex(name));

  static int unifiedXp(GrowthBlock growth, String name) =>
      growth.unifiedPracticePointsFor(name);

  static SkillFocusView viewFor(GrowthBlock growth, SkillProtocol skill) {
    final xp = unifiedXp(growth, skill.skillName);
    final progress = SkillProtocol.practiceLevelProgress(xp);
    final into = xp >= 500
        ? xp - 500
        : xp >= 250
            ? xp - 250
            : xp >= 100
                ? xp - 100
                : xp;
    final toNext = SkillProtocol.practiceXpToNextLevel(xp);
    final goalLevel = skill.levelIndex < 4 ? skill.levelIndex + 1 : 4;
    return SkillFocusView(
      skill: skill,
      xp: xp,
      intoCurrent: into,
      xpCap: into + toNext,
      progress: progress,
      goalLevel: goalLevel,
      accent: accentFor(skill.skillName),
    );
  }

  static String? _weeklySkillName(List<MindLogData> logs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final counts = <String, int>{};
    for (final log in logs) {
      if (log.logDate.isBefore(cutoff)) continue;
      try {
        final acts = jsonDecode(log.activities) as List<dynamic>;
        for (final a in acts) {
          if (a is! String || !a.startsWith('skill:')) continue;
          final name = a.substring('skill:'.length);
          counts[name] = (counts[name] ?? 0) + 1;
        }
      } catch (_) {}
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static SkillProtocol? _resolveSkill(
    GrowthBlock growth,
    String? name,
    List<SkillProtocol> skills,
  ) {
    if (name == null) return null;
    for (final s in skills) {
      if (MindSkillCatalog.namesMatch(s.skillName, name)) return s;
    }
    return null;
  }

  static SkillProtocol? _monthlySkill(GrowthBlock growth, List<SkillProtocol> skills) {
    if (skills.isEmpty) return null;
    return skills.reduce((a, b) {
      final ax = unifiedXp(growth, a.skillName);
      final bx = unifiedXp(growth, b.skillName);
      return bx > ax ? b : a;
    });
  }

  void _openSkill(BuildContext context, String skillName) {
    context.push(
      Uri(
        path: '/social/skills/certificate',
        queryParameters: {
          'skill': skillName,
          'accent': '${accentIndex(skillName)}',
        },
      ).toString(),
    );
  }

  void _startSession(BuildContext context, String skillName) {
    context.push(
      Uri(
        path: '/social/skills',
        queryParameters: {
          'startSkills': skillName,
          'autoStart': '0',
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final growth = context.watch<GrowthBlock>();
    final skills = growth.personLibrarySkills();
    final streakIndex = SkillPracticeStreak.buildDayIndex(logs);

    if (skills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Text(
          l10n.mind_focus_empty,
          style: TextStyle(
            color: HealthMetricColors.textEtched,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      );
    }

    final totalLevel = skills.fold<int>(
      0,
      (s, sk) => s + unifiedXp(growth, sk.skillName) ~/ 100,
    );
    var maxStreak = 0;
    for (final s in skills) {
      final st = SkillPracticeStreak.streakForProtocol(
        streakIndex,
        s.skillName,
      );
      if (st > maxStreak) maxStreak = st;
    }

    final weeklyName = _weeklySkillName(logs);
    final weeklySkill = _resolveSkill(growth, weeklyName, skills) ??
        skills.first;
    final monthlySkill = _monthlySkill(growth, skills);
    final weeklyView = viewFor(growth, weeklySkill);
    final monthlyView =
        monthlySkill != null ? viewFor(growth, monthlySkill) : weeklyView;

    final featured = [...skills]
      ..sort((a, b) => unifiedXp(growth, b.skillName)
          .compareTo(unifiedXp(growth, a.skillName)));
    final featuredTop = featured.take(3).toList();
    final gridSkills = featured.skip(3).take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroStatsRow(
            totalLevel: totalLevel,
            streakDays: maxStreak,
            l10n: l10n,
            isDark: isDark,
            cs: cs,
          ),
          const SizedBox(height: 14),
          _FocusSkillCard(
            title: l10n.mind_focus_weekly_title,
            view: weeklyView,
            showFocusBadge: true,
            isDark: isDark,
            cs: cs,
            l10n: l10n,
            onTap: () => _startSession(context, weeklyView.skill.skillName),
            onCertificate: () =>
                _openSkill(context, weeklyView.skill.skillName),
          ),
          const SizedBox(height: 12),
          if (monthlySkill != null &&
              !MindSkillCatalog.namesMatch(
                monthlySkill.skillName,
                weeklySkill.skillName,
              ))
            _FocusSkillCard(
              title: l10n.mind_focus_monthly_title,
              view: monthlyView,
              showFocusBadge: false,
              isDark: isDark,
              cs: cs,
              l10n: l10n,
              onTap: () => _openSkill(context, monthlyView.skill.skillName),
              onCertificate: () =>
                  _openSkill(context, monthlyView.skill.skillName),
            ),
          if (monthlySkill != null &&
              !MindSkillCatalog.namesMatch(
                monthlySkill.skillName,
                weeklySkill.skillName,
              ))
            const SizedBox(height: 16),
          _SectionLabel(l10n.mind_skill_tree_title, cs),
          const SizedBox(height: 10),
          for (final s in featuredTop) ...[
            _SkillTreeRow(
              view: viewFor(growth, s),
              large: true,
              isDark: isDark,
              cs: cs,
              onTap: () => _openSkill(context, s.skillName),
            ),
            const SizedBox(height: 8),
          ],
          if (gridSkills.isNotEmpty) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
              children: [
                for (final s in gridSkills)
                  _SkillTreeTile(
                    view: viewFor(growth, s),
                    isDark: isDark,
                    cs: cs,
                    onTap: () => _openSkill(context, s.skillName),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _SectionLabel(l10n.mind_skill_certificates_title, cs),
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: skills.length.clamp(0, 8),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final s = skills[i];
                final xp = unifiedXp(growth, s.skillName);
                final earned = xp >= 100;
                final accent = accentFor(s.skillName);
                return _CertificateBadge(
                  skillName: s.skillName,
                  earned: earned,
                  accent: accent,
                  isDark: isDark,
                  cs: cs,
                  onTap: earned
                      ? () => _openSkill(context, s.skillName)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          MindSkillsSessionCard(
            logs: logs,
            scope: SkillSessionScope.calendarMonth,
          ),
        ],
      ),
    );
  }
}

class SkillFocusView {
  const SkillFocusView({
    required this.skill,
    required this.xp,
    required this.intoCurrent,
    required this.xpCap,
    required this.progress,
    required this.goalLevel,
    required this.accent,
  });

  final SkillProtocol skill;
  final int xp;
  final int intoCurrent;
  final int xpCap;
  final double progress;
  final int goalLevel;
  final Color accent;
}

class _HeroStatsRow extends StatelessWidget {
  const _HeroStatsRow({
    required this.totalLevel,
    required this.streakDays,
    required this.l10n,
    required this.isDark,
    required this.cs,
  });

  final int totalLevel;
  final int streakDays;
  final AppLocalizations l10n;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeroStatCard(
            label: l10n.mind_total_level.toUpperCase(),
            value: '$totalLevel',
            subtitle: null,
            accent: HealthMetricColors.pillarBlue,
            isDark: isDark,
            cs: cs,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HeroStatCard(
            label: l10n.mind_streak_label.toUpperCase(),
            value: l10n.mind_streak_days(streakDays),
            subtitle: streakDays > 0 ? l10n.mind_streak_bonus : null,
            accent: HealthMetricColors.pillarYellow,
            isDark: isDark,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    required this.cs,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color accent;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _panel(cs, isDark: isDark, accent: accent.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: HealthMetricColors.mutedInk(cs, isDark: isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: HealthMetricColors.ink(cs, isDark: isDark),
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FocusSkillCard extends StatelessWidget {
  const _FocusSkillCard({
    required this.title,
    required this.view,
    required this.showFocusBadge,
    required this.isDark,
    required this.cs,
    required this.l10n,
    required this.onTap,
    required this.onCertificate,
  });

  final String title;
  final SkillFocusView view;
  final bool showFocusBadge;
  final bool isDark;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onCertificate;

  @override
  Widget build(BuildContext context) {
    final pct = (view.progress * 100).round();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onCertificate,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _panel(
            cs,
            isDark: isDark,
            accent: view.accent.withValues(alpha: 0.45),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HealthMetricColors.mutedInk(cs, isDark: isDark),
                    ),
                  ),
                  const Spacer(),
                  if (showFocusBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: view.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: view.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 12,
                            color: view.accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l10n.mind_focus_badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: view.accent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: view.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      SkillCertificatePage.iconForSkill(view.skill.skillName),
                      color: view.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.skill.skillName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: HealthMetricColors.ink(cs, isDark: isDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.mind_focus_goal_level(view.goalLevel),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: HealthMetricColors.mutedInk(
                              cs,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: view.progress,
                  minHeight: 8,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                  color: view.accent,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    l10n.mind_focus_xp_progress(
                      view.intoCurrent,
                      view.xpCap,
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: HealthMetricColors.mutedInk(cs, isDark: isDark),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: view.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.cs);
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
        color: cs.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}

class _SkillTreeRow extends StatelessWidget {
  const _SkillTreeRow({
    required this.view,
    required this.large,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  final SkillFocusView view;
  final bool large;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _panel(
            cs,
            isDark: isDark,
            accent: view.accent.withValues(alpha: 0.35),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: view.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  SkillCertificatePage.iconForSkill(view.skill.skillName),
                  size: 18,
                  color: view.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            view.skill.skillName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: HealthMetricColors.ink(cs, isDark: isDark),
                            ),
                          ),
                        ),
                        Text(
                          'Lv. ${view.skill.levelIndex.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: view.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: view.progress,
                        minHeight: 4,
                        backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                        color: view.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${view.xp} XP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: HealthMetricColors.mutedInk(cs, isDark: isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillTreeTile extends StatelessWidget {
  const _SkillTreeTile({
    required this.view,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  final SkillFocusView view;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: _panel(
            cs,
            isDark: isDark,
            accent: view.accent.withValues(alpha: 0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                SkillCertificatePage.iconForSkill(view.skill.skillName),
                color: view.accent,
                size: 22,
              ),
              const Spacer(),
              Text(
                view.skill.skillName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: HealthMetricColors.ink(cs, isDark: isDark),
                ),
              ),
              Text(
                'Lv. ${view.skill.levelIndex.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: view.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateBadge extends StatelessWidget {
  const _CertificateBadge({
    required this.skillName,
    required this.earned,
    required this.accent,
    required this.isDark,
    required this.cs,
    required this.onTap,
  });

  final String skillName;
  final bool earned;
  final Color accent;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 92,
          padding: const EdgeInsets.all(10),
          decoration: _panel(
            cs,
            isDark: isDark,
            accent: earned
                ? accent.withValues(alpha: 0.4)
                : cs.outline.withValues(alpha: 0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earned
                      ? accent.withValues(alpha: 0.2)
                      : cs.onSurface.withValues(alpha: 0.06),
                  border: Border.all(
                    color: earned
                        ? accent.withValues(alpha: 0.5)
                        : cs.onSurface.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  earned
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: earned
                      ? accent
                      : cs.onSurface.withValues(alpha: 0.35),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                skillName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: earned
                      ? HealthMetricColors.ink(cs, isDark: isDark)
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _panel(
  ColorScheme cs, {
  required bool isDark,
  required Color accent,
}) {
  final base = HealthMetricColors.shellPanel(
    cs,
    isDark: isDark,
    radius: 18,
    accent: accent,
  );
  if (!isDark) return base;
  return base.copyWith(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          HealthMetricColors.iceBgMid.withValues(alpha: 0.14),
          HealthMetricColors.shellIslandFill,
        ),
        HealthMetricColors.shellIslandFill,
      ],
    ),
  );
}
