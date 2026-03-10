import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  State<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current username
    final authBlock = context.read<AuthBlock>();
    _usernameController.text = authBlock.username.peek() ?? '';
  }

  Future<void> _changeUsername() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authBlock = context.read<AuthBlock>();
      await authBlock.changeUsername(_usernameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Thông báo cập nhật tên đăng nhập thành công
            content: Text(AppLocalizations.of(context)!.msg_username_success),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Thông báo lỗi cập nhật tên đăng nhập
            content: Text(
              AppLocalizations.of(context)!.err_username_failed(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SwipeablePage(
      onSwipe: () => Navigator.of(context).pop(),
      child: Scaffold(
        appBar: AppBar(
          // Tiêu đề trang đổi tên đăng nhập
          title: Text(AppLocalizations.of(context)!.change_username_title),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề phụ: tên đăng nhập duy nhất
                Text(
                  AppLocalizations.of(context)!.unique_username_header,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                // Mô tả yêu cầu tên đăng nhập
                Text(
                  AppLocalizations.of(context)!.username_description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Username Field
                // Nhãn trường tên đăng nhập
                Text(
                  AppLocalizations.of(context)!.username_label,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    // Gợi ý nhập tên đăng nhập mới
                    hintText: AppLocalizations.of(
                      context,
                    )!.enter_new_username_hint,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  // Kiểm tra tên đăng nhập hợp lệ
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.err_enter_username;
                    }
                    if (value.trim().length < 3) {
                      return AppLocalizations.of(context)!.err_username_length;
                    }
                    if (value.contains('@')) {
                      return AppLocalizations.of(
                        context,
                      )!.err_username_invalid_char;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 48),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changeUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        // Nút cập nhật tên đăng nhập
                        : Text(
                            AppLocalizations.of(context)!.btn_update_username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
  }
}
