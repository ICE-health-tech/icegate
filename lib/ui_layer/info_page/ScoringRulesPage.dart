import 'package:flutter/material.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/Const.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/ProjectPoint.dart';

class ScoringRulesPage extends StatelessWidget {
  const ScoringRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Scoring Rules'),
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
              title: '🏃 Health',
              color: Colors.green,
              rules: [
                '1 Point per $STEPS_PER_POINT steps walked',
                '$CALORIE_BONUS_POINTS Points for staying under $CALORIE_LIMIT kcal/day',
                'Points automatically update when health metrics are recorded',
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              title: '💼 Career (Projects)',
              color: Colors.orange,
              rules: [
                '$PROJECT_SCORE_INCREMENT Base Points for completing a project',
                '$TASK_SCORE_INCREMENT Points for each task completed',
                '${ProjectPoint.projectManyTasksBonus} Bonus Points for projects with 5+ tasks',
                '${ProjectPoint.projectLotsTasksBonus} Bonus Points for projects with 10+ tasks',
                '${ProjectPoint.projectDocBonus} Bonus Points for having 3+ research notes',
                '${ProjectPoint.projectWeekBonus} Bonus Points for projects active for 7+ days',
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              title: '💰 Finance',
              color: Colors.blue,
              rules: [
                '$FINANCE_SAVINGS_POINTS Points for every \$$FINANCE_SAVINGS_MILESTONE saved (Net Worth)',
                '$FINANCE_INVESTMENT_POINTS Points for every $FINANCE_INVESTMENT_RETURN_THRESHOLD% investment return',
                'Points update as account balances and asset values change',
              ],
            ),
            const SizedBox(height: 24),
            _buildCategorySection(
              context,
              title: '❤️ Social',
              color: Colors.purple,
              rules: [
                '$CONTACT_POINTS Points for each unique contact added',
                '$AFFECTION_POINTS Points for every $AFFECTION_PER_UNIT affection points earned',
                'Maintain relationships to keep your social score high',
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
                'How it works',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The Ice Gate scoring system measures your growth across four key life elements. Your Global Level is calculated from the sum of these scores. Maintain a high score to unlock legendary status.',
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
          'Balance your physical, social, financial, and workspace growth to become a Legend.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
