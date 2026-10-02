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

  /// n8n Webhook templates often use `{{ $json.body.email_body_plain }}`.
  /// POST sends `{ "body": { ...payload } }` plus top-level copies of key fields.
  static Map<String, dynamic> envelopeForN8n(Map<String, dynamic> payload) {
    final body = Map<String, dynamic>.from(payload);
    return {
      'body': body,
      if (body['email_subject'] != null) 'email_subject': body['email_subject'],
      if (body['email_body_plain'] != null)
        'email_body_plain': body['email_body_plain'],
      if (body['email_body_html'] != null)
        'email_body_html': body['email_body_html'],
    };
  }

  static Future<void> _sendToUrl(
    String url,
    Map<String, dynamic> payload,
    Duration timeout,
  ) async {
    final method = _webhookMethod;
    if (kDebugMode) {
      final preview = method == 'GET'
          ? 'query keys: ${_queryFromPayload(payload).keys.join(", ")}'
          : 'POST envelope keys: ${envelopeForN8n(payload).keys.join(", ")}';
      debugPrint('N8nSummaryDispatch: $method $url ($preview)');
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
        .post(
          uri,
          headers: headers,
          body: jsonEncode(envelopeForN8n(payload)),
        )
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

    String? str(dynamic v) => v == null ? null : '$v';

    final flatKeys = [
      'sent_at',
      'recipient_name',
      'email_subject',
      'email_body_plain',
      'email_body_html',
      'period_label',
      'net_today',
      'income_today',
      'expense_today',
      'net_worth',
      'month_income',
      'month_spending',
      'month_net',
      'daily_delta',
      'total_savings',
      'remaining_budget',
      'budget_usage',
      'savings_rate',
      'drawdown',
      'transactions_today',
      'subscriptions_count',
      'today_transactions_text',
      'steps_display',
      'steps_progress',
      'sleep_display',
      'sleep_progress',
      'water_display',
      'water_progress',
      'heart_rate_display',
      'oxygen_display',
      'calories_burned_display',
      'calories_consumed_display',
      'exercise_display',
      'focus_display',
      'weight_display',
      'mood_display',
      'mood_activities_display',
      'mood_note_display',
      'projects_summary',
      'tasks_summary',
      'projects_active_list',
      'tasks_active_list',
      'finance_daily_income',
      'finance_daily_expense',
      'finance_daily_net',
      'finance_net_worth',
      'finance_ath_balance',
      'finance_drawdown_percent',
      'finance_monthly_income',
      'finance_monthly_spending',
      'finance_monthly_net',
      'finance_daily_delta',
      'finance_total_savings',
      'finance_savings_rate_percent',
      'finance_top_category',
      'finance_top_category_amount',
      'health_steps',
      'health_step_goal',
      'health_steps_progress_percent',
      'health_sleep_hours',
      'health_sleep_goal',
      'health_heart_rate',
      'health_oxygen_saturation',
      'health_water_ml',
      'health_water_goal',
      'health_calories_burned',
      'health_calories_consumed',
      'health_exercise_minutes',
      'health_focus_minutes',
      'health_weight_kg',
      'health_exercise_goal',
      'health_focus_goal',
      'health_calorie_goal',
      'health_exercise_progress_percent',
      'health_focus_progress_percent',
      'mood_score',
      'mood_has_log_today',
      'projects_total',
      'projects_active',
      'projects_done',
      'tasks_active',
      'tasks_done',
    ];

    final out = <String, String>{
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
      if (payload['mood'] != null) 'mood': jsonEncode(payload['mood']),
      if (payload['projects'] != null)
        'projects': jsonEncode(payload['projects']),
    };

    for (final key in flatKeys) {
      final v = str(payload[key]);
      if (v != null) out[key] = v;
    }

    // GET webhooks: fields are on $json.query.* (not $json.body.*).
    // Also expose a JSON blob for workflows that parse body in a Code node.
    out['body'] = jsonEncode(payload);

    return out;
  }
}
