import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:xterm/xterm.dart';
import 'TerminalViewAdapter.dart';
import '../../../../initial_layer/CoreLogics/SSHService.dart';
import 'widgets/SSHHeader.dart';
import 'widgets/SSHSearchBar.dart';
import 'widgets/SSHAIGenerator.dart';
import 'widgets/SSHShortcutKeyRow.dart';
import 'widgets/SSHCommandInput.dart';
import 'SSHHostModel.dart';
import 'SSHStorageService.dart';

class TalkSSHPage extends StatefulWidget {
  const TalkSSHPage({super.key});

  @override
  State<TalkSSHPage> createState() => _TalkSSHPageState();
}

class _TalkSSHPageState extends State<TalkSSHPage> {
  final SSHService _sshService = SSHService();
  final SSHStorageService _storageService = SSHStorageService();
  late final TerminalController _terminalController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commandController = TextEditingController();
  
  final TextEditingController _hostController = TextEditingController(text: 'localhost');
  final TextEditingController _portController = TextEditingController(text: '22');
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isConnecting = false;
  bool _isConnected = false;
  
  // Current session info
  String _currentServerName = "ICE GATE Terminal";
  String _currentIP = "---";
  String _currentUptime = "---";

  @override
  void initState() {
    super.initState();
    _terminalController = TerminalController();
    
    // Listen to connection state
    _sshService.connectionState.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // Initial terminal message
    _sshService.terminal.write('ICE GATE SSH v1.0.0\r\nType /connect or use the settings to start a session.\r\n\r\n');
  }

  void _connect() async {
    setState(() {
      _isConnecting = true;
      _currentServerName = _hostController.text;
      _currentIP = _hostController.text;
    });

    try {
      await _sshService.connect(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _userController.text,
        password: _passController.text,
      );
      
      setState(() {
        _currentUptime = "Just now";
      });
      
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
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _onShortcutPressed(String key) {
    if (!_isConnected) return;
    
    switch (key) {
      case 'ESC': _sshService.write('\x1b'); break;
      case 'TAB': _sshService.write('\t'); break;
      case 'CTRL': /* Handle modifier state if needed */ break;
      case 'ALT': /* Handle modifier state if needed */ break;
      default: _sshService.write(key);
    }
  }

  void _sendCommand() {
    final cmd = _commandController.text;
    if (cmd.isEmpty) return;
    
    if (_isConnected) {
      _sshService.write('$cmd\n');
    } else {
      _sshService.terminal.write('\x1b[33mNot connected. Use /connect to start.\x1b[0m\r\n');
    }
    
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SSHHeader(
              serverName: _isConnected ? _currentServerName : "Disconnected",
              ipAddress: _currentIP,
              uptime: _isConnected ? _currentUptime : "---",
              onDisconnect: () => _sshService.disconnect(),
            ),
            
            // Search Bar
            SSHSearchBar(
              controller: _searchController,
              onSearch: (val) {
                // Implement history search logic if needed
              },
            ),
            
            // Terminal Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                ),
                child: TerminalViewNative(
                  _sshService.terminal,
                  controller: _terminalController,
                  autofocus: true,
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
          ],
        ),
      ),
      floatingActionButton: !_isConnected ? FloatingActionButton(
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add_link, color: colorScheme.onPrimary),
        onPressed: () => _showConnectDialog(context),
      ) : null,
    );
  }

  void _showConnectDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: colorScheme.surfaceVariant,
            title: Text(
              l10n.ssh_new_session, 
              style: TextStyle(
                color: colorScheme.primary, 
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Saved Hosts Section
                    FutureBuilder<List<SSHHostModel>>(
                      future: _storageService.loadHosts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RECENT SESSIONS',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final host = snapshot.data![index];
                                  return GestureDetector(
                                    onTap: () {
                                      _hostController.text = host.host;
                                      _portController.text = host.port.toString();
                                      _userController.text = host.user;
                                      _passController.text = host.password ?? '';
                                      setDialogState(() {});
                                    },
                                    child: Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.computer, color: colorScheme.primary, size: 20),
                                          const SizedBox(height: 4),
                                          Text(
                                            host.name,
                                            style: TextStyle(
                                              color: colorScheme.onSurface, 
                                              fontSize: 12, 
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            host.user,
                                            style: TextStyle(
                                              color: colorScheme.onSurface.withOpacity(0.5), 
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: Colors.white10),
                            ),
                          ],
                        );
                      }
                    ),
                    
                    _buildTextField(context, _hostController, l10n.ssh_host_label),
                    _buildTextField(context, _portController, l10n.ssh_port_label),
                    _buildTextField(context, _userController, l10n.ssh_user_label),
                    _buildTextField(context, _passController, l10n.ssh_pass_label, obscureText: true),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connect();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(
                  l10n.ssh_connect, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label, {bool obscureText = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Courier'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sshService.disconnect();
    _terminalController.dispose();
    super.dispose();
  }
}
