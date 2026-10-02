import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Pinned weekly topic on Mind focus dashboard → [quotes.id].
abstract final class MindWeeklyTopicPrefs {
  MindWeeklyTopicPrefs._();

  static String _key(String personId) => 'mind_weekly_topic_$personId';

  static Future<({String quoteId, String topicTitle})?> load(
    String personId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(personId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final quoteId = decoded['quoteId'] as String? ?? '';
      final topicTitle = decoded['topicTitle'] as String? ?? '';
      if (quoteId.isEmpty) return null;
      return (quoteId: quoteId, topicTitle: topicTitle);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required String personId,
    required String quoteId,
    required String topicTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(personId),
      jsonEncode({'quoteId': quoteId, 'topicTitle': topicTitle}),
    );
  }
}
