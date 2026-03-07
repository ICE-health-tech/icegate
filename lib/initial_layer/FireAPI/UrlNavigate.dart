import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/OSMMapPlugin.dart';
import 'package:ice_gate/orchestration_layer/Action/WebView/LiveMapPlugin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart'; // For debugPrint

Future<void> urlNavigate(String url) async {
  // 1. Basic cleaning and validation
  if (url.isEmpty) {
    debugPrint("URL is empty. Navigation aborted.");
    return;
  }

  // 2. Ensure the URL has a scheme (http/https) for launchUrl
  Uri uri = Uri.tryParse(url) ?? Uri();
  if (!uri.hasScheme) {
    // Prepend HTTPS if no scheme is found
    uri = Uri.tryParse('https://$url') ?? Uri();
  }

  // 3. Check if the device can launch the URL
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Handle error gracefully (e.g., show a Snackbar in the UI)
    debugPrint('Could not launch $uri');
    // Note: If you need to show a Snackbar, this function would need
    // access to a BuildContext or a centralized error service.
    // For now, it just prints the error.
  }
}

void navigateExternalUrl(BuildContext context, String url) async {
  // Check for special widget protocol
  if (url.startsWith('widget://')) {
    if (url == 'widget://map') {
      OSMMapPlugin.navigateToMap(context);
      return;
    }
    if (url.startsWith('widget://webview')) {
      debugPrint("WebView widget detected: $url - Drag this to canvas to use");
      LiveMapPlugin.navigateToWebView(context, url);
      return;
    }
    debugPrint("Widget protocol detected: $url - Drag this to canvas to use");
    return;
  }

  // Future<void> _launchUrl() async {
  // 1. Check if the URL can be launched on the device
  if (!await launchUrl(Uri.parse(url))) {
    // 2. Throw an exception or display an error if launching fails
    throw Exception('Could not launch $url');
    // }
  }
  debugPrint("Navigating to URL: $url");
}
