import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class DomainAnalysisChart extends StatelessWidget {
  final List<AchievementData> achievements;

  const DomainAnalysisChart({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    // Group achievements by domain
    final Map<String, int> domainCounts = {
      'health': 0,
      'finance': 0,
      'good social impact': 0,
      'relationship': 0,
      'project': 0,
      'knowledge': 0,
    };

    num totalMeaningfulness = 0;
    num totalImpact = 0;

    for (var a in achievements) {
      final dom = a.domain.toLowerCase();
      if (domainCounts.containsKey(dom)) {
        domainCounts[dom] = domainCounts[dom]! + 1;
      }
      totalMeaningfulness += a.meaningScore ?? 0;
      totalImpact += a.impactScore;
    }

    final total = achievements.length;
    final maxCount = domainCounts.values.reduce((value, element) => value > element ? value : element);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Insights Dashboard", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(
            "Monthly Reflection: $total Total Feats recorded. Average Meaningfulness: ${(totalMeaningfulness / total).toStringAsFixed(1)}, Average Impact: ${(totalImpact / total).toStringAsFixed(1)}",
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          ...domainCounts.entries.map((entry) {
            final percentage = maxCount > 0 ? entry.value / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text("${entry.value}", textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
