import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/InfraApiService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';

class InfraApiSections extends StatefulWidget {
  const InfraApiSections({
    super.key,
    required this.colorScheme,
    required this.isDark,
  });

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  State<InfraApiSections> createState() => _InfraApiSectionsState();
}

class _InfraApiSectionsState extends State<InfraApiSections> {
  final _providers = InfraApiProvider.values;
  final Map<InfraApiProvider, bool> _configured = {};
  final Map<InfraApiProvider, InfraApiTestResult?> _last = {};
  final Map<InfraApiProvider, bool> _testing = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final configured = <InfraApiProvider, bool>{};
    final last = <InfraApiProvider, InfraApiTestResult?>{};
    for (final p in _providers) {
      configured[p] = await InfraApiService.hasToken(p);
      last[p] = await InfraApiService.readLastResult(p);
    }
    if (!mounted) return;
    setState(() {
      _configured
        ..clear()
        ..addAll(configured);
      _last
        ..clear()
        ..addAll(last);
      _loading = false;
    });
  }

  Future<void> _test(InfraApiProvider provider) async {
    setState(() => _testing[provider] = true);
    final result = await InfraApiService.testConnection(provider);
    if (!mounted) return;
    setState(() {
      _testing[provider] = false;
      _last[provider] = result;
      _configured[provider] = true;
    });
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? l10n.infra_api_test_ok(result.summary ?? result.message)
              : l10n.infra_api_test_fail(result.message),
        ),
      ),
    );
  }

  Future<void> _configure(InfraApiProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final tokenCtrl = TextEditingController();
    final tailnet = provider == InfraApiProvider.tailscale
        ? (await InfraApiService.readTailnet(provider) ?? '-')
        : '';
    final existing = await InfraApiService.readToken(provider);
    if (!mounted) return;
    final tailnetCtrl = TextEditingController(text: tailnet);
    if (existing != null && existing.isNotEmpty) {
      tokenCtrl.text = '••••••••';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.infra_api_configure(InfraApiService.displayName(provider))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                InfraApiService.docsHint(provider),
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: widget.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenCtrl,
                decoration: InputDecoration(
                  labelText: l10n.infra_api_token_label,
                ),
                obscureText: true,
                autocorrect: false,
                onTap: () {
                  if (tokenCtrl.text == '••••••••') tokenCtrl.clear();
                },
              ),
              if (provider == InfraApiProvider.tailscale) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: tailnetCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.infra_api_tailnet_label,
                    hintText: l10n.infra_api_tailnet_hint,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_configured[provider] == true)
            TextButton(
              onPressed: () async {
                await InfraApiService.clearProvider(provider);
                if (ctx.mounted) Navigator.pop(ctx, false);
                await _reload();
              },
              child: Text(l10n.infra_api_clear),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.projects_calendar_save),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final rawToken = tokenCtrl.text.trim();
    if (rawToken.isNotEmpty && rawToken != '••••••••') {
      await InfraApiService.saveToken(provider, rawToken);
    }
    if (provider == InfraApiProvider.tailscale) {
      await InfraApiService.saveTailnet(tailnetCtrl.text);
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: HealthMetricColors.shellPanel(
        widget.colorScheme,
        isDark: widget.isDark,
        radius: 20,
        accent: HealthMetricColors.pillarBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.infra_api_section_title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.infra_api_section_subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.colorScheme.onSurface.withValues(alpha: 0.58),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          for (final provider in _providers) ...[
            _ProviderTile(
              provider: provider,
              configured: _configured[provider] == true,
              last: _last[provider],
              testing: _testing[provider] == true,
              colorScheme: widget.colorScheme,
              onConfigure: () => _configure(provider),
              onTest: () => _test(provider),
            ),
            if (provider != _providers.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.configured,
    required this.last,
    required this.testing,
    required this.colorScheme,
    required this.onConfigure,
    required this.onTest,
  });

  final InfraApiProvider provider;
  final bool configured;
  final InfraApiTestResult? last;
  final bool testing;
  final ColorScheme colorScheme;
  final VoidCallback onConfigure;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = InfraApiService.accentFor(provider);
    final name = InfraApiService.displayName(provider);

    String statusText;
    Color statusColor;
    if (!configured) {
      statusText = l10n.infra_api_not_configured;
      statusColor = colorScheme.onSurface.withValues(alpha: 0.45);
    } else if (last?.ok == true) {
      statusText = last?.summary ?? l10n.infra_api_connected;
      statusColor = HealthMetricColors.pillarGreen;
    } else if (last?.ok == false) {
      statusText = l10n.infra_api_test_fail(last!.message);
      statusColor = const Color(0xFFFF7043);
    } else {
      statusText = l10n.infra_api_token_saved;
      statusColor = HealthMetricColors.pillarYellow;
    }

    return Material(
      color: HealthMetricColors.glassFill(
        colorScheme,
        isDark: Theme.of(context).brightness == Brightness.dark,
        darkAlpha: 0.04,
      ),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onConfigure,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(
                  InfraApiService.iconFor(provider),
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (configured)
                IconButton(
                  tooltip: l10n.infra_api_test,
                  onPressed: testing ? null : onTest,
                  icon: testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 22),
                ),
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
