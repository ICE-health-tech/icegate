import 'package:flutter/material.dart';
import 'PrismPainters.dart';

class TacticalGrid extends StatelessWidget {
  final double scanProgress;
  final double auroraProgress;
  final Offset pointerOffset;

  const TacticalGrid({
    super.key,
    required this.scanProgress,
    required this.auroraProgress,
    required this.pointerOffset,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: TacticalGridPainter(
          scanProgress: scanProgress,
          auroraProgress: auroraProgress,
          pointerOffset: pointerOffset,
        ),
      ),
    );
  }
}
