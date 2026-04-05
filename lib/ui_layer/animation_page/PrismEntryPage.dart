import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class PrismEntryPage extends StatefulWidget {
  const PrismEntryPage({super.key});

  @override
  State<PrismEntryPage> createState() => _PrismEntryPageState();
}

class _PrismEntryPageState extends State<PrismEntryPage> with TickerProviderStateMixin {
  late AnimationController _assemblyController;
  late AnimationController _pulseController;
  late AnimationController _formController;
  
  final List<PrismShard> _shards = [];
  final int _shardCount = 60;
  final math.Random _random = math.Random();

  bool _showForm = false;
  late AuthBlock _authBlock;

  @override
  void initState() {
    super.initState();
    _authBlock = context.read<AuthBlock>();

    _assemblyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initShards();

    _assemblyController.forward().then((_) {
      _onAssemblyComplete();
    });
  }

  void _initShards() {
    for (int i = 0; i < _shardCount; i++) {
      final double angle = _random.nextDouble() * 2 * math.pi;
      final double distance = 300 + _random.nextDouble() * 500;
      
      _shards.add(
        PrismShard(
          startOffset: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
          ),
          targetOffset: Offset.zero, // Centers will be offset in painter
          size: 4 + _random.nextDouble() * 12,
          color: _random.nextBool() ? const Color(0xFFE1F5FE) : const Color(0xFFFFFFFF),
          rotation: _random.nextDouble() * 2 * math.pi,
          delay: _random.nextDouble() * 0.4,
          speed: 0.6 + _random.nextDouble() * 0.4,
        ),
      );
    }
  }

  void _onAssemblyComplete() {
    HapticFeedback.mediumImpact();
    setState(() => _showForm = true);
    _formController.forward();
    
    // Auto-navigate if already authenticated, or show login
    if (_authBlock.status.value == AuthStatus.authenticated) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) context.go('/');
      });
    }
  }

  @override
  void dispose() {
    _assemblyController.dispose();
    _pulseController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010A15), // Deep Midnight Blue
      body: Stack(
        children: [
          // 1. Tactical Grid Background
          const Positioned.fill(child: TacticalGridBackground()),

          // 2. Shard Assembly
          AnimatedBuilder(
            animation: _assemblyController,
            builder: (context, child) {
              return CustomPaint(
                painter: PrismPainter(
                  shards: _shards,
                  progress: _assemblyController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 3. Central Logo
          Center(
            child: AnimatedBuilder(
              animation: _assemblyController,
              builder: (context, child) {
                final double opacity = Curves.easeInQuint.transform(
                  (_assemblyController.value - 0.7).clamp(0.0, 1.0) / 0.3,
                );
                
                return Opacity(
                  opacity: opacity,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.05).animate(
                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: Color(0xFFE1F5FE),
                          size: 80,
                          shadows: [
                            Shadow(color: Color(0xFF80DEEA), blurRadius: 20),
                            Shadow(color: Color(0xFFFFFFFF), blurRadius: 40),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ICE GATE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                            shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Login Actions (Fade in)
          if (_showForm)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: FadeTransition(
                  opacity: _formController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic)),
                    child: _buildActionArea(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 240,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE0F7FA).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'INITIALIZE GATE',
              style: TextStyle(
                color: Color(0xFF01579B), // Dark Blue text for contrast on light button
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'VERIFYING SYSTEM INTEGRITY...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

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

class PrismPainter extends CustomPainter {
  final List<PrismShard> shards;
  final double progress;

  PrismPainter({required this.shards, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var shard in shards) {
      final double adjustedT = ((progress - shard.delay) / shard.speed).clamp(0.0, 1.0);
      if (adjustedT <= 0) continue;

      final double ease = Curves.easeInQuint.transform(adjustedT);
      final currentPos = center + Offset.lerp(shard.startOffset, shard.targetOffset, ease)!;
      final currentOpacity = (1.0 - ease).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = shard.color.withOpacity(currentOpacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(shard.rotation * (1.0 - ease) * 4);

      final path = Path();
      path.moveTo(0, -shard.size);
      path.lineTo(shard.size, shard.size / 2);
      path.lineTo(-shard.size, shard.size / 2);
      path.close();

      canvas.drawPath(path, paint);
      
      // Glow effect for shards
      if (adjustedT > 0.8) {
        final glowPaint = Paint()
          ..color = shard.color.withOpacity(currentOpacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawPath(path, glowPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TacticalGridBackground extends StatelessWidget {
  const TacticalGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE1F5FE).withOpacity(0.08)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Subtle Vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, const Color(0xFF010A15).withOpacity(0.9)],
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
