import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabLoginType.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/DevQuickTabStore.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/DevQuickTabCredentialsSheet.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/HubEntryCard.dart';
import 'package:provider/provider.dart';

/// Dev-tool browser tabs — quick access from Bảng ghép hub.
class DevQuickTabsPage extends StatefulWidget {
  const DevQuickTabsPage({super.key});

  @override
  State<DevQuickTabsPage> createState() => _DevQuickTabsPageState();
}

class _DevQuickTabsPageState extends State<DevQuickTabsPage> {
  List<DevQuickTabProtocol> _tabs = const [];
  bool _loaded = false;

  String get _personId =>
      context.read<PersonBlock>().currentPersonID.value ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final db = context.read<AppDatabase>();
    if (_personId.isNotEmpty && db.supabaseSync != null) {
      await db.supabaseSync!.syncTableDown('dev_quick_tabs', _personId);
    }
    final rows = await DevQuickTabStore.list(db, _personId);
    if (!mounted) return;
    setState(() {
      _tabs = rows;
      _loaded = true;
    });
  }

  void _openTab(DevQuickTabProtocol tab) {
    final uri = Uri(
      path: '/webview',
      queryParameters: {'url': tab.fullUrl, 'title': tab.title},
    );
    context.push(uri.toString());
  }

  Future<void> _showEditor({DevQuickTabProtocol? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final urlCtrl = TextEditingController(text: existing?.fullUrl ?? '');
    final userCtrl = TextEditingController(text: existing?.username ?? '');
    final passCtrl = TextEditingController(text: existing?.password ?? '');
    var loginType = existing != null
        ? DevQuickTabLoginType.fromStorage(existing.loginType)
        : DevQuickTabLoginType.htmlForm;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final showUserPass = loginType != DevQuickTabLoginType.apiKey &&
              loginType != DevQuickTabLoginType.oauth &&
              loginType != DevQuickTabLoginType.none;

          return AlertDialog(
            title: Text(
              isEdit ? l10n.dev_quick_tabs_edit : l10n.dev_quick_tabs_add,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l10n.dev_quick_tabs_label),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    decoration: InputDecoration(labelText: l10n.dev_quick_tabs_url),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DevQuickTabLoginType>(
                    value: loginType,
                    decoration: InputDecoration(
                      labelText: l10n.dev_quick_tabs_login_type,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    items: DevQuickTabLoginType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_loginTypeLabel(l10n, t)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => loginType = v);
                    },
                  ),
                  if (showUserPass) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: userCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.dev_quick_tabs_credentials_username,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.dev_quick_tabs_credentials_password,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty ||
                      urlCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.dev_quick_tabs_validation_error),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: Text(l10n.projects_calendar_save),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || !mounted) return;
    final title = titleCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (title.isEmpty || url.isEmpty) return;

    final db = context.read<AppDatabase>();
    if (isEdit) {
      await DevQuickTabStore.update(
        db,
        _personId,
        existing.copyWith(
          title: title,
          fullUrl: url,
          username: userCtrl.text.trim(),
          password: passCtrl.text,
          loginType: loginType.storageKey,
        ),
      );
    } else {
      await DevQuickTabStore.create(
        db,
        _personId,
        DevQuickTabProtocol(
          id: IDGen.generateUuid(),
          title: title,
          fullUrl: url,
          sortOrder: _tabs.length,
          username: userCtrl.text.trim(),
          password: passCtrl.text,
          loginType: loginType.storageKey,
        ),
      );
    }
    await _reload();
  }

  String _loginTypeLabel(AppLocalizations l10n, DevQuickTabLoginType type) {
    switch (type) {
      case DevQuickTabLoginType.htmlForm:
        return l10n.dev_quick_tabs_login_type_html_form;
      case DevQuickTabLoginType.emailPassword:
        return l10n.dev_quick_tabs_login_type_email_password;
      case DevQuickTabLoginType.httpBasic:
        return l10n.dev_quick_tabs_login_type_http_basic;
      case DevQuickTabLoginType.apiKey:
        return l10n.dev_quick_tabs_login_type_api_key;
      case DevQuickTabLoginType.oauth:
        return l10n.dev_quick_tabs_login_type_oauth;
      case DevQuickTabLoginType.none:
        return l10n.dev_quick_tabs_login_type_none;
    }
  }

  Future<void> _confirmDelete(DevQuickTabProtocol tab) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dev_quick_tabs_delete_title),
        content: Text(l10n.dev_quick_tabs_delete_message(tab.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.dev_quick_tabs_delete_confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final db = context.read<AppDatabase>();
    await DevQuickTabStore.delete(db, _personId, tab.id);
    await _reload();
  }

  Widget _crudMenu(DevQuickTabProtocol tab, Color accent) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: accent.withValues(alpha: 0.8),
        size: 22,
      ),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case 'open':
            _openTab(tab);
          case 'edit':
            _showEditor(existing: tab);
          case 'delete':
            _confirmDelete(tab);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'open',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.open_in_browser_rounded, size: 20),
            title: Text(l10n.dev_quick_tabs_open),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined, size: 20),
            title: Text(l10n.dev_quick_tabs_edit),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Theme.of(ctx).colorScheme.error,
            ),
            title: Text(
              l10n.dev_quick_tabs_delete_confirm,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
            dense: true,
          ),
        ),
      ],
    );
  }

  void _openCredentialsManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DevQuickTabCredentialsSheet(tabs: _tabs),
    );
  }

  static const _accents = [
    HealthMetricColors.pillarBlue,
    HealthMetricColors.pillarViolet,
    HealthMetricColors.pillarGreen,
    HealthMetricColors.pillarYellow,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.dev_quick_tabs_title),
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.dev_quick_tabs_credentials,
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: _openCredentialsManager,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add_rounded),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _tabs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.dev_quick_tabs_empty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                return HubEntryCard(
                  title: tab.title,
                  subtitle: tab.fullUrl,
                  icon: Icons.language_rounded,
                  accent: _accents[index % _accents.length],
                  onTap: () => _openTab(tab),
                  trailing: _crudMenu(tab, _accents[index % _accents.length]),
                );
              },
            ),
    );
  }
}
