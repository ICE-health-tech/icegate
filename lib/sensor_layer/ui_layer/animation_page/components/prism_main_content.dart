import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'prism_background.dart';
import 'premium_logo.dart';
import 'entry_geometry.dart';

class PrismMainContent extends StatelessWidget {
  final Animation<double> crackAnimation;
  final Animation<double> auroraAnimation;
  final Animation<double> scanAnimation;
  final Animation<double> assemblyAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> chargeAnimation;
  final Animation<double> spinAnimation;
  final EntryGeometry geometry;
  final ValueNotifier<Offset> pointerOffset;
  final VoidCallback onTap;

  const PrismMainContent({
    super.key,
    required this.crackAnimation,
    required this.auroraAnimation,
    required this.scanAnimation,
    required this.assemblyAnimation,
    required this.pulseAnimation,
    required this.chargeAnimation,
    required this.spinAnimation,
    required this.geometry,
    required this.pointerOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: crackAnimation,
      builder: (context, child) {
        final double crackVal = crackAnimation.value;
        final double bgOpacity = (1.0 - (crackVal * 1.5)).clamp(0.0, 1.0);

        // SCREEN SETTLE: Gentle displacement for premium feel
        double shakeX = 0;
        double shakeY = 0;
        if (crackVal > 0 && crackVal < 0.15) {
          final double intensity = (1.0 - (crackVal / 0.15)) * 5;
          shakeX = (math.sin(crackVal * 80) * intensity);
          shakeY = (math.cos(crackVal * 90) * intensity);
        }

        return Opacity(
          opacity: bgOpacity,
          child: Transform.translate(
            offset: Offset(shakeX, shakeY),
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          PrismBackground(
            auroraController: auroraAnimation,
            scanController: scanAnimation,
            assemblyController: assemblyAnimation,
            pulseController: pulseAnimation,
            shards: geometry.shards,
            pointerOffset: pointerOffset,
          ),
          Center(
            child: PremiumLogo(
              pulseController: pulseAnimation,
              crackController: crackAnimation,
              chargeController: chargeAnimation,
              spinController: spinAnimation,
              auroraController: auroraAnimation,
              pointerOffset: pointerOffset,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}
