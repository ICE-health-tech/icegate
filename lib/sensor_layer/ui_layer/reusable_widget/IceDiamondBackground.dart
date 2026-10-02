import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

Color _particleWinterColor(math.Random r) {
  // Bias toward lighter ice tones so shards read clearly on the dark radial.
  final roll = r.nextDouble();
  if (roll > 0.5) return EntryLandscapePalette.icyWhiteBlue;
  if (roll > 0.22) return EntryLandscapePalette.dustySkyBlue;
  return EntryLandscapePalette.steelBlue;
}

class IceDiamondBackground extends StatefulWidget {
  final Widget? child;
  final int particleCount;
  final bool showGrid;

  const IceDiamondBackground({
    super.key,
    this.child,
    this.particleCount = 50,
    this.showGrid = true,
  });

  @override
  State<IceDiamondBackground> createState() => _IceDiamondBackgroundState();
}

class _IceDiamondBackgroundState extends State<IceDiamondBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_CrystalParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _CrystalParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 2.8 + _random.nextDouble() * 5.2,
          speed: 0.0003 + _random.nextDouble() * 0.0008,
          drift: (_random.nextDouble() - 0.5) * 0.0005,
          opacity: 0.14 + _random.nextDouble() * 0.32,
          rotation: _random.nextDouble() * math.pi * 2,
          spinSpeed: (_random.nextDouble() - 0.5) * 0.015,
          color: _particleWinterColor(_random),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Winter landscape radial (same family as Prism entry)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: EntryColors.winterLandscapeRadial,
            ),
          ),
        ),

        // 2. Aurora light blobs (adds depth/motion behind particles)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              // Slow drift so it feels alive but not distracting.
              final a1 = Alignment(
                -0.75 + math.sin(t * math.pi * 2) * 0.25,
                -0.65 + math.cos(t * math.pi * 2) * 0.18,
              );
              final a2 = Alignment(
                0.85 + math.cos(t * math.pi * 2) * 0.22,
                0.55 + math.sin(t * math.pi * 2) * 0.2,
              );

              return Stack(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: a1,
                        radius: 1.15,
                        colors: [
                          EntryColors.iceCyan.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: a2,
                        radius: 1.25,
                        colors: [
                          EntryLandscapePalette.mutedSlateBlue.withValues(
                            alpha: 0.16,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 3. Animated Crystalline Particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _IceDiamondPainter(
                  particles: _particles,
                  progress: _controller.value,
                  showGrid: widget.showGrid,
                ),
              );
            },
          ),
        ),

        // 4. Ice Vapor / Vignette — lighter center preserves radial punch; darker rim adds depth.
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.35,
                colors: [
                  EntryLandscapePalette.icyWhiteBlue.withValues(alpha: 0.03),
                  Colors.transparent,
                  EntryLandscapePalette.midnightNavy.withValues(alpha: 0.55),
                ],
                stops: const [0.15, 0.55, 1.0],
              ),
            ),
          ),
        ),

        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _IceDiamondPainter extends CustomPainter {
  final List<_CrystalParticle> particles;
  final double progress;
  final bool showGrid;

  _IceDiamondPainter({
    required this.particles,
    required this.progress,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Tactical Ice Grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = EntryLandscapePalette.steelBlue.withValues(alpha: 0.11)
        ..strokeWidth = 0.65;

      const double step = 80.0;
      for (double i = 0; i < size.width; i += step) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      }
      for (double i = 0; i < size.height; i += step) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
      }
    }

    // 1. Render Crystalline Particles (Rhombus/Diamond Shapes)
    for (var crystal in particles) {
      final double currentY = (crystal.y + progress * crystal.speed * 100) % 1.1;
      final double currentX = (crystal.x + progress * crystal.drift * 50) % 1.1;
      final double currentRotation = crystal.rotation + progress * crystal.spinSpeed * 100;
      
      // Icy Glimmer effect: rhythmic brightness pulse
      final double pulse = (math.sin(progress * 2 * math.pi * 5 + crystal.x * 10) + 1.0) / 2.0;
      final double dynamicOpacity = (crystal.opacity + pulse * 0.24).clamp(0.08, 0.95);

      final crystalPaint = Paint()
        ..color = crystal.color.withValues(alpha: dynamicOpacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        (currentX - 0.05) * size.width,
        (currentY - 0.05) * size.height,
      );
      canvas.rotate(currentRotation);

      // Draw Diamond (Rhombus) shape
      final double w = crystal.size;
      final double h = crystal.size * 1.5;
      
      final path = Path()
        ..moveTo(0, -h / 2)
        ..lineTo(w / 2, 0)
        ..lineTo(0, h / 2)
        ..lineTo(-w / 2, 0)
        ..close();

      canvas.drawPath(path, crystalPaint);
      
      // Specular Highlight line (The "Diamond Glint") - simpler drawing
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: dynamicOpacity * 0.72)
        ..strokeWidth = 0.65;
      
      canvas.drawLine(
        Offset(-w / 2, 0), 
        Offset(w / 2, 0), 
        highlightPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _IceDiamondPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CrystalParticle {
  final double x, y;
  final double size;
  final double speed;
  final double drift;
  final double opacity;
  final double rotation;
  final double spinSpeed;
  final Color color;

  _CrystalParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
    required this.rotation,
    required this.spinSpeed,
    required this.color,
  });
}
