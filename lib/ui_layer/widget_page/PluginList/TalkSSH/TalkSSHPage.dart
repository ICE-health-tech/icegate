import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:xterm/xterm.dart';
import 'TerminalViewAdapter.dart';
import '../../../../initial_layer/CoreLogics/SSHService.dart';
import 'widgets/SSHHeader.dart';
import 'widgets/SSHSearchBar.dart';
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
    
    // Initialize from existing connection if any
    _isConnected = _sshService.isConnected;

    // Listen to connection state
    _sshService.connectionState.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          if (connected) {
            _currentServerName = _sshService.currentHost ?? "ICE GATE Terminal";
            _currentIP = _sshService.currentHost ?? "---";
          } else {
            _currentUptime = "---";
          }
        });
      }
    });

    // Initial terminal message if not connected
    if (!_isConnected) {
      _sshService.terminal.write('\x1b[38;5;240mICE GATE SSH v1.5.0-PRO\x1b[0m\r\n\x1b[38;5;39m>>> READY FOR UPLINK. TYPE /connect OR USE THE HUB.\x1b[0m\r\n\r\n');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return '${duration.inDays}d ${duration.inHours % 24}h';
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes % 60}m';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    return '${duration.inSeconds}s';
  }

  void _connect() async {
    if (_isConnected) {
      _sshService.disconnect();
    }
    
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        title: Text(
          'ICE.TERMINAL.v1.5',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontFamily: 'Courier',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.hub_outlined, color: colorScheme.primary.withOpacity(0.6), size: 20),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colorScheme.primary.withOpacity(0.1), height: 1),
        ),
      ),
      drawer: _buildDrawer(colorScheme),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _sshService.statsStream,
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {};
          final bytesIn = stats['bytesIn'] as int? ?? 0;
          final bytesOut = stats['bytesOut'] as int? ?? 0;
          final latencyMs = stats['latencyMs'] as double? ?? 0.0;
          final uptime = stats['uptime'] as Duration? ?? Duration.zero;
          
          return SafeArea(
            child: Column(
              children: [
                // Header with stats
                SSHHeader(
                  serverName: _isConnected ? _currentServerName : "OFFLINE",
                  ipAddress: _currentIP,
                  uptime: _isConnected ? _formatDuration(uptime) : "---",
                  bytesIn: bytesIn,
                  bytesOut: bytesOut,
                  latencyMs: latencyMs,
                  onDisconnect: () => _sshService.disconnect(),
                  onConnect: () => _showConnectDialog(context),
                  isConnected: _isConnected,
                ),
                
                // Terminal Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.02),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Approximate character size
                          const charWidth = 8.5;
                          const charHeight = 16.0;
                          
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
              ],
            ),
          );
        }
      ),
      floatingActionButton: !_isConnected ? FloatingActionButton(
        backgroundColor: colorScheme.primary,
        onPressed: () => _showConnectDialog(context),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_link_rounded, color: Colors.black),
      ) : null,
    );
  }

  Widget _buildDrawer(ColorScheme colorScheme) {
    return Drawer(
      backgroundColor: Colors.black,
      width: 280,
      child: Column(
        children: [
          _buildDrawerHeader(colorScheme),
          Expanded(
            child: _buildSavedHostsList(colorScheme),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'PROTO.V1.5',
                  style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.primary.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Icon(Icons.terminal_rounded, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'UPLINK HUB',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SELECT TARGET HOST',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedHostsList(ColorScheme colorScheme) {
    return FutureBuilder<List<SSHHostModel>>(
      future: _storageService.loadHosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Opacity(
              opacity: 0.2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 40, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('NO TARGETS STORED', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final host = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _hostController.text = host.host;
                  _portController.text = host.port.toString();
                  _userController.text = host.user;
                  _passController.text = host.password ?? '';
                  _showConnectDialog(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.dns_outlined, color: colorScheme.primary.withOpacity(0.5), size: 18),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              host.name.toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1,
                                fontFamily: 'Courier',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${host.user}@${host.host}',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.3),
                                fontSize: 10,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: colorScheme.primary.withOpacity(0.3)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showConnectDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.add_link, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        l10n.ssh_new_session.toUpperCase(), 
                        style: TextStyle(
                          color: colorScheme.primary, 
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(context, _hostController, l10n.ssh_host_label, Icons.dns),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(flex: 3, child: _buildTextField(context, _userController, l10n.ssh_user_label, Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: _buildTextField(context, _portController, l10n.ssh_port_label, Icons.numbers)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(context, _passController, l10n.ssh_pass_label, Icons.lock, obscureText: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _connect();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                      ),
                      child: Text(
                        l10n.ssh_connect.toUpperCase(), 
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label, IconData icon, {bool obscureText = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        color: colorScheme.onSurface, 
        fontFamily: 'Courier',
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: colorScheme.primary.withOpacity(0.5)),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  void dispose() {
    // Keep SSHService alive for continuous session
    _terminalController.dispose();
    super.dispose();
  }
}
