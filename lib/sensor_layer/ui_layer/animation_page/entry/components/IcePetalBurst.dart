import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A lightweight “ice petal” burst used as an overlay when the logo scales up.
///
/// Drive [progress] with an existing 0..1 animation (e.g. chargeController.value).
class IcePetalBurst extends StatelessWidget {
  final double progress;
  final double size;

  const IcePetalBurst({
    super.key,
    required this.progress,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0.001) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _IcePetalBurstPainter(progress: p),
      ),
    );
  }
}

class _IcePetalBurstPainter extends CustomPainter {
  final double progress;

  _IcePetalBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final t = Curves.easeOutCubic.transform(progress);

    // Visual tuning
    final petalCount = 10;
    final baseRadius = size.shortestSide * 0.10;
    final travel = size.shortestSide * 0.22 * t;
    final petalLen = size.shortestSide * (0.16 - 0.07 * t);
    final petalWid = size.shortestSide * (0.06 - 0.03 * t);
    final blur = size.shortestSide * (0.06 * (1 - t));

    final glowPaint = Paint()
      ..color = const Color(0xFFBDEBFF).withValues(alpha: 0.32 * (1 - t))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    // A subtle center glow to sell the “ice” energy.
    canvas.drawCircle(center, baseRadius * (1.2 + 0.6 * t), glowPaint);

    for (var i = 0; i < petalCount; i++) {
      // Deterministic angle spread (no random state).
      final angle = (i / petalCount) * math.pi * 2 + (t * 0.65);
      final dir = Offset(math.cos(angle), math.sin(angle));
      final petalCenter = center + dir * (baseRadius + travel);

      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final fill = Paint()
        ..color = const Color(0xFFEAF9FF).withValues(alpha: 0.55 * opacity)
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = const Color(0xFF9FE3FF).withValues(alpha: 0.65 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.006;

      final path = Path();
      // A simple “petal” made from two quadratic curves.
      path.moveTo(0, -petalLen * 0.55);
      path.quadraticBezierTo(petalWid, -petalLen * 0.12, 0, petalLen * 0.55);
      path.quadraticBezierTo(-petalWid, -petalLen * 0.12, 0, -petalLen * 0.55);
      path.close();

      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _IcePetalBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

