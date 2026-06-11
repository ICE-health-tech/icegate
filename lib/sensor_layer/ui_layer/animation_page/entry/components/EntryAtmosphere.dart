import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
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

    // L0 — glacial base (same family as Health / home shell).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment(0.35, 1.0),
          colors: [
            HealthMetricColors.iceBgMid,
            HealthMetricColors.iceBgDeep,
            Color(0xFF050910),
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    final focal = Offset(
      size.width * (0.5 + pointerOffset.dx * 0.04),
      size.height * (0.48 + pointerOffset.dy * 0.04),
    );

    // L1 — soft frost bloom (pale ice, not saturated HUD blue).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (focal.dx / size.width) * 2 - 1,
            (focal.dy / size.height) * 2 - 1,
          ),
          radius: 0.95,
          colors: [
            EntryColors.frostBloomMist.withValues(alpha: 0.14),
            EntryColors.primaryIceLight.withValues(alpha: 0.08),
            EntryColors.primaryIceBlue.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.22, 0.45, 1.0],
        ).createShader(rect),
    );

    // L2 — breathing center beacon behind logo.
    final breathe = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);
    final beaconR = short * (0.32 + 0.04 * breathe);
    canvas.drawCircle(
      focal,
      beaconR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            EntryColors.diamondWhite.withValues(alpha: 0.1 + 0.04 * breathe),
            EntryColors.primaryIceLight.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: focal, radius: beaconR))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );

    // L3 — slow drifting frost pools.
    for (int i = 0; i < 3; i++) {
      final angle = auroraProgress * math.pi * 2 + i * (math.pi * 2 / 3);
      final orbit = short * 0.18;
      final blob = Offset(
        focal.dx + math.cos(angle) * orbit + pointerOffset.dx * short * 0.08,
        focal.dy + math.sin(angle * 1.2) * orbit * 0.6 + pointerOffset.dy * short * 0.08,
      );
      final blobR = short * (0.32 + 0.05 * math.sin(angle * 2));
      canvas.drawCircle(
        blob,
        blobR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              EntryColors.frostBloomMist.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: blob, radius: blobR))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
      );
    }

    // L4 — edge depth (ice navy rim, not pure black vignette).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.08,
          colors: [
            Colors.transparent,
            HealthMetricColors.iceBgDeep.withValues(alpha: 0.35),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(EntryAtmospherePainter oldDelegate) =>
      oldDelegate.auroraProgress != auroraProgress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.pointerOffset != pointerOffset;
}
