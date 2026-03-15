import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SSHService.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/SSHStorageService.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/SSHHostModel.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart' hide ThemeData;
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
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!_sshService.isConnected && widget.hostId != null) {
      await _autoConnect();
    }

    _refreshSessions();
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
      appBar: AppBar(
        title: const Text('SSH TMUX MANAGER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => WidgetNavigatorAction.smartPop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _refreshSessions,
          ),
        ],
      ),
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
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _refreshSessions, child: const Text('RETRY')),
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
                  Text('Syncing with remote host...', ),
                ],
              ),
            ),
          ),

        if (_sshService.isConnected && !_isLoading) ...[
          _buildSectionHeader(context, 'LIVE TMUX SESSIONS'),
          _buildLiveSessions(l10n, theme),
        ],

        _buildSectionHeader(context, 'PERSISTED SESSIONS (SQLITE)'),
        _buildPersistedSessions(l10n, theme),
        
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNoConnection(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'NO ACTIVE UPLINK',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Connect to a host first to manage live sessions.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/widgets/ssh'),
            icon: const Icon(Icons.lan),
            label: const Text('GO TO TERMINAL'),
          ),
        ],
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
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final session = _sessions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.layers_rounded)),
                title: Text(
                  session,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                subtitle: Text('Live Session on ${_sshService.currentHost}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.login_rounded, color: Colors.green),
                      tooltip: 'Attach',
                      onPressed: () => context.push('/widgets/ssh', extra: {
                        'autoStartCommand': 'tmux attach -t $session',
                        'initialPrompt': widget.initialPrompt,
                        'initialContent': widget.initialContent,
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      tooltip: 'Kill',
                      onPressed: () => _showKillConfirmation(session),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: _sessions.length,
      ),
    );
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
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final s = persisted[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.storage_rounded)),
                    title: Text(
                      s.ipAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Last used: ${s.updatedAt.toLocal()}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.link_rounded, color: Colors.blue),
                          tooltip: 'Connect',
                          onPressed: () => context.push('/widgets/ssh', extra: {
                            'hostId': s.projectID,
                            'remotePath': s.remotePath,
                            'aiMode': s.aiModel,
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          tooltip: 'Delete Record',
                          onPressed: () => _deletePersistedSession(s.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: persisted.length,
          ),
        );
      },
    );
  }

  void _showKillConfirmation(String sessionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TERMINATE SESSION?'),
        content: Text('Are you sure you want to kill the tmux session "$sessionName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
