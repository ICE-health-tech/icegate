import 'package:flutter/material.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/ProjectPoint.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class ScoringRulesPage extends StatelessWidget {
  const ScoringRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.scoring_rules_title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroduction(context),
            const SizedBox(height: 32),
            _buildCategorySection(
              context,
              title: AppLocalizations.of(context)!.scoring_health,
              color: Colors.green,
              rules: [
                AppLocalizations.of(
                  context,
                )!.rule_health_steps(STEPS_PER_POINT.toInt()),
                AppLocalizations.of(context)!.rule_health_calories(
                  CALORIE_BONUS_POINTS.toInt(),
                  CALORIE_LIMIT.toInt(),
                ),
                AppLocalizations.of(context)!.rule_health_auto,
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              title: AppLocalizations.of(context)!.scoring_career,
              color: Colors.orange,
              rules: [
                AppLocalizations.of(
                  context,
                )!.rule_career_project(PROJECT_SCORE_INCREMENT.toInt()),
                AppLocalizations.of(
                  context,
                )!.rule_career_task(TASK_SCORE_INCREMENT.toInt()),
                AppLocalizations.of(context)!.rule_career_bonus_5(
                  ProjectPoint.projectManyTasksBonus.toInt(),
                ),
                AppLocalizations.of(context)!.rule_career_bonus_10(
                  ProjectPoint.projectLotsTasksBonus.toInt(),
                ),
                AppLocalizations.of(
                  context,
                )!.rule_career_bonus_doc(ProjectPoint.projectDocBonus.toInt()),
                AppLocalizations.of(context)!.rule_career_bonus_week(
                  ProjectPoint.projectWeekBonus.toInt(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              title: AppLocalizations.of(context)!.scoring_finance,
              color: Colors.blue,
              rules: [
                AppLocalizations.of(context)!.rule_finance_savings(
                  FINANCE_SAVINGS_POINTS.toInt(),
                  FINANCE_SAVINGS_MILESTONE.toInt(),
                ),
                AppLocalizations.of(context)!.rule_finance_investment(
                  FINANCE_INVESTMENT_POINTS.toInt(),
                  FINANCE_INVESTMENT_RETURN_THRESHOLD.toInt(),
                ),
                AppLocalizations.of(context)!.rule_finance_auto,
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              title: AppLocalizations.of(context)!.scoring_social,
              color: Colors.purple,
              rules: [
                AppLocalizations.of(
                  context,
                )!.rule_social_contact(CONTACT_POINTS.toInt()),
                AppLocalizations.of(context)!.rule_social_affection(
                  AFFECTION_POINTS.toInt(),
                  AFFECTION_PER_UNIT.toInt(),
                ),
                AppLocalizations.of(context)!.rule_social_maintain,
              ],
            ),
            const SizedBox(height: 40),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroduction(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.how_it_works,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.scoring_intro,
            style: TextStyle(height: 1.5, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required Color color,
    required List<String> rules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: rules.map((rule) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: color.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rule,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Text(
          AppLocalizations.of(context)!.scoring_footer,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
