import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Services/DevLauncherPrefs.dart';

/// Opens homelab shortcuts and pins them to canvas (internal or web widget).
abstract final class DevLauncherBridge {
  static DevWebShortcut shortcutFromPlugin(BasePluginProtocol plugin) {
    final url = plugin.protocol == 'internal'
        ? plugin.url
        : plugin.fullUrl;
    return DevWebShortcut(
      id: plugin.name.toLowerCase().replaceAll(' ', '_'),
      name: plugin.name,
      url: url,
    );
  }

  static void open(BuildContext context, DevWebShortcut item) {
    if (item.url.startsWith('/')) {
      context.push(item.url);
      return;
    }
    WidgetNavigatorAction.navigateExternalUrl(
      context,
      item.url,
      title: item.name,
    );
  }

  static ExternalWidgetProtocol externalProtocolFromUrl(
    String name,
    String urlText,
  ) {
    final parsed = _parseUrl(urlText);
    return ExternalWidgetProtocol(
      name: name,
      protocol: parsed['protocol'] ?? 'https',
      host: parsed['host'] ?? '',
      url: parsed['url'] ?? '/',
      imageUrl: '',
      dateAdded: DateTime.now().toIso8601String(),
    );
  }

  static Future<void> pinToCanvas({
    required BuildContext context,
    required DevWebShortcut item,
    required String personId,
    required ExternalWidgetsDAO externalDao,
    required InternalWidgetsDAO internalDao,
    String scope = 'home',
  }) async {
    if (personId.isEmpty) return;

    if (item.url.startsWith('/')) {
      final widgetId = IDGen.UUIDV7();
      final alias = '${item.name.toLowerCase().replaceAll(' ', '_')}_'
          '${widgetId.substring(0, 8)}';
      await internalDao.insertInternalWidget(
        widgetID: widgetId,
        personID: personId,
        name: item.name,
        alias: alias,
        url: item.url,
        scope: scope,
      );
      return;
    }

    await externalDao.insertNewWidget(
      externalWidgetProtocol: externalProtocolFromUrl(item.name, item.url),
      personID: personId,
    );
  }

  static Map<String, String> _parseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasAuthority) {
      return {
        'protocol': uri.scheme.isNotEmpty ? uri.scheme : 'https',
        'host': uri.host.isNotEmpty ? uri.host : 'N/A',
        'url': uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : ''),
      };
    }
    return {'protocol': 'https', 'host': 'N/A', 'url': url};
  }
}
