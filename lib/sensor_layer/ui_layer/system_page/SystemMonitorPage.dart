import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DatabaseAgent.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/AdminAccess.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/system_page/widgets/DevLauncherSections.dart';
import 'package:ice_gate/sensor_layer/ui_layer/system_page/widgets/InfraApiSections.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({super.key});

  @override
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  VerificationReport? _dbReport;
  PackageInfo? _packageInfo;
  bool _loadingDiagnostics = true;
  bool _refreshingRole = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAccess();
      _loadDiagnostics();
    });
  }

  Future<void> _refreshAccess() async {
    setState(() => _refreshingRole = true);
    await context.read<PersonBlock>().refreshRole();
    if (mounted) setState(() => _refreshingRole = false);
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loadingDiagnostics = true);
    final db = context.read<AppDatabase>();
    final agent = DatabaseVerificationAgent(db);
    final report = await agent.runFullDiagnostics();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _dbReport = report;
      _packageInfo = info;
      _loadingDiagnostics = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final personBlock = context.read<PersonBlock>();
    final authBlock = context.read<AuthBlock>();
    final db = context.read<AppDatabase>();

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Watch((context) {
          final personId = personBlock.currentPersonID.value;
          if (personId == null || personId.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<UserAccountData?>(
            stream: db.personManagementDAO.watchAccountByPersonId(personId),
            builder: (context, accountSnap) {
              final remoteRole = personBlock.account.value.role;
              final localRole = accountSnap.data?.role;
              final isAdmin = AdminAccess.roleIsAdmin(
                localRole: localRole,
                remoteRole: remoteRole,
              );

              if (_refreshingRole) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!isAdmin) {
                return _AccessDenied(
                  l10n: l10n,
                  colorScheme: cs,
                  localRole: localRole?.name ?? '—',
                  remoteRole: remoteRole,
                  onRetry: _refreshAccess,
                );
              }

              final authStatus = authBlock.status.value;
              final supabaseUser = Supabase.instance.client.auth.currentUser;
              final docBlock = context.read<DocumentationBlock>();
              final syncStatus = docBlock.syncStatus.value;
              final uptime = docBlock.uptimeSeconds.value;
              final isSyncing = personBlock.isSyncing.value;

              return RefreshIndicator(
                onRefresh: _loadDiagnostics,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).top + 88,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            l10n.system_monitor_title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.system_monitor_subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.62),
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 20),
                          _MonitorSection(
                            title: l10n.system_monitor_overview_section,
                            colorScheme: cs,
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MetricRow(
                                  label: l10n.system_monitor_app_version,
                                  value: _packageInfo == null
                                      ? '…'
                                      : '${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                                ),
                                _MetricRow(
                                  label: l10n.system_monitor_platform,
                                  value: Platform.operatingSystem,
                                ),
                                _MetricRow(
                                  label: l10n.system_monitor_role,
                                  value: localRole?.name ?? remoteRole,
                                ),
                                _MetricRow(
                                  label: l10n.system_monitor_auth_status,
                                  value: authStatus.name,
                                ),
                                _MetricRow(
                                  label: l10n.system_monitor_supabase_user,
                                  value: supabaseUser?.email ?? '—',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _MonitorSection(
                            title: l10n.system_monitor_db_section,
                            colorScheme: cs,
                            isDark: isDark,
                            trailing: _loadingDiagnostics
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _dbReport?.isHealthy == true
                                        ? Icons.check_circle_rounded
                                        : Icons.error_outline_rounded,
                                    size: 18,
                                    color: _dbReport?.isHealthy == true
                                        ? HealthMetricColors.pillarGreen
                                        : const Color(0xFFFF7043),
                                  ),
                            child: _loadingDiagnostics
                                ? Text(
                                    l10n.system_monitor_running_checks,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dbReport!.isHealthy
                                            ? l10n.system_monitor_healthy
                                            : l10n.system_monitor_issues,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _dbReport!.isHealthy
                                              ? HealthMetricColors.pillarGreen
                                              : const Color(0xFFFF7043),
                                        ),
                                      ),
                                      if (_dbReport!.integrityErrors
                                              ?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Integrity: ${_dbReport!.integrityErrors!.join(', ')}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                      if (_dbReport!.foreignKeyErrors
                                              ?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'FK: ${_dbReport!.foreignKeyErrors!.length}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      _MetricRow(
                                        label: l10n.system_monitor_smoke_test,
                                        value: (_dbReport!.smokeTestPassed ??
                                                false)
                                            ? 'OK'
                                            : 'FAIL',
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 14),
                          _MonitorSection(
                            title: l10n.system_monitor_sync_section,
                            colorScheme: cs,
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MetricRow(
                                  label: l10n.system_monitor_sync_active,
                                  value: isSyncing ? 'YES' : 'NO',
                                ),
                                _MetricRow(
                                  label: l10n.system_monitor_sync_status,
                                  value: syncStatus ?? '—',
                                ),
                                _MetricRow(
                                  label: l10n.system_monitor_uptime,
                                  value: _formatUptime(uptime),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          InfraApiSections(colorScheme: cs, isDark: isDark),
                          const SizedBox(height: 14),
                          DevLauncherSections(colorScheme: cs, isDark: isDark),
                          const SizedBox(height: 20),
                          FilledButton.tonalIcon(
                            onPressed: () => context.push('/sync-engine'),
                            icon: const Icon(Icons.sync_rounded, size: 20),
                            label: Text(l10n.system_monitor_open_sync_engine),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _formatUptime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({
    required this.l10n,
    required this.colorScheme,
    required this.localRole,
    required this.remoteRole,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final String localRole;
  final String remoteRole;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 56,
              color: colorScheme.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.system_monitor_denied_title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.system_monitor_denied_body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.system_monitor_denied_roles(localRole, remoteRole),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    fontFamily: 'Monospace',
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.system_monitor_denied_hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(l10n.system_monitor_retry),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitorSection extends StatelessWidget {
  const _MonitorSection({
    required this.title,
    required this.child,
    required this.colorScheme,
    required this.isDark,
    this.trailing,
  });

  final String title;
  final Widget child;
  final ColorScheme colorScheme;
  final bool isDark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: HealthMetricColors.shellPanel(
        colorScheme,
        isDark: isDark,
        radius: 20,
        accent: const Color.fromARGB(255, 254, 78, 38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Monospace',
                color: cs.onSurface.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
