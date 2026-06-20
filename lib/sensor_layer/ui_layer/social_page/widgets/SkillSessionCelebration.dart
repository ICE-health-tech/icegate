import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/SavingsCelebration.dart';

/// Full-screen proof-of-progress after a skill focus session.
void showSkillSessionCelebration(
  BuildContext context, {
  required int minutes,
  required int totalXp,
  required List<String> leveledUpSkills,
  required int bestStreak,
  required List<String> practicedSkills,
}) {
  final l10n = AppLocalizations.of(context)!;
  final lines = <String>[
    l10n.mind_skills_celebration_proof(minutes, totalXp),
  ];
  if (leveledUpSkills.isNotEmpty) {
    lines.add(
      l10n.mind_skills_celebration_level_up(leveledUpSkills.join(', ')),
    );
  }
  if (bestStreak >= 2) {
    lines.add(l10n.mind_skills_celebration_streak(bestStreak));
  }
  lines.add(l10n.mind_skills_celebration_goal);

  HapticFeedback.heavyImpact();
  showSavingsCelebration(
    context,
    bannerTitle: l10n.mind_skills_celebration_title,
    body: lines.join('\n\n'),
    duration: Duration(
      milliseconds: leveledUpSkills.isNotEmpty ? 2800 : 2200,
    ),
  );
}
