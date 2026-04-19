import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/animation_page/components/entry_constants.dart';

class SnowSilverBackground extends StatefulWidget {
  final Widget? child;
  final int snowCount;
  final bool showGrid;

  const SnowSilverBackground({
    super.key,
    this.child,
    this.snowCount = 40,
    this.showGrid = true,
  });

  @override
  State<SnowSilverBackground> createState() => _SnowSilverBackgroundState();
}

class _SnowSilverBackgroundState extends State<SnowSilverBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SnowEntry> _snowParticles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initSnow();
  }

  void _initSnow() {
    for (int i = 0; i < widget.snowCount; i++) {
      _snowParticles.add(
        _SnowEntry(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 1.5 + _random.nextDouble() * 3.5,
          speed: 0.0004 + _random.nextDouble() * 0.0012,
          drift: (_random.nextDouble() - 0.5) * 0.0008,
          opacity: 0.1 + _random.nextDouble() * 0.4,
          rotation: _random.nextDouble() * math.pi,
          spinSpeed: (_random.nextDouble() - 0.5) * 0.02,
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
        // 1. Silver and Black Gradient (Deep Metallic) - Synced with Entry Architecture
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: EntryColors.obsidianGradient,
            ),
          ),
        ),

        // 2. Animated Snowfall & Grid
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _SnowSilverPainter(
                  particles: _snowParticles,
                  progress: _controller.value,
                  showGrid: widget.showGrid,
                ),
              );
            },
          ),
        ),

        // 3. Glossy Vignette Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.05),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),

        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _SnowSilverPainter extends CustomPainter {
  final List<_SnowEntry> particles;
  final double progress;
  final bool showGrid;

  _SnowSilverPainter({
    required this.particles,
    required this.progress,
    required this.showGrid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Build tactical grid if enabled (Fine Silver Grid)
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFFC7C7CC).withValues(alpha: 0.04)
        ..strokeWidth = 0.5;

      const double step = 60.0;
      for (double i = 0; i < size.width; i += step) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      }
      for (double i = 0; i < size.height; i += step) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
      }
    }

    // 1. Render Snow
    for (var snow in particles) {
      // Manual internal update logic for smooth flow in painter
      final double currentY = (snow.y + progress * snow.speed * 100) % 1.1;
      final double currentX = (snow.x + progress * snow.drift * 50) % 1.1;
      final double currentRotation = snow.rotation + progress * snow.spinSpeed * 100;

      final snowPaint = Paint()
        ..color = Colors.white.withValues(alpha: snow.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);

      canvas.save();
      canvas.translate(
        (currentX - 0.05) * size.width,
        (currentY - 0.05) * size.height,
      );
      canvas.rotate(currentRotation);

      // Draw standard snowflake shape
      final double w = snow.size;
      final double h = snow.size * 0.25;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        snowPaint,
      );
      canvas.rotate(math.pi / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        snowPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SnowSilverPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SnowEntry {
  final double x, y;
  final double size;
  final double speed;
  final double drift;
  final double opacity;
  final double rotation;
  final double spinSpeed;

  _SnowEntry({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
    required this.rotation,
    required this.spinSpeed,
  });
}
