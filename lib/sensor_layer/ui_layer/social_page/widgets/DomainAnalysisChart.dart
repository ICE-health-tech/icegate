import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

/// Domain keys stored on [AchievementData.domain].
const kAchievementDomains = <String>[
  'health',
  'finance',
  'good social impact',
  'relationship',
  'project',
  'knowledge',
];

const kAchievementDomainLabels = <String, String>{
  'health': 'HEALTH',
  'finance': 'FINANCE',
  'good social impact': 'GOOD SOCIAL IMPACT',
  'relationship': 'RELATIONSHIP',
  'project': 'PROJECT',
  'knowledge': 'KNOWLEDGE',
};

Map<String, int> countAchievementsByDomain(
  List<AchievementData> achievements, {
  DateTime? since,
}) {
  final counts = {for (final d in kAchievementDomains) d: 0};
  for (final a in achievements) {
    if (since != null && a.createdAt.isBefore(since)) continue;
    final dom = a.domain.toLowerCase().trim();
    if (counts.containsKey(dom)) {
      counts[dom] = counts[dom]! + 1;
    }
  }
  return counts;
}

int countSkillSessionsInRange(List<MindLogData> logs) {
  var sessions = 0;
  for (final log in logs) {
    try {
      final acts = jsonDecode(log.activities) as List<dynamic>;
      final hasSkill = acts.any(
        (a) => a is String && a.startsWith('skill:'),
      );
      if (hasSkill) sessions++;
    } catch (_) {}
  }
  return sessions;
}

class DomainAnalysisChart extends StatelessWidget {
  final List<AchievementData> achievements;

  const DomainAnalysisChart({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final domainCounts = countAchievementsByDomain(achievements);

    num totalMeaningfulness = 0;
    num totalImpact = 0;

    for (var a in achievements) {
      totalMeaningfulness += a.meaningScore ?? 0;
      totalImpact += a.impactScore;
    }

    final total = achievements.length;
    final maxCount = domainCounts.values.fold<int>(
      0,
      (prev, v) => v > prev ? v : prev,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      margin: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.achievement_insights_title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.achievement_insights_summary(
              total,
              (totalMeaningfulness / total).toStringAsFixed(1),
              (totalImpact / total).toStringAsFixed(1),
            ),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...domainCounts.entries.map((entry) {
            final percentage = maxCount > 0 ? entry.value / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(
                      (kAchievementDomainLabels[entry.key] ?? entry.key)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
