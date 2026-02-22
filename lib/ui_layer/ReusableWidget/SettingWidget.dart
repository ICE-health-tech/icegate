import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/ThemeManager.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';

class SettingsWidget extends StatelessWidget {
  final String title;

  const SettingsWidget({super.key, this.title = 'App Settings'});

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
    final authBlock = context.watch<AuthBlock>();
    final username = authBlock.username.watch(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username ?? 'Guest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  username == 'Guest' ? "Sign in to sync your data" : "Member",
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
              title: "Account",
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: 'Edit Profile',
                  subtitle: 'Update your name and photo',
                  icon: Icons.person_rounded,
                  color: Colors.blue,
                  onTap: () {
                    context.go('/personal-info');
                  },
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: 'Change Password',
                  icon: Icons.lock_rounded,
                  color: Colors.purple,
                  onTap: () {
                    context.push('/settings/change-password');
                  },
                ),
              ],
            ),

            // 2. Preferences
            _buildSettingSection(
              context: context,
              title: "Preferences",
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: 'Change Theme',
                  icon: Icons.palette_rounded,
                  color: Colors.pink,
                  onTap: () {
                    ThemeManager.showThemeSelectionDialog(context);
                  },
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: 'Notifications',
                  icon: Icons.notifications_rounded,
                  color: Colors.amber,
                  trailingWidget: Watch((context) {
                    final notificationService = context
                        .read<LocalNotificationService>();
                    return Switch.adaptive(
                      value: notificationService.notificationsEnabled.value,
                      onChanged: (bool value) {
                        notificationService.setNotificationsEnabled(value);
                      },
                    );
                  }),
                ),
              ],
            ),

            // 3. Info & Support
            _buildSettingSection(
              context: context,
              title: "About & Support",
              children: [
                _buildPremiumSettingTile(
                  context: context,
                  title: 'Manual',
                  icon: Icons.description_rounded,
                  color: Colors.teal,
                  onTap: () {
                    context.go("/manual");
                  },
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: 'Version',
                  subtitle: '2.1.1',
                  icon: Icons.info_outline_rounded,
                  color: Colors.grey,
                  trailingWidget: const SizedBox.shrink(),
                ),
                _buildPremiumSettingTile(
                  context: context,
                  title: 'Reset Database',
                  subtitle: 'Clear all local data',
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
