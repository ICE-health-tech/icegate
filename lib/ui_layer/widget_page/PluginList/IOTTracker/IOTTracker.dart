import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';
import 'GPSTrackingPage.dart';

class IOTTrackerPlugin extends BasePluginProtocol {
  const IOTTrackerPlugin()
    : super(
        name: 'Location Tracker',
        description: 'Track location using Bluetooth GPS devices',
        icon: Icons.gps_fixed,
        protocol: 'bluetooth',
        host: 'gps.device',
        url: '/tracking',
        imageUrl: null,
        category: PluginCategory.tracking,
        tags: const ['gps', 'bluetooth', 'location', 'iot'],
        requiresAuth: false,
      );

  /// Navigate to GPS tracking page
  static void navigateToGPSTracking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GPSTrackingPage()),
    );
  }
}
