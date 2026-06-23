import 'dart:ui';
import 'package:flutter/material.dart';

import 'FlowchartCanvas.dart';

class DragCanvas extends StatelessWidget {
  static const double _headerClearance = 64;

  final Color baseColor;
  final bool isDark;

  const DragCanvas({super.key, required this.baseColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: _headerClearance),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: isDark ? 0.12 : 0.35),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(color: Colors.transparent),
                  ),
                  const FlowchartCanvas(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
