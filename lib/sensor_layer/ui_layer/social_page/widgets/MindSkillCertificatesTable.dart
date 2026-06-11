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

/// Ice table of skill practice certificates on the Focus tab.
class MindSkillCertificatesTable extends StatelessWidget {
  const MindSkillCertificatesTable({super.key, required this.logs});

  final List<MindLogData> logs;

  static int _accentIndex(String name) {
    final i = MindSkillCatalog.defaults.indexWhere(
      (d) => MindSkillCatalog.namesMatch(d, name),
    );
    return i >= 0 ? i : name.hashCode.abs();
  }

  void _openCertificate(BuildContext context, String skillName) {
    context.push(
      Uri(
        path: '/social/skills/certificate',
        queryParameters: {
          'skill': skillName,
          'accent': '${_accentIndex(skillName)}',
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final mindAccent = HealthMetricColors.homePillarAccent('mind');
    final growth = context.watch<GrowthBlock>();
    final skills = growth.personLibrarySkills();
    final streakIndex = SkillPracticeStreak.buildDayIndex(logs);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 28,
                        decoration: BoxDecoration(
                          color: mindAccent.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.mind_skill_certificates_table_title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                            color: HealthMetricColors.mutedInk(
                              cs,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${skills.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: mindAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (skills.isEmpty)
                    Text(
                      l10n.mind_skill_certificates_table_empty,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: HealthMetricColors.textEtched,
                      ),
                    )
                  else ...[
                    _TableHeader(l10n: l10n, cs: cs, isDark: isDark),
                    const SizedBox(height: 6),
                    for (var i = 0; i < skills.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: HealthMetricColors.glassBorder(
                            cs,
                            isDark: isDark,
                            darkAlpha: 0.08,
                          ),
                        ),
                      _CertificateRow(
                        skill: skills[i],
                        accent: MindSkillsSessionCard.accentForSkillName(
                          skills[i].skillName,
                        ),
                        xp: growth.unifiedPracticePointsFor(
                          skills[i].skillName,
                        ),
                        streak: SkillPracticeStreak.streakForProtocol(
                          streakIndex,
                          skills[i].skillName,
                        ),
                        cs: cs,
                        isDark: isDark,
                        onTap: () =>
                            _openCertificate(context, skills[i].skillName),
                      ),
                    ],
                  ],
                ],
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
      accent: accent.withValues(alpha: isDark ? 0.28 : 0.35),
    );
    if (!isDark) return base;
    return base.copyWith(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            HealthMetricColors.iceBgMid.withValues(alpha: 0.18),
            HealthMetricColors.shellIslandFill,
          ),
          HealthMetricColors.shellIslandFill,
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.l10n,
    required this.cs,
    required this.isDark,
  });

  final AppLocalizations l10n;
  final ColorScheme cs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      color: HealthMetricColors.mutedInk(cs, isDark: isDark),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(l10n.mind_skill_certificates_col_skill, style: style)),
          Expanded(flex: 2, child: Text(l10n.mind_skill_certificate_level, style: style)),
          Expanded(flex: 2, child: Text(l10n.mind_skill_certificate_xp, style: style)),
          Expanded(
            flex: 2,
            child: Text(
              l10n.mind_skill_certificate_streak,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _CertificateRow extends StatelessWidget {
  const _CertificateRow({
    required this.skill,
    required this.accent,
    required this.xp,
    required this.streak,
    required this.cs,
    required this.isDark,
    required this.onTap,
  });

  final SkillProtocol skill;
  final Color accent;
  final int xp;
  final int streak;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned = xp > 0 || streak > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        SkillCertificatePage.iconForSkill(skill.skillName),
                        size: 15,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        skill.skillName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: HealthMetricColors.ink(cs, isDark: isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'L${skill.levelIndex}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent.withValues(alpha: earned ? 1 : 0.45),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$xp',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: HealthMetricColors.mutedInk(cs, isDark: isDark),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: streak > 0
                          ? Colors.orange.shade600
                          : cs.onSurface.withValues(alpha: 0.22),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      streak > 0 ? '$streak' : '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: streak > 0
                            ? Colors.orange.shade700
                            : cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
