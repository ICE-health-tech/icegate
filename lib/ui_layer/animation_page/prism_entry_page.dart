import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SnowfallOverlay.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';

import 'components/entry_constants.dart';
import 'components/prism_painters.dart';

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
  late AnimationController _chargeController;
  late AnimationController _spinController;

  final ValueNotifier<Offset> _pointerOffset = ValueNotifier(Offset.zero);

  final List<PrismShard> _shards = [];
  final int _shardCount = 150; // Balanced count for cleaner crystalline bloom
  final math.Random _random = math.Random();

  final List<ScatteringParticleData> _cachedParticles = [];
  final List<GlassCrackData> _cachedGlassCracks = [];

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
      duration: const Duration(milliseconds: 1400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _crackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initShards();

    _assemblyController.forward().then((_) {
      if (mounted) {
        setState(() => _isAssemblyDone = true);
        _onAssemblyComplete();
      }
    });

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
      final double distance = 600 + _random.nextDouble() * 700;

      _shards.add(
        PrismShard(
          startOffset: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
          ),
          targetOffset: Offset.zero,
          size: 2 + _random.nextDouble() * 12,
          color: _random.nextBool()
              ? EntryColors.arcticSilver
              : EntryColors.frostedWhite,
          rotation: _random.nextDouble() * 2 * math.pi,
          delay: _random.nextDouble() * 0.5,
          speed: 0.4 + _random.nextDouble() * 0.5,
        ),
      );
    }
  }

  void _precalculateGeometry() {
    final random = math.Random(42);

    // 1. Glass Cracks - High Fidelity Shattered Web (Destructive Fragmentation)
    const int crackCount =
        10; // Reduced density for cleaner, more dramatic shatter
    final List<List<Offset>> allRadialPoints = [];

    // A. Primary Radial Fractures (Jagged, branching paths)
    for (int i = 0; i < crackCount; i++) {
      final impactOrigin = Offset.zero;
      final double baseAngle = (i / crackCount) * 2 * math.pi;
      // FRACTAL FROST: Growing crystalline branches
      void growBranch(
        Offset start,
        double angle,
        double dist,
        int depth, {
        bool isMain = false,
      }) {
        if (depth > 4 || dist > 6.0) return;

        final List<Offset> branchPoints = [start];
        double bDist = dist;
        double bAngle = angle;

        for (int j = 0; j < 6; j++) {
          final double jitter = 0.2 + (bDist * 0.1);
          bAngle += (random.nextDouble() - 0.5) * jitter;
          bDist += 0.2 + random.nextDouble() * 0.4;

          final nextPoint =
              impactOrigin +
              Offset(math.cos(bAngle) * bDist, math.sin(bAngle) * bDist);
          branchPoints.add(nextPoint);

          // RECURSIVE BRANCHING: split chance
          if (random.nextDouble() > 0.75 - (depth * 0.1)) {
            growBranch(
              nextPoint,
              bAngle + (random.nextBool() ? 0.35 : -0.35),
              bDist,
              depth + 1,
            );
          }
          if (bDist > 6.0) break;
        }

        if (isMain) allRadialPoints.add(branchPoints);
        _cachedGlassCracks.add(GlassCrackData(points: branchPoints));
      }

      growBranch(impactOrigin, baseAngle, 0.0, 0, isMain: true);
    }

    // B. Impact Point Micro-Shatter (Central Crunch)
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = 0.05 + random.nextDouble() * 0.15;
      final p1 = Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      final p2 = Offset(
        math.cos(angle + 0.5) * (dist + 0.1),
        math.sin(angle + 0.5) * (dist + 0.1),
      );
      _cachedGlassCracks.add(GlassCrackData(points: [p1, p2]));
    }

    // C. Concentric Stress Rings (Spiderweb Connections)
    for (int layer = 1; layer < 9; layer++) {
      final double radiusFactor = (layer / 9.0);
      for (int i = 0; i < crackCount; i++) {
        if (random.nextDouble() > 0.25) {
          final Offset p1 =
              allRadialPoints[i][layer.clamp(0, allRadialPoints[i].length - 1)];
          final Offset p2 =
              allRadialPoints[(i + 1) % crackCount][layer.clamp(
                0,
                allRadialPoints[(i + 1) % crackCount].length - 1,
              )];

          // Jagged arc between radials
          final Offset mid = Offset.lerp(p1, p2, 0.5)!;
          final Offset normal = Offset(-(p2.dy - p1.dy), p2.dx - p1.dx);
          final Offset jaggedMid =
              mid + normal * (random.nextDouble() - 0.5) * 0.3 * radiusFactor;

          _cachedGlassCracks.add(GlassCrackData(points: [p1, jaggedMid, p2]));
        }
      }
    }

    // 2. Massive Splinter Shards (Explosive Volume)
    const int largeParticleCount = 280;
    for (int i = 0; i < largeParticleCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      // Start away from the origin to avoid the "face"
      // Explosive force: Start further and move faster
      final double startDist = 100 + random.nextDouble() * 300;
      final double velocity = 2800 + random.nextDouble() * 3500;

      final double length = 180 + random.nextDouble() * 220;
      final double width = 30 + random.nextDouble() * 70;

      final List<Offset> points = [
        Offset(-width / 2, -length / 2),
        Offset(width / 2, -length / 2 + random.nextDouble() * 50),
        Offset(random.nextDouble() * width - width / 2, length / 2),
      ];

      if (random.nextBool()) {
        points.add(Offset(-width / 2 - random.nextDouble() * 30, 0));
      }

      _cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: points,
          rotationSpeed:
              (random.nextDouble() - 0.5) * 65, // More aggressive tumbling
          color: Colors.white.withValues(
            alpha: 0.85 + random.nextDouble() * 0.15,
          ),
          delay: random.nextDouble() * 0.1,
          initialDistance: startDist,
          tier: ParticleTier.large,
        ),
      );
    }

    // Tier 2: Frost/Dust splinters (Particle Storm)
    const int dustCount = 450;
    for (int i = 0; i < dustCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 1400 + random.nextDouble() * 2200;
      final double w = 4 + random.nextDouble() * 6;
      final double l = 15 + random.nextDouble() * 25;
      _cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: [
            Offset(-w / 2, -l / 2),
            Offset(w / 2, -l / 2),
            Offset(0, l / 2),
          ],
          rotationSpeed: 120,
          color: Colors.white.withValues(alpha: 0.25),
          delay: random.nextDouble() * 0.4,
          tier: ParticleTier.dust,
        ),
      );
    }
  }

  void _onAssemblyComplete() async {
    HapticFeedback.heavyImpact();

    final status = _authBlock.status.value;

    if (status == AuthStatus.authenticated) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _triggerCrackAndNavigate();
      });
      return;
    }

    // AUTO-LOGIN DISABLED: The user should click "Fingerprint" or "Gmail" manually
    // to avoid intrusive popups upon entry.
  }

  void _triggerCrackAndNavigate() async {
    if (_isCracking) return;
    setState(() => _isCracking = true);

    HapticFeedback.mediumImpact();
    await _chargeController.forward();

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.vibrate();

    _crackController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
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
    _spinController.dispose();
    _pointerOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(gradient: EntryColors.obsidianGradient),
        child: Listener(
          onPointerMove: (event) {
            final size = MediaQuery.of(context).size;
            _pointerOffset.value = Offset(
              (event.localPosition.dx / size.width) - 0.5,
              (event.localPosition.dy / size.height) - 0.5,
            );
          },
          child: MouseRegion(
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _crackController,
                  builder: (context, child) {
                    final double crackVal = _crackController.value;
                    final double bgOpacity = (1.0 - (crackVal * 1.5)).clamp(
                      0.0,
                      1.0,
                    );

                    // SCREEN SHAKE PHYSICS: High-frequency displacement for impact
                    double shakeX = 0;
                    double shakeY = 0;
                    if (crackVal > 0 && crackVal < 0.25) {
                      final double intensity = (1.0 - (crackVal / 0.25)) * 18;
                      shakeX = (math.sin(crackVal * 100) * intensity);
                      shakeY = (math.cos(crackVal * 120) * intensity);
                    }

                    return Opacity(
                      opacity: bgOpacity,
                      child: Transform.translate(
                        offset: Offset(shakeX, shakeY),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ValueListenableBuilder<Offset>(
                          valueListenable: _pointerOffset,
                          builder: (context, pOffset, child) {
                            return RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _auroraController,
                                  _scanController,
                                ]),
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: TacticalGridPainter(
                                      scanProgress: _scanController.value,
                                      auroraProgress: _auroraController.value,
                                      pointerOffset: pOffset,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const Positioned.fill(
                        child: SnowfallOverlay(snowCount: 60, opacity: 0.4),
                      ),

                      ValueListenableBuilder<Offset>(
                        valueListenable: _pointerOffset,
                        builder: (context, pOffset, child) {
                          return RepaintBoundary(
                            child: AnimatedBuilder(
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
                            ),
                          );
                        },
                      ),

                      Center(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _assemblyController,
                            builder: (context, child) {
                              const double opacity =
                                  1.0; // EMERGENCY FORCE VISIBILITY
                              return Opacity(
                                opacity: opacity,
                                child: GestureDetector(
                                  onTap: _triggerCrackAndNavigate,
                                  behavior: HitTestBehavior.opaque,
                                  child: _buildPremiumLogo(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Scanning Status Overlay
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _assemblyController,
                      builder: (context, child) {
                        final double opacity = Curves.easeIn.transform(
                          (_assemblyController.value / 0.5).clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: opacity,
                          child: const AuthStatusPulse(),
                        );
                      },
                    ),
                  ),
                ),

                IgnorePointer(
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: _pointerOffset,
                    builder: (context, pOffset, child) {
                      return Stack(
                        children: [
                          RepaintBoundary(
                            child: AnimatedBuilder(
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
                          ),
                          RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _crackController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ShockwavePainter(
                                    progress: _crackController.value,
                                  ),
                                  size: Size.infinite,
                                );
                              },
                            ),
                          ),
                          RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _crackController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: IceFlashPainter(
                                    progress: _crackController.value,
                                  ),
                                  size: Size.infinite,
                                );
                              },
                            ),
                          ),
                          RepaintBoundary(
                            child: AnimatedBuilder(
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
                          ),
                        ],
                      );
                    },
                  ),
                ),

                if (_isCracking)
                  AnimatedBuilder(
                    animation: _crackController,
                    builder: (context, child) {
                      final double flashOpacity = Curves.easeInQuint.transform(
                        ((_crackController.value - 0.85) / 0.15).clamp(
                          0.0,
                          1.0,
                        ),
                      );
                      return Container(
                        color: Colors.white.withValues(alpha: flashOpacity),
                      );
                    },
                  ),

                _buildAuthUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _crackController,
        _chargeController,
        _spinController,
        _auroraController,
        _assemblyController, // Ensure we respond to the fade-in threshold
        _pointerOffset,
      ]),
      builder: (context, child) {
        final double crackVal = _crackController.value;
        final double chargeVal = _chargeController.value;
        final Offset pOffset = _pointerOffset.value;

        final double snapScale = (crackVal > 0 && crackVal < 0.2)
            ? (1.0 - math.sin(crackVal * math.pi * 5) * 0.1)
            : 1.0;

        final double scale =
            (1.0 + math.sin(_pulseController.value * math.pi) * 0.1) *
            (1.0 + chargeVal * 0.2) *
            (1.0 - crackVal * 0.15) *
            snapScale;

        final double shake = chargeVal > 0 && crackVal < 0.1
            ? (math.sin(chargeVal * 50) * 5 * chargeVal)
            : 0;

        final double opacity = (1.0 - (crackVal * 2.8)).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(shake + pOffset.dx * 20, pOffset.dy * 20),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle:
                        (_spinController.value * 2 * math.pi) +
                        (_auroraController.value * 0.5 * math.pi) +
                        (chargeVal * 2 * math.pi) +
                        (crackVal * math.pi),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Glow
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: EntryColors.arcticSilver.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          size: const Size(
                            400,
                            400,
                          ), // Larger viewbox to prevent clipping
                          painter: SymmetricPetalPainter(
                            color: EntryColors
                                .arcticSilver, // Restoring premium color
                            pulse: _pulseController.value,
                            transformProgress: crackVal.clamp(0.0, 1.0),
                          ),
                        ),
                      ],
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
      final isUnauthed =
          status == AuthStatus.unauthenticated || status == AuthStatus.failed;

      if (!_isAssemblyDone || _isCracking) return const SizedBox.shrink();

      return Positioned(
        bottom: 80,
        left: 32,
        right: 32,
        child: FadeTransition(
          opacity: _assemblyController.drive(
            CurveTween(curve: const Interval(0.9, 1.0, curve: Curves.easeIn)),
          ),
          child: Column(
            children: [
              if (isUnauthed) ...[
                _buildPremiumGmailButton(),
                const SizedBox(height: 32),
                if (remembered == null) _buildLegacyIconButton(),
              ],

              if (status == AuthStatus.authenticating ||
                  status == AuthStatus.checkingSession)
                const AuthStatusPulse(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPremiumGmailButton() {
    return InkWell(
      onTap: () => _authBlock.signInWithGoogle(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_"G"_logo.svg',
              height: 28,
              width: 28,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, color: Colors.black, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyIconButton() {
    return IconButton(
      onPressed: () => context.push('/login'),
      icon: Icon(
        Icons.vpn_key_outlined,
        color: EntryColors.midSilver.withValues(alpha: 0.3),
        size: 20,
      ),
    );
  }
}

class AuthStatusPulse extends StatefulWidget {
  const AuthStatusPulse({super.key});

  @override
  State<AuthStatusPulse> createState() => _AuthStatusPulseState();
}

class _AuthStatusPulseState extends State<AuthStatusPulse>
    with SingleTickerProviderStateMixin {
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
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Color(0xFF00B4D8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
