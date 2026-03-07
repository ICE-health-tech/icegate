import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';

/// OpenStreetMap plugin for displaying interactive maps
class MapPlugin extends BasePluginProtocol {
  const MapPlugin()
    : super(
        name: 'Map',
        description: 'Interactive OpenStreetMap with multiple tile styles',
        icon: Icons.map,
        protocol: 'https',
        host: 'tile.openstreetmap.org',
        url: '/',
        imageUrl: null,
        category: PluginCategory.other,
        tags: const ['map', 'openstreetmap', 'navigation', 'location'],
        requiresAuth: false,
      );
}
