import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/DevQuickTabStore.dart';
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
    final rows = await DevQuickTabStore.listOrSeed(_personId);
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

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? l10n.dev_quick_tabs_edit : l10n.dev_quick_tabs_add,
        ),
        content: Column(
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

    if (saved != true || !mounted) return;
    final title = titleCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (title.isEmpty || url.isEmpty) return;

    if (isEdit) {
      await DevQuickTabStore.update(
        _personId,
        existing.copyWith(title: title, fullUrl: url),
      );
    } else {
      await DevQuickTabStore.create(
        _personId,
        DevQuickTabProtocol(
          id: IDGen.generateUuid(),
          title: title,
          fullUrl: url,
          sortOrder: _tabs.length,
        ),
      );
    }
    await _reload();
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
    await DevQuickTabStore.delete(_personId, tab.id);
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
