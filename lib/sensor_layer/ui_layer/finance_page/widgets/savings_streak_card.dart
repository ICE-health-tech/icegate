import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/utils/savings_streak.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SavingsStreakCard extends StatelessWidget {
  final FinanceBlock financeBlock;

  const SavingsStreakCard({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final streak = computeSavingsStreak(financeBlock.transactions.value);
      String motivator;
      if (streak.current == 0) {
        motivator = l10n.finance_streak_day_one;
      } else if (streak.current < 3) {
        motivator = l10n.finance_streak_keep;
      } else {
        motivator = l10n.finance_streak_strong;
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.finance_streak_label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  l10n.finance_streak_best(streak.longest),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              streak.current > 0
                  ? l10n.finance_streak_days(streak.current)
                  : l10n.finance_streak_day_one,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              motivator,
              style: TextStyle(
                color: Colors.orangeAccent.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final on = i < streak.last7.length && streak.last7[i];
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on
                        ? EntryColors.financeYellow
                        : Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: on
                          ? EntryColors.financeYellow
                          : Colors.white12,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

/// Small chip for Finance overview: tap switches to Savings tab.
class FinanceOverviewStreakChip extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceOverviewStreakChip({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final streak = computeSavingsStreak(financeBlock.transactions.value);
      return Semantics(
        label: l10n.finance_overview_streak_accessibility,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              financeBlock.activeTab.value = 3;
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: Colors.orangeAccent.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    streak.current > 0
                        ? '${streak.current}'
                        : '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.finance_streak_label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
