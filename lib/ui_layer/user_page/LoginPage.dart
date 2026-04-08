import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/security_routing_layer/Routing/url_route/InternalRoute.dart';
import 'package:ice_gate/ui_layer/animation_page/PrismEntryPage.dart'; // For TacticalGrid

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _hudRotationController;
  late final AnimationController _logoPulseController;

  late AuthBlock _authBlock;
  late final void Function() _disposeEffect;

  @override
  void initState() {
    super.initState();
    _authBlock = context.read<AuthBlock>();

    _hudRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Redirect when authenticated
    _disposeEffect = effect(() {
      if (_authBlock.status.value == AuthStatus.authenticated) {
        if (mounted) {
          final intendedPath = intendedPathNotifier.value;
          if (intendedPath != null && intendedPath.isNotEmpty) {
            debugPrint("📌 [LoginPage] Redirecting to intended path via intro: $intendedPath");
            context.go('/intro');
          } else {
            context.go('/intro');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _disposeEffect(); // Stop watching the signal
    _hudRotationController.dispose();
    _logoPulseController.dispose();
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
        backgroundColor: const Color(0xFF010A15), // Deep Midnight Blue
        body: Stack(
          children: [
            // 1. Tactical Grid Background (Sharp/Striking)
            const Positioned.fill(child: TacticalGridBackground()),

            // 2. Floating Tech Ornaments (HUD Style)
            Positioned(
              top: 100,
              left: -50,
              child: RotationTransition(
                turns: _hudRotationController,
                child: _CircularHUD(
                  size: 200,
                  color: const Color(0xFFE1F5FE).withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -50,
              child: RotationTransition(
                turns: _hudRotationController,
                child: _CircularHUD(
                  size: 250,
                  color: const Color(0xFF80DEEA).withOpacity(0.05),
                ),
              ),
            ),

            // 3. Main Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sharp Glass Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // App Icon / Logo with Neon Glow
                              ScaleTransition(
                                scale: Tween<double>(begin: 1.0, end: 1.05)
                                    .animate(
                                      CurvedAnimation(
                                        parent: _logoPulseController,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1F5FE).withOpacity(0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE1F5FE).withOpacity(0.2),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF80DEEA).withOpacity(0.1),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.ac_unit_rounded,
                                    size: 60,
                                    color: Color(0xFFE1F5FE),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'ICE GATE',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8.0,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Error Display
                              if (error != null)
                                _buildError(error),

                              // Form
                              _buildModernField(
                                controller: _emailController,
                                hint: AppLocalizations.of(context)!.username_email_hint,
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              _buildModernField(
                                controller: _passwordController,
                                hint: AppLocalizations.of(context)!.password_hint,
                                icon: Icons.vpn_key_rounded,
                                obscureText: true,
                              ),
                              const SizedBox(height: 32),

                              // Login Button
                              _buildLoginButton(isLoading, context),
                              const SizedBox(height: 20),

                              // Auth Alternatives
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildIconButton(
                                      icon: Icons.fingerprint_rounded,
                                      label: AppLocalizations.of(context)!.secure_login,
                                      onPressed: isLoading ? null : _handleSecureLogin,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildIconButton(
                                      icon: Icons.g_mobiledata_rounded,
                                      label: AppLocalizations.of(context)!.google_login,
                                      onPressed: isLoading ? null : _handleGoogleSignIn,
                                      isGmail: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Footer Options
                    _buildFooter(isLoading, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
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
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0F7FA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        key: const ValueKey('login_btn'),
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: const Color(0xFF01579B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Color(0xFF01579B), strokeWidth: 3),
              )
            : Text(
                AppLocalizations.of(context)!.go_to_gate.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0),
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
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            AppLocalizations.of(context)!.enroll_hub,
            style: const TextStyle(
              color: Color(0xFFE1F5FE),
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
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isGmail ? Colors.white : const Color(0xFF80DEEA),
              size: isGmail ? 28 : 24,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF80DEEA)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1F5FE), width: 1.5),
        ),
      ),
    );
  }

  Future<void> _handleSecureLogin() async {
    // Hide keyboard to ensure the native biometric/passkey dialog has no UI interference
    FocusScope.of(context).unfocus();
    
    try {
      // Small pause after hiding keyboard
      await Future.delayed(const Duration(milliseconds: 300));
      
      // First attempt biometric (FaceID/TouchID)
      final success = await _authBlock.loginWithBiometrics(context);
      if (!success && mounted) {
        // If biometric fails or cancelled, we can offer Passkey as second attempt
        // or just let the user try again. For "Gate" experience, we'll auto-trigger passkey
        // if the device supports it but biometrics weren't the winning path.
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
            backgroundColor: Colors.redAccent,
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
      // The session change will be picked up by the 'effect' in initState
      // which already redirects to /intro. 
      // But we can add a fallback check here if needed.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Error: $e')),
        );
      }
    }
  }
}

class _CircularHUD extends StatelessWidget {
  final Color color;
  final double size;
  const _CircularHUD({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 2),
            ),
          ),
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.1), width: 8),
            ),
          ),
          // Small dots or accents
          for (int i = 0; i < 4; i++)
            Transform.rotate(
              angle: i * (3.14159 / 2),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 4,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
