import 'dart:io';

import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabProtocol.dart';

/// Picks local (LAN) vs remote URL when opening a dev tab.
abstract final class DevQuickTabUrlResolver {
  DevQuickTabUrlResolver._();

  static Future<bool> hostReachable(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    final port = uri.hasPort
        ? uri.port
        : (uri.scheme == 'https' ? 443 : 80);
    try {
      final socket = await Socket.connect(
        uri.host,
        port,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Tries [DevQuickTabProtocol.fullUrl] (LAN) first, then [remoteUrl].
  static Future<String?> resolveOpenUrl(DevQuickTabProtocol tab) async {
    final local = tab.fullUrl.trim();
    final remote = tab.remoteUrl.trim();
    if (local.isEmpty && remote.isEmpty) return null;
    if (local.isEmpty) return remote;
    if (remote.isEmpty) return local;

    if (await hostReachable(local)) return local;
    if (await hostReachable(remote)) return remote;
    return local;
  }
}
