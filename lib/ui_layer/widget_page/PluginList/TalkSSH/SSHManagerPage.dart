import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SSHService.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/SSHStorageService.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/SSHHostModel.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart'
    hide ThemeData;
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SSHManagerPage extends StatefulWidget {
  final String? initialPrompt;
  final String? hostId;
  final String? remotePath;
  final String? initialContent;

  const SSHManagerPage({
    super.key,
    this.initialPrompt,
    this.hostId,
    this.remotePath,
    this.initialContent,
  });

  @override
  State<SSHManagerPage> createState() => _SSHManagerPageState();
}

class _SSHManagerPageState extends State<SSHManagerPage> {
  final SSHService _sshService = SSHService();
  final SSHStorageService _storageService = SSHStorageService();
  List<String> _sessions = [];
  List<SSHHostModel> _savedHosts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedHosts();
    if (!_sshService.isConnected && widget.hostId != null) {
      await _autoConnect();
    }

    _refreshSessions();
  }

  Future<void> _loadSavedHosts() async {
    final hosts = await _storageService.loadHosts();
    if (mounted) {
      setState(() {
        _savedHosts = hosts;
      });
    }
  }

  Future<void> _autoConnect() async {
    setState(() => _isLoading = true);
    try {
      final hosts = await _storageService.loadHosts();
      final host = hosts.cast<SSHHostModel?>().firstWhere(
        (h) => h?.id == widget.hostId,
        orElse: () => null,
      );

      if (host != null) {
        await _sshService.connect(
          host: host.host,
          port: host.port,
          username: host.user,
          password: host.password ?? '',
          useTmux: true,
        );
      }
    } catch (e) {
      setState(() => _error = 'Auto-connect failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshSessions() async {
    if (!_sshService.isConnected) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🔍 [SSHManager] Fetching tmux sessions...');
      final sessions = await _sshService.listTmuxSessions();
      debugPrint('✅ [SSHManager] Found ${sessions.length} sessions: $sessions');
      setState(() {
        _sessions = sessions;
      });
    } catch (e) {
      debugPrint('❌ [SSHManager] Error fetching sessions: $e');
      setState(() => _error = 'Failed to fetch sessions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _killSession(String name) async {
    _sshService.killTmuxSession(name);
    // Give it a moment to process before refreshing
    await Future.delayed(const Duration(milliseconds: 800));
    await _refreshSessions();
  }

  Future<void> _deletePersistedSession(String id) async {
    final db = context.read<AppDatabase>();
    await db.sshSessionsDAO.deleteSSHSession(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      body: _buildBody(l10n, theme),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshSessions,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (!_sshService.isConnected && !_isLoading)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildNoConnection(l10n),
          ),

        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Syncing with remote host...'),
                ],
              ),
            ),
          ),

        if (_sshService.isConnected && !_isLoading) ...[
          _buildSectionHeader('LIVE TMUX SESSIONS', Icons.terminal_rounded),
          _buildLiveSessions(l10n, theme),
        ],

        _buildSectionHeader('SESSION HISTORY', Icons.history_rounded),
        _buildSessionHistoryGrid(l10n, theme),

        _buildSectionHeader(
          'PERSISTED SESSIONS (SQLITE)',
          Icons.storage_rounded,
        ),
        _buildPersistedSessions(l10n, theme),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.onSurface.withOpacity(0.1),
                      colorScheme.onSurface.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnection(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative Background Glow
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.2),
                        colorScheme.primary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.cloud_off_rounded,
                  size: 80,
                  color: colorScheme.primary.withOpacity(0.4),
                ),
              ],
            ),

            // const SizedBox(height: 32),
            const SizedBox(height: 16),
            Text(
              'Connect to a host first to manage live sessions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: () => context.push('/widgets/ssh'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.terminal_rounded),
                label: const Text(
                  'GO TO TERMINAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSessions(AppLocalizations l10n, ThemeData theme) {
    if (_sessions.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No active tmux sessions found.'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final session = _sessions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.layers_rounded)),
              title: Text(
                session,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              subtitle: Text('Live Session on ${_sshService.currentHost}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.login_rounded, color: Colors.green),
                    tooltip: 'Attach',
                    onPressed: () => context.push(
                      '/widgets/ssh',
                      extra: {
                        'autoStartCommand': 'tmux attach -t $session',
                        'initialPrompt': widget.initialPrompt,
                        'initialContent': widget.initialContent,
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                    ),
                    tooltip: 'Kill',
                    onPressed: () => _showKillConfirmation(session),
                  ),
                ],
              ),
            ),
          ),
        );
      }, childCount: _sessions.length),
    );
  }

  Widget _buildSessionHistoryGrid(AppLocalizations l10n, ThemeData theme) {
    if (_savedHosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No saved hosts')),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _savedHosts.length,
          itemBuilder: (context, index) {
            final host = _savedHosts[index];
            final colorScheme = theme.colorScheme;
            return InkWell(
              onTap: () async {
                if (host.id == _sshService.currentHostId &&
                    _sshService.isConnected) {
                  context.push('/widgets/ssh');
                } else {
                  await _sshService.connect(
                    host: host.host,
                    port: host.port,
                    username: host.user,
                    password: host.password ?? '',
                    useTmux: true,
                  );
                  if (context.mounted) {
                    context.push(
                      '/widgets/ssh',
                      extra: {
                        'hostId': host.id,
                        'remotePath': host.remoteFilePath,
                        'aiMode': host.aiMode,
                      },
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            host.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _editHost(host),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white38,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.computer_rounded,
                          color: Colors.white24,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${host.user}@${host.host}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontFamily: 'Courier',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            host.port.toString(),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatLastUsed(host.lastUsed),
                          style: const TextStyle(
                            color: Colors.white12,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatLastUsed(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildPersistedSessions(AppLocalizations l10n, ThemeData theme) {
    final db = context.read<AppDatabase>();

    return StreamBuilder<List<SSHSessionData>>(
      stream: db.sshSessionsDAO.watchActiveSessions(),
      builder: (context, snapshot) {
        final persisted = snapshot.data ?? [];
        if (persisted.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No persisted sessions in database.'),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final s = persisted[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.storage_rounded),
                  ),
                  title: Text(
                    s.ipAddress,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Last used: ${s.updatedAt.toLocal()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.link_rounded,
                          color: Colors.blue,
                        ),
                        tooltip: 'Connect',
                        onPressed: () => context.push(
                          '/widgets/ssh',
                          extra: {
                            'hostId': s.projectID,
                            'remotePath': s.remotePath,
                            'aiMode': s.aiModel,
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Delete Record',
                        onPressed: () => _deletePersistedSession(s.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }, childCount: persisted.length),
        );
      },
    );
  }

  void _editHost(SSHHostModel host) {
    final nameController = TextEditingController(text: host.name);
    final hostController = TextEditingController(text: host.host);
    final portController = TextEditingController(text: host.port.toString());
    final userController = TextEditingController(text: host.user);
    final passController = TextEditingController(text: host.password ?? '');
    final pathController = TextEditingController(
      text: host.remoteFilePath ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('EDIT CONNECTION'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              TextField(
                controller: hostController,
                decoration: const InputDecoration(labelText: 'Host IP/Address'),
              ),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: pathController,
                decoration: const InputDecoration(labelText: 'Remote Path'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              final updatedHost = SSHHostModel(
                id: host.id,
                name: nameController.text,
                host: hostController.text,
                port: int.tryParse(portController.text) ?? 22,
                user: userController.text,
                password: passController.text,
                remoteFilePath: pathController.text,
                lastUsed: host.lastUsed,
                aiMode: host.aiMode,
                aiPromptPrefix: host.aiPromptPrefix,
              );
              await _storageService.saveHost(updatedHost);
              if (context.mounted) Navigator.pop(context);
              _loadSavedHosts();
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showKillConfirmation(String sessionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TERMINATE SESSION?'),
        content: Text(
          'Are you sure you want to kill the tmux session "$sessionName"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _killSession(sessionName);
            },
            child: const Text('KILL'),
          ),
        ],
      ),
    );
  }
}
