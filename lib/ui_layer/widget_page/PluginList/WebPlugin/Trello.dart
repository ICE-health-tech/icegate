import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';

class TrelloPlugin extends BasePluginProtocol {
  const TrelloPlugin()
    : super(
        name: 'Trello',
        description: 'Manage your project boards and tasks',
        icon: Icons.dashboard,
        protocol: 'https',
        host: 'trello.com',
        url: '/b/',
        imageUrl: null,
        category: PluginCategory.productivity,
        tags: const ['project-management', 'kanban', 'tasks'],
        requiresAuth: true,
      );
}
