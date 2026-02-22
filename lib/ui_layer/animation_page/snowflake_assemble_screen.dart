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
  final int _particleCount = 150;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Initialize particles with random start positions and target center
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < _particleCount; i++) {
        _particles.add(
          SnowflakeParticle(
            startPos: Offset(
              _random.nextDouble() * size.width,
              _random.nextDouble() * size.height,
            ),
            targetPos: Offset(size.width / 2, size.height / 2),
            size: _random.nextDouble() * 4 + 1,
            opacity: _random.nextDouble() * 0.5 + 0.5,
            delay: _random.nextDouble(), // Normalized delay
            speed: _random.nextDouble() * 0.5 + 0.5,
          ),
        );
      }
      _controller.forward().then((_) {
        // After animation, wait a bit then navigate
        Future.delayed(const Duration(milliseconds: 500), () {
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF001F3F), // Dark navy
                  Colors.black,
                ],
              ),
            ),
          ),
          // Particle Animation
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
          // Central Text or Logo (optional, appears as assembly nears completion)
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final opacity = ((_controller.value - 0.7) / 0.3).clamp(
                  0.0,
                  1.0,
                );
                return Opacity(
                  opacity: opacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ac_unit, color: Colors.white, size: 80),
                      const SizedBox(height: 20),
                      Text(
                        'ICE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class SnowflakeParticle {
  final Offset startPos;
  final Offset targetPos;
  final double size;
  final double opacity;
  final double delay;
  final double speed;

  SnowflakeParticle({
    required this.startPos,
    required this.targetPos,
    required this.size,
    required this.opacity,
    required this.delay,
    required this.speed,
  });

  Offset getPosition(double progress) {
    // Apply delay and individual speed
    double adjustedProgress = (progress - delay * 0.3).clamp(0.0, 1.0);
    // Use an easing function for a "snap" feel at the end
    double easedProgress = Curves.easeInOutCubic.transform(adjustedProgress);

    return Offset.lerp(startPos, targetPos, easedProgress)!;
  }
}

class SnowflakePainter extends CustomPainter {
  final List<SnowflakeParticle> particles;
  final double progress;

  SnowflakePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var particle in particles) {
      final pos = particle.getPosition(progress);

      // Calculate opacity based on progress and particle's base opacity
      final currentOpacity = particle.opacity * (1.0 - (progress * 0.3));
      paint.color = Colors.white.withOpacity(currentOpacity.clamp(0.0, 1.0));

      // Draw a "glow" effect for the particle
      final glowPaint = Paint()
        ..color = Colors.blue.withOpacity(currentOpacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(pos, particle.size + 1, glowPaint);
      canvas.drawCircle(pos, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(SnowflakePainter oldDelegate) => true;
}
