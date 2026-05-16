import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class N8nSummaryDispatchException implements Exception {
  final String message;
  const N8nSummaryDispatchException(this.message);

  factory N8nSummaryDispatchException.notConfigured() =>
      const N8nSummaryDispatchException('n8n webhook URL is not configured');

  factory N8nSummaryDispatchException.http(int status, String body) {
    final hint = body.length > 220 ? '${body.substring(0, 220)}…' : body;
    return N8nSummaryDispatchException(
      hint.isNotEmpty ? 'n8n returned HTTP $status: $hint' : 'n8n returned HTTP $status',
    );
  }

  @override
  String toString() => message;
}

/// Sends a finance summary payload to an n8n Webhook node (email workflow).
class N8nSummaryDispatch {
  /// Optional host key: matches `N8N_SUMMARY_WEBHOOK_URL_<HOST>` (e.g. LOCAL, SMALL).
  /// Empty, DEFAULT, or PRIMARY uses [N8N_SUMMARY_WEBHOOK_URL].
  static String? get _webhookUrl {
    final host = dotenv.env['N8N_SUMMARY_HOST']?.trim() ?? '';
    final keySuffix = host.isEmpty
        ? ''
        : host.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '_');
    if (keySuffix.isEmpty ||
        keySuffix == 'DEFAULT' ||
        keySuffix == 'PRIMARY') {
      return dotenv.env['N8N_SUMMARY_WEBHOOK_URL'];
    }
    final specific = dotenv.env['N8N_SUMMARY_WEBHOOK_URL_$keySuffix']?.trim();
    if (specific != null && specific.isNotEmpty) {
      return specific;
    }
    return dotenv.env['N8N_SUMMARY_WEBHOOK_URL'];
  }

  static String? get _webhookSecret => dotenv.env['N8N_WEBHOOK_SECRET'];
  static String get _webhookMethod =>
      (dotenv.env['N8N_SUMMARY_WEBHOOK_METHOD'] ?? 'POST').trim().toUpperCase();

  /// If not `false`, failed requests retry [N8N_SUMMARY_WEBHOOK_URL_LOCAL], [N8N_SUMMARY_WEBHOOK_URL_SMALL], then default URL (deduped, primary first).
  static bool get _tryFallback =>
      (dotenv.env['N8N_SUMMARY_TRY_FALLBACK'] ?? 'true').trim().toLowerCase() !=
      'false';

  static List<String> _urlsToTryOrdered() {
    final seen = <String>{};
    final out = <String>[];
    void add(String? u) {
      final t = u?.trim();
      if (t != null && t.isNotEmpty && seen.add(t)) out.add(t);
    }

    add(_webhookUrl);
    if (!_tryFallback) return out;

    add(dotenv.env['N8N_SUMMARY_WEBHOOK_URL_LOCAL']);
    add(dotenv.env['N8N_SUMMARY_WEBHOOK_URL_SMALL']);
    add(dotenv.env['N8N_SUMMARY_WEBHOOK_URL']);

    final extrasRaw = dotenv.env['N8N_SUMMARY_WEBHOOK_EXTRAS']?.trim();
    if (extrasRaw != null && extrasRaw.isNotEmpty) {
      for (final part in extrasRaw.split(RegExp(r'\s*,\s*'))) {
        add(part);
      }
    }

    const fromDefine =
        String.fromEnvironment('N8N_SUMMARY_WEBHOOK_FALLBACK', defaultValue: '');
    add(fromDefine);

    return out;
  }

  static Future<void> send(Map<String, dynamic> payload) async {
    var urls = _urlsToTryOrdered();
    if (urls.isEmpty) {
      await dotenv.load(fileName: '.env');
      urls = _urlsToTryOrdered();
    }
    if (urls.isEmpty) {
      throw N8nSummaryDispatchException.notConfigured();
    }

    if (kDebugMode) {
      debugPrint(
        'N8nSummaryDispatch: ${urls.length} URL(s), TRY_FALLBACK=$_tryFallback → ${urls.join(' → ')}',
      );
      if (urls.length == 1 && _tryFallback) {
        debugPrint(
          'N8nSummaryDispatch: hint — only one URL in .env; add '
          'N8N_SUMMARY_WEBHOOK_EXTRAS=https://... (comma-separated) and/or '
          'N8N_SUMMARY_WEBHOOK_URL_SMALL + N8N_SUMMARY_WEBHOOK_URL, '
          'or flutter run --dart-define=N8N_SUMMARY_WEBHOOK_FALLBACK=..., then full restart.',
        );
      } else if (urls.length == 1 && !_tryFallback) {
        debugPrint(
          'N8nSummaryDispatch: fallback disabled (N8N_SUMMARY_TRY_FALLBACK=false).',
        );
      }
    }

    Object? lastError;
    StackTrace? lastStack;
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      try {
        await _sendToUrl(url, payload, _timeoutForAttempt(i, urls.length));
        if (kDebugMode && i > 0) {
          debugPrint('N8nSummaryDispatch: OK using fallback #${i + 1} $url');
        }
        return;
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        if (kDebugMode) {
          debugPrint(
            'N8nSummaryDispatch: attempt ${i + 1}/${urls.length} failed ($url): $e',
          );
        }
      }
    }
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStack ?? StackTrace.current);
    }
    throw const N8nSummaryDispatchException('All n8n webhook URLs failed');
  }

  static Duration _timeoutForAttempt(int index, int total) {
    final maxSec = int.tryParse(dotenv.env['N8N_SUMMARY_TIMEOUT_SEC'] ?? '30') ?? 30;
    final max = maxSec.clamp(5, 120);
    if (total <= 1) return Duration(seconds: max);
    final quickSec =
        int.tryParse(dotenv.env['N8N_SUMMARY_QUICK_ATTEMPT_SEC'] ?? '10') ?? 10;
    final quick = quickSec.clamp(3, max);
    return index < total - 1 ? Duration(seconds: quick) : Duration(seconds: max);
  }

  static Future<void> _sendToUrl(
    String url,
    Map<String, dynamic> payload,
    Duration timeout,
  ) async {
    final method = _webhookMethod;
    if (kDebugMode) {
      debugPrint(
        'N8nSummaryDispatch: $method $url (body keys: ${payload.keys.join(", ")})',
      );
    }

    final uri = Uri.parse(url);
    final headers = <String, String>{};
    final secret = _webhookSecret?.trim();
    if (secret != null && secret.isNotEmpty) {
      headers['X-Webhook-Secret'] = secret;
    }

    http.Response response;
    if (method == 'GET') {
      response = await _get(uri, headers, payload, timeout);
    } else {
      headers['Content-Type'] = 'application/json';
      response = await _post(uri, headers, payload, timeout);
      if (_shouldRetryAsGet(response)) {
        response = await _get(uri, headers, payload, timeout);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw N8nSummaryDispatchException.http(
        response.statusCode,
        response.body,
      );
    }
  }

  static bool _shouldRetryAsGet(http.Response response) {
    if (response.statusCode != 404) return false;
    final body = response.body.toLowerCase();
    return body.contains('get request') || body.contains('make a get');
  }

  static Future<http.Response> _post(
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic> payload,
    Duration timeout,
  ) {
    return http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(timeout);
  }

  static Future<http.Response> _get(
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic> payload,
    Duration timeout,
  ) {
    return http
        .get(uri.replace(queryParameters: _queryFromPayload(payload)), headers: headers)
        .timeout(timeout);
  }

  /// Flat query fields for n8n Webhook nodes configured with HTTP GET.
  static Map<String, String> _queryFromPayload(Map<String, dynamic> payload) {
    final period = payload['period'] as Map<String, dynamic>;
    final totals = payload['totals'] as Map<String, dynamic>;
    final delivery = payload['delivery'] as Map<String, dynamic>;

    return {
      'schema_version': '${payload['schema_version']}',
      'report_type': payload['report_type'] as String,
      'person_id': payload['person_id'] as String,
      'locale': payload['locale'] as String,
      'currency': payload['currency'] as String,
      'period_start': period['start'] as String,
      'period_end': period['end'] as String,
      'period_label': period['label'] as String,
      'utc_offset_minutes': '${period['utc_offset_minutes']}',
      'income': '${totals['income']}',
      'expense': '${totals['expense']}',
      'net': '${totals['net']}',
      'transaction_count': '${payload['transaction_count']}',
      'to': delivery['to'] as String,
      'by_category': jsonEncode(payload['by_category']),
      if (payload['finance'] != null)
        'finance': jsonEncode(payload['finance']),
      if (payload['health'] != null) 'health': jsonEncode(payload['health']),
      if (payload['health_steps'] != null)
        'health_steps': '${payload['health_steps']}',
      if (payload['finance_net_worth'] != null)
        'finance_net_worth': '${payload['finance_net_worth']}',
    };
  }
}
