import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum InfraApiProvider { cloudflare, tailscale, northflank }

class InfraApiTestResult {
  const InfraApiTestResult({
    required this.ok,
    required this.message,
    this.statusCode,
    this.summary,
  });

  final bool ok;
  final String message;
  final int? statusCode;
  final String? summary;
}

/// Homelab infra APIs — tokens on device only (System Monitor / admin).
abstract final class InfraApiService {
  static const _configKey = 'infra_api_config_v1';
  static const _secretPrefix = 'infra_api_token_';
  static const _secure = FlutterSecureStorage();

  static const Duration _timeout = Duration(seconds: 20);

  static String displayName(InfraApiProvider provider) => switch (provider) {
        InfraApiProvider.cloudflare => 'Cloudflare',
        InfraApiProvider.tailscale => 'Tailscale',
        InfraApiProvider.northflank => 'Northflank',
      };

  static IconData iconFor(InfraApiProvider provider) => switch (provider) {
        InfraApiProvider.cloudflare => Icons.cloud_rounded,
        InfraApiProvider.tailscale => Icons.vpn_lock_rounded,
        InfraApiProvider.northflank => Icons.cloud_sync_rounded,
      };

  static Color accentFor(InfraApiProvider provider) => switch (provider) {
        InfraApiProvider.cloudflare => const Color(0xFFF48120),
        InfraApiProvider.tailscale => const Color(0xFF64748B),
        InfraApiProvider.northflank => const Color(0xFF0A84FF),
      };

  static String docsHint(InfraApiProvider provider) => switch (provider) {
        InfraApiProvider.cloudflare =>
          'API Token → My Profile → API Tokens (Zone:Read, Account:Read)',
        InfraApiProvider.tailscale =>
          'Admin Console → Settings → Keys → Generate API key',
        InfraApiProvider.northflank =>
          'Team → API → Personal access token',
      };

