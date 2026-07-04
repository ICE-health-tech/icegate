import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabLoginType.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/DevQuickTabStore.dart';
import 'package:ice_gate/orchestration_layer/Services/HomelabHostPolicy.dart';
import 'package:ice_gate/orchestration_layer/Services/WebViewCredentialStore.dart';
import 'package:provider/provider.dart';

/// Bottom sheet — inline username / password / passkey per dev-tab host.
class DevQuickTabCredentialsSheet extends StatelessWidget {
  const DevQuickTabCredentialsSheet({super.key, required this.tabs});

  final List<DevQuickTabProtocol> tabs;

  List<({String host, String label})> get _hostEntries {
    final seen = <String>{};
    final entries = <({String host, String label})>[];
    for (final tab in tabs) {
      final host = Uri.tryParse(tab.fullUrl)?.host ?? '';
      if (host.isEmpty || seen.contains(host)) continue;
      seen.add(host);
      entries.add((host: host, label: tab.title));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final entries = _hostEntries;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dev_quick_tabs_credentials,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            l10n.dev_quick_tabs_credentials_subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.dev_quick_tabs_empty,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _HostCredentialCard(
                            key: ValueKey(entry.host),
                            host: entry.host,
                            label: entry.label,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HostCredentialCard extends StatefulWidget {
  const _HostCredentialCard({
    super.key,
    required this.host,
    required this.label,
  });

  final String host;
  final String label;

  @override
  State<_HostCredentialCard> createState() => _HostCredentialCardState();
}

class _HostCredentialCardState extends State<_HostCredentialCard> {
  final WebViewCredentialStore _store = WebViewCredentialStore();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passkeyCtrl = TextEditingController();
  DevQuickTabLoginType _loginType = DevQuickTabLoginType.htmlForm;
  bool _sslTrusted = false;
  bool _loaded = false;
  bool _saving = false;

  bool get _isPrivateLan => HomelabHostPolicy.isPrivateLan(widget.host);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passkeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final creds = await _store.readHostCredentials(widget.host);
    if (!mounted) return;
    setState(() {
      _userCtrl.text = creds.username;
      _passCtrl.text = creds.password;
      _passkeyCtrl.text = creds.passkey;
      _sslTrusted = creds.sslTrusted;
      _loginType = creds.loginType;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _store.saveHostCredentials(
      host: widget.host,
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      passkey: _passkeyCtrl.text.trim(),
      sslTrusted: _sslTrusted,
      loginType: _loginType,
    );
    // Mirror into dev_quick_tabs rows so credentials sync to Supabase.
    if (mounted) {
      final db = context.read<AppDatabase>();
      final personId =
          context.read<PersonBlock>().currentPersonID.value ?? '';
      await DevQuickTabStore.applyHostCredentialsToTabs(
        db,
        personId,
        host: widget.host,
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        loginType: _loginType.storageKey,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.dev_quick_tabs_credentials_saved)),
    );
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dev_quick_tabs_credentials_clear_title),
        content: Text(l10n.dev_quick_tabs_credentials_clear_message(widget.host)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.dev_quick_tabs_credentials_clear),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _store.clearHost(widget.host);
    if (mounted) {
      final db = context.read<AppDatabase>();
      final personId =
          context.read<PersonBlock>().currentPersonID.value ?? '';
      await DevQuickTabStore.applyHostCredentialsToTabs(
        db,
        personId,
        host: widget.host,
        username: '',
        password: '',
        loginType: DevQuickTabLoginType.inferForHost(widget.host).storageKey,
      );
    }
    if (!mounted) return;
    _userCtrl.clear();
    _passCtrl.clear();
    _passkeyCtrl.clear();
    setState(() {
      _sslTrusted = false;
      _loginType = DevQuickTabLoginType.inferForHost(widget.host);
    });
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

  bool get _showUserPass =>
      _loginType != DevQuickTabLoginType.apiKey &&
      _loginType != DevQuickTabLoginType.oauth &&
      _loginType != DevQuickTabLoginType.none;

  bool get _showPasskey => _loginType == DevQuickTabLoginType.apiKey;

  bool get _showOAuthHint => _loginType == DevQuickTabLoginType.oauth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (!_loaded) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              widget.host,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<DevQuickTabLoginType>(
              value: _loginType,
              decoration: InputDecoration(
                labelText: l10n.dev_quick_tabs_login_type,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              items: DevQuickTabLoginType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_loginTypeLabel(l10n, type)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _loginType = v);
              },
            ),
            if (_showOAuthHint) ...[
              const SizedBox(height: 10),
              Text(
                l10n.dev_quick_tabs_login_type_oauth_hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            if (_showUserPass) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _userCtrl,
                textInputAction: TextInputAction.next,
                keyboardType: _loginType == DevQuickTabLoginType.emailPassword
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                autofillHints: _loginType == DevQuickTabLoginType.emailPassword
                    ? const [AutofillHints.email]
                    : const [AutofillHints.username],
                decoration: InputDecoration(
                  labelText: _loginType == DevQuickTabLoginType.emailPassword
                      ? l10n.dev_quick_tabs_credentials_email
                      : l10n.dev_quick_tabs_credentials_username,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: l10n.dev_quick_tabs_credentials_password,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            if (_showPasskey) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _passkeyCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.dev_quick_tabs_credentials_passkey,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            if (_isPrivateLan) ...[
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.dev_quick_tabs_credentials_ssl,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  l10n.dev_quick_tabs_credentials_ssl_hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                value: _sslTrusted,
                onChanged: (v) => setState(() => _sslTrusted = v),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : _clear,
                  child: Text(l10n.dev_quick_tabs_credentials_clear),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.projects_calendar_save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
