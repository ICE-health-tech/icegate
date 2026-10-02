
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/link_layer/skills/skill_practice_streak.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillCatalog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Full-screen practice certificate for one skill (tap / double-tap from list).
class SkillCertificatePage extends StatelessWidget {
  final String skillName;
  final int accentIndex;
  final bool initiallySelected;

  const SkillCertificatePage({
    super.key,
    required this.skillName,
    this.accentIndex = 0,
    this.initiallySelected = false,
  });

  /// Element icons aligned with the crystal compass (ice / water / thunder / fire / wind / nature).
  static IconData iconForSkill(String label) {
    return switch (label.toLowerCase()) {
      'focus' => Icons.ac_unit_rounded,
      'syntax' => Icons.ac_unit_rounded,
      'health' => Icons.water_drop_rounded,
      'adaptation' => Icons.air_rounded,
      'logic' => Icons.bolt_rounded,
      'meta mental' => Icons.bolt_rounded,
      'presentation' => Icons.local_fire_department_rounded,
      'spirit' => Icons.local_fire_department_rounded,
      'design' => Icons.eco_rounded,
      'growth' => Icons.eco_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  static Color colorForSkill(String label) {
    switch (label.toLowerCase()) {
      case 'focus':
        return const Color(0xFF41E3D0);
      case 'logic':
        return const Color(0xFF8C7BFF);
      case 'design':
        return const Color(0xFFFF7FD1);
      case 'syntax':
        return const Color(0xFF56C0FF);
      case 'growth':
        return const Color(0xFF9BE15D);
      case 'health':
        return const Color(0xFF5AF2B0);
      case 'presentation':
        return const Color(0xFFFFD66B);
      case 'adaptation':
        return const Color(0xFF53E1FF);
      case 'meta mental':
        return const Color(0xFFB794F4);
      case 'spirit':
        return const Color(0xFFFF9A6B);
      default:
        var h = 0;
        for (final c in label.codeUnits) {
          h = (h * 16777619 + c) & 0x7fffffff;
        }
        h = h == 0 ? 1 : h;
        return HSLColor.fromAHSL(1.0, (h % 360).toDouble(), 0.72, 0.55).toColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accent = HealthMetricColors.pillarAccentAt(accentIndex);
    final personId = context.watch<PersonBlock>().currentPersonID.value;

    if (personId == null || personId.isEmpty) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final growth = context.watch<GrowthBlock>();
    final mindBlock = context.read<MindBlock>();
    SkillProtocol? skill;
    for (final s in growth.personLibrarySkills()) {
      if (MindSkillCatalog.namesMatch(s.skillName, skillName)) {
        skill = s;
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<MindLogData>>(
        stream: mindBlock.watchMindLogs(personId),
        builder: (context, snapshot) {
          final streakIndex =
              SkillPracticeStreak.buildDayIndex(snapshot.data ?? []);
          final streak = SkillPracticeStreak.streakForProtocol(
            streakIndex,
            skillName,
          );
          return _CertificateBody(
            l10n: l10n,
            skillName: skillName,
            skill: skill,
            accent: accent,
            streak: streak,
            initiallySelected: initiallySelected,
          );
        },
      ),
    );
  }
}

class _CertificateBody extends StatefulWidget {
  const _CertificateBody({
    required this.l10n,
    required this.skillName,
    required this.skill,
    required this.accent,
    required this.streak,
    required this.initiallySelected,
  });

  final AppLocalizations l10n;
  final String skillName;
  final SkillProtocol? skill;
  final Color accent;
  final int streak;
  final bool initiallySelected;

  @override
  State<_CertificateBody> createState() => _CertificateBodyState();
}

Future<void> _showSkillCertificateEditSheet(
  BuildContext context, {
  required AppLocalizations l10n,
  required String skillName,
  required SkillProtocol skill,
}) async {
  final growth = context.read<GrowthBlock>();
  final descriptionCtrl = TextEditingController(text: skill.description ?? '');
  var createdAt = skill.createdAt.toLocal();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                  l10n.mind_skill_certificate_edit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.mind_skill_certificate_created,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: createdAt,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked == null) return;
                    setSheetState(() {
                      createdAt = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        createdAt.hour,
                        createdAt.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(DateFormat.yMMMd().format(createdAt)),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.mind_skill_certificate_updated,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().add_Hm().format(skill.updatedAt.toLocal()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descriptionCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: l10n.mind_skill_certificate_description,
                    hintText: l10n.mind_skill_certificate_description_hint,
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await growth.updateSkillCertificateDetails(
                      skillName: skillName,
                      description: descriptionCtrl.text,
                      createdAt: createdAt.toUtc(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(l10n.mind_skill_certificate_save),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  descriptionCtrl.dispose();
}

class _CertificateBodyState extends State<_CertificateBody> {
  late bool _selectedForSession;

  @override
  void initState() {
    super.initState();
    _selectedForSession = widget.initiallySelected;
  }

  String _proficiencyLabel(String raw) {
    if (raw.isEmpty) return 'Beginner';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _formatDate(DateTime dt) =>
      DateFormat.yMMMd().add_Hm().format(dt.toLocal());

  String _formatDateShort(DateTime dt) =>
      DateFormat('dd/MM/yyyy').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final skill = widget.skill;
    final level = skill?.levelIndex ?? 1;
    final xp = skill?.practicePoints ?? 0;
    final xpRemaining = skill?.xpToNextLevel ?? 100;
    final progress = skill?.levelProgress ?? 0.0;
    final createdAt = skill?.createdAt ?? DateTime.now();
    final updatedAt = skill?.updatedAt ?? DateTime.now();
    final description = skill?.description?.trim();
    final proofText = description != null && description.isNotEmpty
        ? description
        : l10n.mind_skill_certificate_proof;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              CustomPaint(
                painter: _CertificateFramePainter(
                  accent: widget.accent,
                ),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: Column(
                    children: [
                      Text(
                        l10n.mind_skill_certificate_header,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.2,
                          color: widget.accent.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.mind_skill_certificate_subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.45),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.accent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          SkillCertificatePage.iconForSkill(widget.skillName),
                          size: 36,
                          color: widget.accent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.skillName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.mind_skill_certificate_awarded_to,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _certRow(
                        l10n.mind_skill_certificate_level,
                        '${l10n.mind_skills_level_short(level)} · ${_proficiencyLabel(skill?.proficiencyLevel ?? 'beginner')}',
                      ),
                      const SizedBox(height: 10),
                      _certRow(
                        l10n.mind_skill_certificate_xp,
                        l10n.project_skill_xp_hint(xp, xpRemaining),
                      ),
                      const SizedBox(height: 10),
                      _certRow(
                        l10n.mind_skill_certificate_streak,
                        widget.streak > 0
                            ? l10n.project_skill_streak_days(widget.streak)
                            : l10n.project_skill_streak_none,
                      ),
                      const SizedBox(height: 10),
                      _certRow(
                        l10n.mind_skill_certificate_created,
                        _formatDate(createdAt),
                      ),
                      const SizedBox(height: 10),
                      _certRow(
                        l10n.mind_skill_certificate_updated,
                        _formatDate(updatedAt),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          color: widget.accent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        proofText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontStyle: description == null || description.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: Colors.white.withValues(alpha: 0.55),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 28,
                            color: widget.accent.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.mind_skill_certificate_seal,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8,
                                  color: widget.accent.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                _formatDateShort(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (skill != null)
                OutlinedButton.icon(
                  onPressed: () => _showSkillCertificateEditSheet(
                    context,
                    l10n: l10n,
                    skillName: widget.skillName,
                    skill: skill,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: Text(l10n.mind_skill_certificate_edit),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: Colors.white.withValues(alpha: 0.85),
                    side: BorderSide(
                      color: widget.accent.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _selectedForSession = !_selectedForSession);
                },
                icon: Icon(
                  _selectedForSession
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                ),
                label: Text(
                  _selectedForSession
                      ? l10n.mind_skills_status_selected
                      : l10n.mind_skill_certificate_select_session,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: widget.accent.withValues(alpha: 0.22),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.pop(_selectedForSession),
                child: Text(l10n.mind_skill_certificate_close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _CertificateFramePainter extends CustomPainter {
  _CertificateFramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(14),
    );

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF14141C),
          const Color(0xFF0E0E14),
        ],
      ).createShader(outer.outerRect);

    canvas.drawRRect(outer, fill);

    final borderOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: 0.55);
    canvas.drawRRect(outer, borderOuter);

    final borderInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.22);
    canvas.drawRRect(innerRect, borderInner);

    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.75);
    const cLen = 22.0;
    for (final origin in [
      const Offset(14, 14),
      Offset(size.width - 14, 14),
      Offset(14, size.height - 14),
      Offset(size.width - 14, size.height - 14),
    ]) {
      final dx = origin.dx < size.width / 2 ? 1.0 : -1.0;
      final dy = origin.dy < size.height / 2 ? 1.0 : -1.0;
      canvas.drawLine(origin, origin + Offset(cLen * dx, 0), corner);
      canvas.drawLine(origin, origin + Offset(0, cLen * dy), corner);
    }
  }

  @override
  bool shouldRepaint(covariant _CertificateFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
