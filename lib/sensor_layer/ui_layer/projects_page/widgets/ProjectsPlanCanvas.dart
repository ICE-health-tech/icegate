import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/FlowchartCanvas.dart';

/// Schedule planner canvas on the dedicated plan page.
class ProjectsPlanCanvas extends StatelessWidget {
  const ProjectsPlanCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = cs.surface.withValues(alpha: isDark ? 0.35 : 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.transparent),
            ),
            const FlowchartCanvas(),
          ],
        ),
      ),
    );
  }
}
