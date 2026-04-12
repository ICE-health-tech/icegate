import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';
import 'TalkSSHPage.dart';

class TalkSSHPlugin extends BasePluginProtocol {
  const TalkSSHPlugin()
    : super(
        name: 'UPLINK Terminal',
        description: 'Establish a secure encrypted link to remote cognitive environments',
        icon: Icons.terminal_rounded,
        protocol: 'ssh',
        host: 'remote.cli',
        url: '/widgets/ssh',
        imageUrl: null,
        category: PluginCategory.other,
        tags: const ['ssh', 'terminal', 'cli', 'gemini'],
        requiresAuth: true,
      );

  static void navigateToSSH(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TalkSSHPage()),
    );
  }
}
