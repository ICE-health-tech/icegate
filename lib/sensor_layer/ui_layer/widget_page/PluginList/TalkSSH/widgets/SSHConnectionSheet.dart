import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/CursorApiService.dart';
import 'package:ice_gate/orchestration_layer/Services/SSHService.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../SSHHostModel.dart';
import '../SSHStorageService.dart';

class SSHConnectionSheet extends StatefulWidget {
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController userController;
  final TextEditingController passController;
  final TextEditingController remotePathController;
  final bool useTmux;
  final ValueChanged<bool> onUseTmuxChanged;
  final VoidCallback onConnect;

  const SSHConnectionSheet({
    super.key,
    required this.hostController,
    required this.portController,
    required this.userController,
    required this.passController,
    required this.remotePathController,
    required this.useTmux,
    required this.onUseTmuxChanged,
    required this.onConnect,
  });

  @override
  State<SSHConnectionSheet> createState() => _SSHConnectionSheetState();
}

class _SSHConnectionSheetState extends State<SSHConnectionSheet> {
  List<SSHHostModel> _savedHosts = [];
  bool _isLoadingHosts = true;
  final _cursorKeyController = TextEditingController();
  final _cursorApi = CursorApiService.instance;
  final _sshService = SSHService();
  bool _cursorKeyObscure = true;
  String? _cursorStatus;

  @override
  void initState() {
    super.initState();
    _loadHosts();
    _cursorApi.refreshKeyState();
  }

  @override
  void dispose() {
    _cursorKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadHosts() async {
    final storageService = SSHStorageService();
    final hosts = await storageService.loadHosts();
    if (mounted) {
      setState(() {
        _savedHosts = hosts;
        _isLoadingHosts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
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
            if (_isLoadingHosts)
              const Center(child: CircularProgressIndicator())
            else if (_savedHosts.isNotEmpty) ...[
              Text(
                'SAVED CONNECTIONS',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontFamily: 'Courier',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedHosts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final host = _savedHosts[index];
                    return ActionChip(
                      label: Text(
                        host.name,
                        style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold),
                      ),
                      avatar: const Icon(Icons.computer, size: 16),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                      onPressed: () {
                        widget.hostController.text = host.host;
                        widget.portController.text = host.port.toString();
                        widget.userController.text = host.user;
                        widget.passController.text = host.password ?? '';
                        widget.remotePathController.text = host.remoteFilePath ?? '';
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField(context, widget.hostController, l10n.ssh_host_label, Icons.dns),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 3, child: _buildTextField(context, widget.userController, l10n.ssh_user_label, Icons.person)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField(context, widget.portController, l10n.ssh_port_label, Icons.numbers)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(context, widget.passController, l10n.ssh_pass_label, Icons.lock, obscureText: true),
            const SizedBox(height: 12),
            _buildTextField(context, widget.remotePathController, 'REMOTE FILE PATH', Icons.folder_open),
            const SizedBox(height: 16),
            Watch((context) {
              if (_sshService.aiMode.value != 'cursor') {
                return const SizedBox.shrink();
              }
              final hasKey = _cursorApi.hasKeySignal.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.tealAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.smart_toy_outlined,
                          size: 18,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.ssh_cursor_api_title.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontFamily: 'Courier',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (hasKey) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.ssh_cursor_api_key_stored,
                        style: TextStyle(
                          color: Colors.greenAccent.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cursorKeyController,
                      obscureText: _cursorKeyObscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.ssh_cursor_api_key_hint,
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _cursorKeyObscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _cursorKeyObscure = !_cursorKeyObscure,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_cursorStatus != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _cursorStatus!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await _cursorApi.saveApiKey(
                              _cursorKeyController.text,
                            );
                            if (!mounted) return;
                            setState(() {
                              _cursorStatus = l10n.ssh_cursor_api_saved;
                            });
                            _cursorKeyController.clear();
                          },
                          child: Text(l10n.ssh_cursor_api_save),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await _cursorApi.testConnection(
                              apiKey: _cursorKeyController.text.trim().isEmpty
                                  ? null
                                  : _cursorKeyController.text,
                            );
                            if (!mounted) return;
                            setState(() {
                              if (result.ok) {
                                _cursorStatus = l10n.ssh_cursor_api_test_ok;
                                if (_cursorKeyController.text
                                    .trim()
                                    .isNotEmpty) {
                                  _cursorApi.saveApiKey(
                                    _cursorKeyController.text,
                                  );
                                  _cursorKeyController.clear();
                                }
                              } else if (result.message == 'missing_key') {
                                _cursorStatus =
                                    l10n.ssh_cursor_api_missing_key;
                              } else {
                                _cursorStatus = l10n.ssh_cursor_api_test_fail(
                                  result.message,
                                );
                              }
                            });
                          },
                          child: Text(l10n.ssh_cursor_api_test),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'PERSISTENT SESSION (TMUX)',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Keeps shell alive on server if app closes',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                    value: widget.useTmux,
                    onChanged: widget.onUseTmuxChanged,
                    activeThumbColor: colorScheme.primary,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.terminal_rounded, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'SESSION TOOLS',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                              fontFamily: 'Courier',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 14),
                          label: const Text('KILL DEPLOY_1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          onPressed: () {
                            SSHService().killTmuxSession('deploy_1');
                          },                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onConnect();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.4),
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
        prefixIcon: Icon(icon, size: 18, color: colorScheme.primary.withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
