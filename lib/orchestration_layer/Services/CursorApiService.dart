import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ice_gate/orchestration_layer/Services/SSHService.dart';
import 'package:ice_gate/orchestration_layer/Services/cursor_agent_models.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Cursor API key, Cloud Agents API, and SSH env sync for ice_gate.
class CursorApiService {
  CursorApiService._();
  static final CursorApiService instance = CursorApiService._();

  static const agentsDashboardUrl = 'https://cursor.com/agents';
  static const workerStartCommand = 'agent worker start';

  static const _storageKey = 'cursor_api_key';
  static const _machineNameKey = 'cursor_machine_name';
  static const _apiBase = 'https://api.cursor.com/v1';
  static const _modelsUrl = '$_apiBase/models';

  final _storage = const FlutterSecureStorage();

  /// Reactive: true when a non-empty key is stored on device.
  final hasKeySignal = signal(false);

  /// Reactive: true after last API test succeeded (reset when key cleared).
  final apiValidatedSignal = signal(false);

  Future<void> refreshKeyState() async {
    hasKeySignal.value = await hasApiKey();
    if (!hasKeySignal.value) {
      apiValidatedSignal.value = false;
    }
  }

  Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clearApiKey();
      return;
    }
    await _storage.write(key: _storageKey, value: trimmed);
    hasKeySignal.value = true;
    apiValidatedSignal.value = false;
  }

  Future<String?> getApiKey() => _storage.read(key: _storageKey);

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<void> clearApiKey() async {
    await _storage.delete(key: _storageKey);
    hasKeySignal.value = false;
    apiValidatedSignal.value = false;
  }

  /// Validates the stored key against Cursor Cloud Agents API.
  Future<CursorApiTestResult> testConnection({String? apiKey}) async {
    final key = (apiKey ?? await getApiKey())?.trim();
    if (key == null || key.isEmpty) {
      return const CursorApiTestResult(
        ok: false,
        message: 'missing_key',
      );
    }

    try {
      final credentials = base64Encode(utf8.encode('$key:'));
      final response = await http
          .get(
            Uri.parse(_modelsUrl),
            headers: {'Authorization': 'Basic $credentials'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        hasKeySignal.value = true;
        apiValidatedSignal.value = true;
        return const CursorApiTestResult(ok: true, message: 'ok');
      }
      apiValidatedSignal.value = false;
      return CursorApiTestResult(
        ok: false,
        message: 'http_${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return CursorApiTestResult(ok: false, message: e.toString());
    }
  }

  /// Exports CURSOR_API_KEY in the active SSH shell (for Cursor `agent` CLI).
  Future<void> applyToRemoteSession(SSHService ssh) async {
    if (!ssh.isConnected) return;
    final key = await getApiKey();
    if (key == null || key.isEmpty) return;
    final escaped = key.replaceAll("'", "'\\''");
    await ssh.execute("export CURSOR_API_KEY='$escaped'");
  }

  Future<void> saveMachineName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await _storage.delete(key: _machineNameKey);
      return;
    }
    await _storage.write(key: _machineNameKey, value: trimmed);
  }

  Future<String?> getMachineName() => _storage.read(key: _machineNameKey);

  Future<Map<String, String>> _authHeaders() async {
    final key = (await getApiKey())?.trim();
    if (key == null || key.isEmpty) {
      throw const CursorApiException('missing_key');
    }
    final credentials = base64Encode(utf8.encode('$key:'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }

  /// Launch a task on your Mac via My Machines (`agent worker start` required).
  Future<CursorCreateAgentResult> createAgent({
    required String promptText,
    CursorAgentTarget target = CursorAgentTarget.machine,
    String? machineName,
    String? repoUrl,
    String? startingRef,
  }) async {
    final text = promptText.trim();
    if (text.isEmpty) {
      return const CursorCreateAgentResult(
        ok: false,
        message: 'empty_prompt',
      );
    }

    try {
      final headers = await _authHeaders();
      final body = <String, dynamic>{
        'prompt': {'text': text},
      };

      switch (target) {
        case CursorAgentTarget.machine:
          final name = (machineName ?? await getMachineName())?.trim();
          body['env'] = {
            'type': 'machine',
            if (name != null && name.isNotEmpty) 'name': name,
          };
          break;
        case CursorAgentTarget.cloudRepo:
          final url = repoUrl?.trim();
          if (url == null || url.isEmpty) {
            return const CursorCreateAgentResult(
              ok: false,
              message: 'missing_repo',
            );
          }
          body['repos'] = [
            {
              'url': url,
              if (startingRef != null && startingRef.trim().isNotEmpty)
                'startingRef': startingRef.trim(),
            },
          ];
          break;
      }

      final response = await http
          .post(
            Uri.parse('$_apiBase/agents'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final agentJson = decoded['agent'] as Map<String, dynamic>?;
        final agent = agentJson != null
            ? CursorAgentSummary.fromJson(agentJson)
            : null;
        return CursorCreateAgentResult(
          ok: true,
          agent: agent,
          agentUrl: agent?.url,
          message: 'ok',
          statusCode: response.statusCode,
        );
      }

      return CursorCreateAgentResult(
        ok: false,
        message: _errorMessageFromBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    } on CursorApiException catch (e) {
      return CursorCreateAgentResult(ok: false, message: e.code);
    } catch (e) {
      return CursorCreateAgentResult(ok: false, message: e.toString());
    }
  }

  Future<List<CursorAgentSummary>> listAgents({int limit = 12}) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('$_apiBase/agents?limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items = decoded['items'];
      if (items is! List) return [];

      return items
          .whereType<Map<String, dynamic>>()
          .map(CursorAgentSummary.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _errorMessageFromBody(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message = decoded['message'] ?? decoded['error'];
      if (message != null) return '$message (HTTP $statusCode)';
    } catch (_) {}
    return 'http_$statusCode';
  }
}

class CursorApiException implements Exception {
  const CursorApiException(this.code);
  final String code;

  @override
  String toString() => code;
}

class CursorApiTestResult {
  final bool ok;
  final String message;
  final int? statusCode;

  const CursorApiTestResult({
    required this.ok,
    required this.message,
    this.statusCode,
  });
}
