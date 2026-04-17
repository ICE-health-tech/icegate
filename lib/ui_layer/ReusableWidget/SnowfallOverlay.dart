import 'dart:math' as math;
import 'package:flutter/material.dart';

class SnowfallOverlay extends StatefulWidget {
  final int snowCount;
  final double opacity;
  
  const SnowfallOverlay({
    super.key,
    this.snowCount = 30,
    this.opacity = 0.3,
  });

  @override
  State<SnowfallOverlay> createState() => _SnowfallOverlayState();
}

class _SnowfallOverlayState extends State<SnowfallOverlay> with SingleTickerProviderStateMixin {
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
          size: 1 + _random.nextDouble() * 3,
          speed: 0.001 + _random.nextDouble() * 0.003,
          drift: (_random.nextDouble() - 0.5) * 0.001,
          opacity: (0.1 + _random.nextDouble() * 0.3) * widget.opacity,
          rotation: _random.nextDouble() * math.pi,
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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SnowPainter(
              snowParticles: _snowParticles,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<_SnowEntry> snowParticles;
  final double progress;

  _SnowPainter({required this.snowParticles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var snow in snowParticles) {
      // Calculate position based on progress to avoid state mutation in paint
      final double totalMoveY = progress; 
      final double currentY = (snow.y + totalMoveY * snow.speed * 100) % 1.0;
      final double currentX = (snow.x + totalMoveY * snow.drift * 50) % 1.0;
      final double currentRotation = snow.rotation + progress * math.pi * 2;

      final snowPaint = Paint()..color = Colors.white.withValues(alpha: snow.opacity);
      canvas.save();
      canvas.translate(currentX * size.width, currentY * size.height);
      canvas.rotate(currentRotation);
      
      // Draw a tiny snowflake cross
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: snow.size, height: snow.size * 0.2), snowPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: snow.size * 0.2, height: snow.size), snowPaint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => 
      oldDelegate.progress != progress;
}

class _SnowEntry {
  double x, y;
  final double size;
  final double speed;
  final double drift;
  final double opacity;
  double rotation;

  _SnowEntry({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
    this.rotation = 0.0,
  });
}
