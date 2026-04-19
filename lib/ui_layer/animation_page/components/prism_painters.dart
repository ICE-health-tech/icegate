import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'entry_constants.dart';

// --- Models ---

class PrismShard {
  final Offset startOffset;
  final Offset targetOffset;
  final double size;
  final Color color;
  final double rotation;
  final double delay;
  final double speed;

  PrismShard({
    required this.startOffset,
    required this.targetOffset,
    required this.size,
    required this.color,
    required this.rotation,
    required this.delay,
    required this.speed,
  });
}

class FlowerPetalData {
  final int flowerIndex;
  final Offset centerOffset;
  final double angle;
  final double size;
  final double opacity;
  final Color color;
  final double rotationOffset;
  FlowerPetalData({
    required this.flowerIndex,
    required this.centerOffset,
    required this.angle,
    required this.size,
    required this.opacity,
    required this.color,
    required this.rotationOffset,
  });
}

class GlassCrackData {
  final List<Offset> points;
  GlassCrackData({required this.points});
}

enum ParticleTier { large, dust }

class ScatteringParticleData {
  final double angle;
  final double velocity;
  final List<Offset> points;
  final double rotationSpeed;
  final Color color;
  final double delay;
  final double initialDistance;
  final ParticleTier tier;

  ScatteringParticleData({
    required this.angle,
    required this.velocity,
    required this.points,
    required this.rotationSpeed,
    required this.color,
    required this.delay,
    this.initialDistance = 0.0,
    this.tier = ParticleTier.large,
  });
}

// --- Painters ---

class SymmetricPetalPainter extends CustomPainter {
  final Color color;
  final double pulse;
  final double transformProgress;

  SymmetricPetalPainter({
    required this.color,
    required this.pulse,
    this.transformProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // SCALE DOWN to 45% to ensure the logo is compact and premium
    const double viewScale = 0.45;
    
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width / 2) * viewScale;

    // 1. DRAW GLOWING AMBIENT HALO (Misty/Sparkling circle from image)
    final haloPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        r * 1.6,
        [
          color.withValues(alpha: 0.18 + (pulse * 0.04)),
          color.withValues(alpha: 0.05 + (pulse * 0.02)),
          color.withValues(alpha: 0.0),
        ],
        [0.0, 0.7, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(center, r * 1.4, haloPaint);

    // Subtle Particle Aura Ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1 + (pulse * 0.05))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, r * 1.05, ringPaint);

    // 2. DRAW 4-SHARD CRYSTALLINE STRUCTURE
    const int shardCount = 4;
    for (int i = 0; i < shardCount; i++) {
      final double angle = (i * 90) * math.pi / 180;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      _drawCrystallineShard(canvas, r, pulse);

      canvas.restore();
    }

    // 3. DRAW RADIANT CORE (Soft white glow from image)
    _drawPremiumCore(canvas, center, r * 0.2, pulse);
  }

  void _drawCrystallineShard(Canvas canvas, double r, double pulse) {
    // Dynamic geometry based on pulse
    final double shardWidth = r * (0.35 + (pulse * 0.05));
    final double shoulderY = -r * 0.4;
    final double tipY = -r * (1.15 + (pulse * 0.08) + (transformProgress * 0.25));
    final double innerNotchY = -r * 0.12;
    final double baseWidth = shardWidth * 0.25;

    // LEFT FACET PATH
    final leftFacetPath = Path()
      ..moveTo(0, innerNotchY)
      ..lineTo(-baseWidth, 0)
      ..lineTo(-shardWidth * 0.5, shoulderY)
      ..lineTo(0, tipY)
      ..close();

    // RIGHT FACET PATH
    final rightFacetPath = Path()
      ..moveTo(0, innerNotchY)
      ..lineTo(baseWidth, 0)
      ..lineTo(shardWidth * 0.5, shoulderY)
      ..lineTo(0, tipY)
      ..close();

    // LEFT SHADING (Lighter, catching "light")
    final leftPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-shardWidth * 0.5, shoulderY),
        Offset(0, tipY),
        [
          Colors.white.withValues(alpha: 0.95),
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.2),
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;

    // RIGHT SHADING (Deeper blue, depth)
    final rightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(shardWidth * 0.5, shoulderY),
        Offset(0, tipY),
        [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0.1),
        ],
        [0.0, 0.6, 1.0],
      )
      ..style = PaintingStyle.fill;

    // RIDGE & EDGE HIGHLIGHTS
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 + (pulse * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeJoin = StrokeJoin.round;

    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 + (pulse * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    // DRAW FACETS
    canvas.drawPath(leftFacetPath, leftPaint);
    canvas.drawPath(rightFacetPath, rightPaint);

    // DRAW OUTLINES
    canvas.drawPath(leftFacetPath, strokePaint);
    canvas.drawPath(rightFacetPath, strokePaint);

    // DRAW CENTRAL RIDGE
    canvas.drawLine(Offset(0, innerNotchY), Offset(0, tipY), ridgePaint);

    // INNER GLINT (Sparkle effect)
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 + (pulse * 0.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(0, shoulderY), shardWidth * 0.2, glintPaint);
  }

  void _drawPremiumCore(Canvas canvas, Offset center, double size, double pulse) {
    // Radiant Soft Core Glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size * 2.5,
        [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, size * 2.0, glowPaint);

    // Sharp Core Star
    final starPath = Path();
    const int points = 4; // 4-pointed star to match shards
    for (int i = 0; i < points * 2; i++) {
      final double angle = (i * math.pi) / points - (math.pi / 2);
      final double radius = i.isEven ? size : size * 0.25;
      final px = center.dx + math.cos(angle) * radius;
      final py = center.dy + math.sin(angle) * radius;
      if (i == 0) starPath.moveTo(px, py);
      else starPath.lineTo(px, py);
    }
    starPath.close();

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is! SymmetricPetalPainter) return true;
    return oldDelegate.pulse != pulse ||
        oldDelegate.color != color ||
        oldDelegate.transformProgress != transformProgress;
  }
}

