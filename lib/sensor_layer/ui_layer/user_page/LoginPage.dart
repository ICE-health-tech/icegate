import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/IceDiamondBackground.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

// Components
import 'login_components/LoginDecorations.dart';
import 'login_components/LoginFields.dart';
import 'login_components/LoginButtons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Cyberpunk "route rings" background: broken arcs + orbit dots.
/// Kept subtle and low-frequency to avoid distracting from the CTA.
class _CyberRouteRings extends StatelessWidget {
  final Animation<double> t;
  const _CyberRouteRings({required this.t});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: t,
        builder: (context, child) {
          return CustomPaint(
            painter: _CyberRouteRingsPainter(progress: t.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _CyberRouteRingsPainter extends CustomPainter {
  final double progress;
  _CyberRouteRingsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.36);
    // "Impact" point like the reference crack/ring HUD.
    final impact = Offset(size.width * 0.58, size.height * 0.25);
    final base = math.min(size.width, size.height);

    // Paints
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Shatter rays (Cyclepunk / cracked-glass vibe)
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final impactGlow = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus;

    // 3 rings: each has a slightly different speed + dash pattern
    final rings = <_RingSpec>[
      _RingSpec(r: base * 0.36, w: 1.3, a: 0.14, speed: 0.55),
      _RingSpec(r: base * 0.46, w: 1.0, a: 0.11, speed: -0.32),
      _RingSpec(r: base * 0.58, w: 0.9, a: 0.09, speed: 0.22),
    ];

    // Impact glow + tiny core dot
    impactGlow.shader = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.22),
        EntryColors.iceCyan.withValues(alpha: 0.12),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 1.0],
    ).createShader(Rect.fromCircle(center: impact, radius: base * 0.22));
    canvas.drawCircle(impact, base * 0.22, impactGlow);
    dotPaint.color = Colors.white.withValues(alpha: 0.65);
    canvas.drawCircle(impact, 1.8, dotPaint);

    // Rays: multiple thin cracks + a few thicker "shards"
    final rayLen = base * 0.62;
    for (int i = 0; i < 18; i++) {
      final a = (i / 18) * math.pi * 2 + math.sin(progress * math.pi * 2) * 0.06;
      final jitter = math.sin((impact.dx + impact.dy) * 0.002 + i * 1.7) * 0.035;
      final start = impact + Offset(math.cos(a) * (base * 0.02), math.sin(a) * (base * 0.02));
      final end = impact + Offset(math.cos(a + jitter) * (rayLen * (0.35 + (i % 5) * 0.1)), math.sin(a + jitter) * (rayLen * (0.35 + (i % 5) * 0.1)));

      final thick = (i % 6 == 0);
      rayPaint
        ..strokeWidth = thick ? 1.6 : 0.85
        ..color = (thick ? Colors.white : EntryLandscapePalette.dustySkyBlue)
            .withValues(alpha: thick ? 0.11 : 0.08);
      canvas.drawLine(start, end, rayPaint);

      // Occasional side-branch
      if (i % 4 == 0) {
        final b = a + (i.isEven ? 0.35 : -0.32);
        final mid = Offset.lerp(start, end, 0.55)!;
        final bend = mid + Offset(math.cos(b) * base * 0.08, math.sin(b) * base * 0.08);
        rayPaint
          ..strokeWidth = 0.7
          ..color = Colors.white.withValues(alpha: 0.06);
        final p = Path()..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(bend.dx, bend.dy, end.dx, end.dy);
        canvas.drawPath(p, rayPaint);
      }
    }

    for (final spec in rings) {
      final rot = (progress * math.pi * 2) * spec.speed;

      ringPaint
        ..strokeWidth = spec.w
        ..color = EntryColors.iceCyan.withValues(alpha: spec.a);

      // Broken arcs
      _drawArcSegment(canvas, center, spec.r, rot + 0.15, 0.9, ringPaint);
      _drawArcSegment(canvas, center, spec.r, rot + 1.55, 0.55, ringPaint);
      _drawArcSegment(canvas, center, spec.r, rot + 2.55, 0.75, ringPaint);

      // Add a couple of arcs centered around impact (reference-like)
      ringPaint.color = Colors.white.withValues(alpha: spec.a * 0.42);
      final around = math.atan2(impact.dy - center.dy, impact.dx - center.dx);
      _drawArcSegment(canvas, center, spec.r, around - 0.35 + rot * 0.1, 0.6, ringPaint);

      // Secondary faint ring to feel "etched"
      ringPaint.color = Colors.white.withValues(alpha: spec.a * 0.35);
      _drawArcSegment(canvas, center, spec.r, rot + 0.75, 0.22, ringPaint);
      _drawArcSegment(canvas, center, spec.r, rot + 3.65, 0.18, ringPaint);

      // Orbit dot (like a router packet)
      final theta = rot + 0.35;
      final dot = Offset(
        center.dx + math.cos(theta) * spec.r,
        center.dy + math.sin(theta) * spec.r,
      );
      dotPaint.color = EntryColors.iceCyan.withValues(alpha: spec.a * 2.2);
      canvas.drawCircle(dot, 2.2, dotPaint);
    }

