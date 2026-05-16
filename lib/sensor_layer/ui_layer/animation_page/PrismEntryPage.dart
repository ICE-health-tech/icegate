import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

import 'components/EntryConstants.dart';
import 'components/EntryGeometry.dart';
import 'components/PrismBackground.dart';
import 'components/PrismPainters.dart';

class PrismEntryPage extends StatefulWidget {
  const PrismEntryPage({super.key});

  @override
  State<PrismEntryPage> createState() => _PrismEntryPageState();
}

class _PrismEntryPageState extends State<PrismEntryPage>
    with TickerProviderStateMixin {
  late AnimationController _assemblyController;
  late AnimationController _pulseController;
  late AnimationController _auroraController;
  late AnimationController _scanController;
  late AnimationController _spinController;
  late AnimationController _crackController;
  late AnimationController _chargeController;

  final ValueNotifier<Offset> _pointerOffset = ValueNotifier(Offset.zero);
  late final List<PrismShard> _assemblyShards;

  final List<ScatteringParticleData> _cachedParticles = [];

  bool _exitInProgress = false;
  bool _isAssemblyDone = false;
  late AuthBlock _authBlock;
  late final void Function() _disposeStatusEffect;
  late final void Function() _disposeErrorEffect;

  @override
  void initState() {
    super.initState();
    _authBlock = context.read<AuthBlock>();
    _assemblyShards = EntryGeometry.generateShardsOnly(
      80,
      seed: 17,
      winterShardHints: true,
    );
    _precalculateExitParticles();

    _assemblyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _crackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _assemblyController.forward().then((_) {
      if (mounted) {
        setState(() => _isAssemblyDone = true);
        _onAssemblyComplete();
      }
    });

    _disposeStatusEffect = effect(() {
      final status = _authBlock.status.value;
      if (status == AuthStatus.authenticated &&
          _isAssemblyDone &&
          !_exitInProgress) {
        _playElegantExit();
      }
    });

    _disposeErrorEffect = effect(() {
      final error = _authBlock.error.value;
      if (error != null && mounted) {
        _showLoginError(error);
        // Clear the error after showing it to avoid repeated notifications if logic triggers again
        Future.microtask(() => _authBlock.error.value = null);
      }
    });
  }

  void _showLoginError(String error) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final String localizedError = _getLocalizedError(context, error);
    final String message =
        l10n?.msg_secure_login_failed(localizedError) ??
        "Login failed: $localizedError";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EntryConstraints.snackBarFloatingMargin,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getLocalizedError(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;

    switch (key) {
      case "err_invalid_credentials":
        return l10n.err_invalid_credentials;
      case "err_email_not_confirmed":
        return l10n.err_email_not_confirmed;
      case "err_user_not_found":
        return l10n.err_user_not_found;
      case "err_network_fail":
        return l10n.err_network_fail;
      case "err_passkey_canceled":
        return l10n.err_passkey_canceled;
      case "err_passkey_failed":
        return l10n.err_passkey_failed;
      case "err_biometric_unsupported":
        return l10n.err_biometric_unsupported;
      case "err_biometric_disabled":
        return l10n.err_biometric_disabled;
      case "err_too_many_attempts":
        return l10n.err_too_many_attempts;
      case "err_unexpected":
        return l10n.err_unexpected("System Error");
      default:
        return key; // Fallback to raw string if not a known key
    }
  }

  void _onAssemblyComplete() async {
    HapticFeedback.heavyImpact();

    final status = _authBlock.status.value;

    if (status == AuthStatus.authenticated) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _playElegantExit();
      });
      return;
    }

    // AUTO-LOGIN DISABLED: The user should click "Fingerprint" or "Gmail" manually
    // to avoid intrusive popups upon entry.
  }

  /// Charge pulse, flash / shatter VFX, then route (no fracture lines).
  void _playElegantExit() async {
    if (_exitInProgress) return;
    setState(() => _exitInProgress = true);

    HapticFeedback.lightImpact();
    await _chargeController.forward();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    _crackController.forward();
    await Future.delayed(const Duration(milliseconds: 1220));
    if (!mounted) return;
    if (_authBlock.status.value == AuthStatus.authenticated) {
      context.go('/', extra: 'from_entry');
    } else {
      context.go('/login');
    }
  }

  void _precalculateExitParticles() {
    final random = math.Random(
      DateTime.now().millisecondsSinceEpoch ^
          DateTime.now().microsecondsSinceEpoch,
    );

    const int dustCount = 52;
    for (int i = 0; i < dustCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 1100 + random.nextDouble() * 1900;
      final double w = 0.45 + random.nextDouble() * 0.85;
      final double l = 7 + random.nextDouble() * 14;
      final startDist = 50 + random.nextDouble() * 140;
      _cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: [
            Offset(0, -l / 2),
            Offset(w / 2, 0),
            Offset(0, l / 2),
            Offset(-w / 2, 0),
          ],
          rotationSpeed: 72,
          color: EntryColors.iceCyan.withValues(alpha: 0.35),
          delay: random.nextDouble() * 0.35,
          initialDistance: startDist,
          distRank: (startDist / 190.0).clamp(0.0, 1.0),
          tier: ParticleTier.dust,
          noiseSeed: random.nextDouble() * 100.0,
        ),
      );
    }

    const int shrapnelCount = 30;
    for (int i = 0; i < shrapnelCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 1700 + random.nextDouble() * 2200;
      final double size = 11 + random.nextDouble() * 16;

      final startDist = 55 + random.nextDouble() * 120;
      _cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: [
            Offset(0, -size / 2),
            Offset(size / 3, 0),
            Offset(0, size / 2),
            Offset(-size / 3, -size / 4),
          ],
          rotationSpeed: (random.nextDouble() - 0.5) * 40,
          color: EntryColors.primaryIceLight,
          delay: random.nextDouble() * 0.18,
          initialDistance: startDist,
          distRank: (startDist / 175.0).clamp(0.0, 1.0),
          tier: ParticleTier.shrapnel,
          noiseSeed: random.nextDouble() * 100.0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposeStatusEffect();
    _disposeErrorEffect();
    _assemblyController.dispose();
    _pulseController.dispose();
    _auroraController.dispose();
    _scanController.dispose();
    _spinController.dispose();
    _crackController.dispose();
    _chargeController.dispose();
    _pointerOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        decoration: const BoxDecoration(
          gradient: EntryColors.winterEntryVivid,
        ),
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
                IgnorePointer(
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: _pointerOffset,
                    builder: (context, pOffset, _) {
                      return AnimatedBuilder(
                        animation: _chargeController,
                        builder: (context, _) {
                          if (_chargeController.value <= 0) {
                            return const SizedBox.shrink();
                          }
                          return CustomPaint(
                            painter: IceGateChargePulsePainter(
                              progress: _chargeController.value,
                              pointerOffset: pOffset,
                            ),
                            size: Size.infinite,
                          );
                        },
                      );
                    },
                  ),
                ),
                AnimatedBuilder(
                  animation: _crackController,
                  builder: (context, child) {
                    final double c = _crackController.value;
                    final double bgOpacity = (1.0 - (c * 1.12)).clamp(0.0, 1.0);
                    double shakeX = 0;
                    double shakeY = 0;
                    if (c > 0 && c < 0.17) {
                      final double k = (1.0 - (c / 0.17)) * 6.2;
                      shakeX = math.sin(c * 86) * k;
                      shakeY = math.cos(c * 94) * k;
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
                        child: PrismBackground(
                          auroraController: _auroraController,
                          scanController: _scanController,
                          assemblyController: _assemblyController,
                          pulseController: _pulseController,
                          shards: _assemblyShards,
                          pointerOffset: _pointerOffset,
                          snowOpacity: 0.18,
                        ),
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
                                  onTap: _playElegantExit,
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
                                  painter: ShockwavePainter(
                                    progress: _crackController.value,
                                    refined: true,
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
                                    refined: true,
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
                                    refined: true,
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

                if (_exitInProgress)
                  AnimatedBuilder(
                    animation: _crackController,
                    builder: (context, child) {
                      final double flashOpacity = Curves.easeOut.transform(
                        ((_crackController.value - 0.76) / 0.22).clamp(
                          0.0,
                          1.0,
                        ),
                      );
                      return Container(
                        color: Colors.white.withValues(alpha: flashOpacity * 0.55),
                      );
                    },
                  ),

                // 3. Scanning Status Overlay
                // Positioned(
                //   bottom: 80,
                //   left: 0,
                //   right: 0,
                //   child: Center(
                //     child: AnimatedBuilder(
                //       animation: _assemblyController,
                //       builder: (context, child) {
                //         final double opacity = Curves.easeIn.transform(
                //           (_assemblyController.value / 0.5).clamp(0.0, 1.0),
                //         );
                //         return Opacity(
                //           opacity: opacity,
                //           child: const AuthStatusPulse(),
                //         );
                //       },
                //     ),
                //   ),
                // ),
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
        _spinController,
        _auroraController,
        _assemblyController,
        _pointerOffset,
        _crackController,
        _chargeController,
      ]),
      builder: (context, child) {
        final Offset pOffset = _pointerOffset.value;
        final double crackVal = _crackController.value;
        final double chargeVal = _chargeController.value;

        final double snapScale = (crackVal > 0 && crackVal < 0.2)
            ? (1.0 - math.sin(crackVal * math.pi * 5.5) * 0.09)
            : 1.0;

        final double scale =
            (1.0 + math.sin(_pulseController.value * math.pi) * 0.1) *
            (1.0 + chargeVal * 0.16) *
            (1.0 - crackVal * 0.14) *
            snapScale;

        final double shake =
            chargeVal > 0 && crackVal < 0.1
                ? (math.sin(chargeVal * 52) * 5.2 * chargeVal)
                : 0;

        final double opacity = (1.0 - (crackVal * 2.35)).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(shake + pOffset.dx * 18, pOffset.dy * 18),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: (_spinController.value * 2 * math.pi) +
                        (_auroraController.value * 0.5 * math.pi) +
                        (chargeVal * 1.45 * math.pi) +
                        (crackVal * 1.05 * math.pi),
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
                                color: EntryColors.winterMoonCore.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 48,
                                spreadRadius: 12,
                              ),
                              BoxShadow(
                                color: EntryColors.primaryIceLight.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/iceflowerlogo.png',
                          width: 200,
                          height: 200,
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
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 72, 64, 218).withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EntryColors.winterMoonCore.withValues(alpha: 0.9),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