class TacticalGridPainter extends CustomPainter {
  final double scanProgress;
  final double auroraProgress;
  final Offset pointerOffset;
  TacticalGridPainter({
    required this.scanProgress,
    required this.auroraProgress,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final auroraPaint = Paint();
    final center = Offset(
      size.width / 2 + pointerOffset.dx * 30,
      size.height / 2 + pointerOffset.dy * 30,
    );

    for (int i = 0; i < 3; i++) {
      final double angle = (auroraProgress * 2 * math.pi) + (i * math.pi * 0.6);
      final double x =
          center.dx + math.cos(angle) * 120 + pointerOffset.dx * 100;
      final double y =
          center.dy + math.sin(angle * 1.5) * 60 + pointerOffset.dy * 100;

      final gradient = RadialGradient(
        colors: [
          EntryColors.arcticSilver.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 300));

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        auroraPaint..shader = gradient,
      );
    }

    final paint = Paint()
      ..color = EntryColors.midSilver.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const double step = 60.0;
    for (double i = -100; i < size.width + 100; i += step) {
      final double x = i + pointerOffset.dx * 40;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double i = -100; i < size.height + 100; i += step) {
      final double y = i + pointerOffset.dy * 40;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final scanlineY = size.height * scanProgress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          EntryColors.arcticSilver.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, scanlineY - 40, size.width, 80));

    canvas.drawRect(
      Rect.fromLTWH(0, scanlineY - 40, size.width, 80),
      scanPaint,
    );

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00050A).withValues(alpha: 0.95),
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant TacticalGridPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.auroraProgress != auroraProgress;
}

class FlowerPainter extends CustomPainter {
  final double progress;
  final List<FlowerPetalData> petals;
  final Offset pointerOffset;

