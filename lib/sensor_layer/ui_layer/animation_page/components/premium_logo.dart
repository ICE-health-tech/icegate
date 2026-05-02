import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'entry_constants.dart';

class PremiumLogo extends StatelessWidget {
  final Animation<double> pulseController;
  final Animation<double> crackController;
  final Animation<double> chargeController;
  final Animation<double> spinController;
  final Animation<double> auroraController;
  final ValueNotifier<Offset> pointerOffset;
  final VoidCallback onTap;

  const PremiumLogo({
    super.key,
    required this.pulseController,
    required this.crackController,
    required this.chargeController,
    required this.spinController,
    required this.auroraController,
    required this.pointerOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        pulseController,
        crackController,
        chargeController,
        spinController,
        auroraController,
        pointerOffset,
      ]),
      builder: (context, child) {
        final double crackVal = crackController.value;
        final double chargeVal = chargeController.value;
        final Offset pOffset = pointerOffset.value;

        final double snapScale = (crackVal > 0 && crackVal < 0.2)
            ? (1.0 - math.sin(crackVal * math.pi * 5) * 0.1)
            : 1.0;

        final double scale =
            (1.0 + math.sin(pulseController.value * math.pi) * 0.1) *
            (1.0 + chargeVal * 0.2) *
            (1.0 - crackVal * 0.15) *
            snapScale;

        final double shake = chargeVal > 0 && crackVal < 0.1
            ? (math.sin(chargeVal * 50) * 5 * chargeVal)
            : 0;

        final double opacity = (1.0 - (crackVal * 2.8)).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(shake + pOffset.dx * 20, pOffset.dy * 20),
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: (spinController.value * 2 * math.pi) +
                          (auroraController.value * 0.5 * math.pi) +
                          (chargeVal * 2 * math.pi) +
                          (crackVal * math.pi),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Glow
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: EntryColors.arcticSilver.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/images/iceflowerlogo.png',
                            width: 200,
                            height: 200,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
