import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';

/// A sophisticated HUD (Heads-Up Display) ornament with multiple rings and tech lines.
/// This component provides the futuristic "UPLINK" aesthetic.
class CoolerHUD extends StatelessWidget {
  final Color color;
  final double size;
  
  const CoolerHUD({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HUDPainter(color: color),
      ),
    );
  }
}

class _HUDPainter extends CustomPainter {
  final Color color;
  _HUDPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Drawing concentric rings with varying patterns to simulate a radar/tech interface
    canvas.drawCircle(center, size.width * 0.45, paint);
    
    // Outer dashed ring
    _drawDashedArc(canvas, center, size.width * 0.48, paint, 0.2);
    
    // Technical markers (crosshair style)
    final markerPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.0;
      
    canvas.drawLine(
      Offset(center.dx, center.dy - size.width * 0.5),
      Offset(center.dx, center.dy - size.width * 0.4),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + size.width * 0.5),
      Offset(center.dx, center.dy + size.width * 0.4),
      markerPaint,
    );
  }

  void _drawDashedArc(Canvas canvas, Offset center, double radius, Paint paint, double gap) {
    for (double i = 0; i < 2 * math.pi; i += gap * 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i,
        gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Spinning rings used as background ornaments.
class SpinningRing extends StatelessWidget {
  final double size;
  final double opacity;
  final bool isClockwise;

  const SpinningRing({
    super.key,
    required this.size,
    required this.opacity,
    required this.isClockwise,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            // Decorative tech notches
            ...List.generate(8, (index) {
              return Transform.rotate(
                angle: (index * 45) * math.pi / 180,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 2,
                    height: 10,
                    color: colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// A vertical scanline effect that moves top-to-bottom.
class ScanlinePainter extends CustomPainter {
  final double progress;
  ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          EntryColors.iceCyan.withValues(alpha: 0.0),
          EntryColors.iceCyan.withValues(alpha: 0.15),
          EntryColors.iceCyan.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, (progress * size.height) - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, (progress * size.height) - 40, size.width, 80), paint);
  }

  @override
  bool shouldRepaint(ScanlinePainter oldDelegate) => oldDelegate.progress != progress;
}

/// A shine sweep effect that moves diagonally across the surface.
class ShinePainter extends CustomPainter {
  final double progress;
  ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH((progress * size.width * 2) - size.width, 0, size.width, size.height));

    // Rotate the canvas to create a diagonal shine sweep
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi / 4);
    canvas.translate(-size.width / 2, -size.height / 2);
    
    canvas.drawRect(
      Rect.fromLTWH((progress * size.width * 2) - size.width, -size.height, size.width, size.height * 3),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ShinePainter oldDelegate) => oldDelegate.progress != progress;
}

/// A particle system that simulates floating digital "ice" or "data" fragments.
class ParticleSystem extends StatelessWidget {
  final AnimationController controller;
  
  const ParticleSystem({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(progress: controller.value),
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speed;
  double opacity;
  
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static List<_Particle>? _particles;
  static final math.Random _random = math.Random();

  _ParticlePainter({required this.progress}) {
    _particles ??= List.generate(40, (index) {
        return _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1,
          speed: _random.nextDouble() * 0.2 + 0.1, // Fixed speed base
          opacity: _random.nextDouble() * 0.5 + 0.1,
        );
      });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in _particles!) {
      // Calculate current Y based on initial Y and progress
      // This is pure and doesn't modify p.y
      final double currentY = (p.y - (progress * p.speed)) % 1.2;
      final double displayY = currentY - 0.1;

      final offset = Offset(p.x * size.width, displayY * size.height);
      paint.color = EntryColors.iceCyan.withValues(alpha: p.opacity);
      
      canvas.drawRect(
        Rect.fromCenter(center: offset, width: p.size, height: p.size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => 
      oldDelegate.progress != progress;
}
