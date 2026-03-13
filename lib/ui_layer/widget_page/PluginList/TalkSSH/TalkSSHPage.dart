import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
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
  const TalkSSHPage({super.key, this.initialPrompt});

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
        final subButtons = hosts.take(5).map((host) => SubButton(
          icon: Icons.computer,
          label: host.name,
          backgroundColor: colorScheme.secondaryContainer,
          iconColor: colorScheme.onSecondaryContainer,
          onPressed: () {
            _TalkSSHPageState._activeState?._applyHostAndConnect(host);
          },
        )).toList();

        return MainButton(
          type: 'ssh_uplink',
          size: size,
          icon: Icons.lan,
          backgroundColor: colorScheme.primary,
          iconColor: colorScheme.onPrimary,
          mainFunction: () => _TalkSSHPageState._activeState?._showConnectDialog(context),
          subButtons: subButtons,
        );
      }
    );
  }
}

class _TalkSSHPageState extends State<TalkSSHPage> {
  static _TalkSSHPageState? _activeState;
  final SSHService _sshService = SSHService();
  final SSHStorageService _storageService = SSHStorageService();
  late final TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();
  
  final TextEditingController _hostController = TextEditingController(text: 'localhost');
  final TextEditingController _portController = TextEditingController(text: '22');
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _useTmux = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _activeState = this;
    _terminalController = TerminalController();
    
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
      _sshService.terminal.write('\x1b[38;5;240mICE GATE SSH v1.6.0-BACKGROUND-READY\x1b[0m\r\n\x1b[38;5;39m>>> READY FOR UPLINK. TYPE /connect OR USE THE HUB.\x1b[0m\r\n\r\n');
    }

    // Handle initial prompt from router
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInitialPrompt(widget.initialPrompt!);
      });
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
              _sshService.write('gemini prompt "${prompt.replaceAll('"', '\\"')}"\r');
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
    _connect();
  }

  void _connect() async {
    if (_isConnected) {
      _sshService.disconnect();
    }
    
    try {
      await _sshService.connect(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _userController.text,
        password: _passController.text,
        useTmux: _useTmux,
      );
      
      // Save host info if successful
      await _storageService.saveHost(SSHHostModel(
        name: _hostController.text,
        host: _hostController.text,
        port: int.parse(_portController.text),
        user: _userController.text,
        password: _passController.text,
      ));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('UPLINK FAILURE: $e', style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
          ),
        );
      }
    }
  }

  void _onShortcutPressed(String key) {
    if (!_isConnected) return;
    
    switch (key) {
      case 'ESC': _sshService.write('\x1b'); break;
      case 'TAB': _sshService.write('\t'); break;
      case 'S-TAB': _sshService.write('\x1b[Z'); break;
      default: _sshService.write(key);
    }
  }

  void _sendCommand() {
    final cmd = _commandController.text;
    
    if (_isConnected) {
      _sshService.write('$cmd\r');
    } else {
      _sshService.terminal.write('\x1b[38;5;196m>>> OFFLINE. ESTABLISH UPLINK FIRST.\x1b[0m\r\n');
    }
    
    _commandController.clear();
  }

  void _showNoteSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SSHNoteSelectorSheet(
        onNoteSelected: _handleNoteImport,
      ),
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
              _sshService.write('gemini prompt "${plainText.replaceAll('"', '\\"')}"\r');
            },
            child: const Text('Send as Gemini'),
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
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Spacer for Dynamic Island height - kept minimal
          const SizedBox(height: 60),
          
          // Terminal Area - Maximized estate
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
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
                    const charWidth = 9.0;
                    const charHeight = 18.0;
                    
                    final cols = (constraints.maxWidth / charWidth).floor();
                    final rows = (constraints.maxHeight / charHeight).floor();
                    
                    _sshService.resize(cols, rows);
                    
                    return TerminalViewNative(
                      _sshService.terminal,
                      controller: _terminalController,
                      autofocus: true,
                    );
                  }
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
