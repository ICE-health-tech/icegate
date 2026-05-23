import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'EntryConstants.dart';

/// Deep animated backdrop for [PrismEntryPage] — gradients, aurora, center beacon.
class EntryAtmosphere extends StatelessWidget {
  const EntryAtmosphere({
    super.key,
    required this.auroraProgress,
    required this.pulseProgress,
    required this.pointerOffset,
  });

  final Animation<double> auroraProgress;
  final Animation<double> pulseProgress;
  final ValueNotifier<Offset> pointerOffset;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: pointerOffset,
      builder: (context, pOffset, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([auroraProgress, pulseProgress]),
          builder: (context, _) {
            return CustomPaint(
              painter: EntryAtmospherePainter(
                auroraProgress: auroraProgress.value,
                pulse: pulseProgress.value,
                pointerOffset: pOffset,
              ),
              size: Size.infinite,
            );
          },
        );
      },
    );
  }
}

class EntryAtmospherePainter extends CustomPainter {
  EntryAtmospherePainter({
    required this.auroraProgress,
    required this.pulse,
    required this.pointerOffset,
  });

  final double auroraProgress;
  final double pulse;
  final Offset pointerOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final short = size.shortestSide;

    // Base vertical depth (cold sky → abyss).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1A2A),
            Color(0xFF061018),
            Color(0xFF02060C),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    final focal = Offset(
      size.width * (0.5 + pointerOffset.dx * 0.06),
      size.height * (0.46 + pointerOffset.dy * 0.05),
    );

    // Moonlit radial field (parallax center).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (focal.dx / size.width) * 2 - 1,
            (focal.dy / size.height) * 2 - 1,
          ),
          radius: 1.15,
          colors: [
            EntryColors.winterMoonCore.withValues(alpha: 0.38),
            const Color(0xFF3D6F94).withValues(alpha: 0.55),
            EntryColors.winterSkyBand.withValues(alpha: 0.72),
            EntryColors.winterDeepHorizon.withValues(alpha: 0.92),
            EntryColors.winterEdge,
          ],
          stops: const [0.0, 0.18, 0.42, 0.72, 1.0],
        ).createShader(rect),
    );

    // Breathing center beacon behind the logo.
    final breathe = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);
    final beaconR = short * (0.36 + 0.05 * breathe);
    canvas.drawCircle(
      focal,
      beaconR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            EntryColors.iceCyan.withValues(alpha: 0.2 + 0.06 * breathe),
            EntryColors.primaryIceBlue.withValues(alpha: 0.14 + 0.04 * breathe),
            EntryColors.primaryIceLight.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.22, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: focal, radius: beaconR))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Slow drifting aurora pools.
    for (int i = 0; i < 4; i++) {
      final angle = auroraProgress * math.pi * 2 + i * (math.pi / 2);
      final orbit = short * 0.22;
      final blob = Offset(
        focal.dx + math.cos(angle) * orbit + pointerOffset.dx * short * 0.12,
        focal.dy + math.sin(angle * 1.35) * orbit * 0.65 + pointerOffset.dy * short * 0.1,
      );
      final blobR = short * (0.38 + 0.06 * math.sin(angle * 2));
      canvas.drawCircle(
        blob,
        blobR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (i.isEven ? EntryColors.iceCyan : EntryColors.primaryIceLight)
                  .withValues(alpha: 0.11),
              EntryColors.winterSkyBand.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: blob, radius: blobR))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42),
      );
    }

    // Soft horizon band (ground mist).
    final horizonTop = size.height * 0.62;
    canvas.drawRect(
      Rect.fromLTWH(0, horizonTop, size.width, size.height - horizonTop),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            EntryColors.winterDeepHorizon.withValues(alpha: 0.35),
            EntryColors.winterEdge.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromLTWH(0, horizonTop, size.width, size.height - horizonTop)),
    );

    // Corner cool tint (subtle framing).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.05,
          colors: [
            Colors.transparent,
            EntryColors.winterEdge.withValues(alpha: 0.55),
          ],
          stops: const [0.58, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(EntryAtmospherePainter oldDelegate) =>
      oldDelegate.auroraProgress != auroraProgress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.pointerOffset != pointerOffset;
}
