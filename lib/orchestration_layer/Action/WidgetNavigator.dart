import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WebView/WebViewPage.dart';

class WidgetNavigatorAction {
  static void navigateExternalUrl(
    BuildContext context,
    String fullUrl, {
    String? title,
    List<WebViewUrlOption> urlOptions = const [],
  }) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) => WebViewPage(
          url: fullUrl,
          title: title ?? _titleFromUrl(fullUrl),
          urlOptions: urlOptions,
        ),
      ),
    );
  }

  static String _titleFromUrl(String fullUrl) {
    try {
      final host = Uri.parse(fullUrl).host.toLowerCase();
      if (host.contains('calendar.google')) return 'Google Calendar';
      if (host.isNotEmpty) return host;
    } catch (_) {}
    return 'Web';
  }

  static void smartPop(BuildContext context, [String route = "/"]) {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(route);
      }
    } catch (e) {
      debugPrint("Navigator Pop Error: $e");
      context.go(route);
    }
  }
}
