import 'dart:math' as math;
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
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Transition color from Dark Silver to Bright Silver
    final Color petalColor = Color.lerp(
      EntryColors.darkSilver,
      EntryColors.arcticSilver,
      transformProgress,
    )!;

    final paint = Paint()
      ..color = petalColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final double angle = (i * 90) * math.pi / 180;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path();
      path.moveTo(0, 0);

      // Transform from soft curves to sharp icy points
      final double curveFactor = 0.6 * (1.0 - transformProgress);
      final double pointFactor = 1.0 + (transformProgress * 0.2);

      path.quadraticBezierTo(r * curveFactor, -r * 0.4, 0, -r * pointFactor);
      path.quadraticBezierTo(-r * curveFactor, -r * 0.4, 0, 0);
      path.close();

      canvas.drawPath(path, paint);

      // Metallic highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: 0.2 + (transformProgress * 0.3),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + transformProgress;
      canvas.drawPath(path, highlightPaint);

      // Glow intensity increase with progress
      final glowPaint = Paint()
        ..color = petalColor.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          8 + (transformProgress * 12),
        );
      canvas.drawPath(path, glowPaint);

      canvas.restore();
    }

    // Draw Central Snowflake/Ice Core
    _drawSnowflake(
      canvas,
      center,
      14 + (transformProgress * 4),
      transformProgress,
    );
  }

  void _drawSnowflake(
    Canvas canvas,
    Offset center,
    double size,
    double progress,
  ) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 + (progress * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    // Draw branching arms
    for (int i = 0; i < 6; i++) {
        final double angle = (i * 60) * math.pi / 180;
        final double x = center.dx + math.cos(angle) * size;
        final double y = center.dy + math.sin(angle) * size;
        canvas.drawLine(center, Offset(x, y), paint);

        // Sub-branches
        final double branchSize = size * 0.4;
        final double branchAngle1 = angle + math.pi / 4;
        final double branchAngle2 = angle - math.pi / 4;

        final branchOrigin = Offset(
            center.dx + math.cos(angle) * size * 0.6,
            center.dy + math.sin(angle) * size * 0.6,
        );

        canvas.drawLine(
            branchOrigin,
            branchOrigin + Offset(math.cos(branchAngle1) * branchSize, math.sin(branchAngle1) * branchSize),
            paint,
        );
        canvas.drawLine(
            branchOrigin,
            branchOrigin + Offset(math.cos(branchAngle2) * branchSize, math.sin(branchAngle2) * branchSize),
            paint,
        );
    }
}

  @override
  bool shouldRepaint(covariant SymmetricPetalPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.color != color ||
      oldDelegate.transformProgress != transformProgress;
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
          const Color(0xFFC7C7CC).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 300));

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        auroraPaint..shader = gradient,
      );
    }

    final paint = Paint()
      ..color = const Color(0xFFC7C7CC).withValues(alpha: 0.04)
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
          const Color(0xFFC7C7CC).withValues(alpha: 0.15),
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

      final path = Path();
      path.moveTo(0, 0);
      path.lineTo(petal.size * 0.5, -petal.size * 0.7);
      path.lineTo(0, -petal.size * 1.5);
      path.lineTo(-petal.size * 0.5, -petal.size * 0.7);
      path.close();

      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..color = petal.color.withValues(alpha: petal.opacity * 0.4 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
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
      
      // We'll iterate through points to draw with variable thickness
      for (int i = 0; i < crack.points.length; i++) {
        final p = crack.points[i];
        final pos = center + Offset(p.dx * size.width * 0.5, p.dy * size.height * 0.5);
        
        if (first) {
          // Tightened center: Start 2px out with a tiny random jagged offset for realism
          if (p.dx == 0 && p.dy == 0) {
            if (crack.points.length > 1) {
              final nextP = crack.points[1];
              final dir = Offset(nextP.dx, nextP.dy);
              final mag = math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
              if (mag > 0) {
                // Crunchy origin: push 2px out
                final push = Offset(dir.dx / mag * 2, dir.dy / mag * 2);
                path.moveTo(pos.dx + push.dx, pos.dy + push.dy);
              } else {
                path.moveTo(pos.dx, pos.dy);
              }
            } else {
              path.moveTo(pos.dx, pos.dy);
            }
          } else {
            path.moveTo(pos.dx, pos.dy);
          }
          first = false;
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }

      // Pass 1: Chromatic Aberration (Glitch Effect - Cyan/Magenta Offset)
      final double glitchOffset = crackOpacity * 2.5;
      
      // Deep Silver Offset
      canvas.save();
      canvas.translate(glitchOffset, -glitchOffset * 0.5);
      canvas.drawPath(
        path,
        Paint()
          ..color = EntryColors.darkSilver.withValues(alpha: crackOpacity * 0.4)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();

      // Mid Silver Offset
      canvas.save();
      canvas.translate(-glitchOffset, glitchOffset * 0.5);
      canvas.drawPath(
        path,
        Paint()
          ..color = EntryColors.midSilver.withValues(alpha: crackOpacity * 0.4)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();

      // Pass 2: Outer frost/stress fracture
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFC7C7CC).withValues(alpha: crackOpacity * 0.3)
          ..strokeWidth = 4.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Pass 3: Specular Core (The sharpest part)
      canvas.drawPath(
        path,
        Paint()
          ..color = EntryColors.arcticSilver.withValues(alpha: crackOpacity)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Pass 4: Sharp Glints (Reflections at jagged intersections)
      final glintPaint = Paint()
        ..color = Colors.white.withValues(alpha: crackOpacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      for (int i = 1; i < crack.points.length - 1; i++) {
        // Add glints at sharp turns (intersections)
        if (math.Random(i).nextDouble() > 0.7) {
          final p = crack.points[i];
          final pos = center + Offset(p.dx * size.width * 0.5, p.dy * size.height * 0.5);
          
          // Tiny diamond-shaped glint
          final glintPath = Path();
          glintPath.moveTo(pos.dx, pos.dy - 1.5);
          glintPath.lineTo(pos.dx + 1.5, pos.dy);
          glintPath.lineTo(pos.dx, pos.dy + 1.5);
          glintPath.lineTo(pos.dx - 1.5, pos.dy);
          glintPath.close();
          canvas.drawPath(glintPath, glintPaint);
        }
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
      final double distance = (particle.initialDistance + particle.velocity * ease) / zDepth;
      
      final double shatterProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      final double opacity = (1.0 - (shatterProgress * 1.1)).clamp(0.0, 1.0);

      // Chromatic aberration / glitch effect
      final double glitchOffset = (1.0 - ease) * 12.0;
      final abPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = EntryColors.midSilver.withValues(alpha: opacity * 0.4);

      final cyanPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = EntryColors.arcticSilver.withValues(alpha: opacity * 0.4);

      canvas.save();
      final particleCenter = Offset(
        center.dx + math.cos(particle.angle) * distance,
        center.dy + math.sin(particle.angle) * distance,
      );

      canvas.translate(particleCenter.dx, particleCenter.dy);
      
      // Intense 3D tumbling rotation
      final double currentRot = (particle.rotationSpeed * ease * 10) + (particle.rotationSpeed * 0.2);
      canvas.rotate(currentRot);

      // Perspective Scale: Shrink as they retreat. Larger shards last longer.
      final double baseScale = (particle.tier == ParticleTier.dust ? 0.4 + ease : 1.0 - ease * 0.9);
      final double flipY = math.cos(currentRot * 1.8).abs().clamp(0.1, 1.0);
      
      canvas.scale(
        baseScale.clamp(0.05, 1.5), 
        baseScale * flipY,
      );

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

      // Glitch trail behind the fastest particles
      if (t < 0.4 && particle.tier == ParticleTier.large) {
        canvas.save();
        canvas.translate(glitchOffset * 2, 0);
        canvas.drawPath(path, abPaint);
        canvas.translate(-glitchOffset * 4, 0);
        canvas.drawPath(path, cyanPaint);
        canvas.restore();
      }

      // Base glass body (semi-transparent, slightly blue/silver tinted for thickness)
      final bodyPaint = Paint()
        ..color = const Color(0xFFE5E5EA).withValues(
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
            ..moveTo(bounds.left - bounds.width, bounds.top + bounds.height * 0.5)
            ..lineTo(bounds.right + bounds.width, bounds.bottom - bounds.height * 0.5);

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
          
          final Offset trailEnd = Offset(-math.cos(particle.angle) * 60 * t, -math.sin(particle.angle) * 60 * t);
          canvas.drawLine(Offset.zero, trailEnd, trailPaint);
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
      ..strokeWidth = 2 + (1.0 - t) * 20
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
