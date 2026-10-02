import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/QuoteBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SkillCertificatePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillCatalog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindFocusTrendEditor.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindSkillFocusHub.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Focus tab dashboard — weekly topic, target skills, linked projects, certificates.
class MindFocusDashboard extends StatelessWidget {
  const MindFocusDashboard({
    super.key,
    required this.logs,
    required this.trends,
    required this.horizontalPad,
  });

  final List<MindLogData> logs;
  final List<MindFocusTrend> trends;
  final double horizontalPad;

  /// Projects that have at least one target skill attached, with those skill names.
  static List<({ProjectProtocol project, List<String> skillNames})> _focusProjects({
    required GrowthBlock growth,
    required List<SkillProtocol> focusSkills,
    required List<ProjectProtocol> projects,
  }) {
    if (focusSkills.isEmpty) return const [];

    final merged = <String, ({ProjectProtocol project, List<String> skills})>{};
    for (final focus in focusSkills) {
      for (final s in growth.skills.value) {
        if (!MindSkillCatalog.namesMatch(s.skillName, focus.skillName)) {
          continue;
        }
        final linked = s.linkedProjectId;
        if (linked == null || linked.isEmpty) continue;

        ProjectProtocol? project;
        for (final p in projects) {
          if (p.id == linked || p.projectID == linked) {
            project = p;
            break;
          }
        }
        if (project == null) continue;

        final key = project.id;
        final existing = merged[key];
        if (existing == null) {
          merged[key] = (project: project, skills: [focus.skillName]);
          continue;
        }
        final alreadyListed = existing.skills.any(
          (name) => MindSkillCatalog.namesMatch(name, focus.skillName),
        );
        if (alreadyListed) continue;
        merged[key] = (
          project: project,
          skills: [...existing.skills, focus.skillName],
        );
      }
    }

    final list = merged.values.toList()
      ..sort((a, b) => a.project.name.compareTo(b.project.name));
    return [
      for (final e in list) (project: e.project, skillNames: e.skills),
    ];
  }

  void _openCertificate(BuildContext context, String skillName) {
    context.push(
      Uri(
        path: '/social/skills/certificate',
        queryParameters: {
          'skill': skillName,
          'accent': '${MindSkillFocusHub.accentIndex(skillName)}',
        },
      ).toString(),
    );
  }

  void _openSkillsSession(BuildContext context, String skillName) {
    context.push(
      Uri(
        path: '/social/skills',
        queryParameters: {'startSkills': skillName, 'autoStart': '0'},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final mindAccent = HealthMetricColors.homePillarAccent('mind');
    final growth = context.watch<GrowthBlock>();

    final skills = growth.personLibrarySkills()
      ..sort(
        (a, b) => MindSkillFocusHub.unifiedXp(growth, b.skillName)
            .compareTo(MindSkillFocusHub.unifiedXp(growth, a.skillName)),
      );
    final topSkills = skills.take(3).toList();
    final certSkills = skills.take(4).toList();
    final projects = context.watch<ProjectBlock>().projects.value;
    final focusProjects = _focusProjects(
      growth: growth,
      focusSkills: topSkills,
      projects: projects,
    );
    final shownProjects = focusProjects.take(5).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeeklyTopicSection(
            title: l10n.mind_dashboard_weekly_topic,
            accent: mindAccent,
            colorScheme: cs,
            isDark: isDark,
            l10n: l10n,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: l10n.mind_dashboard_target_skills,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: mindAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mindAccent.withValues(alpha: 0.28)),
              ),
              child: Text(
                l10n.mind_dashboard_in_progress,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: mindAccent,
                ),
              ),
            ),
            colorScheme: cs,
          ),
          const SizedBox(height: 10),
          if (topSkills.isEmpty)
            Text(
              l10n.mind_focus_empty,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.55),
                height: 1.35,
              ),
            )
          else
            Column(
              children: [
                for (final s in topSkills)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SkillProgressRow(
                      view: MindSkillFocusHub.viewFor(growth, s),
                      colorScheme: cs,
                      isDark: isDark,
                      l10n: l10n,
                      onTap: () => _openSkillsSession(context, s.skillName),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: l10n.mind_dashboard_focus_week,
            trailing: TextButton(
              onPressed: () => context.push('/projects'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                l10n.mind_focus_open_projects,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ),
            colorScheme: cs,
          ),
          const SizedBox(height: 8),
          if (shownProjects.isEmpty)
            _GlassCard(
              isDark: isDark,
              colorScheme: cs,
              child: Text(
                topSkills.isEmpty
                    ? l10n.mind_focus_empty
                    : l10n.mind_dashboard_no_linked_projects,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            )
          else
            ...shownProjects.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FocusProjectCard(
                  project: entry.project,
                  skillNames: entry.skillNames,
                  colorScheme: cs,
                  isDark: isDark,
                  activeLabel: l10n.mind_dashboard_in_progress,
                  doneLabel: l10n.mind_dashboard_status_done,
                ),
              ),
            ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: l10n.mind_dashboard_certificates,
            trailing: TextButton(
              onPressed: () => context.push('/social/skills'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                l10n.mind_dashboard_see_all,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ),
            colorScheme: cs,
          ),
          const SizedBox(height: 10),
          if (certSkills.isEmpty)
            Text(
              l10n.mind_focus_empty,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: [
                for (final s in certSkills)
                  _CertificateTile(
                    skillName: s.skillName,
                    xp: MindSkillFocusHub.unifiedXp(growth, s.skillName),
                    accent: MindSkillFocusHub.accentFor(s.skillName),
                    colorScheme: cs,
                    isDark: isDark,
                    verifiedLabel: l10n.mind_dashboard_verified,
                    onTap: () => _openCertificate(context, s.skillName),
                  ),
              ],
            ),
          if (trends.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
              title: l10n.mind_focus_title,
              trailing: IconButton(
                icon: const Icon(Icons.add_rounded, size: 20),
                tooltip: l10n.mind_focus_add,
                onPressed: () async {
                  final personId =
                      context.read<PersonBlock>().currentPersonID.value ?? '';
                  if (personId.isEmpty) return;
                  await MindFocusTrendEditor.show(
                    context,
                    onSave: (trend) async {
                      final list = await MindFocusTrendPrefs.load(personId);
                      list.add(trend);
                      await MindFocusTrendPrefs.save(personId, list);
                      if (context.mounted) {
                        context.read<SocialBlock>().notifyFocusTrendsChanged();
                      }
                    },
                  );
                },
              ),
              colorScheme: cs,
            ),
          ],
        ],
      ),
    );
    });
  }
}

