import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/BackWidget.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';

class SettingsWidget extends StatelessWidget {
  final String title;

  const SettingsWidget({super.key, this.title = 'App Settings'});

  static Widget icon(BuildContext context, {double size = 24.0}) {
    return Container(
      child: IconButton(
        icon: Icon(Icons.settings),
        iconSize: size,
        onPressed: () {
          context.go('/settings');
        },
      ),
      // child: Icon(Icons.settings),
    );
  }

  // A helper function to build a standard setting item
  Widget _buildSettingTile({
    required BuildContext context,
    required String settingTitle,
    String? subtitle,
    IconData? icon,
    VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: icon != null ? Icon(icon, color: colorScheme.secondary) : null,
      title: AutoSizeText(
        settingTitle,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
      ),
      subtitle: subtitle != null ? AutoSizeText(subtitle, maxLines: 1) : null,
      trailing: trailingWidget ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 30),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view, size: 30),
            onPressed: () => context.go('/canvas'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: <Widget>[
          // 1. Account Settings
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AutoSizeText(
              'ACCOUNT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
            ),
          ),
          _buildSettingTile(
            context: context,
            settingTitle: 'Edit Profile',
            subtitle: 'Update your name and photo',
            icon: Icons.person,
            onTap: () {
              // Action: Navigate to profile edit page
              context.go('/personal-info');
              print('Navigate to Profile Edit');
            },
          ),
          _buildSettingTile(
            context: context,
            settingTitle: 'Change Password',
            icon: Icons.lock,
            onTap: () {
              // Action: Navigate to password change page
              print('Navigate to Change Password');
            },
          ),

          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),

          // 2. Application Preferences
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AutoSizeText(
              'PREFERENCES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
            ),
          ),

          // Example: Theme Switch
          _buildSettingTile(
            context: context,
            settingTitle: 'Change Theme',
            icon: Icons.palette,
            onTap: () {
              // Navigator.of(context).pop();
              ThemeManager.showThemeSelectionDialog(context);
            },
          ),

          // Example: Notifications Toggle
          _buildSettingTile(
            context: context,
            settingTitle: 'Notifications',
            icon: Icons.notifications,
            trailingWidget: Watch((context) {
              final notificationService = context
                  .watch<LocalNotificationService>();
              return Switch(
                value: notificationService.notificationsEnabled.value,
                onChanged: (bool value) {
                  notificationService.setNotificationsEnabled(value);
                },
              );
            }),
            onTap: null,
          ),

          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),

          // 3. Info and Support
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AutoSizeText(
              'ABOUT & SUPPORT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
            ),
          ),

          _buildSettingTile(
            context: context,
            settingTitle: 'Manual',
            icon: Icons.description,
            onTap: () {
              // Action: Open terms page
              print('Navigate to Terms');
              context.go("/manual");
            },
          ),
          _buildSettingTile(
            context: context,
            settingTitle: 'Version',
            subtitle: '1.1.1',
            icon: Icons.info_outline,
            trailingWidget: const SizedBox.shrink(),
            onTap: null,
          ),

          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),

          // 4. System / Debug
          // const Padding(
          //   padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          //   child: AutoSizeText(
          //     'SYSTEM',
          //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          //     maxLines: 1,
          //   ),
          // ),

          // _buildSettingTile(
          //   context: context,
          //   settingTitle: 'Reset Database',
          //   subtitle: 'Clear all local application data',
          //   icon: Icons.delete_forever,
          //   onTap: () => _showResetDatabaseDialog(context),
          // ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Database?'),
          content: const Text(
            'This will permanently delete all your local data including focus sessions, health logs, and settings. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                final database = context.read<AppDatabase>();
                await database.clearAllData();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database reset successful.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('RESET ALL DATA'),
            ),
          ],
        );
      },
    );
  }
}