    // Subtle connector lines ("routes")
    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = EntryLandscapePalette.dustySkyBlue.withValues(alpha: 0.08);

    final p1 = Offset(center.dx - base * 0.22, center.dy + base * 0.02);
    final p2 = Offset(center.dx + base * 0.26, center.dy - base * 0.06);
    final p3 = Offset(center.dx + base * 0.06, center.dy + base * 0.22);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(center.dx, center.dy - base * 0.08, p2.dx, p2.dy)
      ..quadraticBezierTo(center.dx + base * 0.18, center.dy + base * 0.12, p3.dx, p3.dy);
    canvas.drawPath(path, routePaint);
  }

  void _drawArcSegment(
    Canvas canvas,
    Offset center,
    double radius,
    double start,
    double sweep,
    Paint paint,
  ) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CyberRouteRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RingSpec {
  final double r;
  final double w;
  final double a;
  final double speed;
  _RingSpec({required this.r, required this.w, required this.a, required this.speed});
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Animation Controllers for various "UPLINK" effects
  late AnimationController _hudRotationController;
  late AnimationController _logoPulseController;
  late AnimationController _scanController;
  late AnimationController _appearanceController;
  late AnimationController _shineController;
  late AnimationController _ringFastController;
  late AnimationController _ringMidController;
  late AnimationController _ringSlowController;

  late AuthBlock _authBlock;
  late final void Function() _disposeEffect;

  @override
  void initState() {
    super.initState();
    _authBlock = context.read<AuthBlock>();

    // Initializing complex background and tech animations
    _hudRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _ringFastController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _ringMidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    _ringSlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();

    // Redirect when authenticated
    _disposeEffect = effect(() {
      if (_authBlock.status.value == AuthStatus.authenticated) {
        if (mounted) {
          context.go('/intro');
        }
      }
    });
  }

  @override
  void dispose() {
    _disposeEffect();
    _hudRotationController.dispose();
    _logoPulseController.dispose();
    _scanController.dispose();
    _appearanceController.dispose();
    _shineController.dispose();
    _ringFastController.dispose();
    _ringMidController.dispose();
    _ringSlowController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final status = _authBlock.status.value;
      final error = _authBlock.error.value;
      /// Locks inputs/footer while session is restoring or a login is in flight.
      final controlsLocked =
          status == AuthStatus.authenticating ||
          status == AuthStatus.registering ||
          status == AuthStatus.checkingSession;
      /// Spinner on primary CTA only during active login/OAuth — not during session check.
      final primaryShowsSpinner =
          status == AuthStatus.authenticating ||
          status == AuthStatus.registering;

      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF000510),
        body: IceDiamondBackground(
          particleCount: 110,
          child: Stack(
            children: [
              // 0. Cyberpunk route rings (Cyclepunk vibe)
              Positioned.fill(
                child: _CyberRouteRings(t: _hudRotationController),
              ),

              // 1. Tech Background Ornaments
              _buildBackgroundOrnaments(),
              
              // 2. Main Login Content
              Center(
                child: FadeTransition(
                  opacity: _appearanceController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _appearanceController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EntryConstraints.loginScrollPadding,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPremiumMainCard(
                                controlsLocked,
                                primaryShowsSpinner,
                                error,
                                context,
                              ),
                              const SizedBox(height: 40),
                              _buildLoginFooter(controlsLocked, context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBackgroundOrnaments() {
    return Stack(
      children: [
        Positioned(
          bottom: -100,
          right: -100,
          child: RotationTransition(
            turns: _ringSlowController,
            child: const SpinningRing(size: 500, opacity: 0.1, isClockwise: true),
          ),
        ),
        Positioned(
          top: -50,
          left: -80,
          child: RotationTransition(
            turns: _ringMidController,
            child: const SpinningRing(size: 380, opacity: 0.12, isClockwise: false),
          ),
        ),
        Positioned(
          top: 300,
          left: -120,
          child: RotationTransition(
            turns: _ringFastController,
            child: const SpinningRing(size: 250, opacity: 0.08, isClockwise: true),
          ),
        ),
        Positioned(
          top: -100,
          right: -100,
          child: RepaintBoundary(
            child: RotationTransition(
              turns: _hudRotationController,
              child: CoolerHUD(
                size: 400,
                color: EntryLandscapePalette.mutedSlateBlue.withValues(
                  alpha: 0.12,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: RepaintBoundary(
            child: RotationTransition(
              turns: Tween<double>(begin: 1.0, end: 0.0).animate(_hudRotationController),
              child: CoolerHUD(
                size: 500,
                color: EntryLandscapePalette.dustySkyBlue.withValues(
                  alpha: 0.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumMainCard(
    bool controlsLocked,
    bool primaryShowsSpinner,
    String? error,
    BuildContext context,
  ) {
    // No 3D transform: perspective + BackdropFilter causes mirrored backdrop artifacts on iOS.
    // Shine/scan overlays use Positioned.fill so they cannot paint outside the card or over the footer.
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF122536).withValues(alpha: 0.94),
                    const Color(0xFF050912).withValues(alpha: 0.97),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
                border: Border.all(
                  color: EntryLandscapePalette.icyWhiteBlue.withValues(alpha: 0.42),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.72),
                    blurRadius: 56,
                    offset: const Offset(0, 32),
                    spreadRadius: -6,
                  ),
                  BoxShadow(
                    color: EntryColors.iceCyan.withValues(alpha: 0.18),
                    blurRadius: 36,
                    offset: const Offset(0, -6),
                    spreadRadius: -14,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -2),
                    spreadRadius: -16,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Bevel + vignette overlays to create 3D depth (no perspective transforms).
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                            stops: const [0.0, 0.38, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: RadialGradient(
                            center: const Alignment(-0.25, -0.55),
                            radius: 1.05,
                            colors: [
                              EntryColors.iceCyan.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    children: [
                      _buildAnimatedLogo(),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.app_title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8.0,
                          color: const Color(0xFFF5FBFF),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.85),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                            Shadow(
                              color: EntryColors.iceCyan.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: Offset.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (error != null) _buildErrorMessage(error),

                      ModernAuthField(
                        controller: _emailController,
                        hint: AppLocalizations.of(context)!.username_email_hint,
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      ModernAuthField(
                        controller: _passwordController,
                        hint: AppLocalizations.of(context)!.password_hint,
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              controlsLocked
                                  ? null
                                  : () => _showForgotPasswordDialog(context),
                          child: Text(
                            AppLocalizations.of(context)!.forgot_password,
                            style: TextStyle(
                              color: const Color(0xFFCBE9FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFFCBE9FF)
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
             

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: ShimmerButton(
                            label: AppLocalizations.of(context)!.btn_enter,
                            isLoading: primaryShowsSpinner,
                            onPressed: _handleLogin,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildAlternativeAuthRow(controlsLocked, context),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _shineController,
                builder: (context, child) => CustomPaint(
                  painter: ShinePainter(progress: _shineController.value),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) => CustomPaint(
                  painter: ScanlinePainter(progress: _scanController.value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoPulseController,
      builder: (context, child) {
        final double glow = 30 + math.sin(_logoPulseController.value * math.pi) * 20;
        final double scale = 1.0 + math.sin(_logoPulseController.value * math.pi) * 0.05;
        // Subtle 3D spin (perspective tilt) for the crystal mark.
        final t = _logoPulseController.value;
        final double rotY = math.sin(t * math.pi * 2) * 0.28;
        final double rotX = math.cos(t * math.pi * 2) * 0.16;

        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.22),
                blurRadius: glow,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateX(rotX)
              ..rotateY(rotY),
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'assets/images/crystal_logo2.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlternativeAuthRow(bool isLoading, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: AuthIconButton(
            pillarKey: 'health',
            icon: Icons.fingerprint_rounded,
            label: 'Face ID',
            onPressed: isLoading ? null : _handleSecureLogin,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthIconButton(
            pillarKey: 'mind',
            icon: Icons.apple_rounded,
            label: l10n.apple_login,
            onPressed: isLoading ? null : _handleAppleSignIn,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthIconButton(
            pillarKey: 'google',
            leading: AuthIconButton.googleMark(),
            label: l10n.google_login,
            onPressed: isLoading ? null : _handleGoogleSignIn,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getLocalizedError(context, error),
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedError(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    // Allow `AuthBlock` to pass through unexpected error details while still
    // mapping to the localized `err_unexpected` template.
    if (key.startsWith('err_unexpected|')) {
      final details = key.substring('err_unexpected|'.length);
      return l10n.err_unexpected(details.isEmpty ? 'System Error' : details);
    }
    switch (key) {
      case "err_invalid_credentials": return l10n.err_invalid_credentials;
      case "err_email_not_confirmed": return l10n.err_email_not_confirmed;
      case "err_user_not_found": return l10n.err_user_not_found;
      case "err_network_fail": return l10n.err_network_fail;
      case "err_auth_timeout": return l10n.err_auth_timeout;
      case "err_passkey_canceled": return l10n.err_passkey_canceled;
      case "err_passkey_failed": return l10n.err_passkey_failed;
      case "err_google_canceled": return l10n.err_google_canceled;
      case "err_google_failed": return l10n.err_google_failed;
      case "err_biometric_unsupported": return l10n.err_biometric_unsupported;
      case "err_biometric_disabled": return l10n.err_biometric_disabled;
      case "err_too_many_attempts": return l10n.err_too_many_attempts;
      case "err_unexpected": return l10n.err_unexpected("System Error");
      case "err_forgot_password_empty_email":
        return l10n.err_forgot_password_empty_email;
      case "err_forgot_password_invalid_email":
        return l10n.err_forgot_password_invalid_email;
      default: return key;
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final emailCtrl = TextEditingController(text: _emailController.text.trim());

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: EntryLandscapePalette.midnightNavy,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.forgot_password_title,
            style: const TextStyle(
              color: EntryLandscapePalette.icyWhiteBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.forgot_password_body,
                  style: TextStyle(
                    fontSize: 14,
                    color: EntryLandscapePalette.dustySkyBlue.withValues(alpha: 0.92),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(
                    color: EntryLandscapePalette.icyWhiteBlue,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.username_email_hint,
                    labelStyle: TextStyle(
                      color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.95),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: EntryLandscapePalette.mutedSlateBlue.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: EntryLandscapePalette.steelBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: EntryLandscapePalette.dustySkyBlue.withValues(alpha: 0.95),
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: EntryLandscapePalette.steelBlue,
                foregroundColor: EntryLandscapePalette.midnightNavy,
              ),
              onPressed: () async {
                final err = await _authBlock.requestPasswordReset(
                  emailCtrl.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      err == null
                          ? l10n.forgot_password_success
                          : _getLocalizedError(context, err),
                    ),
                    backgroundColor:
                        err == null ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                );
              },
              child: Text(l10n.forgot_password_send),
            ),
          ],
        );
      },
    );

    emailCtrl.dispose();
  }

  Widget _buildLoginFooter(bool isLoading, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: isLoading ? null : _handleGuestLogin,
          child: Text(
            AppLocalizations.of(context)!.guest_access.toUpperCase(),
            style: TextStyle(
              color: EntryLandscapePalette.icyWhiteBlue.withValues(alpha: 0.42),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 4, height: 4,
            decoration: BoxDecoration(
            color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: isLoading ? null : () => context.push('/register'),
          child: Text(
            AppLocalizations.of(context)!.enroll_hub.toUpperCase(),
            style: const TextStyle(
              color: EntryLandscapePalette.dustySkyBlue,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  // Auth Handlers
  Future<void> _handleSecureLogin() async {
    FocusScope.of(context).unfocus();
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      final emailHint = _emailController.text.trim();
      await _authBlock.loginWithQuickAccess(
        context,
        emailHint: emailHint.isEmpty ? null : emailHint,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.msg_secure_login_failed(
                e.toString(),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.msg_enter_credentials)),
      );
      return;
    }
    await _authBlock.login(email, password, context);
  }

  Future<void> _handleGuestLogin() async => await _authBlock.loginAsGuest();

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    await _authBlock.signInWithGoogle();
  }

  Future<void> _handleAppleSignIn() async {
    try {
      await _authBlock.signInWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.apple_signin_error(e.toString()))),
        );
      }
    }
  }
}