class _WeeklyTopicSection extends StatefulWidget {
  const _WeeklyTopicSection({
    required this.title,
    required this.accent,
    required this.colorScheme,
    required this.isDark,
    required this.l10n,
  });

  final String title;
  final Color accent;
  final ColorScheme colorScheme;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  State<_WeeklyTopicSection> createState() => _WeeklyTopicSectionState();
}

class _WeeklyTopicSectionState extends State<_WeeklyTopicSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeeklyTopic());
  }

  void _loadWeeklyTopic() {
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return;
    context.read<QuoteBlock>().loadWeeklyTopic(personId);
  }

  Future<void> _showEditSheet() async {
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return;

    final quoteBlock = context.read<QuoteBlock>();
    final weekly = quoteBlock.weeklyTopic.value;
    final fallbackQuote = quoteBlock.currentQuote.value;
    final fallbackAuthor = quoteBlock.currentAuthor.value;
    final activeTrend = context.read<SocialBlock>().activeFocusTrend.value;

    final topicCtrl = TextEditingController(
      text: weekly?.topicTitle ?? activeTrend?.name ?? '',
    );
    final quoteCtrl = TextEditingController(
      text: weekly?.content ?? fallbackQuote,
    );
    final authorCtrl = TextEditingController(
      text: weekly?.author ?? fallbackAuthor ?? '',
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.colorScheme.surface.withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.l10n.mind_dashboard_edit_topic,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: widget.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: topicCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.l10n.mind_dashboard_topic_title,
                  hintText: widget.l10n.mind_dashboard_topic_title_hint,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quoteCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.l10n.notification_wisdom_content,
                  hintText: widget.l10n.mind_dashboard_topic_quote_hint,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: widget.l10n.notification_wisdom_author,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(widget.l10n.tooltip_save),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true || !mounted) {
      topicCtrl.dispose();
      quoteCtrl.dispose();
      authorCtrl.dispose();
      return;
    }

    await quoteBlock.saveWeeklyTopic(
      personId: personId,
      topicTitle: topicCtrl.text,
      content: quoteCtrl.text,
      author: authorCtrl.text,
    );

    topicCtrl.dispose();
    quoteCtrl.dispose();
    authorCtrl.dispose();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.l10n.mind_dashboard_topic_saved),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final quoteBlock = context.watch<QuoteBlock>();
      final weekly = quoteBlock.weeklyTopic.value;
      final activeTrend = context.watch<SocialBlock>().activeFocusTrend.value;

      final quote = weekly?.content ?? quoteBlock.currentQuote.value;
      final author = weekly?.author ?? quoteBlock.currentAuthor.value;
      final focusName = weekly?.topicTitle ?? activeTrend?.name;

      return _WeeklyTopicCard(
        title: widget.title,
        quote: quote,
        author: author,
        focusName: focusName,
        accent: widget.accent,
        colorScheme: widget.colorScheme,
        isDark: widget.isDark,
        onEdit: _showEditSheet,
      );
    });
  }
}

