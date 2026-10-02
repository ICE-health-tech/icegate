import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ice_gate/utils/app_log.dart';

/// Calls a backend LLM agent for personalized daily-report suggestions.
class DailyMailSummaryAiService {
  static String? get _baseUrl {
    final dedicated = dotenv.env['MAIL_SUGGESTIONS_AGENT_URL']?.trim();
    if (dedicated != null && dedicated.isNotEmpty) return dedicated;
    return dotenv.env['FOOD_AGENT_URL']?.trim();
  }

  static int get _timeoutSec =>
      int.tryParse(dotenv.env['MAIL_SUGGESTIONS_TIMEOUT_SEC'] ?? '25') ?? 25;

  static Future<List<String>> fetchSuggestions({
    required Map<String, dynamic> summaryContext,
    required String locale,
    int max = 5,
  }) async {
    final base = _baseUrl;
    if (base == null || base.isEmpty) {
      appLog('DailyMailSummaryAiService: no agent URL configured');
      return const [];
    }

    final uri = Uri.parse(
      base.endsWith('/')
          ? '${base}suggest_daily_summary'
          : '$base/suggest_daily_summary',
    );

    try {
      appLog('DailyMailSummaryAiService: POST $uri');
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'locale': locale,
              'max_suggestions': max,
              'summary': summaryContext,
            }),
          )
          .timeout(Duration(seconds: _timeoutSec));

      if (response.statusCode != 200) {
        appLog(
          'DailyMailSummaryAiService: HTTP ${response.statusCode} ${response.body}',
        );
        return const [];
      }

      final decoded = jsonDecode(response.body);
      return _parseSuggestions(decoded, max);
    } catch (e) {
      appLog('DailyMailSummaryAiService: failed — $e');
      return const [];
    }
  }

  static List<String> _parseSuggestions(dynamic decoded, int max) {
    final raw = _extractList(decoded);
    final out = <String>[];
    for (final item in raw) {
      final text = item?.toString().trim();
      if (text == null || text.isEmpty) continue;
      final cleaned = text.replaceFirst(RegExp(r'^[-•*]\s*'), '');
      if (cleaned.isNotEmpty) out.add(cleaned);
      if (out.length >= max) break;
    }
    return out;
  }

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is! Map) return const [];

    for (final key in ['suggestions', 'tips', 'items']) {
      final v = decoded[key];
      if (v is List) return v;
    }

    final output = decoded['output'];
    if (output is List) return output;
    if (output is String && output.trim().isNotEmpty) {
      return output
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }

    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return [message.trim()];
    }

    return const [];
  }
}
