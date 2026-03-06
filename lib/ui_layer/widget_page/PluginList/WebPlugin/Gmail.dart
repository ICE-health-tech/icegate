import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';

class GmailPlugin extends BasePluginProtocol {
  const GmailPlugin()
    : super(
        name: 'Gmail',
        description: 'Access your email inbox and messages',
        icon: Icons.email,
        protocol: 'https',
        host: 'mail.google.com',
        url: '/mail/u/0/',
        imageUrl: null,
        category: PluginCategory.communication,
        tags: const ['email', 'google', 'messaging'],
        requiresAuth: true,
      );
}
