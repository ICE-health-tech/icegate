import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/DevLauncherBridge.dart';
import 'package:ice_gate/orchestration_layer/Services/DevLauncherPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/WebPlugin/HomelabWebPlugins.dart';
import 'package:provider/provider.dart';

class DevLauncherSections extends StatefulWidget {
  const DevLauncherSections({
    super.key,
    required this.colorScheme,
    required this.isDark,
  });

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  State<DevLauncherSections> createState() => _DevLauncherSectionsState();
}

class _DevLauncherSectionsState extends State<DevLauncherSections> {
  List<DevWebShortcut> _shortcuts = [];
  List<DevServiceAccount> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final shortcuts = await DevLauncherPrefs.loadShortcuts();
    final accounts = await DevLauncherPrefs.loadAccounts();
    if (!mounted) return;
    setState(() {
      _shortcuts = shortcuts;
      _accounts = accounts;
      _loading = false;
    });
  }

  void _openWeb(DevWebShortcut item) => DevLauncherBridge.open(context, item);

  Future<void> _pinShortcut(DevWebShortcut item) async {
    final l10n = AppLocalizations.of(context)!;
    final personId =
        context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;

    await DevLauncherBridge.pinToCanvas(
      context: context,
      item: item,
      personId: personId,
      externalDao: context.read<ExternalWidgetsDAO>(),
      internalDao: context.read<InternalWidgetsDAO>(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.dev_launcher_pinned)),
    );
  }

  Future<void> _addFromCatalog() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDialog<DevWebShortcut>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.dev_launcher_pick_plugin),
        children: [
          for (final plugin in HomelabWebPlugins.catalog)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(
                ctx,
                DevLauncherBridge.shortcutFromPlugin(plugin),
              ),
              child: ListTile(
                leading: Icon(plugin.icon),
                title: Text(plugin.name),
                subtitle: Text(plugin.description, maxLines: 1),
              ),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    if (_shortcuts.any((s) => s.url == picked.url)) return;
    await DevLauncherPrefs.saveShortcuts([..._shortcuts, picked]);
    await _reload();
  }

  void _showAddWebMenu() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.apps_rounded),
              title: Text(l10n.dev_launcher_add_from_catalog),
              onTap: () {
                Navigator.pop(ctx);
                _addFromCatalog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: Text(l10n.dev_launcher_add_web),
              onTap: () {
                Navigator.pop(ctx);
                _addShortcut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addShortcut() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dev_launcher_add_web),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.dev_launcher_name),
            ),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(labelText: l10n.dev_launcher_url),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
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
    final name = nameCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    final next = [
      ..._shortcuts,
      DevWebShortcut(id: IDGen.UUIDV7(), name: name, url: url),
    ];
    await DevLauncherPrefs.saveShortcuts(next);
    await _reload();
  }

  Future<void> _addAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final serviceCtrl = TextEditingController(text: 'OPNsense');
    final userCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    final passCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dev_launcher_add_account),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serviceCtrl,
                decoration: InputDecoration(labelText: l10n.dev_launcher_service),
              ),
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(labelText: l10n.dev_launcher_username),
              ),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(labelText: l10n.dev_launcher_url),
              ),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(labelText: l10n.dev_launcher_password),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
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
    final service = serviceCtrl.text.trim();
    final username = userCtrl.text.trim();
    if (service.isEmpty || username.isEmpty) return;
    final id = IDGen.UUIDV7();
    final next = [
      ..._accounts,
      DevServiceAccount(
        id: id,
        service: service,
        username: username,
        portalUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
      ),
    ];
    await DevLauncherPrefs.saveAccounts(next);
    if (passCtrl.text.isNotEmpty) {
      await DevLauncherPrefs.saveAccountSecret(id, passCtrl.text);
    }
    await _reload();
  }

  Future<void> _copyAccount(DevServiceAccount account) async {
    final secret = await DevLauncherPrefs.readAccountSecret(account.id);
    final buf = StringBuffer()
      ..writeln('Service: ${account.service}')
      ..writeln('User: ${account.username}');
    if (account.portalUrl != null) buf.writeln('URL: ${account.portalUrl}');
    if (secret != null && secret.isNotEmpty) buf.writeln('Password: $secret');
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.dev_launcher_copied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionShell(
          title: l10n.dev_launcher_web_title,
          colorScheme: widget.colorScheme,
          isDark: widget.isDark,
          trailing: IconButton(
            tooltip: l10n.dev_launcher_add_web,
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: _showAddWebMenu,
          ),
          child: Column(
            children: [
              for (final s in _shortcuts) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.language_rounded, color: widget.colorScheme.primary),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(s.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.dev_launcher_pin_canvas,
                        icon: const Icon(Icons.push_pin_outlined, size: 18),
                        onPressed: () => _pinShortcut(s),
                      ),
                      const Icon(Icons.open_in_new_rounded, size: 18),
                    ],
                  ),
                  onTap: () => _openWeb(s),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionShell(
          title: l10n.dev_launcher_accounts_title,
          colorScheme: widget.colorScheme,
          isDark: widget.isDark,
          trailing: IconButton(
            tooltip: l10n.dev_launcher_add_account,
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: _addAccount,
          ),
          child: _accounts.isEmpty
              ? Text(
                  l10n.dev_launcher_accounts_empty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                )
              : Column(
                  children: [
                    for (final a in _accounts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.key_rounded, color: HealthMetricColors.pillarYellow),
                        title: Text(a.service, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(a.username),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () => _copyAccount(a),
                        ),
                        onTap: () {
                          if (a.portalUrl != null && a.portalUrl!.isNotEmpty) {
                            _openWeb(DevWebShortcut(
                              id: a.id,
                              name: a.service,
                              url: a.portalUrl!,
                            ));
                          }
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
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
        accent: const Color.fromARGB(255, 255, 106, 72),
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
