import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SSHService.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/SSHHostModel.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart';

class SSHConfigForm extends StatefulWidget {
  final double scalingFactor;
  final ColorScheme colorScheme;

  const SSHConfigForm({
    super.key,
    required this.scalingFactor,
    required this.colorScheme,
  });

  @override
  State<SSHConfigForm> createState() => _SSHConfigFormState();
}

class _SSHConfigFormState extends State<SSHConfigForm> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _userController;
  late final TextEditingController _passController;
  late final TextEditingController _pathController;
  final sshService = SSHService();

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: sshService.hostSignal.value);
    _portController = TextEditingController(text: sshService.portSignal.value.toString());
    _userController = TextEditingController(text: sshService.userSignal.value);
    _passController = TextEditingController(text: sshService.passSignal.value);
    _pathController = TextEditingController(text: sshService.remotePathSignal.value);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _commitChanges() {
    sshService.hostSignal.value = _hostController.text;
    sshService.portSignal.value = int.tryParse(_portController.text) ?? 22;
    sshService.userSignal.value = _userController.text;
    sshService.passSignal.value = _passController.text;
    sshService.remotePathSignal.value = _pathController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final useTmux = sshService.useTmuxSignal.value;
      
      return Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              sshService.isConfigMode.value = false;
            },
            child: Icon(
              Icons.close_rounded,
              size: 14 * widget.scalingFactor,
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _configInput(
                    "IP",
                    _hostController,
                    widget.colorScheme,
                    widget.scalingFactor,
                  ),
                  _divider(widget.colorScheme),
                  _configInput(
                    "PORT",
                    _portController,
                    widget.colorScheme,
                    widget.scalingFactor,
                    keyboardType: TextInputType.number,
                  ),
                  _divider(widget.colorScheme),
                  _configInput(
                    "USER",
                    _userController,
                    widget.colorScheme,
                    widget.scalingFactor,
                  ),
                  _divider(widget.colorScheme),
                  _configInput(
                    "PASS",
                    _passController,
                    widget.colorScheme,
                    widget.scalingFactor,
                    isPassword: true,
                  ),
                  _divider(widget.colorScheme),
                  _configInput(
                    "PATH",
                    _pathController,
                    widget.colorScheme,
                    widget.scalingFactor,
                  ),
                  _divider(widget.colorScheme),
                  // TMUX Toggle
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      sshService.useTmuxSignal.value = !useTmux;
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "TMUX",
                          style: TextStyle(
                            color: widget.colorScheme.onSurfaceVariant,
                            fontSize: 7 * widget.scalingFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          useTmux ? Icons.toggle_on : Icons.toggle_off,
                          color: useTmux
                              ? Colors.greenAccent
                              : widget.colorScheme.onSurfaceVariant.withOpacity(0.5),
                          size: 16 * widget.scalingFactor,
                        ),
                      ],
                    ),
                  ),
                  _divider(widget.colorScheme),
                  // AI Prefix Config button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      TalkSSHPage.activeState?.showConfigDialog();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * widget.scalingFactor,
                        vertical: 2 * widget.scalingFactor,
                      ),
                      decoration: BoxDecoration(
                        color: widget.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "AI PRE",
                        style: TextStyle(
                          color: widget.colorScheme.primary,
                          fontSize: 7 * widget.scalingFactor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  _divider(widget.colorScheme),
                  // Kill Sessions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _killButton(
                        "D1",
                        "deploy_1",
                        Colors.redAccent,
                        widget.scalingFactor,
                      ),
                      const SizedBox(width: 4),
                      _killButton(
                        "IG",
                        "ice_gate",
                        Colors.orangeAccent,
                        widget.scalingFactor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // CONNECT Button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _commitChanges();
              TalkSSHPage.activeState?.applyHostAndConnect(
                SSHHostModel(
                  id: sshService.currentHostId,
                  name: sshService.hostSignal.value,
                  host: sshService.hostSignal.value,
                  port: sshService.portSignal.value,
                  user: sshService.userSignal.value,
                  password: sshService.passSignal.value,
                  remoteFilePath: sshService.remotePathSignal.value,
                  aiMode: sshService.aiMode.value,
                  aiPromptPrefix: sshService.aiPromptPrefix.value,
                ),
              );
              sshService.isConfigMode.value = false;
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * widget.scalingFactor,
                vertical: 4 * widget.scalingFactor,
              ),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "CONNECT",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 8 * widget.scalingFactor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _configInput(
    String label,
    TextEditingController controller,
    ColorScheme colorScheme,
    double scalingFactor, {
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 7 * scalingFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        SizedBox(
          width: 60 * scalingFactor,
          height: 14 * scalingFactor,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 9 * scalingFactor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Container(
      width: 0.5,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colorScheme.outlineVariant.withOpacity(0.3),
    );
  }

  Widget _killButton(
    String label,
    String sessionName,
    Color color,
    double scalingFactor,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        SSHService().killTmuxSession(sessionName);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 6 * scalingFactor,
          vertical: 2 * scalingFactor,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 7 * scalingFactor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
