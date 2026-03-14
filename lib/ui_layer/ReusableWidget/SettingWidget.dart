import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/ThemeManager.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/LocaleBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';

class SettingsWidget extends StatelessWidget {
  final String? title;

  const SettingsWidget({super.key, this.title});

  static Widget icon(BuildContext context, {double size = 24.0}) {
    return IconButton(
      icon: const Icon(Icons.settings),
      iconSize: size,
      onPressed: () {
        context.go('/settings');
      },
    );
  }

  Widget _buildPremiumSettingTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            trailingWidget ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final objectResource = context.read<ObjectDatabaseBlock>();
    final authBlock = context.read<AuthBlock>();
    final userData = authBlock.user.value;
    final personBlock = context.read<PersonBlock>();
    final info = personBlock.information.watch(context);
    final username = info.profiles.username;
    final String? personID =
        userData?['person_id']?.toString() ?? userData?['id']?.toString();
    return Container(
      padding: const EdgeInsets.all(24),

      child: Row(
        children: [
          Container(
            width: 100, // Balanced size for settings header
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: LocalFirstImage(
                ownerId: personID,
                localPath: info.profiles.avatarLocalPath,
                remoteUrl: info.profiles.profileImageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username ?? AppLocalizations.of(context)!.guest_user,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  (username == 'Guest')
                      ? AppLocalizations.of(context)!.msg_sign_in_to_sync
                      : AppLocalizations.of(context)!.member_status,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (username == 'Guest')
            IconButton.filledTonal(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login_rounded),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? AppLocalizations.of(context)!.app_settings_title),
        toolbarHeight: 70,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 30),
            onPressed: () {
              WidgetNavigatorAction.smartPop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, size: 30),
            onPressed: () => context.go('/canvas'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildProfileHeader(context),

            // 1. Account Settings
            _buildSettingSection(
              context: context,
              title: AppLocalizations.of(context)!.account_section,
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: AppLocalizations.of(context)!.edit_profile,
                  subtitle: AppLocalizations.of(context)!.edit_profile_subtitle,
                  icon: Icons.person_rounded,
                  color: Colors.blue,
                  onTap: () {
                    context.go('/personal-info');
                  },
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: AppLocalizations.of(context)!.change_password,
                  icon: Icons.lock_rounded,
                  color: Colors.purple,
                  onTap: () {
                    context.push('/settings/change-password');
                  },
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: AppLocalizations.of(context)!.change_username,
                  icon: Icons.alternate_email_rounded,
                  color: Colors.orange,
                  onTap: () {
                    context.push('/settings/change-username');
                  },
                ),
              ],
            ),

            // 2. Preferences
            _buildSettingSection(
              context: context,
              title: AppLocalizations.of(context)!.preferences_section,
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: AppLocalizations.of(context)!.change_theme,
                  icon: Icons.palette_rounded,
                  color: Colors.pink,
                  onTap: () {
                    ThemeManager.showThemeSelectionDialog(context);
                  },
                ),
                Watch((context) {
                  final notificationService = context
                      .read<LocalNotificationService>();
                  final isEnabled = notificationService.notificationsEnabled
                      .watch(context);

                  return _buildPremiumSettingTile(
                    context: context,
                    title: AppLocalizations.of(context)!.system_notifications,
                    subtitle: isEnabled
                        ? AppLocalizations.of(context)!.notifications_active
                        : AppLocalizations.of(context)!.notifications_paused,
                    icon: isEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: isEnabled ? Colors.green : Colors.amber,
                    trailingWidget: Switch.adaptive(
                      value: isEnabled,
                      activeTrackColor: Colors.green.withValues(alpha: 0.5),
                      activeColor: Colors.green,
                      onChanged: (bool value) {
                        notificationService.setNotificationsEnabled(value);
                      },
                    ),
                  );
                }),
                // Tile cho đổi ngôn ngữ — hiển thị ngôn ngữ hiện tại
                Watch((context) {
                  final localeBlock = context.read<LocaleBlock>();
                  final currentLocale = localeBlock.currentLocale.watch(
                    context,
                  );
                  final currentName = localeBlock.getLocaleName(currentLocale);

                  return _buildPremiumSettingTile(
                    context: context,
                    title: AppLocalizations.of(context)!.change_language,
                    subtitle: currentName,
                    icon: Icons.language_rounded,
                    color: Colors.blue,
                    onTap: () {
                      // Hiển thị dialog chọn ngôn ngữ
                      _showLanguageSelectionDialog(context, localeBlock);
                    },
                  );
                }),
              ],
            ),