  FlowerPainter({
    required this.progress,
    required this.petals,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress > 0.85) return;

    final center = Offset(
      size.width / 2 + pointerOffset.dx * 15,
      size.height / 2 + pointerOffset.dy * 15,
    );

    for (var petal in petals) {
      final double startT = petal.flowerIndex * 0.2;
      final double bloomT = ((progress - startT) / 0.25).clamp(0.0, 1.0);
      if (bloomT <= 0) continue;

      final double easeBloom = Curves.easeOutBack.transform(bloomT);
      final double shatterFade = ((progress - 0.7) / 0.15).clamp(0.0, 1.0);
      final double opacity = (1.0 - shatterFade).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = petal.color.withValues(alpha: petal.opacity * opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        center.dx + petal.centerOffset.dx,
        center.dy + petal.centerOffset.dy,
      );
      canvas.rotate(petal.angle + (bloomT * 0.1) + petal.rotationOffset);
      canvas.scale(easeBloom);

      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          -petal.size * 0.6,
          -petal.size * 0.4,
          -petal.size * 0.5,
          -petal.size * 0.7,
        )
        ..quadraticBezierTo(
          -petal.size * 0.3,
          -petal.size * 1.2,
          0,
          -petal.size * 1.5,
        )
        ..quadraticBezierTo(
          petal.size * 0.3,
          -petal.size * 1.2,
          petal.size * 0.5,
          -petal.size * 0.7,
        )
        ..quadraticBezierTo(petal.size * 0.6, -petal.size * 0.4, 0, 0)
        ..close();

      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..color = petal.color.withValues(alpha: petal.opacity * 0.3 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(path, glowPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FlowerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class GlassCrackPainter extends CustomPainter {
  final double progress;
  final List<GlassCrackData> cracks;
  final Offset pointerOffset;

  GlassCrackPainter({
    required this.progress,
    required this.cracks,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.3 || progress > 0.85) return;

    final center = Offset(
      size.width / 2 + pointerOffset.dx * 15,
      size.height / 2 + pointerOffset.dy * 15,
    );

    final double crackOpacity =
        ((progress - 0.3) / 0.15).clamp(0.0, 1.0) *
        (1.0 - ((progress - 0.78) / 0.07).clamp(0.0, 1.0));

    for (var crack in cracks) {
      final path = Path();
      bool first = true;

      for (int i = 0; i < crack.points.length; i++) {
        final p = crack.points[i];
        final pos =
            center + Offset(p.dx * size.width * 0.5, p.dy * size.height * 0.5);

        if (first) {
          path.moveTo(pos.dx, pos.dy);
          first = false;
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }

      // Pass 0: Depth Shadow (Subtle dark silver offset for 3D effect)
      canvas.save();
      canvas.translate(1.0, 1.5);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: crackOpacity * 0.3)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.restore();

      // Pass 1: Frost & Stress Fracture (Core glow)
      canvas.drawPath(
        path,
        Paint()
          ..color = EntryColors.frostedWhite.withValues(
            alpha: crackOpacity * 0.25,
          )
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Pass 2: Sharp Specular Core
      canvas.drawPath(
        path,
        Paint()
          ..color = EntryColors.arcticSilver.withValues(
            alpha: crackOpacity * 0.8,
          )
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Pass 3: Neon Highlight (Center of the crack)
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: crackOpacity)
          ..strokeWidth = 0.4
          ..style = PaintingStyle.stroke,
      );

      // Pass 4: Jagged Origin Glints
      if (math.Random().nextDouble() > 0.4) {
        final p = crack.points[0];
        final pos =
            center + Offset(p.dx * size.width * 0.5, p.dy * size.height * 0.5);
        canvas.drawCircle(
          pos,
          1.2,
          Paint()..color = Colors.white.withValues(alpha: crackOpacity),
        );
      }
    }

    // PASS 7: Destructive Aura (Shockwave Bloom)
    if (crackOpacity > 0.3) {
      final double auraPulse = (math.sin(progress * 30) * 0.1) + 1.0;
      final double auraSize = (40 + (progress * 60)) * auraPulse;

      final auraPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            EntryColors.arcticSilver.withValues(alpha: crackOpacity * 0.5),
            EntryColors.midSilver.withValues(alpha: crackOpacity * 0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: auraSize))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 + (progress * 10));

      // Draw the expanding shockwave aura
      canvas.drawCircle(center, auraSize, auraPaint);

      // Delicate energy rings
      final ringPaint = Paint()
        ..color = EntryColors.arcticSilver.withValues(alpha: crackOpacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawCircle(center, auraSize * 0.8, ringPaint);
    }
  }

  @override
  bool shouldRepaint(GlassCrackPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class GlassShatterPainter extends CustomPainter {
  final double progress;
  final List<ScatteringParticleData> particles;
  final Offset pointerOffset;

  GlassShatterPainter({
    required this.progress,
    required this.particles,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.7) return;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final center = Offset(
        size.width / 2 + pointerOffset.dx * 20,
        size.height / 2 + pointerOffset.dy * 20,
      );

      final double t = ((progress - particle.delay - 0.7) / 0.3).clamp(
        0.0,
        1.0,
      );
      if (t <= 0) continue;

      final double ease = Curves.easeOutQuart.transform(t);

      // PERSPECTIVE DEPTH: Shards move outward and "backwards" by dividing by zDepth
      final double zDepth = 1.0 + (ease * 3.0);
      final double distance =
          (particle.initialDistance + particle.velocity * ease) / zDepth;

      final double shatterProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      final double opacity = (1.0 - (shatterProgress * 1.1)).clamp(0.0, 1.0);

      // Premium Silver Glitch Effect (Replacing chromatic aberration for unified silver brand)
      final double glitchOffset = (1.0 - ease) * 35.0;
      final abPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = EntryColors.darkSilver.withValues(alpha: opacity * 0.5);

      final silverHighlightPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = EntryColors.arcticSilver.withValues(alpha: opacity * 0.6);

      canvas.save();
      final particleCenter = Offset(
        center.dx + math.cos(particle.angle) * distance,
        center.dy + math.sin(particle.angle) * distance,
      );

      canvas.translate(particleCenter.dx, particleCenter.dy);

      // Intense 3D tumbling rotation
      final double currentRot =
          (particle.rotationSpeed * ease * 10) + (particle.rotationSpeed * 0.2);
      canvas.rotate(currentRot);

      // Perspective Scale: Shrink as they retreat. Larger shards last longer.
      final double baseScale = (particle.tier == ParticleTier.dust
          ? 0.4 + ease
          : 1.0 - ease * 0.9);
      final double flipY = math.cos(currentRot * 1.8).abs().clamp(0.1, 1.0);

      canvas.scale(baseScale.clamp(0.05, 1.5), baseScale * flipY);

      final path = Path();
      bool first = true;
      for (var p in particle.points) {
        if (first) {
          path.moveTo(p.dx, p.dy);
          first = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();

      // Glitch trail behind the fastest particles (Unified Silver Identity)
      if (t < 0.4 && particle.tier == ParticleTier.large) {
        canvas.save();
        canvas.translate(glitchOffset * 2, 0);
        canvas.drawPath(path, abPaint);
        canvas.translate(-glitchOffset * 4, 0);
        canvas.drawPath(path, silverHighlightPaint);
        canvas.restore();
      }

      // Base glass body (Premium Frosted Silver)
      final bodyPaint = Paint()
        ..color = EntryColors.frostedWhite.withValues(
          alpha: opacity * (particle.tier == ParticleTier.dust ? 0.4 : 0.6),
        )
        ..style = PaintingStyle.fill;

      if (particle.tier == ParticleTier.dust) {
        bodyPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      } else {
        // Add a subtle gradient across large shards to simulate light refraction
        bodyPaint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: opacity * 0.8),
            const Color(0xFFAAAABB).withValues(alpha: opacity * 0.3),
          ],
        ).createShader(path.getBounds());
      }

      canvas.drawPath(path, bodyPaint);

      // High-fidelity Specular Highlights and Edge Glints for Large Shards
      if (particle.tier == ParticleTier.large) {
        // Bright inner bevel / edge reflection
        final edgePaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.miter;
        canvas.drawPath(path, edgePaint);

        // Soft outer glow to simulate light scattering off the edge
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);

        // Directional 'glint' (a bright streak across the shard)
        if (i % 2 == 0) {
          // More frequent glints for that anime sparkle
          final bounds = path.getBounds();
          final glintPath = Path()
            ..moveTo(
              bounds.left - bounds.width,
              bounds.top + bounds.height * 0.5,
            )
            ..lineTo(
              bounds.right + bounds.width,
              bounds.bottom - bounds.height * 0.5,
            );

          final glintStroke = Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

          canvas.save();
          canvas.clipPath(path);
          canvas.drawPath(glintPath, glintStroke);
          canvas.restore();
        }

        // SPEED LINES (Anime trail effect)
        if (t < 0.3) {
          final trailPaint = Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.3)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke;

          final Offset trailEnd = Offset(
            -math.cos(particle.angle) * 120 * t,
            -math.sin(particle.angle) * 120 * t,
          );
          canvas.drawLine(Offset.zero, trailEnd, trailPaint);

          // Second brighter core trail
          final coreTrailPaint = Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.5)
            ..strokeWidth = 1.0;
          canvas.drawLine(Offset.zero, trailEnd * 0.7, coreTrailPaint);
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(GlassShatterPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ShockwavePainter extends CustomPainter {
  final double progress;
  ShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.7 || progress > 0.95) return;

    final double t = (progress - 0.7) / 0.25;
    final double radius = t * size.shortestSide * 0.8;
    final double opacity = (1.0 - t).clamp(0.0, 1.0);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 + (1.0 - t) * 45
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity * 0.5),
              const Color(0xFFC7C7CC).withValues(alpha: 0.0),
            ],
            stops: const [0.9, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: radius + 10,
            ),
          );

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);

    final bloomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = t * 40
      ..color = Colors.white.withValues(alpha: opacity * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius * 1.1,
      bloomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class PrismPainter extends CustomPainter {
  final List<PrismShard> shards;
  final double progress;
  final Offset pointerOffset;

  PrismPainter({
    required this.shards,
    required this.progress,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2 + pointerOffset.dx * 20,
      size.height / 2 + pointerOffset.dy * 20,
    );

    for (var shard in shards) {
      final double adjustedT = ((progress - shard.delay) / shard.speed).clamp(
        0.0,
        1.0,
      );
      if (adjustedT <= 0) continue;

      final double ease = Curves.easeInQuint.transform(adjustedT);
      final currentPos =
          center + Offset.lerp(shard.startOffset, shard.targetOffset, ease)!;
      final currentOpacity = (1.0 - ease).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = shard.color.withValues(alpha: currentOpacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(shard.rotation * (1.0 - ease) * 5);

      final path = Path();
      path.moveTo(0, -shard.size);
      path.lineTo(shard.size, shard.size / 2);
      path.lineTo(-shard.size, shard.size / 2);
      path.close();

      canvas.drawPath(path, paint);

      if (adjustedT > 0.8) {
        final glowPaint = Paint()
          ..color = shard.color.withValues(alpha: currentOpacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawPath(path, glowPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PrismPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pointerOffset != pointerOffset;
}

class IceFlashPainter extends CustomPainter {
  final double progress;
  final Color flashColor;

  IceFlashPainter({required this.progress, this.flashColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = size.center(Offset.zero);

    // 1. Central Radial Flash
    final flashOpacity = (1.0 - progress).clamp(0.0, 1.0);
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          flashColor.withValues(alpha: flashOpacity * 0.8),
          flashColor.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, size.width * 1.5 * progress, radialPaint);

    // 2. Shockwave Ring
    final ringOpacity = (1.0 - math.pow(progress, 0.5))
        .clamp(0.0, 0.6)
        .toDouble();
    final ringPaint = Paint()
      ..color = flashColor.withValues(alpha: ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40 * (1 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(center, size.width * 2 * progress, ringPaint);
  }

  @override
  bool shouldRepaint(IceFlashPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
