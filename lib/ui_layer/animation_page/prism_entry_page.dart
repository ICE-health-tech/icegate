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

  final ValueNotifier<Offset> _pointerOffset = ValueNotifier(Offset.zero);

  final List<PrismShard> _shards = [];
  final int _shardCount = 80;
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
      final double distance = 400 + _random.nextDouble() * 700;

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

    // 1. Glass Cracks - Minimal & Cinematic (Center Epicenter)
    const int crackCount = 9; 
    final List<List<Offset>> allRadialPoints = [];
    
    // A. Main radial fractures
    for (int i = 0; i < crackCount; i++) {
      final impactOrigin = Offset.zero;
      final double angle = (i / crackCount) * 2 * math.pi + random.nextDouble() * 0.2;
      final List<Offset> mainPoints = [impactOrigin];
      double currentDist = 0;
      double currentAngle = angle;

      while (currentDist < 5.0) {
        currentAngle += (random.nextDouble() - 0.5) * 0.15;
        currentDist += 0.3 + random.nextDouble() * 0.6; 
        final p = impactOrigin +
            Offset(math.cos(currentAngle) * currentDist,
                math.sin(currentAngle) * currentDist);
        mainPoints.add(p);
      }
      allRadialPoints.add(mainPoints);
      _cachedGlassCracks.add(GlassCrackData(points: mainPoints));
    }

    // B. Connecting spiderweb web lines
    for (int i = 0; i < crackCount; i++) {
      final List<Offset> currentRadial = allRadialPoints[i];
      final List<Offset> nextRadial = allRadialPoints[(i + 1) % crackCount];
      for (int j = 1; j < currentRadial.length && j < nextRadial.length; j += 2) {
        if (random.nextDouble() > 0.4) {
           final Offset p1 = currentRadial[j];
           final Offset p2 = nextRadial[j];
           final Offset mid = Offset.lerp(p1, p2, 0.5 + (random.nextDouble() - 0.5) * 0.4)!;
           final Offset jaggedMid = mid + Offset((random.nextDouble() - 0.5) * 0.1, (random.nextDouble() - 0.5) * 0.1);
           _cachedGlassCracks.add(GlassCrackData(points: [p1, jaggedMid, p2]));
        }
      }
    }

    // 2. Massive Splinter Shards
    const int largeParticleCount = 70;
    for (int i = 0; i < largeParticleCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 1800 + random.nextDouble() * 3200;

      final double length = 180 + random.nextDouble() * 220;
      final double width = 30 + random.nextDouble() * 70;
      
      final List<Offset> points = [
        Offset(-width / 2, -length / 2),
        Offset(width / 2, -length / 2 + random.nextDouble() * 50),
        Offset(random.nextDouble() * width - width / 2, length / 2),
      ];
      
      if (random.nextBool()) points.add(Offset(-width / 2 - random.nextDouble() * 30, 0));

      _cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: points,
          rotationSpeed: (random.nextDouble() - 0.5) * 35,
          color: Colors.white.withValues(alpha: 0.85 + random.nextDouble() * 0.15),
          delay: random.nextDouble() * 0.2,
          tier: ParticleTier.large,
        ),
      );
    }

    // Tier 2: Frost/Dust splinters
    const int dustCount = 120;
    for (int i = 0; i < dustCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 1000 + random.nextDouble() * 4000;
      final double w = 4 + random.nextDouble() * 6;
      final double l = 15 + random.nextDouble() * 25;
      _cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: [Offset(-w/2, -l/2), Offset(w/2, -l/2), Offset(0, l/2)],
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
    _crackController.forward();

    Future.delayed(
      const Duration(milliseconds: 150),
      () => HapticFeedback.vibrate(),
    );

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
    _pointerOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntryColors.obsidianBase,
      body: Listener(
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
                  final double bgOpacity =
                      (1.0 - (_crackController.value * 1.5)).clamp(0.0, 1.0);
                  return Opacity(opacity: bgOpacity, child: child);
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
                      ((_crackController.value - 0.85) / 0.15).clamp(0.0, 1.0),
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
    );
  }

  Widget _buildPremiumLogo() {
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
                    angle: (_auroraController.value * 2 * math.pi) +
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
                                  color: EntryColors.arcticSilver.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          CustomPaint(
                            size: const Size(130, 130),
                            painter: SymmetricPetalPainter(
                              color: EntryColors.arcticSilver,
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
                const SizedBox(height: 24),
                if (remembered == null) _buildLegacyTextButton(),
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
              height: 22,
              width: 22,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, color: Colors.black),
            ),
            const SizedBox(width: 16),
            const Text(
              "GMAIL FAST TRACK",
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyTextButton() {
    return TextButton(
      onPressed: () => context.push('/login'),
      child: Text(
        "LEGACY PROTOCOL",
        style: TextStyle(
          color: EntryColors.midSilver.withValues(alpha: 0.4),
          fontSize: 10,
          letterSpacing: 3,
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
      child: Container(
        padding: const EdgeInsets.all(12),
        child: const Text("SCANNING...", style: EntryStyles.authStatus),
      ),
    );
  }
}
