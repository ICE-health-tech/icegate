import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WebView/WebViewPage.dart';

class WidgetNavigatorAction {
  static void navigateExternalUrl(BuildContext context, String fullUrl) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => WebViewPage(url: fullUrl)));
  }

  static void smartPop(BuildContext context, [String route = "/"]) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(route);
    }
  }
}
