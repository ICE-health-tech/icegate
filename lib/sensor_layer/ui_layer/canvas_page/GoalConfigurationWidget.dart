import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/widgets/HealthGoalConfigurationPanel.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:go_router/go_router.dart';

class GoalConfigurationWidget extends StatelessWidget {
  const GoalConfigurationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: EntryColors.silverMetallicGradient,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        title: Text(
                          l10n.goal_mission,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                        sliver: const SliverToBoxAdapter(
                          child: HealthGoalConfigurationPanel(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TacticalGridPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  TacticalGridPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final markerPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (double i = spacing; i < size.width; i += spacing * 4) {
      for (double j = spacing; j < size.height; j += spacing * 4) {
        canvas.drawLine(Offset(i - 4, j), Offset(i + 4, j), markerPaint);
        canvas.drawLine(Offset(i, j - 4), Offset(i, j + 4), markerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
