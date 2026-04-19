import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'TerminalViewAdapter.dart';
import '../../../../initial_layer/CoreLogics/SSHService.dart';
import '../../../home_page/MainButton.dart';
import 'widgets/SSHCommandInput.dart';
import 'widgets/SSHConnectionSheet.dart';
import 'widgets/SSHNoteSelectorSheet.dart';
import 'SSHHostModel.dart';
import 'SSHStorageService.dart';

class TalkSSHPage extends StatefulWidget {
  final String? initialPrompt;
  final String? hostId;
  final String? remotePath;
  final String? initialContent;
  final String? aiMode; // gemini or opencode
  final String? autoStartCommand;

  const TalkSSHPage({
    super.key,
    this.initialPrompt,
    this.hostId,
    this.remotePath,
    this.initialContent,
    this.aiMode,
    this.autoStartCommand,
  });

  static dynamic get activeState => _TalkSSHPageState.activeState;

  @override
  State<TalkSSHPage> createState() => _TalkSSHPageState();

  static Widget icon(BuildContext context, {double? size}) {
    final storageService = SSHStorageService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<SSHHostModel>>(
      future: storageService.loadHosts(),
      builder: (context, snapshot) {
        final hosts = snapshot.data ?? [];
        final subButtons = hosts
            .take(5)
            .map(
              (host) => SubButton(
                icon: Icons.computer,
                label: '${host.name}\n${host.user}@${host.host}',
                backgroundColor: colorScheme.secondaryContainer,
                iconColor: colorScheme.onSecondaryContainer,
                onPressed: () {
                  if (_TalkSSHPageState._activeState != null) {
                    _TalkSSHPageState._activeState?.applyHostAndConnect(host);
                  } else {
                    context.push('/widgets/ssh', extra: {'hostId': host.id});
                  }
                },
              ),
            )
            .toList();

        return MainButton(
          type: 'ssh_uplink',
          size: size,
          icon: Icons.lan,
          backgroundColor: colorScheme.primary,
          iconColor: colorScheme.onPrimary,
          mainFunction: () =>
              _TalkSSHPageState._activeState?.showConnectDialog(),

          onSwipeUp: () {
            WidgetNavigatorAction.smartPop(context);
          },
          onSwipeRight: () {
            WidgetNavigatorAction.smartPop(context);
          },
          onSwipeLeft: () {
            WidgetNavigatorAction.smartPop(context);
          },

          subButtons: subButtons,
        );
      },
    );
  }
}

class _TalkSSHPageState extends State<TalkSSHPage> {
  static _TalkSSHPageState? _activeState;
  static _TalkSSHPageState? get activeState => _activeState;

  final SSHService _sshService = SSHService();
  final SSHStorageService _storageService = SSHStorageService();
  late final TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _remotePathController = TextEditingController();
  bool _useTmux = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isConnected = false;
  late StreamSubscription _connectionSub;
  late final dynamic _signalEffect;
  bool _hasDoneInitialCd = false;

