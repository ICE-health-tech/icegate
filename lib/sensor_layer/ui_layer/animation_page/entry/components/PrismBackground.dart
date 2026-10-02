import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SnowfallOverlay.dart';
import 'EntryAtmosphere.dart';
import 'PrismPainters.dart';
import 'TacticalGrid.dart';

class PrismBackground extends StatelessWidget {
  final Animation<double> auroraController;
  final Animation<double> scanController;
  final Animation<double> assemblyController;
  final Animation<double> pulseController;
  final List<PrismShard> shards;
  final ValueNotifier<Offset> pointerOffset;

  /// Foreground snow; lower = more contrast on the crystal.
  final double snowOpacity;

  const PrismBackground({
    super.key,
    required this.auroraController,
    required this.scanController,
    required this.assemblyController,
    required this.pulseController,
    required this.shards,
    required this.pointerOffset,
    this.snowOpacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        EntryAtmosphere(
          auroraProgress: auroraController,
          pulseProgress: pulseController,
          pointerOffset: pointerOffset,
        ),
        ValueListenableBuilder<Offset>(
          valueListenable: pointerOffset,
          builder: (context, pOffset, child) {
            return AnimatedBuilder(
              animation: Listenable.merge([
                auroraController,
                scanController,
              ]),
              builder: (context, child) {
                return TacticalGrid(
                  scanProgress: scanController.value,
                  auroraProgress: auroraController.value,
                  pointerOffset: pOffset,
                );
              },
            );
          },
        ),
        SnowfallOverlay(snowCount: 48, opacity: snowOpacity),
        ValueListenableBuilder<Offset>(
          valueListenable: pointerOffset,
          builder: (context, pOffset, child) {
            return RepaintBoundary(
              child: AnimatedBuilder(
                animation: assemblyController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: PrismPainter(
                      shards: shards,
                      progress: assemblyController.value,
                      pulse: pulseController.value,
                      pointerOffset: pOffset,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
