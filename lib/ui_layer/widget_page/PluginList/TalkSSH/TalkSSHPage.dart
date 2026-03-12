import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'TerminalViewAdapter.dart';
import '../../../../initial_layer/CoreLogics/SSHService.dart';
import '../../../home_page/MainButton.dart';
import 'widgets/SSHShortcutKeyRow.dart';
import 'widgets/SSHCommandInput.dart';
import 'widgets/SSHConnectionSheet.dart';
import 'SSHHostModel.dart';
import 'SSHStorageService.dart';

class TalkSSHPage extends StatefulWidget {
  static final GlobalKey<_TalkSSHPageState> talkSSHKey = GlobalKey<_TalkSSHPageState>();
  const TalkSSHPage({super.key});

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
            talkSSHKey.currentState?._applyHostAndConnect(host);
          },
        )).toList();

        return MainButton(
          type: 'ssh_uplink',
          size: size,
          icon: Icons.lan,
          backgroundColor: colorScheme.primary,
          iconColor: colorScheme.onPrimary,
          mainFunction: () => talkSSHKey.currentState?._showConnectDialog(context),
          subButtons: subButtons,
        );
      }
    );
  }
}

class _TalkSSHPageState extends State<TalkSSHPage> {
  final SSHService _sshService = SSHService();
  final SSHStorageService _storageService = SSHStorageService();
  late final TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();
  
  final TextEditingController _hostController = TextEditingController(text: 'localhost');
  final TextEditingController _portController = TextEditingController(text: '22');
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
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
      _sshService.terminal.write('\x1b[38;5;240mICE GATE SSH v1.5.0-PRO\x1b[0m\r\n\x1b[38;5;39m>>> READY FOR UPLINK. TYPE /connect OR USE THE HUB.\x1b[0m\r\n\r\n');
    }
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
    if (cmd.isEmpty) return;
    
    if (_isConnected) {
      _sshService.write('$cmd\n');
    } else {
      _sshService.terminal.write('\x1b[38;5;196m>>> OFFLINE. ESTABLISH UPLINK FIRST.\x1b[0m\r\n');
    }
    
    _commandController.clear();
  }

  void _showConnectDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SSHConnectionSheet(
        hostController: _hostController,
        portController: _portController,
        userController: _userController,
        passController: _passController,
        onConnect: _connect,
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
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _terminalController.dispose();
    super.dispose();
  }
}
