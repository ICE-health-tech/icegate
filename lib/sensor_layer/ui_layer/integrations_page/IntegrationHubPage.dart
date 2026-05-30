import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/integration_account.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/integration_domain.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleSignInHub.dart';
import 'package:ice_gate/data_layer/Services/cloud/google_api_error.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Integrations/IntegrationHubBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Central place to connect calendar accounts and health data sources.
class IntegrationHubPage extends StatefulWidget {
  const IntegrationHubPage({super.key, this.initialFocus});

  /// `calendar` or `health` — scroll/highlight section (phase 3).
  final String? initialFocus;

  @override
  State<IntegrationHubPage> createState() => _IntegrationHubPageState();
}

class _IntegrationHubPageState extends State<IntegrationHubPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IntegrationHubBlock>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final block = context.read<IntegrationHubBlock>();
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Watch((context) {
          final accounts = block.accounts.value;
          final topSafe = MediaQuery.paddingOf(context).top;
          // Clear MainShell Dynamic Island (~50) + breathing room.
          final headerClearance = topSafe + 88;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: headerClearance)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      l10n.integration_hub_title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.integration_hub_subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel(l10n.integration_hub_calendars_section),
                    const SizedBox(height: 12),
              _providerCard(
                context,
                title: l10n.projects_calendar_connect_google,
                subtitle: l10n.projects_calendar_connect_hint,
                icon: Icons.event_rounded,
                iconColor: const Color(0xFF4285F4),
                connected: _isConnected(
                  accounts,
                  IntegrationProviderId.googleCalendar,
                ),
                onConnect: () => _connectProvider(
                  context,
                  block,
                  IntegrationProviderId.googleCalendar,
                ),
              ),
              if (DeviceCalendarService.isSupported) ...[
                const SizedBox(height: 12),
                _providerCard(
                  context,
                  title: isIos
                      ? l10n.projects_calendar_connect_apple
                      : l10n.projects_calendar_connect_device,
                  subtitle: l10n.projects_calendar_device_hint,
                  icon: isIos ? Icons.apple_rounded : Icons.smartphone_rounded,
                  iconColor: theme.colorScheme.secondary,
                  connected: _isConnected(
                    accounts,
                    isIos
                        ? IntegrationProviderId.appleDeviceCalendar
                        : IntegrationProviderId.androidDeviceCalendar,
                  ),
                  onConnect: () => _connectProvider(
                    context,
                    block,
                    isIos
                        ? IntegrationProviderId.appleDeviceCalendar
                        : IntegrationProviderId.androidDeviceCalendar,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _sectionLabel(l10n.integration_hub_health_section),
              const SizedBox(height: 12),
              _providerCard(
                context,
                title: l10n.integration_hub_apple_health,
                subtitle: l10n.integration_hub_apple_health_hint,
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFF32D74B),
                connected: _isConnected(
                  accounts,
                  IntegrationProviderId.appleHealth,
                ),
                onConnect: () => _connectProvider(
                  context,
                  block,
                  IntegrationProviderId.appleHealth,
                ),
              ),
              const SizedBox(height: 12),
              _providerCard(
                context,
                title: l10n.integration_hub_google_fit,
                subtitle: l10n.integration_hub_google_fit_hint,
                icon: Icons.directions_run_rounded,
                iconColor: const Color(0xFF34A853),
                connected: _isConnected(
                  accounts,
                  IntegrationProviderId.googleFit,
                ),
                onConnect: () => _connectProvider(
                  context,
                  block,
                  IntegrationProviderId.googleFit,
                ),
              ),
              const SizedBox(height: 12),
              _providerCard(
                context,
                title: l10n.integration_hub_huawei_health,
                subtitle: l10n.integration_hub_huawei_health_hint,
                icon: Icons.watch_rounded,
                iconColor: const Color(0xFFFF9500),
                connected: _isConnected(
                  accounts,
                  IntegrationProviderId.huaweiHealth,
                ),
                onConnect: () => _connectProvider(
                  context,
                  block,
                  IntegrationProviderId.huaweiHealth,
                ),
              ),
              const SizedBox(height: 28),
              _sectionLabel(l10n.cursor_hub_section_title),
              const SizedBox(height: 12),
              _providerCard(
                context,
                title: l10n.cursor_hub_title,
                subtitle: l10n.cursor_hub_integration_subtitle,
                icon: Icons.smart_toy_outlined,
                iconColor: Colors.tealAccent,
                connected: false,
                onConnect: () => context.push('/integrations/cursor'),
                alwaysShowOpen: true,
              ),
              const SizedBox(height: 28),
              _sectionLabel(l10n.integration_hub_sensors_section),
              const SizedBox(height: 12),
              _providerCard(
                context,
                title: l10n.integration_hub_open_sensor_hub,
                subtitle: l10n.integration_hub_sensor_hub_hint,
                icon: Icons.sensors_rounded,
                iconColor: theme.colorScheme.primary,
                connected: false,
                onConnect: () => context.push('/integrations/sensors'),
                alwaysShowOpen: true,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.integration_hub_phase2_notice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                ),
              ),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _connectProvider(
    BuildContext context,
    IntegrationHubBlock block,
    IntegrationProviderId provider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (block.personId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.integration_hub_sign_in_required)),
      );
      return;
    }

    final ok = await block.connect(provider);
    if (!context.mounted) return;

    if (ok) {
      final message = switch (provider) {
        IntegrationProviderId.googleCalendar =>
          l10n.projects_calendar_google_connected,
        IntegrationProviderId.googleFit => l10n.integration_hub_status_connected,
        IntegrationProviderId.appleDeviceCalendar =>
          l10n.projects_calendar_apple_connected,
        IntegrationProviderId.androidDeviceCalendar =>
          l10n.projects_calendar_device_connected,
        IntegrationProviderId.appleHealth => l10n.integration_hub_status_connected,
        IntegrationProviderId.huaweiHealth => l10n.integration_hub_status_connected,
        _ => l10n.integration_hub_status_connected,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
      return;
    }

    final failMessage = switch (provider) {
      IntegrationProviderId.huaweiHealth => l10n.integration_hub_huawei_sensor_hint,
      IntegrationProviderId.appleHealth when !isIos =>
        l10n.integration_hub_health_coming_soon,
      IntegrationProviderId.googleCalendar => () {
        final code = GoogleApiError.classify(
          context.read<GoogleCalendarService>().lastSignInError,
        );
        return switch (code) {
          GoogleApiError.apiNotEnabled =>
            l10n.projects_calendar_api_not_enabled(
              GoogleSignInHub.darwinProjectNumber,
            ),
          GoogleApiError.insufficientScopes =>
            l10n.projects_calendar_insufficient_scopes,
          _ => l10n.projects_calendar_sign_in_failed,
        };
      }(),
      _ => l10n.projects_calendar_sign_in_failed,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failMessage), duration: const Duration(seconds: 5)),
    );
  }

  bool _isConnected(
    List<IntegrationAccount> accounts,
    IntegrationProviderId provider,
  ) {
    for (final a in accounts) {
      if (a.provider == provider &&
          a.status == IntegrationConnectionStatus.connected) {
        return true;
      }
    }
    return false;
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _providerCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool connected,
    required VoidCallback onConnect,
    bool alwaysShowOpen = false,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final faceTop = Color.lerp(
      theme.colorScheme.surfaceContainerHigh,
      iconColor,
      0.1,
    )!;
    final faceBottom = theme.colorScheme.surfaceContainerHigh;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: connected && !alwaysShowOpen ? null : onConnect,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [faceTop, faceBottom],
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.62,
                          ),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (connected && !alwaysShowOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.integration_hub_status_connected,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: onConnect,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      alwaysShowOpen
                          ? l10n.integration_hub_open_sensor_hub
                          : l10n.integration_hub_connect,
                      style: const TextStyle(fontSize: 12),
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
