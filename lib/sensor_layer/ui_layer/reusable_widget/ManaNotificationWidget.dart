import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:provider/provider.dart';

class ManaNotificationWidget extends StatelessWidget {
  const ManaNotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreBlock = context.watch<ScoreBlock>();

    return Watch((context) {
      // We'll use the total XP as "Mana" for now
      final manaPoints = scoreBlock.totalXP.value.toInt();
      final progress = scoreBlock.levelProgress.value;

      return Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.blueAccent, size: 16),
            const SizedBox(width: 6),
            Text(
              "$manaPoints MP",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            // Mini progress bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
