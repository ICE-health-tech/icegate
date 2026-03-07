import 'package:flutter/material.dart';
import '../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';
import 'WebViewPage.dart';

/// Plugin definition for a Live Map widget using WebView
class LiveMapPlugin extends BasePluginProtocol {
  const LiveMapPlugin()
    : super(
        name: 'Live Web Map',
        description: 'Embed live OpenStreetMap website',
        icon: Icons.public,
        protocol: 'widget',
        host: 'webview',
        // We use a query parameter to specify the target URL
        url: 'widget://webview?target=https://www.openstreetmap.org',
        imageUrl: null,
        category: PluginCategory.tracking,
        tags: const ['map', 'web', 'live', 'openstreetmap'],
        requiresAuth: false,
      );

  /// Navigate to WebView page
  static void navigateToWebView(BuildContext context, String url) {
    // Parse target URL
    final uri = Uri.parse(url);
    final targetUrl = uri.queryParameters['target'] ?? 'https://google.com';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WebViewPage(url: targetUrl, title: 'Live Web Map'),
      ),
    );
  }
}