class _WeeklyTopicCard extends StatelessWidget {
  const _WeeklyTopicCard({
    required this.title,
    required this.quote,
    required this.author,
    required this.focusName,
    required this.accent,
    required this.colorScheme,
    required this.isDark,
    required this.onEdit,
  });

  final String title;
  final String quote;
  final String? author;
  final String? focusName;
  final Color accent;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  accent.withValues(alpha: isDark ? 0.16 : 0.1),
                  HealthMetricColors.glassFill(
                    colorScheme,
                    isDark: isDark,
                    darkAlpha: 0.04,
                  ),
                ),
                HealthMetricColors.glassFill(
                  colorScheme,
                  isDark: isDark,
                  darkAlpha: 0.02,
                ),
              ],
            ),
            border: Border.all(
              color: HealthMetricColors.glassBorder(
                colorScheme,
                isDark: isDark,
                darkAlpha: 0.1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (focusName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        focusName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      '"$quote"',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: colorScheme.primary.withValues(alpha: 0.95),
                      ),
                    ),
                    if (author != null && author!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        author!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                color: colorScheme.surface.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Icon(Icons.edit_rounded, color: accent, size: 18),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    required this.colorScheme,
  });

  final String title;
  final Widget trailing;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _SkillProgressRow extends StatelessWidget {
  const _SkillProgressRow({
    required this.view,
    required this.colorScheme,
    required this.isDark,
    required this.l10n,
    required this.onTap,
  });

  final SkillFocusView view;
  final ColorScheme colorScheme;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (view.progress * 100).round();
    final accent = view.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: accent.withValues(alpha: isDark ? 0.08 : 0.06),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    SkillCertificatePage.iconForSkill(view.skill.skillName),
                    size: 16,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      view.skill.skillName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: view.progress,
                  minHeight: 6,
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.mind_focus_xp_progress(view.intoCurrent, view.xpCap),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.colorScheme,
    required this.isDark,
  });

  final Widget child;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: HealthMetricColors.shellPanel(
        colorScheme,
        isDark: isDark,
        radius: 16,
        accent: HealthMetricColors.homePillarAccent('mind'),
      ),
      child: child,
    );
  }
}

class _FocusProjectCard extends StatelessWidget {
  const _FocusProjectCard({
    required this.project,
    required this.skillNames,
    required this.colorScheme,
    required this.isDark,
    required this.activeLabel,
    required this.doneLabel,
  });

  final ProjectProtocol project;
  final List<String> skillNames;
  final ColorScheme colorScheme;
  final bool isDark;
  final String activeLabel;
  final String doneLabel;

  Color? _projectTint() {
    final raw = project.color;
    if (raw == null || raw.isEmpty) return null;
    final hex = raw.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return hex.length == 6 ? Color(0xFF000000 | value) : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final completed = project.status == 1;
    final tint = _projectTint() ?? colorScheme.primary;
    final statusLabel = completed ? doneLabel : activeLabel;
    final statusColor = completed
        ? HealthMetricColors.pillarGreen
        : HealthMetricColors.pillarOrange;

    return _GlassCard(
      isDark: isDark,
      colorScheme: colorScheme,
      child: InkWell(
        onTap: () => context.push('/projects/${project.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_rounded,
                size: 18,
                color: tint,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                  if (skillNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final name in skillNames)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: MindSkillFocusHub.accentFor(name)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: MindSkillFocusHub.accentFor(name),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({
    required this.skillName,
    required this.xp,
    required this.accent,
    required this.colorScheme,
    required this.isDark,
    required this.verifiedLabel,
    required this.onTap,
  });

  final String skillName;
  final int xp;
  final Color accent;
  final ColorScheme colorScheme;
  final bool isDark;
  final String verifiedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned = xp >= 100;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: earned ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: HealthMetricColors.shellPanel(
            colorScheme,
            isDark: isDark,
            radius: 18,
            accent: earned ? accent : colorScheme.outline,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: earned ? 0.15 : 0.06),
                ),
                child: Icon(
                  SkillCertificatePage.iconForSkill(skillName),
                  color: earned ? accent : colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                skillName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withValues(
                    alpha: earned ? 0.9 : 0.4,
                  ),
                ),
              ),
              if (earned) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    verifiedLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
