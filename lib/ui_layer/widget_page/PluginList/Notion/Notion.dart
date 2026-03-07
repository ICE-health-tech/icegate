import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';

class NotionPlugin extends BasePluginProtocol {
  const NotionPlugin()
    : super(
        name: 'Notion',
        description: 'Access your notes and databases',
        icon: Icons.note,
        protocol: 'https',
        host: 'notion.so',
        url: '/',
        imageUrl: null,
        category: PluginCategory.productivity,
        tags: const ['notes', 'database', 'workspace'],
        requiresAuth: true,
      );
}
