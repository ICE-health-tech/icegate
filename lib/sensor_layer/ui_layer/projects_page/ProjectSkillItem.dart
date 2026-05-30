import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:provider/provider.dart';

class ProjectSkillItem extends StatelessWidget {
  final SkillProtocol skill;
  final int practiceStreak;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ProjectSkillItem({
    super.key,
    required this.skill,
    this.practiceStreak = 0,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final unifiedXp = context
        .read<GrowthBlock>()
        .unifiedPracticePointsFor(skill.skillName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.primary.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: SkillProtocol.practiceLevelProgress(unifiedXp),
                      strokeWidth: 3,
                      backgroundColor:
                          colorScheme.onSurface.withValues(alpha: 0.08),
                      color: colorScheme.primary,
                    ),
                    Text(
                      '${skill.levelIndex}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.skillName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: SkillProtocol.practiceLevelProgress(unifiedXp),
                        minHeight: 4,
                        backgroundColor:
                            colorScheme.onSurface.withValues(alpha: 0.06),
                        color: colorScheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: practiceStreak > 0
                              ? Colors.orange.shade600
                              : colorScheme.onSurface.withValues(alpha: 0.25),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          practiceStreak > 0
                              ? l10n.project_skill_streak_days(practiceStreak)
                              : l10n.project_skill_streak_none,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: practiceStreak > 0
                                ? Colors.orange.shade700
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.project_skill_xp_hint(
                        unifiedXp,
                        SkillProtocol.practiceXpToNextLevel(unifiedXp),
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Checkbox(
                value: isSelected,
                onChanged: onTap != null ? (_) => onTap!() : null,
                activeColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
