import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SnowflakeAssembleScreen extends StatefulWidget {
  const SnowflakeAssembleScreen({super.key});

  @override
  State<SnowflakeAssembleScreen> createState() =>
      _SnowflakeAssembleScreenState();
}

class _SnowflakeAssembleScreenState extends State<SnowflakeAssembleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SnowflakeParticle> _particles = [];
  final List<Sparkle> _sparkles = [];
  final int _particleCount = 100;
  final int _sparkleCount = 40;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Initialize particles with random start positions and target center
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;

      // Setup Shards
      for (int i = 0; i < _particleCount; i++) {
        // Create a simple triangular shard path
        final shardPath = [
          const Offset(0, -1),
          const Offset(0.8, 0.5),
          const Offset(-0.8, 0.5),
        ];

        final double angle =
            (_random.nextDouble() * 4 * math.pi / 2); // 4 branches
        final double dist = _random.nextDouble() * 100 + 20;
        final target = Offset(
          size.width / 2 + math.cos(angle) * dist,
          size.height / 2 + math.sin(angle) * dist,
        );

        _particles.add(
          SnowflakeParticle(
            startPos: Offset(
              _random.nextDouble() * size.width,
              _random.nextDouble() * size.height,
            ),
            targetPos: target,
            size: _random.nextDouble() * 8 + 5,
            opacity: _random.nextDouble() * 0.4 + 0.6,
            delay: _random.nextDouble(),
            speed: _random.nextDouble() * 0.5 + 0.5,
            rotation: _random.nextDouble(),
            shardPath: shardPath,
          ),
        );
      }

      // Setup Sparkles
      for (int i = 0; i < _sparkleCount; i++) {
        _sparkles.add(
          Sparkle(
            position: Offset(
              _random.nextDouble() * size.width,
              _random.nextDouble() * size.height,
            ),
            size: _random.nextDouble() * 2 + 1,
            delay: _random.nextDouble(),
            speed: _random.nextDouble() * 2 + 1,
          ),
        );
      }

      _controller.forward().then((_) {
        // After animation, wait a bit then navigate
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            context.go('/');
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF0F8FF,
      ), // Alice Blue for a pristine look
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE6F7FF), // Very pale blue
                  Color(0xFFFFFFFF), // Pristine white
                ],
              ),
            ),
          ),
          // Sparkle Animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: SparklePainter(
                  sparkles: _sparkles,
                  progress: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Particle Animation (Shards)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: SnowflakePainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Central Text or Logo
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final opacity = ((_controller.value - 0.75) / 0.25).clamp(
                  0.0,
                  1.0,
                );
                final scale = 0.8 + (opacity * 0.2);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: Color(0xFF00BFFF), // Bright Sky Blue
                          size: 100,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 10),
                          ],
                        ),
                        const SizedBox(height: 30),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF00BFFF),
                              Color(0xFF0077BE),
                            ], // Shades of Blue
                          ).createShader(bounds),
                          child: Text(
                            'ICE GATE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Sparkle {
  final Offset position;
  final double size;
  final double delay;
  final double speed;

  Sparkle({
    required this.position,
    required this.size,
    required this.delay,
    required this.speed,
  });
}

class SparklePainter extends CustomPainter {
  final List<Sparkle> sparkles;
  final double progress;

  SparklePainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42);

    for (var sparkle in sparkles) {
      double t = (progress * sparkle.speed + sparkle.delay) % 1.0;
      double opacity = math.sin(t * math.pi).clamp(0.0, 1.0);

      paint.color = Colors.white.withValues(alpha: opacity * 0.8);
      canvas.drawCircle(sparkle.position, sparkle.size, paint);

      // Secondary glow
      if (random.nextDouble() > 0.8) {
        final glowPaint = Paint()
          ..color = Colors.blueAccent.withValues(alpha: opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(sparkle.position, sparkle.size * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SnowflakeParticle {
  final Offset startPos;
  final Offset targetPos;
  final double size;
  final double opacity;
  final double delay;
  final double speed;
  final double rotation;
  final List<Offset> shardPath;

  SnowflakeParticle({
    required this.startPos,
    required this.targetPos,
    required this.size,
    required this.opacity,
    required this.delay,
    required this.speed,
    required this.rotation,
    required this.shardPath,
  });

  Offset getPosition(double progress) {
    double adjustedProgress = (progress - delay * 0.4).clamp(0.0, 1.0);
    // Dynamic snap curve
    double easedProgress = Curves.easeInQuint.transform(adjustedProgress);
    if (adjustedProgress > 0.8) {
      easedProgress = Curves.elasticOut.transform(
        (adjustedProgress - 0.8) / 0.2 * 0.5 + 0.5,
      );
    }

    return Offset.lerp(startPos, targetPos, easedProgress)!;
  }
}

class SnowflakePainter extends CustomPainter {
  final List<SnowflakeParticle> particles;
  final double progress;

  SnowflakePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final pos = particle.getPosition(progress);
      final currentOpacity = (particle.opacity * (1.2 - progress)).clamp(
        0.0,
        1.0,
      );

      final paint = Paint()
        ..color = const Color(0xFF00BFFF)
            .withValues(alpha: currentOpacity) // Bright Sky Blue
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(particle.rotation * (1.0 - progress) * 2 * math.pi);

      final shardPath = Path();
      shardPath.moveTo(
        particle.shardPath[0].dx * particle.size,
        particle.shardPath[0].dy * particle.size,
      );
      for (int i = 1; i < particle.shardPath.length; i++) {
        shardPath.lineTo(
          particle.shardPath[i].dx * particle.size,
          particle.shardPath[i].dy * particle.size,
        );
      }
      shardPath.close();

      // Sharp edge glow
      final glowPaint = Paint()
        ..color = const Color(0xFFADD8E6)
            .withValues(alpha: currentOpacity * 0.4) // Light Blue
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(shardPath, glowPaint);
      canvas.drawPath(shardPath, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SnowflakePainter oldDelegate) => true;
}
