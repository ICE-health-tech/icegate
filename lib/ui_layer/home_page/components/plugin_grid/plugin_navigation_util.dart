import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';

class PluginNavigationUtil {
  /// Navigates to an internal URL based on the provided name.
  /// Handles special cases for projects and default routing.
  static void navigateInternal(BuildContext context, String name) {
    if (name == '/projects') {
      context.push(name);
      return;
    }

    if (name.startsWith('/project')) {
      final parts = name.split('/');
      if (parts.length > 2) {
        final id = parts.last;
        context.push('/projects/$id');
        return;
      }
      context.push('/projects');
      return;
    }

    // Default case for internal routes
    context.push(name);
  }

  /// Navigates to an external URL using the WidgetNavigatorAction utility.
  static void navigateExternal(BuildContext context, String fullUrl) {
    WidgetNavigatorAction.navigateExternalUrl(context, fullUrl);
  }
}
