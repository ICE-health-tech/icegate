import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
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
import 'widgets/SSHShortcutKeyRow.dart';
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
                    _TalkSSHPageState._activeState?._applyHostAndConnect(host);
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
              _TalkSSHPageState._activeState?._showConnectDialog(context),
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
  final SSHService _sshService = SSHService();
  final SSHStorageService _storageService = SSHStorageService();
  late final TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();

  final TextEditingController _hostController = TextEditingController(
    text: 'localhost',
  );
  final TextEditingController _portController = TextEditingController(
    text: '22',
  );
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _remotePathController = TextEditingController();
  bool _useTmux = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isConnected = false;
  String? _aiPromptPrefix;

  @override
  void initState() {
    super.initState();
    _activeState = this;
    _terminalController = TerminalController();
    _loadAiPrompt();

    // Initialize from existing connection if any
    _isConnected = _sshService.isConnected;

    // Listen to connection state
    _sshService.connectionState.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // Initial terminal message if not connected
    if (!_isConnected) {
      _sshService.terminal.write(
        '\x1b[1m\x1b[38;5;39mUPLINK TERMINAL v2.0 - SECURE ACCESS LAYER\x1b[0m\r\n\x1b[38;5;240m>>> COGNITIVE ENGINE READY. STANDBY FOR LINK.\x1b[0m\r\n\r\n',
      );
    }

    // Handle initial prompt from router
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialPrompt(widget.initialPrompt!);
      });
    }

    if (widget.remotePath != null) {
      _remotePathController.text = widget.remotePath!;
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

    // Auto-connect if hostId is provided
    if (widget.hostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final hosts = await _storageService.loadHosts();
        final host = hosts.cast<SSHHostModel?>().firstWhere(
          (h) => h?.id == widget.hostId,
          orElse: () => null,
        );
        if (host != null) {
          _applyHostAndConnect(host);

          // If we have initial content (e.g. a note), send it as an AI prompt after connecting
          if (widget.initialContent != null) {
            _handleInitialContent(widget.initialContent!);
          }
        }
      });
    }
  }

  void _handleInitialContent(String content) {
    // Convert to plain text if it's JSON content
    final plainText = _extractPlainText(content);

    if (_sshService.isConnected) {
      debugPrint('🚀 [TalkSSH] Already connected, sending AI prompt immediately');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _sendAiPrompt(plainText);
      });
      return;
    }

    // Wait for connection to be active before sending AI prompt
    debugPrint('⏳ [TalkSSH] Waiting for connection before sending prompt...');
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

  Future<void> _loadAiPrompt() async {
    final personID = context.read<PersonBlock>().information.value.profiles.id;
    if (personID == null) return;

    final mode = _currentAiMode;
    final dao = context.read<AppDatabase>().aiPromptsDAO;
    final data = await dao.getPrompt(personID, mode);
    
    setState(() {
      _aiPromptPrefix = data?.prompt ?? '';
    });
  }

  Future<void> _saveAiPrompt(String prompt) async {
    final personID = context.read<PersonBlock>().information.value.profiles.id;
    if (personID == null) return;

    final mode = _currentAiMode;
    final dao = context.read<AppDatabase>().aiPromptsDAO;
    await dao.savePrompt(personID, mode, prompt);
    
    setState(() {
      _aiPromptPrefix = prompt;
    });
  }

  String get _currentAiMode => _localAiMode ?? widget.aiMode ?? 'standard';
  String? _localAiMode;

  void _toggleAiMode() async {
    final modes = ['standard', 'gemini', 'opencode', 'openclaw'];
    final currentIndex = modes.indexOf(_currentAiMode);
    final nextMode = modes[(currentIndex + 1) % modes.length];
    
    setState(() {
      _localAiMode = nextMode;
    });
    
    // Persist choice to database
    await context.read<AppDatabase>().internalWidgetsDAO.updateInternalWidgetUrl(
      'ssh_uplink',
      '/widgets/ssh?aiMode=$nextMode',
    );
    
    // Reload prompt for new mode (if applicable)
    if (nextMode != 'standard') {
      _loadAiPrompt();
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

  void _applyHostAndConnect(SSHHostModel host) {
    _hostController.text = host.host;
    _portController.text = host.port.toString();
    _userController.text = host.user;
    _passController.text = host.password ?? '';
    _remotePathController.text = host.remoteFilePath ?? '';
    _connect();
  }

  void _connect() async {
    if (_isConnected) {
      _sshService.disconnect();
      await _clearSessionFromDb();
    }

    try {
      final host = _hostController.text;
      final port = int.parse(_portController.text);
      final user = _userController.text;
      final pass = _passController.text;

      final autoCmd = _remotePathController.text.isNotEmpty
          ? 'cd "${_remotePathController.text}" && clear'
          : null;

      await _sshService.connect(
        host: host,
        port: port,
        username: user,
        password: pass,
        useTmux: _useTmux,
        autoStartCommand: autoCmd,
      );

      // Save host info if successful
      await _storageService.saveHost(
        SSHHostModel(
          name: host,
          host: host,
          port: port,
          user: user,
          password: pass,
          remoteFilePath: _remotePathController.text,
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
      final host = _hostController.text;
      
      // Clear old sessions for this IP first
      await db.sshSessionsDAO.deleteSessionsByIp(host);
      
      await db.sshSessionsDAO.insertSSHSession(SSHSessionsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        ipAddress: host,
        localPath: const Value.absent(),
        remotePath: Value(_remotePathController.text),
        projectID: Value(widget.hostId), // If hostId is project ID in some contexts
        sessionName: 'ssh_session_${DateTime.now().millisecondsSinceEpoch}',
        aiModel: Value(_currentAiMode),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      debugPrint('💾 [TalkSSH] Session saved to SQLite for $host');
    } catch (e) {
      debugPrint('❌ [TalkSSH] Failed to save session to DB: $e');
    }
  }

  Future<void> _clearSessionFromDb() async {
    try {
      final db = context.read<AppDatabase>();
      final host = _hostController.text;
      await db.sshSessionsDAO.deleteSessionsByIp(host);
      debugPrint('🧹 [TalkSSH] Session cleared from SQLite for $host');
    } catch (e) {
      debugPrint('❌ [TalkSSH] Failed to clear session from DB: $e');
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
      if (cmd.startsWith('/') || cmd.contains('gemini') || cmd.contains('opencode')) {
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
    if (includeContext && _remotePathController.text.isNotEmpty) {
      aiContext =
          '\n\n[System Context: The user is currently focusing on this remote path/file: ${_remotePathController.text}]';
    }

    final mode = _currentAiMode;
    final customPrefix = _aiPromptPrefix ?? '';
    final fullPrompt = '$customPrefix$promptText$aiContext';

    // Robust Bash Escaping: wrap in single quotes, escape inner single quotes
    final escapedPrompt = "'${fullPrompt.replaceAll("'", "'\\''")}'";

    // Use Ctrl+U (\x15) to clear current line in bash before sending command
    if (mode == 'gemini') {
      _sshService.write('\x15gemini prompt $escapedPrompt\r');
    } else if (mode == 'opencode') {
      _sshService.write('\x15opencode run $escapedPrompt\r');
    } else if (mode == 'openclaw') {
      _sshService.write('\x15openclaw run $escapedPrompt\r');
    }
  }

  void _showConfigDialog() {
    final controller = TextEditingController(text: _aiPromptPrefix);
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

  void _showConnectDialog(BuildContext context) {
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
            setModalState(() => _useTmux = val);
            setState(() {});
          },
          onConnect: _connect,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UPLINK Terminal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _isConnected ? 'Connected to ${_hostController.text}' : 'Ready for Uplink',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentAiMode == 'standard'
                    ? Colors.white12
                    : (_currentAiMode == 'gemini' 
                        ? Colors.orange.withOpacity(0.2) 
                        : (_currentAiMode == 'opencode' 
                            ? Colors.blue.withOpacity(0.2) 
                            : Colors.purple.withOpacity(0.2))),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                elevation: 0,
              ),
              onPressed: _toggleAiMode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentAiMode == 'standard'
                        ? Icons.terminal_rounded
                        : (_currentAiMode == 'gemini' 
                            ? Icons.auto_awesome 
                            : (_currentAiMode == 'opencode' 
                                ? Icons.code_rounded 
                                : Icons.hub_rounded)),
                    size: 16,
                    color: _currentAiMode == 'standard'
                        ? Colors.white
                        : (_currentAiMode == 'gemini' 
                            ? Colors.orangeAccent 
                            : (_currentAiMode == 'opencode' 
                                ? Colors.blueAccent 
                                : Colors.purpleAccent)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentAiMode.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          if (_currentAiMode == 'openclaw')
            IconButton(
              icon: const Icon(Icons.security_rounded, size: 20),
              onPressed: () => _sshService.write('\x15openclaw providers\r'),
              tooltip: 'OpenClaw Providers',
            ),
          IconButton(
            icon: const Icon(Icons.lan_outlined, size: 20),
            onPressed: () => _showConnectDialog(context),
            tooltip: 'Connection Settings',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: _showConfigDialog,
            tooltip: 'AI Prompt Settings',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'kill_deploy_1') {
                _sshService.killTmuxSession('deploy_1');
              } else if (value == 'kill_ice_gate') {
                _sshService.killTmuxSession('ice_gate');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'kill_deploy_1',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                    SizedBox(width: 12),
                    Text('Kill deploy_1', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'kill_ice_gate',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.orangeAccent, size: 18),
                    SizedBox(width: 12),
                    Text('Kill ice_gate', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
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
              child: ClipRRect(
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
            ),
          ),

          // Shortcut Keys
          SSHShortcutKeyRow(onKeyPressed: _onShortcutPressed),

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

  @override
  void dispose() {
    if (_activeState == this) _activeState = null;
    _terminalController.dispose();
    super.dispose();
  }
}
