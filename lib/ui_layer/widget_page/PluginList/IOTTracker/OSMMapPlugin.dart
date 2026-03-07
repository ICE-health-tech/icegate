import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';
import 'GPSTrackingPage.dart';

/// Plugin definition for embeddable OSM Map widget
///
/// This plugin allows users to add an interactive OpenStreetMap widget
/// to their canvas. It uses a special protocol 'widget://map' to indicate
/// it should be rendered as an embedded map rather than a standard card.
class OSMMapPlugin extends BasePluginProtocol {
  const OSMMapPlugin()
    : super(
        name: 'GPS Map',
        description: 'Interactive OpenStreetMap widget for tracking locations',
        icon: Icons.map,
        protocol: 'widget',
        host: 'map',
        url: 'widget://map',
        imageUrl: null,
        category: PluginCategory.tracking,
        tags: const ['map', 'gps', 'location', 'openstreetmap', 'widget'],
        requiresAuth: false,
      );

  /// Navigate to GPS tracking page (Map View)
  static void navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GPSTrackingPage()),
    );
  }
}
