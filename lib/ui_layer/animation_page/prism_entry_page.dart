import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SnowfallOverlay.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';

class PrismEntryPage extends StatefulWidget {
  const PrismEntryPage({super.key});

  @override
  State<PrismEntryPage> createState() => _PrismEntryPageState();
}

class _PrismEntryPageState extends State<PrismEntryPage>
    with TickerProviderStateMixin {
  late AnimationController _assemblyController;
  late AnimationController _pulseController;
  late AnimationController _crackController;
  late AnimationController _scanController;
  late AnimationController _auroraController;
  late AnimationController _chargeController; // New: Power-up sequence

  final ValueNotifier<Offset> _pointerOffset = ValueNotifier(Offset.zero);

  final List<PrismShard> _shards = [];
  final int _shardCount = 80;
  final math.Random _random = math.Random();

  final List<_FlowerPetal> _cachedPetals = [];
  final List<_ScatteringParticle> _cachedParticles = [];
  final List<_GlassCrack> _cachedGlassCracks = [];

  bool _isCracking = false;
  bool _isAssemblyDone = false;
  late AuthBlock _authBlock;
  late final void Function() _disposeEffect;

  @override
  void initState() {
    super.initState();
    _authBlock = context.read<AuthBlock>();
    _precalculateGeometry();
    _assemblyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _crackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // Slightly longer for 3-stage countdown
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initShards();

    _assemblyController.forward().then((_) {
      if (mounted) {
        setState(() => _isAssemblyDone = true);
        _onAssemblyComplete();
      }
    });

    // Reactive Auth Monitoring: Auto-navigate if already authenticated or once authenticated
    _disposeEffect = effect(() {
      final status = _authBlock.status.value;
      if (status == AuthStatus.authenticated &&
          _isAssemblyDone &&
          !_isCracking) {
        _triggerCrackAndNavigate();
      }
    });
  }

  void _initShards() {
    for (int i = 0; i < _shardCount; i++) {
      final double angle = _random.nextDouble() * 2 * math.pi;
      final double distance = 350 + _random.nextDouble() * 600;

      _shards.add(
        PrismShard(
          startOffset: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
          ),
          targetOffset: Offset.zero,
          size: 2 + _random.nextDouble() * 10,
          color: _random.nextBool()
              ? const Color(0xFFC7C7CC)
              : const Color(0xFFFFFFFF),
          rotation: _random.nextDouble() * 2 * math.pi,
          delay: _random.nextDouble() * 0.4,
          speed: 0.4 + _random.nextDouble() * 0.4,
        ),
      );
    }
  }

  void _precalculateGeometry() {
    final random = math.Random(42);

    // 1. Generate Single Central 4-Petal Silver Flower
    const int petalsPerFlower = 4;
    for (int i = 0; i < petalsPerFlower; i++) {
      final double angle = (i / petalsPerFlower) * 2 * math.pi;
      _cachedPetals.add(
        _FlowerPetal(
          flowerIndex: 0,
          centerOffset: Offset.zero,
          angle: angle,
          size: 45 + random.nextDouble() * 10,
          opacity: 0.9 + random.nextDouble() * 0.1,
          color: const Color(0xFFC7C7CC), // Silver
          rotationOffset: 0,
        ),
      );
    }

    // 2. Generate Fractal "Spider-web" Glass Cracks
    const int crackCount = 18; // More cracks
    for (int i = 0; i < crackCount; i++) {
      final double angle = (i / crackCount) * 2 * math.pi + (random.nextDouble() * 0.4);
      final List<Offset> mainPoints = [Offset.zero];
      double currentDist = 0;
      double currentAngle = angle;
      
      while (currentDist < 1.0) {
        currentAngle += (random.nextDouble() - 0.5) * 0.4;
        currentDist += 0.05 + random.nextDouble() * 0.1;
        final p = Offset(
          math.cos(currentAngle) * currentDist,
          math.sin(currentAngle) * currentDist,
        );
        mainPoints.add(p);

        // Sub-branching for detail
        if (random.nextDouble() > 0.7 && currentDist < 0.8) {
          final List<Offset> branchPoints = [p];
          double bDist = currentDist;
          double bAngle = currentAngle + (random.nextBool() ? 0.8 : -0.8);
          for (int b = 0; b < 3; b++) {
            bAngle += (random.nextDouble() - 0.5) * 0.4;
            bDist += 0.05 + random.nextDouble() * 0.1;
            branchPoints.add(Offset(math.cos(bAngle) * bDist, math.sin(bAngle) * bDist));
          }
          _cachedGlassCracks.add(_GlassCrack(points: branchPoints));
        }
      }
      _cachedGlassCracks.add(_GlassCrack(points: mainPoints));
    }

    // 3. Generate High-Density Metallic Shards
    const int particleCount = 350; // Increased density
    for (int i = 0; i < particleCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 800 + random.nextDouble() * 2200; // Faster
      
      final List<Offset> points = [];
      final int sideCount = 3 + random.nextInt(3);
      for (int s = 0; s < sideCount; s++) {
        final double sAngle = (s / sideCount) * 2 * math.pi + random.nextDouble() * 0.5;
        final double sDist = 2 + random.nextDouble() * 10;
        points.add(Offset(math.cos(sAngle) * sDist, math.sin(sAngle) * sDist));
      }

      _cachedParticles.add(
        _ScatteringParticle(
          angle: angle,
          velocity: velocity,
          points: points,
          rotationSpeed: (random.nextDouble() - 0.5) * 60,
          color: Colors.white.withValues(alpha: 0.5 + random.nextDouble() * 0.4),
          delay: random.nextDouble() * 0.4,
        ),
      );
    }
  }

  void _onAssemblyComplete() async {
    HapticFeedback.mediumImpact(); // Stronger "lock-in" feel

    final status = _authBlock.status.value;

    // 1. If already authenticated (e.g. checkSession succeeded), navigate immediately
    if (status == AuthStatus.authenticated) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _triggerCrackAndNavigate();
      });
      return;
    }

    // 2. If unauthenticated but we have a remembered user, try Fast-Track (Passkey/Biometric)
    if (status == AuthStatus.unauthenticated &&
        _authBlock.rememberedUser.value != null &&
        !_isCracking) {
      print("🚀 [PrismEntryPage] Attempting Fast-Track Auto-Auth...");
      
      // We'll give the user a tiny moment to see the logo before the biometric prompt appears
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        // Attempt biometrics first (it's fastest and locally controlled)
        final success = await _authBlock.loginWithBiometrics(context);
        if (!success && mounted) {
          // If biometrics failed (or not enabled/supported), maybe try passkey?
          // For now we'll stick to biometrics as the primary auto-prompt
        }
      }
    }
  }

  void _triggerCrackAndNavigate() async {
    if (_isCracking) return;
    setState(() => _isCracking = true);

    // Stage 1: Overload Charging
    HapticFeedback.lightImpact();
    await _chargeController.forward();
    
    // Stage 2: Sharp Shatter
    HapticFeedback.heavyImpact(); 
    _crackController.forward();

    // Stage 3: Intense Vibration
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.vibrate());

    // Navigate slightly before the white flash peaks
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      if (_authBlock.status.value == AuthStatus.authenticated) {
        context.go('/');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _disposeEffect();
    _assemblyController.dispose();
    _pulseController.dispose();
    _crackController.dispose();
    _scanController.dispose();
    _auroraController.dispose();
    _chargeController.dispose();
    _pointerOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerMove: (event) {
          final size = MediaQuery.of(context).size;
          _pointerOffset.value = Offset(
            (event.localPosition.dx / size.width) - 0.5,
            (event.localPosition.dy / size.height) - 0.5,
          );
        },
        child: MouseRegion(
          onHover: (event) {
            final size = MediaQuery.of(context).size;
            _pointerOffset.value = Offset(
              (event.localPosition.dx / size.width) - 0.5,
              (event.localPosition.dy / size.height) - 0.5,
            );
          },
          child: Stack(
            children: [
          // 1. Fading Background Layer (Aurora, Grid, Snow, Logo, Assembly)
          AnimatedBuilder(
            animation: _crackController,
            builder: (context, child) {
              // Background fades out earlier
              final double bgOpacity = (1.0 - (_crackController.value * 1.4))
                  .clamp(0.0, 1.0);
              return Opacity(opacity: bgOpacity, child: child);
            },
            child: Stack(
              children: [
                // Aurora Background & Tactical Grid
                Positioned.fill(
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: _pointerOffset,
                    builder: (context, pOffset, child) {
                      return AnimatedBuilder(
                        animation: Listenable.merge([_auroraController, _scanController]),
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _TacticalGridPainter(
                              scanProgress: _scanController.value,
                              auroraProgress: _auroraController.value,
                              pointerOffset: pOffset,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Snowfall Layer
                const Positioned.fill(
                  child: SnowfallOverlay(snowCount: 50, opacity: 0.35),
                ),

                // Shard Assembly
                ValueListenableBuilder<Offset>(
                  valueListenable: _pointerOffset,
                  builder: (context, pOffset, child) {
                    return AnimatedBuilder(
                      animation: _assemblyController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PrismPainter(
                            shards: _shards,
                            progress: _assemblyController.value,
                            pointerOffset: pOffset,
                          ),
                          size: Size.infinite,
                        );
                      },
                    );
                  },
                ),

                // Central Interactive Logo
                Center(
                  child: AnimatedBuilder(
                    animation: _assemblyController,
                    builder: (context, child) {
                      final double opacity = Curves.easeInQuint.transform(
                        ((_assemblyController.value - 0.7) / 0.3).clamp(
                          0.0,
                          1.0,
                        ),
                      );
                      return Opacity(
                        opacity: opacity,
                        child: GestureDetector(
                          onTap: _triggerCrackAndNavigate,
                          behavior: HitTestBehavior.opaque,
                          child: _buildCoolerLogo(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. Ice Flower Bloom & Blow Layer
          IgnorePointer(
            child: ValueListenableBuilder<Offset>(
              valueListenable: _pointerOffset,
              builder: (context, pOffset, child) {
                return Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _crackController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: FlowerPainter(
                            progress: _crackController.value,
                            petals: _cachedPetals,
                            pointerOffset: pOffset,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                    // Glass Crack Layer
                    AnimatedBuilder(
                      animation: _crackController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: GlassCrackPainter(
                            progress: _crackController.value,
                            cracks: _cachedGlassCracks,
                            pointerOffset: pOffset,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                    // Shockwave Impact Layer
                    AnimatedBuilder(
                      animation: _crackController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _ShockwavePainter(
                            progress: _crackController.value,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _crackController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: GlassShatterPainter(
                            progress: _crackController.value,
                            particles: _cachedParticles,
                            pointerOffset: pOffset,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. White Flash (The transition 'portal')
          if (_isCracking)
            AnimatedBuilder(
              animation: _crackController,
              builder: (context, child) {
                final double flashOpacity = Curves.easeInQuint.transform(
                  ((_crackController.value - 0.8) / 0.2).clamp(0.0, 1.0),
                );
                return Container(
                  color: Colors.white.withValues(alpha: flashOpacity),
                );
              },
            ),

          // 4. Authentication & Identity UI (Gmail Fast Track)
          _buildAuthUI(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCoolerLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _crackController,
        _chargeController,
        _pointerOffset,
      ]),
      builder: (context, child) {
        final double crackVal = _crackController.value;
        final double chargeVal = _chargeController.value;
        final Offset pOffset = _pointerOffset.value;

        // Reactive Scale: Pulse + Charge Expansion
        final double scale =
            (1.0 + math.sin(_pulseController.value * math.pi) * 0.08) *
            (1.0 + chargeVal * 0.15) *
            (1.0 - crackVal * 0.1);

        // Digital Glitch/Shake during charge
        final double shake = chargeVal > 0 && crackVal < 0.1
            ? (math.sin(chargeVal * 40) * 4 * chargeVal)
            : 0;

        final double opacity = (1.0 - (crackVal * 2.5)).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(shake + pOffset.dx * 15, pOffset.dy * 15),
            child: Transform.scale(
              scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Far Outer Atmospheric Ring
                Transform.rotate(
                  angle: -_pulseController.value * 0.1,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC7C7CC).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Outer Ring
                Transform.rotate(
                  angle: _pulseController.value * 0.2,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC7C7CC).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Middle Symmetric 4-Petal Mandala
                Transform.rotate(
                  angle: -_pulseController.value * 0.3,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: _SymmetricPetalPainter(
                      color: const Color(0xFFC7C7CC).withValues(alpha: 0.4),
                      pulse: _pulseController.value,
                    ),
                  ),
                ),
                // Inner Core
                Hero(
                  tag: 'app_icon_hero',
                  child: Container(
                    width: 60,
                    height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC7C7CC)
                                .withValues(alpha: 0.6 + (chargeVal * 0.4)),
                            blurRadius: 40 + (chargeVal * 60),
                            spreadRadius: 2 + (chargeVal * 20),
                          ),
                        ],
                      ),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.8),
                                Colors.white,
                                Colors.white.withValues(alpha: 0.8),
                              ],
                              stops: [
                                (_pulseController.value - 0.2).clamp(0.0, 1.0),
                                _pulseController.value,
                                (_pulseController.value + 0.2).clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.ac_unit_rounded, // Back to snowflake/ice feel
                            color: Colors.white,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildAuthUI() {
  return Watch((context) {
    final status = _authBlock.status.value;
    final remembered = _authBlock.rememberedUser.value;
    final isUnauthed = status == AuthStatus.unauthenticated || 
                       status == AuthStatus.failed;

    // We only show these UI elements after assembly is done and if we aren't cracking
    if (!_isAssemblyDone || _isCracking) return const SizedBox.shrink();

    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _assemblyController.drive(
          CurveTween(curve: const Interval(0.9, 1.0, curve: Curves.easeIn)),
        ),
        child: Column(
          children: [
            // 👤 Identity Glance
            if (remembered != null) ...[
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (remembered['avatarUrl'] != null)
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: NetworkImage(remembered['avatarUrl']!),
                                    backgroundColor: Colors.transparent,
                                  )
                                else
                                  Icon(Icons.person_outline, size: 16, color: const Color(0xFFC7C7CC)),
                                const SizedBox(width: 10),
                                Text(
                                  remembered['displayName'] ?? remembered['username'] ?? "Ice Traveler",
                                  style: const TextStyle(
                                    color: Color(0xFFC7C7CC),
                                    fontSize: 13,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isUnauthed)
                            TextButton(
                              onPressed: () => context.push('/login'),
                              child: Text(
                                "NOT YOU?".toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 9,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],

            // 🌐 Gmail Fast Track Button
            if (isUnauthed) ...[
               _buildGmailFastTrackButton(),
               const SizedBox(height: 20),
               if (remembered == null)
                 TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      "LEGACY LOGIN".toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                 ),
            ],
            
            // ⌛ Authenticaton Status Indicator
            if (status == AuthStatus.authenticating || status == AuthStatus.checkingSession)
              const AuthStatusPulse(),
          ],
        ),
      ),
    );
  });
}

Widget _buildGmailFastTrackButton() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 40),
    child: InkWell(
      onTap: () => _authBlock.signInWithGoogle(),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_\"G\"_logo.svg',
              height: 20,
              width: 20,
              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white),
            ),
            const SizedBox(width: 15),
            const Text(
              "GMAIL FAST TRACK",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class AuthStatusPulse extends StatefulWidget {
  const AuthStatusPulse({super.key});

  @override
  State<AuthStatusPulse> createState() => _AuthStatusPulseState();
}

class _AuthStatusPulseState extends State<AuthStatusPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Text(
          "SCANNING...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class _SymmetricPetalPainter extends CustomPainter {
  final Color color;
  final double pulse;

  _SymmetricPetalPainter({required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    for (int i = 0; i < 4; i++) {
      final double angle = (i * 90) * math.pi / 180;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      
      final path = Path();
      // Smooth crystalline petal using quadratic bezier
      path.moveTo(0, 0);
      // Outer curve
      path.quadraticBezierTo(r * 0.6, -r * 0.4, 0, -r);
      // Return curve
      path.quadraticBezierTo(-r * 0.6, -r * 0.4, 0, 0);
      path.close();
      
      // Draw main petal
      canvas.drawPath(path, paint);
      
      // Inner petal highlight for depth
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, highlightPaint);

      // Glow effect
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
      
      canvas.restore();
    }
    
    // Tiny center core connector
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, corePaint);
  }

  @override
  bool shouldRepaint(covariant _SymmetricPetalPainter oldDelegate) => 
      oldDelegate.pulse != pulse;
}

class _TacticalGridPainter extends CustomPainter {
  final double scanProgress;
  final double auroraProgress;
  final Offset pointerOffset;
  _TacticalGridPainter({
    required this.scanProgress,
    required this.auroraProgress,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final auroraPaint = Paint();
    final center = Offset(
      size.width / 2 + pointerOffset.dx * 30, 
      size.height / 2 + pointerOffset.dy * 30
    );

    for (int i = 0; i < 3; i++) {
      final double angle = (auroraProgress * 2 * math.pi) + (i * math.pi * 0.6);
      final double x = center.dx + math.cos(angle) * 120 + pointerOffset.dx * 100;
      final double y = center.dy + math.sin(angle * 1.5) * 60 + pointerOffset.dy * 100;

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
  bool shouldRepaint(covariant _TacticalGridPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.auroraProgress != auroraProgress;
}

class FlowerPainter extends CustomPainter {
  final double progress;
  final List<_FlowerPetal> petals;
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
      size.height / 2 + pointerOffset.dy * 15
    );

    for (var petal in petals) {
      // Staggered Bloom sequence: 
      // Flower 0: 0.0 - 0.25
      // Flower 1: 0.2 - 0.45
      // Flower 2: 0.4 - 0.65
      final double startT = petal.flowerIndex * 0.2;
      
      final double bloomT = ((progress - startT) / 0.25).clamp(0.0, 1.0);
      if (bloomT <= 0) continue;

      // Shatter/Fade phase: 0.7 to 0.85
      final double fadeT = ((progress - 0.7) / 0.15).clamp(0.0, 1.0);
      
      final double easeBloom = Curves.easeOutBack.transform(bloomT);
      final double opacity = (1.0 - fadeT).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = petal.color.withValues(alpha: petal.opacity * opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(center.dx + petal.centerOffset.dx, center.dy + petal.centerOffset.dy);
      canvas.rotate(petal.angle + (bloomT * 0.1) + petal.rotationOffset);
      canvas.scale(easeBloom);

      final path = Path();
      // Sharp crystalline petal shape
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
  bool shouldRepaint(FlowerPainter oldDelegate) => oldDelegate.progress != progress;
}

class _FlowerPetal {
  final int flowerIndex;
  final Offset centerOffset;
  final double angle;
  final double size;
  final double opacity;
  final Color color;
  final double rotationOffset;
  _FlowerPetal({
    required this.flowerIndex,
    required this.centerOffset,
    required this.angle,
    required this.size,
    required this.opacity,
    required this.color,
    required this.rotationOffset,
  });
}

class GlassCrackPainter extends CustomPainter {
  final double progress;
  final List<_GlassCrack> cracks;
  final Offset pointerOffset;

  GlassCrackPainter({
    required this.progress,
    required this.cracks,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.4 || progress > 0.85) return;

    final center = Offset(
      size.width / 2 + pointerOffset.dx * 15, 
      size.height / 2 + pointerOffset.dy * 15
    );
    // Cracks appear between 0.4 and 0.75
    final double crackOpacity = ((progress - 0.4) / 0.15).clamp(0.0, 1.0) *
                                (1.0 - ((progress - 0.75) / 0.1).clamp(0.0, 1.0));

    final mainPaint = Paint()
      ..color = Colors.white.withValues(alpha: crackOpacity * 0.7)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final branchPaint = Paint()
      ..color = const Color(0xFFC7C7CC).withValues(alpha: crackOpacity * 0.4)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    for (var crack in cracks) {
      final path = Path();
      bool first = true;
      for (var p in crack.points) {
        final pos = center + Offset(p.dx * size.width * 0.5, p.dy * size.height * 0.5);
        if (first) {
          path.moveTo(pos.dx, pos.dy);
          first = false;
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      // Use branch paint for shorter segments (branches)
      canvas.drawPath(path, (crack.points.length < 5) ? branchPaint : mainPaint);
    }
  }

  @override
  bool shouldRepaint(GlassCrackPainter oldDelegate) => oldDelegate.progress != progress;
}

class GlassShatterPainter extends CustomPainter {
  final double progress;
  final List<_ScatteringParticle> particles;
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
        size.height / 2 + pointerOffset.dy * 20
      );
      
      final double t = ((progress - particle.delay - 0.7) / 0.3).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final double ease = Curves.easeOutQuart.transform(t);
      final double distance = particle.velocity * ease;
      final double opacity = (1.0 - ease).clamp(0.0, 1.0);

      // Enhanced Glitch Aberration (variable intensity)
      final double glitchOffset = (1.0 - ease) * 5.0;
      final abPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF00FF).withValues(alpha: opacity * 0.3); // Magenta
      
      final cyanPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF00FFFF).withValues(alpha: opacity * 0.3); // Cyan

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      final particleCenter = Offset(
        center.dx + math.cos(particle.angle) * distance,
        center.dy + math.sin(particle.angle) * distance,
      );
      
      canvas.translate(particleCenter.dx, particleCenter.dy);
      canvas.rotate(particle.rotationSpeed * ease);
      canvas.scale(1.0 + ease * 2.0); // Slightly larger expansion

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

      // Draw Glitch Layers
      if (t < 0.5) {
        canvas.save();
        canvas.translate(glitchOffset, 0);
        canvas.drawPath(path, abPaint);
        canvas.translate(-glitchOffset * 2, 0);
        canvas.drawPath(path, cyanPaint);
        canvas.restore();
      }

      canvas.drawPath(path, paint);
      
      // Highly reflective silver glints (Chrome effect)
      if (i % 3 == 0) {
        final glintPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawPath(path, glintPaint);
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(GlassShatterPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ShockwavePainter extends CustomPainter {
  final double progress;
  _ShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.7 || progress > 0.95) return;

    final double t = (progress - 0.7) / 0.25;
    final double radius = t * size.shortestSide * 0.8;
    final double opacity = (1.0 - t).clamp(0.0, 1.0);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + (1.0 - t) * 20
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity * 0.5),
          const Color(0xFFC7C7CC).withValues(alpha: 0.0),
        ],
        stops: const [0.9, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(size.width/2, size.height/2), radius: radius + 10));

    canvas.drawCircle(Offset(size.width/2, size.height/2), radius, paint);
    
    // Outer secondary bloom ring
    final bloomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = t * 40
      ..color = Colors.white.withValues(alpha: opacity * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(size.width/2, size.height/2), radius * 1.1, bloomPaint);
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter oldDelegate) => oldDelegate.progress != progress;
}

class _ScatteringParticle {
  final double angle;
  final double velocity;
  final List<Offset> points;
  final double rotationSpeed;
  final Color color;
  final double delay;
  _ScatteringParticle({
    required this.angle,
    required this.velocity,
    required this.points,
    required this.rotationSpeed,
    required this.color,
    required this.delay,
  });
}

class _GlassCrack {
  final List<Offset> points;
  _GlassCrack({required this.points});
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
      size.height / 2 + pointerOffset.dy * 20
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