  static Future<Map<String, dynamic>> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveConfig(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(map));
  }

  static String _id(InfraApiProvider p) => p.name;

  static Future<String?> readToken(InfraApiProvider provider) =>
      _secure.read(key: '$_secretPrefix${_id(provider)}');

  static Future<bool> hasToken(InfraApiProvider provider) async {
    final token = await readToken(provider);
    return token != null && token.trim().isNotEmpty;
  }

  static Future<void> saveToken(InfraApiProvider provider, String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      await clearToken(provider);
      return;
    }
    await _secure.write(key: '$_secretPrefix${_id(provider)}', value: trimmed);
  }

  static Future<void> clearToken(InfraApiProvider provider) =>
      _secure.delete(key: '$_secretPrefix${_id(provider)}');

  static Future<String?> readTailnet(InfraApiProvider provider) async {
    if (provider != InfraApiProvider.tailscale) return null;
    final cfg = await _loadConfig();
    final entry = cfg[_id(provider)];
    if (entry is! Map) return null;
    final tailnet = entry['tailnet'] as String?;
    if (tailnet == null || tailnet.trim().isEmpty) return '-';
    return tailnet.trim();
  }

  static Future<void> saveTailnet(String tailnet) async {
    final cfg = await _loadConfig();
    final id = _id(InfraApiProvider.tailscale);
    final entry = Map<String, dynamic>.from(
      (cfg[id] as Map?)?.cast<String, dynamic>() ?? {},
    );
    entry['tailnet'] = tailnet.trim().isEmpty ? '-' : tailnet.trim();
    cfg[id] = entry;
    await _saveConfig(cfg);
  }

  static Future<InfraApiTestResult?> readLastResult(
    InfraApiProvider provider,
  ) async {
    final cfg = await _loadConfig();
    final entry = cfg[_id(provider)];
    if (entry is! Map) return null;
    final ok = entry['lastOk'];
    final message = entry['lastMessage'] as String?;
    if (ok is! bool || message == null) return null;
    return InfraApiTestResult(
      ok: ok,
      message: message,
      summary: entry['lastSummary'] as String?,
    );
  }

  static Future<void> _persistLastResult(
    InfraApiProvider provider,
    InfraApiTestResult result,
  ) async {
    final cfg = await _loadConfig();
    final id = _id(provider);
    final entry = Map<String, dynamic>.from(
      (cfg[id] as Map?)?.cast<String, dynamic>() ?? {},
    );
    entry['lastOk'] = result.ok;
    entry['lastMessage'] = result.message;
    entry['lastSummary'] = result.summary;
    entry['lastTestAt'] = DateTime.now().toIso8601String();
    cfg[id] = entry;
    await _saveConfig(cfg);
  }

  static Future<void> clearProvider(InfraApiProvider provider) async {
    await clearToken(provider);
    final cfg = await _loadConfig();
    cfg.remove(_id(provider));
    await _saveConfig(cfg);
  }

  static Future<InfraApiTestResult> testConnection(
    InfraApiProvider provider, {
    String? tokenOverride,
  }) async {
    final token = (tokenOverride ?? await readToken(provider))?.trim();
    if (token == null || token.isEmpty) {
      return const InfraApiTestResult(ok: false, message: 'missing_key');
    }

    final InfraApiTestResult result;
    switch (provider) {
      case InfraApiProvider.cloudflare:
        result = await _testCloudflare(token);
      case InfraApiProvider.tailscale:
        result = await _testTailscale(token);
      case InfraApiProvider.northflank:
        result = await _testNorthflank(token);
    }

    if (tokenOverride == null) {
      await _persistLastResult(provider, result);
    }
    return result;
  }

  static Future<InfraApiTestResult> _testCloudflare(String token) async {
    try {
      final verify = await http
          .get(
            Uri.parse('https://api.cloudflare.com/client/v4/user/tokens/verify'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      final verifyBody = jsonDecode(verify.body) as Map<String, dynamic>;
      final success = verifyBody['success'] == true;
      if (verify.statusCode != 200 || !success) {
        final errors = verifyBody['errors'];
        final msg = errors is List && errors.isNotEmpty
            ? (errors.first as Map)['message']?.toString()
            : 'http_${verify.statusCode}';
        return InfraApiTestResult(
          ok: false,
          message: msg ?? 'verify_failed',
          statusCode: verify.statusCode,
        );
      }

      final zones = await http
          .get(
            Uri.parse(
              'https://api.cloudflare.com/client/v4/zones?per_page=1',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      var summary = 'Token valid';
      if (zones.statusCode == 200) {
        final zBody = jsonDecode(zones.body) as Map<String, dynamic>;
        if (zBody['success'] == true) {
          final info = zBody['result_info'] as Map<String, dynamic>?;
          final total = info?['total_count'];
          if (total is int) summary = '$total zone(s)';
        }
      }

      return InfraApiTestResult(
        ok: true,
        message: 'ok',
        statusCode: verify.statusCode,
        summary: summary,
      );
    } catch (e) {
      return InfraApiTestResult(ok: false, message: e.toString());
    }
  }

  static Future<InfraApiTestResult> _testTailscale(String token) async {
    try {
      final tailnet = await readTailnet(InfraApiProvider.tailscale) ?? '-';
      final encodedTailnet = Uri.encodeComponent(tailnet);
      final response = await http
          .get(
            Uri.parse(
              'https://api.tailscale.com/api/v2/tailnet/$encodedTailnet/devices',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return InfraApiTestResult(
          ok: false,
          message: 'http_${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final devices = body['devices'];
      final count = devices is List ? devices.length : 0;
      var online = 0;
      if (devices is List) {
        for (final d in devices) {
          if (d is Map && d['online'] == true) online++;
        }
      }

      return InfraApiTestResult(
        ok: true,
        message: 'ok',
        statusCode: response.statusCode,
        summary: '$online/$count device(s) online',
      );
    } catch (e) {
      return InfraApiTestResult(ok: false, message: e.toString());
    }
  }

  static Future<InfraApiTestResult> _testNorthflank(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://api.northflank.com/v1/projects'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return InfraApiTestResult(
          ok: false,
          message: 'http_${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      final count = data is List ? data.length : 0;

      return InfraApiTestResult(
        ok: true,
        message: 'ok',
        statusCode: response.statusCode,
        summary: '$count project(s)',
      );
    } catch (e) {
      return InfraApiTestResult(ok: false, message: e.toString());
    }
  }
}