            // 3. Modality Settings: Finance
            _buildSettingSection(
              context: context,
              title: "Finance Settings",
              children: [
                Watch((context) {
                  final configBlock = context.read<ConfigBlock>();
                  final currency = configBlock.currency.watch(context);
                  return _buildPremiumSettingTile(
                    context: context,
                    title: "Currency Unit",
                    subtitle: "Current: $currency",
                    icon: Icons.monetization_on_rounded,
                    color: Colors.green,
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currency, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: currency == 'VND',
                          onChanged: (_) => configBlock.toggleCurrency(),
                        ),
                      ],
                    ),
                    onTap: () => configBlock.toggleCurrency(),
                  );
                }),
              ],
            ),

            // 4. Modality Settings: Health, Social, Projects
            _buildSettingSection(
              context: context,
              title: "Modality Preferences",
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: "Health Modality",
                  subtitle: "Custom goals and tracking",
                  icon: Icons.favorite_rounded,
                  color: Colors.redAccent,
                  onTap: () {},
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: "Social Modality",
                  subtitle: "Privacy and connections",
                  icon: Icons.people_rounded,
                  color: Colors.blueAccent,
                  onTap: () {},
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: "Projects Modality",
                  subtitle: "Default folders and AI flow",
                  icon: Icons.code_rounded,
                  color: Colors.deepOrange,
                  onTap: () {},
                ),
              ],
            ),

            // 5. Info & Support
            _buildSettingSection(
              context: context,
              title: AppLocalizations.of(context)!.about_support_section,
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: AppLocalizations.of(context)!.manual,
                  icon: Icons.description_rounded,
                  color: Colors.teal,
                  onTap: () {
                    context.go("/manual");
                  },
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: AppLocalizations.of(context)!.btn_send_feedback,
                  subtitle: AppLocalizations.of(context)!.feedback_subtitle,
                  icon: Icons.feedback_rounded,
                  color: Colors.orange,
                  onTap: () {
                    _showFeedbackDialog(context);
                  },
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: AppLocalizations.of(context)!.version,
                  subtitle: '2.6.0',
                  icon: Icons.info_outline_rounded,
                  color: Colors.grey,
                  trailingWidget: const SizedBox.shrink(),
                ),
              ],
            ),

            _buildSettingSection(
              context: context,
              title: "Developer Tools",
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: "Reset Database",
                  subtitle: "Wipe all local data",
                  icon: Icons.delete_forever_rounded,
                  color: Colors.red,
                  onTap: () => _showResetDatabaseDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showResetDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.reset_database_title),
          content: Text(AppLocalizations.of(context)!.reset_database_msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                final database = context.read<AppDatabase>();
                await database.clearAllData();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.msg_database_reset_success,
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.btn_reset_all_data),
            ),
          ],
        );
      },
    );
  }

  /// Hiển thị dialog chọn ngôn ngữ với danh sách các locale được hỗ trợ
  void _showLanguageSelectionDialog(
    BuildContext context,
    LocaleBlock localeBlock,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.change_language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: LocaleBlock.supportedLocales.map((locale) {
              // Kiểm tra xem locale này có phải là locale hiện tại không
              final isSelected =
                  locale.languageCode ==
                  localeBlock.currentLocale.value.languageCode;
              final name = localeBlock.getLocaleName(locale);

              return ListTile(
                // Biểu tượng cờ hoặc chữ viết tắt ngôn ngữ
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHigh,
                  child: Text(
                    locale.languageCode.toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                // Dấu tick cho ngôn ngữ đang chọn
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : null,
                onTap: () {
                  // Đổi ngôn ngữ và đóng dialog
                  localeBlock.setLocale(locale);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final textController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.btn_send_feedback),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.feedback_subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final feedback = textController.text;
                if (feedback.isNotEmpty) {
                  // TODO: Send feedback to backend or email
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cảm ơn phản hồi của bạn! / Thank you for your feedback!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("Gửi / Send"),
            ),
          ],
        );
      },
    );
  }
}