  @override
  void initState() {
    super.initState();
    _activeState = this;
    _terminalController = TerminalController();

    // Initialize from signals
    _hostController.text = _sshService.hostSignal.value;
    _portController.text = _sshService.portSignal.value.toString();
    _userController.text = _sshService.userSignal.value;
    _passController.text = _sshService.passSignal.value;
    _remotePathController.text = _sshService.remotePathSignal.value;
    _useTmux = _sshService.useTmuxSignal.value;

    // Sync controllers to signals when they change
    _signalEffect = effect(() {
      final host = _sshService.hostSignal.value;
      final port = _sshService.portSignal.value;
      final user = _sshService.userSignal.value;
      final pass = _sshService.passSignal.value;
      final remotePath = _sshService.remotePathSignal.value;
      final tmux = _sshService.useTmuxSignal.value;

      if (_hostController.text != host) _hostController.text = host;
      if (_portController.text != port.toString()) _portController.text = port.toString();
      if (_userController.text != user) _userController.text = user;
      if (_passController.text != pass) _passController.text = pass;
      if (_remotePathController.text != remotePath) _remotePathController.text = remotePath;
      if (_useTmux != tmux) {
        setState(() {
          _useTmux = tmux;
        });
      }
    });

    if (widget.aiMode != null) {
      _sshService.aiMode.value = widget.aiMode!;
    }

    // Initialize from existing connection if any
    _isConnected = _sshService.isConnected;

    // Listen to connection state
    _connectionSub = _sshService.connectionState.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
        if (!connected) {
          _hasDoneInitialCd = false;
        }
      }
    });

    // Initial terminal message if not connected
    if (!_isConnected) {
      _sshService.terminal.write(
        '\x1b[1m\x1b[38;5;39mREMOTE SSH - SECURE ACCESS LAYER\x1b[0m\r\n\x1b[38;5;240m>>> COGNITIVE ENGINE READY. STANDBY FOR LINK.\x1b[0m\r\n\r\n',
      );
    }

    // Handle initial prompt from router
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialPrompt(widget.initialPrompt!);
      });
    }

    if (widget.remotePath != null) {
      _sshService.remotePathSignal.value = widget.remotePath!;
    }

    // Handle autoStartCommand if provided from router
    if (widget.autoStartCommand != null) {
      StreamSubscription? sub;
      sub = _sshService.connectionState.listen((connected) {
        if (connected) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _sshService.isConnected) {
              _sshService.write('${widget.autoStartCommand}\n');
            }
            sub?.cancel();
          });
        }
      });
    }

    // Auto-connect logic
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hosts = await _storageService.loadHosts();
      
      SSHHostModel? hostToConnect;
      if (widget.hostId != null) {
        hostToConnect = hosts.cast<SSHHostModel?>().firstWhere(
          (h) => h?.id == widget.hostId,
          orElse: () => null,
        );
      } else if (!_isConnected && hosts.isNotEmpty) {
        // Automatically connect to the first (usually last saved) host if not connected
        hostToConnect = hosts.first;
      }

      if (hostToConnect != null) {
        applyHostAndConnect(hostToConnect);

        // If we have initial content (e.g. a note), send it as an AI prompt after connecting
        if (widget.initialContent != null) {
          _handleInitialContent(widget.initialContent!);
        }
      }
    });
  }

  void _handleInitialContent(String content) {
    // Convert to plain text if it's JSON content
    final plainText = _extractPlainText(content);

    if (_sshService.isConnected) {
      debugPrint('🚀 [RemoteSSH] Already connected, sending AI prompt immediately');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _sendAiPrompt(plainText);
      });
      return;
    }

    // Wait for connection to be active before sending AI prompt
    debugPrint('⏳ [RemoteSSH] Waiting for connection before sending prompt...');
    StreamSubscription? sub;
    sub = _sshService.connectionState.listen((connected) {
      if (connected) {
        // Send AI prompt after a short delay for auto-cd to complete
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _sendAiPrompt(plainText);
          }
          sub?.cancel();
        });
      }
    });
  }

  Future<void> _saveAiPrompt(String prompt) async {
    _sshService.aiPromptPrefix.value = prompt;
    
    // Persist to host model if available
    if (_sshService.currentHostId != null) {
      final hosts = await _storageService.loadHosts();
      final hostIndex = hosts.indexWhere((h) => h.id == _sshService.currentHostId);
      if (hostIndex != -1) {
        final host = hosts[hostIndex];
        host.aiPromptPrefix = prompt;
        await _storageService.saveHost(host);
        debugPrint('💾 [RemoteSSH] AI prompt prefix persisted for host ${host.name}');
      }
    }

    // Also persist to global AI prompts table for this mode
    final personBlock = context.read<PersonBlock>();
    final personID = personBlock.information.value.profiles.id;
    if (personID != null) {
      final mode = _sshService.aiMode.value;
      final dao = context.read<AppDatabase>().aiPromptsDAO;
      await dao.savePrompt(personID, mode, prompt);
    }
  }

  String get _currentAiMode => _sshService.aiMode.value;

  void toggleAiMode() async {
    final modes = ['standard', 'gemini', 'opencode', 'openclaw'];
    final currentIndex = modes.indexOf(_currentAiMode);
    final nextMode = modes[(currentIndex + 1) % modes.length];
    
    _sshService.aiMode.value = nextMode;
    
    // Persist to host model if available
    if (_sshService.currentHostId != null) {
      final hosts = await _storageService.loadHosts();
      final hostIndex = hosts.indexWhere((h) => h.id == _sshService.currentHostId);
      if (hostIndex != -1) {
        final host = hosts[hostIndex];
        host.aiMode = nextMode;
        await _storageService.saveHost(host);
        debugPrint('💾 [RemoteSSH] AI mode persisted for host ${host.name}');
      }
    }

    // Persist choice to database
    await context.read<AppDatabase>().internalWidgetsDAO.updateInternalWidgetUrl(
      'ssh_uplink',
      '/widgets/ssh?aiMode=$nextMode',
    );

    // Update current active session in DB if connected
    if (_isConnected) {
      final db = context.read<AppDatabase>();
      final host = _sshService.hostSignal.value;
      try {
        await db.sshSessionsDAO.updateAiModelByIp(host, nextMode);
        debugPrint('💾 [RemoteSSH] Session AI model updated in SQLite for $host to $nextMode');
      } catch (e) {
        debugPrint('❌ [RemoteSSH] Failed to update session AI model: $e');
      }
    }
    
    // Reload prompt for new mode from global database if not host-specific
    final personBlock = context.read<PersonBlock>();
    final personID = personBlock.information.value.profiles.id;
    if (personID != null && nextMode != 'standard') {
      final dao = context.read<AppDatabase>().aiPromptsDAO;
      final data = await dao.getPrompt(personID, nextMode);
      if (data != null && _sshService.aiPromptPrefix.value.isEmpty) {
        _sshService.aiPromptPrefix.value = data.prompt;
      }
    }
  }

  void _handleInitialPrompt(String prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Connection Active'),
        content: const Text(
          'A plan has been received. How would you like to proceed?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _commandController.text = prompt);
            },
            child: const Text('Paste to Input'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _sendAiPrompt(prompt, includeContext: false);
            },
            child: const Text('Send to AI'),
          ),
        ],
      ),
    );
  }

  void applyHostAndConnect(SSHHostModel host) {
    _sshService.currentHostId = host.id;
    // Prefer explicitly passed aiMode if it's already set to something non-standard
    if (_sshService.aiMode.value == 'standard') {
      _sshService.aiMode.value = host.aiMode ?? 'standard';
    }
    _sshService.aiPromptPrefix.value = host.aiPromptPrefix ?? '';

    _sshService.hostSignal.value = host.host;
    _sshService.portSignal.value = host.port;
    _sshService.userSignal.value = host.user;
    _sshService.passSignal.value = host.password ?? '';
    _sshService.remotePathSignal.value = host.remoteFilePath ?? '';
    _connect();
  }

  void _connect() async {
    if (_isConnected) {
      _sshService.disconnect();
      await _clearSessionFromDb();
    }

    try {
      final hostIp = _sshService.hostSignal.value;
      final port = _sshService.portSignal.value;
      final user = _sshService.userSignal.value;
      final pass = _sshService.passSignal.value;

      final autoCmd = _sshService.remotePathSignal.value.isNotEmpty
          ? 'cd "${_sshService.remotePathSignal.value}" && clear'
          : null;

      await _sshService.connect(
        host: hostIp,
        port: port,
        username: user,
        password: pass,
        useTmux: _sshService.useTmuxSignal.value,
        autoStartCommand: autoCmd,
      );

      // Save host info if successful
      await _storageService.saveHost(
        SSHHostModel(
          id: _sshService.currentHostId,
          name: hostIp,
          host: hostIp,
          port: port,
          user: user,
          password: pass,
          remoteFilePath: _sshService.remotePathSignal.value,
          aiMode: _sshService.aiMode.value,
          aiPromptPrefix: _sshService.aiPromptPrefix.value,
        ),
      );

      // Save session to SQLite
      await _saveSessionToDb();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'UPLINK FAILURE: $e',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveSessionToDb() async {
    try {
      final db = context.read<AppDatabase>();
      final host = _sshService.hostSignal.value;
      
      // Clear old sessions for this IP first
      await db.sshSessionsDAO.deleteSessionsByIp(host);
      
      await db.sshSessionsDAO.insertSSHSession(SSHSessionsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        ipAddress: host,
        localPath: const Value.absent(),
        remotePath: Value(_sshService.remotePathSignal.value),
        projectID: Value(widget.hostId), // If hostId is project ID in some contexts
        sessionName: 'ssh_session_${DateTime.now().millisecondsSinceEpoch}',
        aiModel: Value(_currentAiMode),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      debugPrint('💾 [RemoteSSH] Session saved to SQLite for $host');
    } catch (e) {
      debugPrint('❌ [RemoteSSH] Failed to save session to DB: $e');
    }
  }

  Future<void> _clearSessionFromDb() async {
    try {
      final db = context.read<AppDatabase>();
      final host = _sshService.hostSignal.value;
      await db.sshSessionsDAO.deleteSessionsByIp(host);
      debugPrint('🧹 [RemoteSSH] Session cleared from SQLite for $host');
    } catch (e) {
      debugPrint('❌ [RemoteSSH] Failed to clear session from DB: $e');
    }
  }

  void _onShortcutPressed(String key) {
    if (!_isConnected) return;

    switch (key) {
      case 'ESC':
        _sshService.write('\x1b');
        break;
      case 'TAB':
        _sshService.write('\t');
        break;
      case 'S-TAB':
        _sshService.write('\x1b[Z');
        break;
      default:
        _sshService.write(key);
    }
  }

  void _sendCommand() {
    final cmd = _commandController.text;

    if (_isConnected) {
      if (_currentAiMode != 'standard' || cmd.startsWith('/') || cmd.contains('gemini') || cmd.contains('opencode')) {
        // AI Command - Provide context if path is set
        _sendAiPrompt(cmd);
      } else {
        _sshService.write('$cmd\r');
      }
    } else {
      _sshService.terminal.write(
        '\x1b[38;5;196m>>> OFFLINE. ESTABLISH UPLINK FIRST.\x1b[0m\r\n',
      );
    }

    _commandController.clear();
  }

  void _showNoteSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          SSHNoteSelectorSheet(onNoteSelected: _handleNoteImport),
    );
  }

  void _handleNoteImport(ProjectNoteData note) {
    final plainText = _extractPlainText(note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importing Plan'),
        content: Text(
          'How would you like to process "${note.title}"?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _commandController.text = plainText;
              });
            },
            child: const Text('Paste to Input'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _sendAiPrompt(plainText);
            },
            child: const Text('Send as AI'),
          ),
        ],
      ),
    );
  }

  String _extractPlainText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .where((op) => op is Map && op.containsKey('insert'))
            .map((op) => op['insert'])
            .join('')
            .trim();
      }
    } catch (_) {}
    // Strip markdown formatting for shell compatibility
    return content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'~~'), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'>\s'), '')
        .replaceAll(RegExp(r'- '), '')
        .trim();
  }

  void _sendAiPrompt(String text, {bool includeContext = true}) {
    if (!_isConnected) return;
    
    // Check if we need to do the initial cd
    if (!_hasDoneInitialCd && _sshService.remotePathSignal.value.isNotEmpty) {
      _sshService.write('cd "${_sshService.remotePathSignal.value}"\r');
      _hasDoneInitialCd = true;
    }

    if (_currentAiMode == 'standard') {
      _sshService.write('$text\r');
      return;
    }

    String promptText = text.trim();
    if (promptText.isEmpty) return;

    // Clean up if user already included command prefixes
    if (promptText.startsWith('/')) {
      promptText = promptText.substring(1).trim();
    } else if (promptText.startsWith('gemini ')) {
      promptText = promptText.substring(7).trim();
      if (promptText.startsWith('prompt ')) {
        promptText = promptText.substring(7).trim();
      }
    } else if (promptText.startsWith('opencode ')) {
      promptText = promptText.substring(9).trim();
      if (promptText.startsWith('prompt ')) {
        promptText = promptText.substring(7).trim();
      }
    }

    String aiContext = '';
    if (includeContext && _sshService.remotePathSignal.value.isNotEmpty) {
      aiContext =
          '\n\n[System Context: The user is currently focusing on this remote path/file: ${_sshService.remotePathSignal.value}]';
    }

    final mode = _sshService.aiMode.value;
    final customPrefix = _sshService.aiPromptPrefix.value;
    final fullPrompt = '$customPrefix$promptText$aiContext';

    // Robust Bash Escaping: wrap in single quotes, escape inner single quotes
    final escapedPrompt = "'${fullPrompt.replaceAll("'", "'\\''")}'";

    // Use Ctrl+U (\x15) to clear current line in bash before sending command
    if (mode == 'gemini') {
      _sshService.write('\x15gemini prompt $escapedPrompt\r');
    } else if (mode == 'opencode') {
      _sshService.write('\x15opencode prompt $escapedPrompt\r');
    } else if (mode == 'openclaw') {
      _sshService.write('\x15openclaw run $escapedPrompt\r');
    }
  }

  void showConfigDialog() {
    final controller = TextEditingController(text: _sshService.aiPromptPrefix.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Config ${_currentAiMode.toUpperCase()} Prompt'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter systemic prefix for AI commands...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _saveAiPrompt(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void showConnectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SSHConnectionSheet(
          hostController: _hostController,
          portController: _portController,
          userController: _userController,
          passController: _passController,
          remotePathController: _remotePathController,
          useTmux: _useTmux,
          onUseTmuxChanged: (val) {
            _sshService.useTmuxSignal.value = val;
            setModalState(() {});
          },
          onConnect: _connect,
        ),
      ),
    );
  }

  Widget _buildTerminalVisualEffects() {
    return Stack(
      children: [
        // Scanlines
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: List.generate(
                  200,
                  (index) => index % 2 == 0 ? Colors.black.withOpacity(0.05) : Colors.transparent,
                ),
                stops: List.generate(200, (index) => index / 200),
              ),
            ),
          ),
        ),
        // Vignette
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalHUD() {
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<Map<String, dynamic>>(
      stream: _sshService.statsStream,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final latency = stats['latencyMs']?.toStringAsFixed(1) ?? '0.0';
        final uptime = stats['uptime']?.toString().split('.').first ?? '00:00:00';
        final kbitsIn = ((stats['bytesIn'] ?? 0) * 8 / 1024).toStringAsFixed(1);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _hudLine('UPLINK', _isConnected ? 'LINKED' : 'OFFLINE', _isConnected ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(height: 4),
              _hudLine('LATENCY', '${latency}ms', colorScheme.primary),
              const SizedBox(height: 4),
              _hudLine('TRAFFIC', '${kbitsIn}kbps', colorScheme.secondary),
              const SizedBox(height: 4),
              _hudLine('UPTIME', uptime, Colors.white.withOpacity(0.5)),
            ],
          ),
        );
      },
    );
  }

  Widget _hudLine(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'Monospace'),
        ),
      ],
    );
  }

  Widget _buildUplinkOfflineOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'UPLINK INTERRUPTED',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                'INITIATING AUTO-RECOVERY PROTOCOL...',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_activeState == this) _activeState = null;
    _terminalController.dispose();
    _connectionSub.cancel();
    _signalEffect.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0A0C10),
      body: Column(
        children: [
          // Padding for Dynamic Island
          const SizedBox(height: 70),
          // Terminal Area - Maximized estate
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.05),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = (constraints.maxWidth / 9.0).floor();
                        final rows = (constraints.maxHeight / 18.0).floor();

                        _sshService.resize(cols, rows);

                        return TerminalViewNative(
                          _sshService.terminal,
                          controller: _terminalController,
                          autofocus: true,
                        );
                      },
                    ),
                  ),
                  // Terminal Overlay (Scanlines/Glow)
                  IgnorePointer(
                    child: _buildTerminalVisualEffects(),
                  ),
                  // HUD Telemetry
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildTerminalHUD(),
                  ),
                  // Connection Stability Indicator
                  if (!_isConnected)
                    Positioned.fill(
                      child: _buildUplinkOfflineOverlay(),
                    ),
                ],
              ),
            ),
          ),

     
          // Quick Command Buttons for better control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickBtn('ESC', '\x1b', Colors.orangeAccent, colorScheme),
                _quickBtn('ENTER', '\r', Colors.greenAccent, colorScheme),
                _quickBtn('CTRL+C', '\x03', Colors.redAccent, colorScheme),
                const Spacer(),
                _quickBtn('←', '\x1b[D', colorScheme.primary, colorScheme),
                _quickBtn('↑', '\x1b[A', colorScheme.primary, colorScheme),
                _quickBtn('↓', '\x1b[B', colorScheme.primary, colorScheme),
                _quickBtn('→', '\x1b[C', colorScheme.primary, colorScheme),
              ],
            ),
          ),

          // Command Input
          SSHCommandInput(
            controller: _commandController,
            onSend: _sendCommand,
            onNoteImportPressed: _showNoteSelector,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _quickBtn(String label, String value, Color color, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _sshService.write(value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

