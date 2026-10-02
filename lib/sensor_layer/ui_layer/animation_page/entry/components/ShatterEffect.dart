import 'package:flutter/material.dart';
import 'PrismPainters.dart';

class ShatterEffect extends StatelessWidget {
  final AnimationController crackController;
  final AnimationController brokenGlassController;
  final List<GlassCrackData> cachedGlassCracks;
  final List<ScatteringParticleData> cachedParticles;
  final List<BrokenGlassPaneData> cachedPanes;
  final ValueNotifier<Offset> pointerOffset;

  const ShatterEffect({
    super.key,
    required this.crackController,
    required this.brokenGlassController,
    required this.cachedGlassCracks,
    required this.cachedParticles,
    required this.cachedPanes,
    required this.pointerOffset,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<Offset>(
        valueListenable: pointerOffset,
        builder: (context, pOffset, child) {
          return Stack(
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: crackController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: GlassCrackPainter(
                        progress: crackController.value,
                        cracks: cachedGlassCracks,
                        pointerOffset: pOffset,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: crackController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ShockwavePainter(
                        progress: crackController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: crackController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: IceFlashPainter(
                        progress: crackController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: crackController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: GlassShatterPainter(
                        progress: crackController.value,
                        particles: cachedParticles,
                        pointerOffset: pOffset,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
              // --- BROKEN GLASS PANES: elegant large-frag slide-out ---
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: brokenGlassController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: BrokenGlassPanePainter(
                        progress: brokenGlassController.value,
                        panes: cachedPanes,
                        pointerOffset: pOffset,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
