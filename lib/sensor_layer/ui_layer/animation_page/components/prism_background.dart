import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SnowfallOverlay.dart';
import 'prism_painters.dart';
import 'tactical_grid.dart';

class PrismBackground extends StatelessWidget {
  final Animation<double> auroraController;
  final Animation<double> scanController;
  final Animation<double> assemblyController;
  final Animation<double> pulseController;
  final List<PrismShard> shards;
  final ValueNotifier<Offset> pointerOffset;

  const PrismBackground({
    super.key,
    required this.auroraController,
    required this.scanController,
    required this.assemblyController,
    required this.pulseController,
    required this.shards,
    required this.pointerOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder<Offset>(
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
        ),
        const Positioned.fill(
          child: SnowfallOverlay(snowCount: 60, opacity: 0.4),
        ),
        Positioned.fill(
          child: ValueListenableBuilder<Offset>(
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
        ),
      ],
    );
  }
}
