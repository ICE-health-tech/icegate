import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/animation_page/components/entry_constants.dart';

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
          size: 2.0 + _random.nextDouble() * 4.0,
          speed: 0.0003 + _random.nextDouble() * 0.0008,
          drift: (_random.nextDouble() - 0.5) * 0.0005,
          opacity: 0.05 + _random.nextDouble() * 0.3,
          rotation: _random.nextDouble() * math.pi * 2,
          spinSpeed: (_random.nextDouble() - 0.5) * 0.015,
          color: _random.nextDouble() > 0.7 
              ? EntryColors.iceCyan 
              : EntryColors.diamondWhite,
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
        // 1. Deep Glacier Gradient Base
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: EntryColors.iceGradient,
            ),
          ),
        ),

        // 2. Animated Crystalline Particles
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

        // 3. Ice Vapor / Vignette Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [
                  EntryColors.iceCyan.withValues(alpha: 0.05),
                  EntryColors.glacierBase.withValues(alpha: 0.4),
                ],
                stops: const [0.3, 1.0],
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
        ..color = EntryColors.iceCyan.withValues(alpha: 0.03)
        ..strokeWidth = 0.5;

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
      final double dynamicOpacity = crystal.opacity + (pulse * 0.15);

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

      // Add soft glow to some diamonds
      if (crystal.color == EntryColors.iceCyan) {
          canvas.drawPath(
            path, 
            Paint()
              ..color = crystal.color.withValues(alpha: dynamicOpacity * 0.5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          );
      }

      canvas.drawPath(path, crystalPaint);
      
      // Specular Highlight line (The "Diamond Glint")
      canvas.drawLine(
        Offset(-w / 2, 0), 
        Offset(w / 2, 0), 
        Paint()
          ..color = Colors.white.withValues(alpha: dynamicOpacity * 0.8)
          ..strokeWidth = 0.5
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
