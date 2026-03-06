import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';

class GitHubPlugin extends BasePluginProtocol {
  const GitHubPlugin()
    : super(
        name: 'GitHub',
        description: 'View repositories and code activity',
        icon: Icons.code,
        protocol: 'https',
        host: 'github.com',
        url: '/',
        imageUrl: null,
        category: PluginCategory.development,
        tags: const ['git', 'code', 'version-control'],
        requiresAuth: true,
      );
}
