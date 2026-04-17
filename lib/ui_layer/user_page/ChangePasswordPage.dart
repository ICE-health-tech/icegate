import 'package:drift/drift.dart' as Drift;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _requiresCurrentPassword = true;

  @override
  void initState() {
    super.initState();
    _checkPasswordRequirement();
  }

  Future<void> _checkPasswordRequirement() async {
    try {
      final db = context.read<AppDatabase>();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        final account = await db.personManagementDAO.getAccountByPersonId(
          userId,
        );
        if (account != null) {
          final hash = account.passwordHash;
          if (hash == 'EXTERNAL_AUTH' || hash == null || hash.isEmpty) {
            if (mounted) {
              setState(() {
                _requiresCurrentPassword = false;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking password requirement: $e");
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final email = client.auth.currentUser?.email;
      if (email == null) throw Exception("No authenticated user found");

      // 1. Re-authenticate to verify current password (if required)
      if (_requiresCurrentPassword) {
        print("🔐 [ChangePassword] Verifying current password for $email...");
        try {
          await client.auth.signInWithPassword(
            email: email,
            password: _currentPasswordController.text,
          );
        } catch (authErr) {
          // Dùng key l10n err_verification_failed khi hiển thị cho người dùng
          throw Exception('VERIFICATION_FAILED');
        }
      } else {
        print(
          "🔐 [ChangePassword] Skipping current password verification (External Auth/No Password).",
        );
      }

      // 2. Update password
      print("🔐 [ChangePassword] Updating to new password...");
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception("User session lost during update");
      }

      await client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      // 3. Sync metadata and finish
      await _syncMetadataAndPop(currentUser);
    } on AuthException catch (e) {
      // If setting password for the first time and it's already this password in Supabase,
      // we consider it a success and still update our public user_accounts table.
      if (e.message.toLowerCase().contains("different") &&
          !_requiresCurrentPassword) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          print(
            "🔐 [ChangePassword] Password is already set to this value in Supabase. Proceeding to sync metadata.",
          );
          await _syncMetadataAndPop(currentUser);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("❌ Password update error: $e");
      if (mounted) {
        // Hiển thị lỗi bất ngờ với localized text
        final errMsg = e.toString().contains('VERIFICATION_FAILED')
            ? AppLocalizations.of(context)!.err_verification_failed
            : AppLocalizations.of(context)!.err_unexpected(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncMetadataAndPop(User user) async {
    // 1. First, explicitly update public.user_accounts on Supabase
    try {
      final nowIso = DateTime.now().toIso8601String();
      final passwordBytes = utf8.encode(_passwordController.text);
      final passwordHash = sha256.convert(passwordBytes).toString();

      print("🌐 [ChangePassword] Syncing user_accounts record on Supabase...");
      await Supabase.instance.client
          .from('user_accounts')
          .update({
            'password_changed_at': nowIso,
            'updated_at': nowIso,
            'password_hash': passwordHash,
          })
          .eq('id', user.id);
    } catch (supaErr) {
      debugPrint("Remote user_accounts table update failed: $supaErr");
    }

    // 2. Next, update local database
    if (mounted) {
      try {
        final db = context.read<AppDatabase>();
        final personId = user.id;

        final account = await db.personManagementDAO.getAccountByPersonId(
          personId,
        );
        if (account != null) {
          final now = Drift.Value(DateTime.now());
          final passwordBytes = utf8.encode(_passwordController.text);
          final passwordHash = sha256.convert(passwordBytes).toString();

          final updatedAccount = account.copyWith(
            passwordChangedAt: now,
            updatedAt: now,
            passwordHash: Drift.Value(passwordHash),
          );
          await db.personManagementDAO.updateAccount(updatedAccount);
          print("💾 [ChangePassword] Local user_accounts record updated.");
        }
      } catch (dbErr) {
        debugPrint("Local DB update failed: $dbErr");
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.msg_password_success),
          backgroundColor: Colors.green,
        ),
      );
      WidgetNavigatorAction.smartPop(context);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        // Tiêu đề trang bảo mật
        title: Text(
          AppLocalizations.of(context)!.security_title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _requiresCurrentPassword ? Icons.lock_reset_rounded : Icons.security_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    // Tiêu đề thay đổi hoặc thiết lập mật khẩu
                    Text(
                      _requiresCurrentPassword
                          ? AppLocalizations.of(context)!.change_password
                          : "IDENTITY UPGRADE",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mô tả yêu cầu mật khẩu
                    Text(
                      _requiresCurrentPassword
                          ? AppLocalizations.of(
                              context,
                            )!.msg_password_requirement
                          : "You've successfully established your identity via Google. Now, set a unique local password to unlock advanced security features and Passkey enrollment.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Current Password
              if (_requiresCurrentPassword) ...[
                // Nhãn mật khẩu hiện tại
                Text(
                  AppLocalizations.of(context)!.current_password_label,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.enter_current_password_hint,
                    prefixIcon: const Icon(Icons.lock_person_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureCurrentPassword = !_obscureCurrentPassword,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  // Kiểm tra mật khẩu hiện tại không được trống
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.err_enter_current_password;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // New Password
              // Nhãn mật khẩu mới
              Text(
                AppLocalizations.of(context)!.new_password_label,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  )!.enter_new_password_hint,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                // Kiểm tra mật khẩu mới hợp lệ
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.err_enter_password;
                  }
                  if (value.length < 6) {
                    return AppLocalizations.of(context)!.err_password_length;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm Password
              // Nhãn xác nhận mật khẩu
              Text(
                AppLocalizations.of(context)!.confirm_password_label,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  )!.confirm_new_password_hint,
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                // Kiểm tra xác nhận mật khẩu
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.err_confirm_password;
                  }
                  if (value != _passwordController.text) {
                    return AppLocalizations.of(
                      context,
                    )!.err_passwords_not_match;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    // Nút cập nhật hoặc thiết lập mật khẩu
                    : Text(
                        _requiresCurrentPassword
                            ? AppLocalizations.of(context)!.btn_update_password
                            : AppLocalizations.of(context)!.set_password,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
