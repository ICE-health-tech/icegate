import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SnowSilverBackground.dart';
import 'package:ice_gate/ui_layer/animation_page/components/entry_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
      final isLoading =
          status == AuthStatus.authenticating ||
          status == AuthStatus.registering ||
          status == AuthStatus.checkingSession;

      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: EntryColors.obsidianBase,
        body: SnowSilverBackground(
          // Note: We can tint this with the ornaments
          child: Stack(
            children: [
              // 1. Floating Tech Ornaments
              _buildTechOrnaments(),

              // 2. Main Content
              Center(
                child: FadeTransition(
                  opacity: _appearanceController,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _appearanceController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMainCard(isLoading, error, context),
                          const SizedBox(height: 40),
                          _buildFooter(isLoading, context),
                        ],
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

  Widget _buildTechOrnaments() {
    return Stack(
      children: [
        // 1. Slow Bottom-Right Large Ring
        Positioned(
          bottom: -100,
          right: -100,
          child: RotationTransition(
            turns: _ringSlowController,
            child: const _SpinningRing(
              size: 500,
              opacity: 0.1,
              isClockwise: true,
            ),
          ),
        ),

        // 2. Mid Top-Left Ring
        Positioned(
          top: -50,
          left: -80,
          child: RotationTransition(
            turns: _ringMidController,
            child: const _SpinningRing(
              size: 380,
              opacity: 0.12,
              isClockwise: false,
            ),
          ),
        ),

        // 3. Fast Small Center-Left Ring
        Positioned(
          top: 300,
          left: -120,
          child: RotationTransition(
            turns: _ringFastController,
            child: const _SpinningRing(
              size: 250,
              opacity: 0.08,
              isClockwise: true,
            ),
          ),
        ),

        Positioned(
          top: -100,
          right: -100,
          child: RepaintBoundary(
            child: RotationTransition(
              turns: _hudRotationController,
              child: _CoolerHUD(
                size: 400,
                color: EntryColors.arcticSilver.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: RepaintBoundary(
            child: RotationTransition(
              turns: Tween<double>(
                begin: 1.0,
                end: 0.0,
              ).animate(_hudRotationController),
              child: _CoolerHUD(
                size: 500,
                color: EntryColors.arcticSilver.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(bool isLoading, String? error, BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.03,
                ), // Ultra-frosted silver glass
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15), // Silver Glass Border
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: EntryColors.arcticSilver.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLogoSection(),
                  const SizedBox(height: 48),
                  if (error != null) _buildError(error),
                  _buildModernField(
                    controller: _emailController,
                    hint: AppLocalizations.of(context)!.username_email_hint,
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildModernField(
                    controller: _passwordController,
                    hint: AppLocalizations.of(context)!.password_hint,
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),
                  _buildLoginButton(isLoading, context),
                  const SizedBox(height: 24),
                  _buildAuthAlternatives(isLoading, context),
                ],
              ),
            ),
          ),
        ),
        IgnorePointer(child: RepaintBoundary(child: _buildShineSweep())),
        IgnorePointer(child: RepaintBoundary(child: _buildScanline())),
      ],
    );
  }

  Widget _buildScanline() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            width: double.infinity,
            height: 520,
            child: CustomPaint(
              painter: _ScanlinePainter(progress: _scanController.value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShineSweep() {
    return AnimatedBuilder(
      animation: _shineController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            width: double.infinity,
            height: 520, // Approximate height of the card
            child: CustomPaint(
              painter: _ShinePainter(progress: _shineController.value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _logoPulseController,
            builder: (context, child) {
              final double glow =
                  20 + math.sin(_logoPulseController.value * math.pi) * 15;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EntryColors.arcticSilver.withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: EntryColors.arcticSilver.withValues(alpha: 0.2),
                      blurRadius: glow,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: EntryColors.arcticSilver.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _logoPulseController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            EntryColors.arcticSilver.withValues(alpha: 0.8),
                            Colors.white,
                            EntryColors.arcticSilver.withValues(alpha: 0.8),
                          ],
                          stops: [
                            (_logoPulseController.value - 0.2).clamp(0.0, 1.0),
                            _logoPulseController.value,
                            (_logoPulseController.value + 0.2).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds);
                      },
                      child: Icon(
                        Icons.ac_unit_rounded,
                        size: 48,
                        color: EntryColors.arcticSilver,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE5E5EA), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'ICE GATE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 10.0,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthAlternatives(bool isLoading, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildIconButton(
            icon: Icons.fingerprint_rounded,
            label: "",
            onPressed: isLoading ? null : _handleSecureLogin,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildIconButton(
            icon: Icons.g_mobiledata_rounded,
            label: AppLocalizations.of(context)!.google_login,
            onPressed: isLoading ? null : _handleGoogleSignIn,
            isGmail: true,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
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
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading, BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color(0xFFE5E5EA), // Light Silver
            Color(0xFFA1A1A6), // Metallic Silver
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: EntryColors.arcticSilver.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(4, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _handleLogin();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.black, // Dark text on silver button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                'ENTER THE GATE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: Colors.black87,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter(bool isLoading, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: isLoading ? null : _handleGuestLogin,
          child: Text(
            AppLocalizations.of(context)!.guest_access,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF8E8E93).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () {},
          child: Text(
            AppLocalizations.of(context)!.enroll_hub,
            style: const TextStyle(
              color: Color(0xFFE5E5EA),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isGmail = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed?.call();
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: EntryColors.arcticSilver.withValues(alpha: 0.9),
                  size: isGmail ? 28 : 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label.split(' ').first, // Symbolic/Minimal label
                  style: TextStyle(
                    color: const Color(0xFFE5E5EA),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Color(0xFFE5E5EA),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
          decoration: InputDecoration(
            hintText: hint.toUpperCase(),
            hintStyle: TextStyle(
              color: const Color(0xFFE5E5EA).withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: EntryColors.arcticSilver.withValues(alpha: 0.8),
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: EntryColors.arcticSilver,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSecureLogin() async {
    FocusScope.of(context).unfocus();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final success = await _authBlock.loginWithBiometrics(context);
      if (!success && mounted) {
        await _authBlock.loginWithPasskey(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.msg_secure_login_failed(e.toString()),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.msg_enter_credentials),
        ),
      );
      return;
    }
    await _authBlock.login(email, password, context);
  }

  Future<void> _handleGuestLogin() async {
    await _authBlock.loginAsGuest();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _authBlock.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google Sign-In Error: $e')));
      }
    }
  }
}

class _CoolerHUD extends StatelessWidget {
  final Color color;
  final double size;
  const _CoolerHUD({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hexagon Ring
          CustomPaint(
            size: Size(size, size),
            painter: _HexagonPainter(color: color.withValues(alpha: 0.5)),
          ),
          // Dashed Ring
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
          ),
          // Crosshair
          for (int i = 0; i < 4; i++)
            Transform.rotate(
              angle: i * (math.pi / 2),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: size * 0.1,
                  margin: EdgeInsets.only(top: size * 0.05),
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final double radius = size.width / 2;
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * math.pi / 180;
      double x = size.width / 2 + radius * math.cos(angle);
      double y = size.height / 2 + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpinningRing extends StatelessWidget {
  final double size;
  final double opacity;
  final bool isClockwise;

  const _SpinningRing({
    required this.size,
    required this.opacity,
    required this.isClockwise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(opacity: opacity),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double opacity;

  _RingPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: opacity * 0.2),
              Colors.white.withValues(alpha: opacity * 0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw main ring
    canvas.drawCircle(center, radius, paint);

    // Draw dashed outer ring
    final dashedPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.white.withValues(alpha: opacity * 1.5);

    const int dashes = 8;
    const double dashAngle = 2 * math.pi / dashes;
    for (int i = 0; i < dashes; i++) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 8),
        startAngle,
        dashAngle * 0.2,
        false,
        dashedPaint,
      );
    }

    // Draw notches
    final notchPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0
          ..color = Colors.white.withValues(alpha: opacity * 2);

    const int notches = 4;
    const double notchAngle = 2 * math.pi / notches;
    for (int i = 0; i < notches; i++) {
      final startAngle = i * notchAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 20),
        startAngle,
        0.05,
        false,
        notchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShinePainter extends CustomPainter {
  final double progress;

  _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromLTWH(
              (progress * size.width * 2) - size.width,
              0,
              size.width,
              size.height,
            ),
          );

    // Draw diagonal shine
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ScanlinePainter extends CustomPainter {
  final double progress;

  _ScanlinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double y = progress * size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          EntryColors.arcticSilver.withValues(alpha: 0.0),
          EntryColors.arcticSilver.withValues(alpha: 0.2),
          EntryColors.arcticSilver.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), paint);

    // Subtle bright leading line
    final linePaint = Paint()
      ..color = EntryColors.arcticSilver.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
