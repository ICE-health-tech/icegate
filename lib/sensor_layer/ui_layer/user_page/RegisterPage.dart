import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/User/RegistrationProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/IceDiamondBackground.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/login_components/LoginButtons.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/login_components/LoginFields.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _userName = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  late AuthBlock _authBlock;

  @override
  void initState() {
    super.initState();
    _authBlock = context.read<AuthBlock>();
    _authBlock.error.value = null;
  }

  @override
  void dispose() {
    _userName.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final userName = _userName.text.trim();
    final email = _email.text.trim();
    final pw = _password.text;
    final confirm = _confirm.text;

    if (userName.isEmpty ||
        email.isEmpty ||
        pw.isEmpty ||
        _firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.msg_enter_credentials)),
      );
      return;
    }
    if (pw != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.err_register_password_mismatch)),
      );
      return;
    }

    await _authBlock.register(
      RegistrationPayload(
        userName: userName,
        email: email,
        password: pw,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
      ),
    );

    if (!mounted) return;

    final pending = _authBlock.registerPendingEmail.value;
    if (pending != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.msg_register_check_email(pending)),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    final err = await _authBlock.resendSignupConfirmation(email);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err == null ? l10n.msg_resend_confirm_sent : _mapErr(context, err),
        ),
        backgroundColor: err == null ? Colors.green.shade800 : Colors.red.shade800,
      ),
    );
  }

  String _mapErr(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'err_forgot_password_empty_email':
        return l10n.err_forgot_password_empty_email;
      case 'err_forgot_password_invalid_email':
        return l10n.err_forgot_password_invalid_email;
      default:
        return l10n.err_unexpected(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isLoading = _authBlock.status.value == AuthStatus.registering;
      final err = _authBlock.error.value;
      final l10n = AppLocalizations.of(context)!;

      return Scaffold(
        backgroundColor: EntryLandscapePalette.midnightNavy,
        body: IceDiamondBackground(
          particleCount: 40,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _authBlock.clearRegisterPending();
                          context.pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: EntryLandscapePalette.icyWhiteBlue,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.register_page_title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: EntryLandscapePalette.icyWhiteBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (err != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        _mapErr(context, err),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ModernAuthField(
                    controller: _userName,
                    hint: l10n.register_username_hint,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  ModernAuthField(
                    controller: _firstName,
                    hint: l10n.register_first_name,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  ModernAuthField(
                    controller: _lastName,
                    hint: l10n.register_last_name,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  ModernAuthField(
                    controller: _email,
                    hint: l10n.username_email_hint,
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  ModernAuthField(
                    controller: _password,
                    hint: l10n.password_hint,
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ModernAuthField(
                    controller: _confirm,
                    hint: l10n.register_password_confirm,
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 28),
                  ShimmerButton(
                    label: l10n.btn_create_account,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : _resend,
                    child: Text(
                      l10n.register_resend_email,
                      style: TextStyle(
                        color: EntryLandscapePalette.dustySkyBlue.withValues(
                          alpha: 0.95,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                          _authBlock.clearRegisterPending();
                          context.pop();
                        },
                    child: Text(
                      l10n.register_back_to_login,
                      style: TextStyle(
                        color: EntryLandscapePalette.icyWhiteBlue.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
