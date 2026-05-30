import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/CursorApiService.dart';
import 'package:ice_gate/orchestration_layer/Services/SSHService.dart';
import 'package:ice_gate/orchestration_layer/Services/cursor_agent_models.dart';
import 'package:ice_gate/orchestration_layer/Services/cursor_repo_catalog_service.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cursor API + My Machines + optional SSH terminal entry.
class CursorHubPanel extends StatefulWidget {
  const CursorHubPanel({super.key, this.compact = false});

  final bool compact;

  @override
  State<CursorHubPanel> createState() => _CursorHubPanelState();
}

class _CursorHubPanelState extends State<CursorHubPanel> {
  final _cursorApi = CursorApiService.instance;
  final _keyController = TextEditingController();
  final _machineController = TextEditingController();
  final _repoController = TextEditingController();
  final _promptController = TextEditingController();

  bool _loading = false;
  bool _obscureKey = true;
  String? _statusMessage;
  List<CursorAgentSummary> _recentAgents = [];
  List<CursorRepoEntry> _repos = [];
  bool _reposLoading = false;
  CursorAgentTarget _target = CursorAgentTarget.machine;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _cursorApi.refreshKeyState();
    final machine = await _cursorApi.getMachineName();
    if (machine != null) _machineController.text = machine;
    await _refreshAgents();
    await _loadRepos();
  }

  Future<void> _loadRepos() async {
    setState(() => _reposLoading = true);
    final repos = await CursorRepoCatalogService.instance.loadRepos();
    if (!mounted) return;
    setState(() {
      _repos = repos;
      _reposLoading = false;
      if (_repoController.text.isEmpty) {
        final icegate = repos.cast<CursorRepoEntry?>().firstWhere(
          (r) => r?.name == 'icegate',
          orElse: () => repos.isNotEmpty ? repos.first : null,
        );
        if (icegate != null) {
          _repoController.text = icegate.httpsUrl;
        }
      }
    });
  }

  Future<void> _refreshAgents() async {
    if (!await _cursorApi.hasApiKey()) return;
    final agents = await _cursorApi.listAgents();
    if (mounted) setState(() => _recentAgents = agents);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _machineController.dispose();
    _repoController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _copyWorkerCommand() async {
    await Clipboard.setData(
      const ClipboardData(text: CursorApiService.workerStartCommand),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.cursor_hub_worker_copied),
      ),
    );
  }

  Future<void> _openAgentsDashboard() async {
    final uri = Uri.parse(CursorApiService.agentsDashboardUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      setState(() => _statusMessage = uri.toString());
    }
  }

  Future<void> _openAgentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveKey() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    await _cursorApi.saveApiKey(_keyController.text);
    _keyController.clear();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _statusMessage = AppLocalizations.of(context)!.ssh_cursor_api_saved;
    });
    await _refreshAgents();
  }

  Future<void> _testKey() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    final key = _keyController.text.trim();
    final result = await _cursorApi.testConnection(
      apiKey: key.isNotEmpty ? key : null,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      if (result.ok) {
        _statusMessage = l10n.ssh_cursor_api_test_ok;
        if (key.isNotEmpty) _cursorApi.saveApiKey(key);
        _keyController.clear();
      } else if (result.message == 'missing_key') {
        _statusMessage = l10n.ssh_cursor_api_missing_key;
      } else {
        _statusMessage = l10n.ssh_cursor_api_test_fail(result.message);
      }
    });
    if (result.ok) await _refreshAgents();
  }

  Future<void> _sendPrompt() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _cursorApi.hasApiKey()) {
      setState(() => _statusMessage = l10n.ssh_cursor_api_missing_key);
      return;
    }

    await _cursorApi.saveMachineName(_machineController.text);

    setState(() {
      _loading = true;
      _statusMessage = null;
    });

    final result = await _cursorApi.createAgent(
      promptText: _promptController.text,
      target: _target,
      machineName: _machineController.text,
      repoUrl: _repoController.text,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _statusMessage = l10n.cursor_hub_task_sent;
        _promptController.clear();
      } else if (result.message == 'missing_key') {
        _statusMessage = l10n.ssh_cursor_api_missing_key;
      } else if (result.message != null &&
          result.message!.contains('usage_limit_exceeded')) {
        _statusMessage = l10n.cursor_hub_usage_limit;
      } else {
        _statusMessage = l10n.cursor_hub_task_failed(
          result.message ?? 'unknown',
        );
      }
    });

    if (result.ok && result.agentUrl != null) {
      await _openAgentUrl(result.agentUrl!);
    }
    await _refreshAgents();
  }

  void _openSshTerminal() {
    final ssh = SSHService();
    ssh.aiMode.value = 'cursor';
    context.push('/widgets/ssh?aiMode=cursor');
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final hasKey = _cursorApi.hasKeySignal.value;
      final validated = _cursorApi.apiValidatedSignal.value;

      if (widget.compact) {
        return _buildCompact(context, hasKey, validated);
      }
      return _buildFull(context, hasKey, validated);
    });
  }

  Widget _buildCompact(BuildContext context, bool hasKey, bool validated) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cursor_hub_title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasKey
                  ? (validated
                      ? l10n.cursor_hub_key_ready
                      : l10n.ssh_cursor_api_key_stored)
                  : l10n.ssh_cursor_api_missing_key,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => context.push('/integrations/cursor'),
                  child: Text(l10n.cursor_hub_open_full),
                ),
                OutlinedButton(
                  onPressed: _openAgentsDashboard,
                  child: Text(l10n.cursor_hub_open_agents),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context, bool hasKey, bool validated) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.ssh_cursor_api_title, Icons.key_rounded, cs),
        if (hasKey)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              validated
                  ? l10n.cursor_hub_key_ready
                  : l10n.ssh_cursor_api_key_stored,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.greenAccent.shade400,
              ),
            ),
          ),
        TextField(
          controller: _keyController,
          obscureText: _obscureKey,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: l10n.ssh_cursor_api_key_hint,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureKey
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: _loading ? null : _saveKey,
              child: Text(l10n.ssh_cursor_api_save),
            ),
            OutlinedButton(
              onPressed: _loading ? null : _testKey,
              child: Text(l10n.ssh_cursor_api_test),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle(l10n.cursor_hub_worker_title, Icons.desktop_mac_rounded, cs),
        Text(
          l10n.cursor_hub_worker_body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            CursorApiService.workerStartCommand,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _copyWorkerCommand,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l10n.cursor_hub_copy_worker_cmd),
            ),
            FilledButton.icon(
              onPressed: _openAgentsDashboard,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(l10n.cursor_hub_open_agents),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle(l10n.cursor_hub_send_title, Icons.send_rounded, cs),
        SegmentedButton<CursorAgentTarget>(
          segments: [
            ButtonSegment(
              value: CursorAgentTarget.machine,
              label: Text(l10n.cursor_hub_target_machine),
              icon: const Icon(Icons.laptop_mac_rounded, size: 18),
            ),
            ButtonSegment(
              value: CursorAgentTarget.cloudRepo,
              label: Text(l10n.cursor_hub_target_cloud),
              icon: const Icon(Icons.cloud_rounded, size: 18),
            ),
          ],
          selected: {_target},
          onSelectionChanged: (s) {
            setState(() => _target = s.first);
            if (s.first == CursorAgentTarget.cloudRepo && _repos.isEmpty) {
              _loadRepos();
            }
          },
        ),
        const SizedBox(height: 12),
        if (_target == CursorAgentTarget.machine)
          TextField(
            controller: _machineController,
            decoration: InputDecoration(
              labelText: l10n.cursor_hub_machine_name,
              hintText: l10n.cursor_hub_machine_name_hint,
              border: const OutlineInputBorder(),
            ),
          )
        else
          _buildRepoPicker(context, l10n, cs),
        const SizedBox(height: 12),
        TextField(
          controller: _promptController,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.cursor_hub_prompt_label,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _loading ? null : _sendPrompt,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.cursor_hub_send_task),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openSshTerminal,
          icon: const Icon(Icons.terminal_rounded, size: 18),
          label: Text(l10n.ssh_cursor_api_open_terminal),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusMessage!,
            style: theme.textTheme.bodySmall?.copyWith(color: cs.primary),
          ),
        ],
        if (_recentAgents.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(l10n.cursor_hub_recent_title, Icons.history_rounded, cs),
          ..._recentAgents.map((a) => _agentTile(context, a)),
        ],
      ],
    );
  }

  Widget _buildRepoPicker(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.cursor_hub_pick_repo,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (_reposLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: l10n.cursor_hub_refresh_repos,
                onPressed: () => CursorRepoCatalogService.instance
                    .loadRepos(forceRefresh: true)
                    .then((_) => _loadRepos()),
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_repos.isEmpty && !_reposLoading)
          Text(
            l10n.cursor_hub_repos_empty,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              itemCount: _repos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final repo = _repos[index];
                final selected = _repoController.text == repo.httpsUrl;
                return Material(
                  color: selected
                      ? cs.primaryContainer.withValues(alpha: 0.5)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    dense: true,
                    selected: selected,
                    leading: Icon(
                      repo.isPrivate ? Icons.lock_rounded : Icons.folder_rounded,
                      size: 20,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    title: Text(
                      repo.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      repo.localPath != null
                          ? repo.localPath!
                          : repo.httpsUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      setState(() => _repoController.text = repo.httpsUrl);
                    },
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _repoController,
          decoration: InputDecoration(
            labelText: l10n.cursor_hub_repo_url,
            hintText: 'https://github.com/DuyLongArt/icegate',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.tertiary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _agentTile(BuildContext context, CursorAgentSummary agent) {
    final envLabel = agent.envType != null
        ? '${agent.envType}${agent.envName != null ? ': ${agent.envName}' : ''}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(
          agent.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${agent.status} $envLabel'.trim()),
        trailing: agent.url != null
            ? IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () => _openAgentUrl(agent.url!),
              )
            : null,
        onTap: agent.url != null ? () => _openAgentUrl(agent.url!) : null,
      ),
    );
  }
}

/// Sliver wrapper for SSH manager scroll view.
class CursorHubSliver extends StatelessWidget {
  const CursorHubSliver({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, compact ? 16 : 0, 16, 0),
        child: CursorHubPanel(compact: compact),
      ),
    );
  }
}
