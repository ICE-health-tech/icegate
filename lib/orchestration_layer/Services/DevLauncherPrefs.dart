import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/WebPlugin/HomelabWebPlugins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local homelab launcher: web shortcuts + dev service logins (admin device only).
class DevWebShortcut {
  const DevWebShortcut({
    required this.id,
    required this.name,
    required this.url,
  });

  final String id;
  final String name;
  final String url;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'url': url};

  factory DevWebShortcut.fromJson(Map<String, dynamic> json) => DevWebShortcut(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
      );
}

class DevServiceAccount {
  const DevServiceAccount({
    required this.id,
    required this.service,
    required this.username,
    this.portalUrl,
  });

  final String id;
  final String service;
  final String username;
  final String? portalUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'service': service,
        'username': username,
        'portalUrl': portalUrl,
      };

  factory DevServiceAccount.fromJson(Map<String, dynamic> json) =>
      DevServiceAccount(
        id: json['id'] as String,
        service: json['service'] as String,
        username: json['username'] as String,
        portalUrl: json['portalUrl'] as String?,
      );
}

abstract final class DevLauncherPrefs {
  static const _shortcutsKey = 'dev_launcher_web_shortcuts_v1';
  static const _accountsKey = 'dev_launcher_accounts_v1';
  static const _secretPrefix = 'dev_launcher_secret_';

  static const _secure = FlutterSecureStorage();

  static Future<List<DevWebShortcut>> loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shortcutsKey);
    if (raw == null || raw.isEmpty) return _defaultShortcuts();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DevWebShortcut.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return _defaultShortcuts();
    }
  }

  static Future<void> saveShortcuts(List<DevWebShortcut> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _shortcutsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static List<DevWebShortcut> _defaultShortcuts() =>
      HomelabWebPlugins.catalog.map(_shortcutFromPlugin).toList();

  static DevWebShortcut _shortcutFromPlugin(BasePluginProtocol plugin) {
    final url =
        plugin.protocol == 'internal' ? plugin.url : plugin.fullUrl;
    return DevWebShortcut(
      id: plugin.name.toLowerCase().replaceAll(' ', '_'),
      name: plugin.name,
      url: url,
    );
  }

  static Future<List<DevServiceAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DevServiceAccount.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAccounts(List<DevServiceAccount> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> saveAccountSecret(String id, String secret) async {
    await _secure.write(key: '$_secretPrefix$id', value: secret);
  }

  static Future<String?> readAccountSecret(String id) =>
      _secure.read(key: '$_secretPrefix$id');

  static Future<void> deleteAccountSecret(String id) =>
      _secure.delete(key: '$_secretPrefix$id');
}
