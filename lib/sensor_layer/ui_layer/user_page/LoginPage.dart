import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/IceDiamondBackground.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';

// Components
import 'login_components/LoginDecorations.dart';
import 'login_components/LoginFields.dart';
import 'login_components/LoginButtons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
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
      final isLoading =
          status == AuthStatus.authenticating ||
          status == AuthStatus.registering ||
          status == AuthStatus.checkingSession;

      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: EntryColors.glacierBase,
        body: IceDiamondBackground(
          particleCount: 80,
          child: Stack(
            children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPremiumMainCard(isLoading, error, context),
                          const SizedBox(height: 40),
                          _buildLoginFooter(isLoading, context),
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
                color: EntryColors.iceCyan.withValues(alpha: 0.1),
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
                color: const Color(0xFF6679BE).withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumMainCard(bool isLoading, String? error, BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015) // Increased Perspective
        ..rotateX(-0.08) // More tilt back
        ..rotateY(0.04), // More tilt side
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Main Glass Container
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: EntryColors.iceCyan.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    // Deep 3D Shadow - More pronounced
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 50,
                      offset: const Offset(20, 35),
                      spreadRadius: -8,
                    ),
                    BoxShadow(
                      color: EntryColors.iceCyan.withValues(alpha: 0.15),
                      blurRadius: 80,
                      offset: const Offset(-8, -8),
                      spreadRadius: -15,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildAnimatedLogo(),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.app_title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.0,
                        color: EntryColors.diamondWhite,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (error != null) _buildErrorMessage(error),
                    
                    // Form Fields
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
                    
                    const SizedBox(height: 40),
                    
                    // Primary Login Action
                    ShimmerButton(
                      label: AppLocalizations.of(context)!.btn_enter,
                      isLoading: isLoading,
                      onPressed: _handleLogin,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Alternative Auth Methods
                    _buildAlternativeAuthRow(isLoading, context),
                  ],
                ),
              ),
            ),
          ),
          
          // Scan and Shine Effects
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) => CustomPaint(
                size: const Size(double.infinity, 580),
                painter: ShinePainter(progress: _shineController.value),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) => CustomPaint(
                size: const Size(double.infinity, 580),
                painter: ScanlinePainter(progress: _scanController.value),
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

        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EntryColors.iceCyan.withValues(alpha: 0.15),
                blurRadius: glow,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              'assets/images/crystal_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlternativeAuthRow(bool isLoading, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AuthIconButton(
            icon: Icons.fingerprint_rounded,
            label: "",
            onPressed: isLoading ? null : _handleSecureLogin,
            color: EntryColors.iceCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AuthIconButton(
            icon: Icons.apple_rounded,
            label: AppLocalizations.of(context)!.apple_login,
            onPressed: isLoading ? null : _handleAppleSignIn,
            color: EntryColors.diamondWhite,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AuthIconButton(
            icon: Icons.g_mobiledata_rounded,
            label: AppLocalizations.of(context)!.google_login,
            onPressed: isLoading ? null : _handleGoogleSignIn,
            isLargeIcon: true,
            color: EntryColors.projectBlue,
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
    switch (key) {
      case "err_invalid_credentials": return l10n.err_invalid_credentials;
      case "err_email_not_confirmed": return l10n.err_email_not_confirmed;
      case "err_user_not_found": return l10n.err_user_not_found;
      case "err_network_fail": return l10n.err_network_fail;
      case "err_passkey_canceled": return l10n.err_passkey_canceled;
      case "err_passkey_failed": return l10n.err_passkey_failed;
      case "err_biometric_unsupported": return l10n.err_biometric_unsupported;
      case "err_biometric_disabled": return l10n.err_biometric_disabled;
      case "err_too_many_attempts": return l10n.err_too_many_attempts;
      case "err_unexpected": return l10n.err_unexpected("System Error");
      default: return key;
    }
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
              color: Colors.white.withValues(alpha: 0.4),
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
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () {},
          child: Text(
            AppLocalizations.of(context)!.enroll_hub.toUpperCase(),
            style: const TextStyle(
              color: EntryColors.iceCyan,
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
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final success = await _authBlock.loginWithBiometrics(context);
      if (!success && mounted) {
        await _authBlock.loginWithPasskey(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.msg_secure_login_failed(e.toString()))),
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
    try {
      await _authBlock.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.google_signin_error(e.toString()))),
        );
      }
    }
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
