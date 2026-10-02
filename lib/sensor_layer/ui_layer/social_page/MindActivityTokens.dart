import 'dart:convert';

import 'package:ice_gate/l10n/app_localizations.dart';

/// Tokens for [mind_logs.activities] JSON arrays: built-in `act_*`, synced custom `act_user_ref:<uuid>`.
abstract final class MindActivityTokens {
  MindActivityTokens._();

  static const userRefPrefix = 'act_user_ref:';
  static const gratitudeToken = 'act_gratitude';

  /// Appended to mirrored [project_notes.content] when activity includes gratitude.
  static const journalGratitudeMark = '<!--ice:act_gratitude-->';

  static bool contentHasGratitudeMark(String? content) {
    if (content == null || content.isEmpty) return false;
    return content.contains(journalGratitudeMark);
  }

  /// Journal card / gratitude-tab filter: marker, title label, or JSON payload.
  static bool noteLooksLikeGratitude({
    required String title,
    required String content,
    String? gratitudeLabel,
  }) {
    if (contentHasGratitudeMark(content)) return true;
    if (content.contains('"gratitude"') && content.contains('entry_id')) {
      return true;
    }
    final t = title.toLowerCase();
    if (t.contains('act_gratitude')) return true;
    if (gratitudeLabel != null &&
        gratitudeLabel.isNotEmpty &&
        title.contains(gratitudeLabel)) {
      return true;
    }
    if (t.contains('biết ơn') || t.contains('gratitude')) return true;
    return false;
  }

  static String refToken(String optionId) => '$userRefPrefix$optionId';

  /// Skill Boost session tokens — not shown on NHẬT KÝ / journal cards.
  static bool isInternalSessionToken(String token) {
    return token.startsWith('skill:') ||
        token.startsWith('learn:') ||
        token.startsWith('project:') ||
        token.startsWith('mindset_topic:') ||
        token == 'mindset_learn';
  }

  /// Returns option UUID when [token] is a synced custom ref; otherwise null.
  static String? parseOptionId(String token) {
    if (!token.startsWith(userRefPrefix)) return null;
    final id = token.substring(userRefPrefix.length).trim();
    return id.isEmpty ? null : id;
  }

  /// Resolve one activity token for display (presets via l10n; refs via [optionLabels]).
  static String displayLabel(
    AppLocalizations l10n,
    String token,
    Map<String, String> optionLabels,
  ) {
    final oid = parseOptionId(token);
    if (oid != null) {
      return optionLabels[oid] ?? token;
    }
    return presetLabel(l10n, token);
  }

  /// Built-in activity keys from [ActivitySelector] presets.
  static String presetLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'act_deep_work':
        return l10n.act_deep_work;
      case 'act_learning':
        return l10n.act_learning;
      case 'act_finance':
        return l10n.act_finance;
      case 'act_planning':
        return l10n.act_planning;
      case 'act_exercise':
        return l10n.act_exercise;
      case 'act_meditation':
        return l10n.act_meditation;
      case 'act_healthy_meal':
        return l10n.act_healthy_meal;
      case 'act_great_sleep':
        return l10n.act_great_sleep;
      case 'act_family':
        return l10n.act_family;
      case 'act_friends':
        return l10n.act_friends;
      case 'act_dating':
        return l10n.act_dating;
      case 'act_kindness':
        return l10n.act_kindness;
      case 'act_gratitude':
        return l10n.act_gratitude;
      case 'act_gaming':
        return l10n.act_gaming;
      case 'act_reading':
        return l10n.act_reading;
      case 'act_cinema':
        return l10n.act_cinema;
      case 'act_walking':
        return l10n.act_walking;
      case 'focus:todos_streak':
        return l10n.act_focus_todos_streak;
      case 'focus:todos_complete':
        return l10n.act_focus_todos_complete;
      default:
        return key;
    }
  }

  /// Decode stored JSON activities array and join localized labels.
  static String formatActivitiesJson(
    AppLocalizations l10n,
    String activitiesJson,
    Map<String, String> optionLabels,
  ) {
    try {
      final raw = jsonDecode(activitiesJson);
      if (raw is! List) return activitiesJson;
      return raw
          .map((e) => displayLabel(l10n, e.toString(), optionLabels))
          .join(', ');
    } catch (_) {
      return activitiesJson;
    }
  }

  /// Journal preview: hide Skill Boost tokens; fall back to mood-only label.
  static String formatJournalActivitiesJson(
    AppLocalizations l10n,
    String activitiesJson,
    Map<String, String> optionLabels,
  ) {
    try {
      final raw = jsonDecode(activitiesJson);
      if (raw is! List) return activitiesJson;
      final labels = raw
          .whereType<String>()
          .where((t) => !isInternalSessionToken(t))
          .map((t) => displayLabel(l10n, t, optionLabels))
          .where((label) => label.trim().isNotEmpty)
          .join(', ');
      return labels.isEmpty ? l10n.mind_logged_mood : labels;
    } catch (_) {
      return activitiesJson;
    }
  }

  static bool activitiesJsonContains(String activitiesJson, String token) {
    try {
      final raw = jsonDecode(activitiesJson);
      if (raw is List) {
        return raw.whereType<String>().contains(token);
      }
    } catch (_) {}
    return false;
  }

  /// Encoded in [mind_logs.note] when logged from the gratitude tab or journal.
  static String encodeGratitudeNote({
    required String name,
    required String kind,
    String? text,
    String? entryId,
  }) {
    return jsonEncode({
      'gratitude': {
        if (entryId != null && entryId.isNotEmpty) 'entry_id': entryId,
        'name': name,
        'kind': kind,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      },
    });
  }

  static ({String? entryId, String name, String kind, String? text})
      parseGratitudeNote(
    String? note,
  ) {
    if (note == null || note.trim().isEmpty) {
      return (entryId: null, name: '—', kind: 'person', text: null);
    }
    try {
      final raw = jsonDecode(note);
      if (raw is Map && raw['gratitude'] is Map) {
        final g = Map<String, dynamic>.from(raw['gratitude'] as Map);
        final name = (g['name'] as String?)?.trim();
        return (
          entryId: g['entry_id'] as String?,
          name: (name == null || name.isEmpty) ? '—' : name,
          kind: (g['kind'] as String?) == 'thing' ? 'thing' : 'person',
          text: (g['text'] as String?)?.trim(),
        );
      }
    } catch (_) {}
    final lines = note.split('\n');
    final first = lines.first.trim();
    return (
      entryId: null,
      name: first.isEmpty ? '—' : first,
      kind: 'person',
      text: lines.length > 1 ? lines.skip(1).join('\n').trim() : null,
    );
  }

  /// Built-in gratitude filter tags (stored on [gratitude_entries.note] JSON).
  static const tagPlay = 'play';
  static const tagLearn = 'learn';
  static const tagWork = 'work';
  static const tagHealth = 'health';
  static const tagSocial = 'social';
  static const tagFamily = 'family';

  static const presetTags = <String>[
    tagPlay,
    tagLearn,
    tagWork,
    tagHealth,
    tagSocial,
    tagFamily,
  ];

  static String tagLabel(AppLocalizations l10n, String tag) {
    switch (tag) {
      case tagPlay:
        return l10n.gratitude_tag_play;
      case tagLearn:
        return l10n.gratitude_tag_learn;
      case tagWork:
        return l10n.gratitude_tag_work;
      case tagHealth:
        return l10n.gratitude_tag_health;
      case tagSocial:
        return l10n.gratitude_tag_social;
      case tagFamily:
        return l10n.gratitude_tag_family;
      default:
        return tag;
    }
  }

  /// Persist free-text + tags in [gratitude_entries.note] without a schema bump.
  static String? encodeEntryNote({String? text, List<String> tags = const []}) {
    final cleaned = text?.trim();
    final uniq = tags
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if ((cleaned == null || cleaned.isEmpty) && uniq.isEmpty) return null;
    if (uniq.isEmpty) return cleaned;
    return jsonEncode({
      'text': cleaned ?? '',
      'tags': uniq,
    });
  }

  static ({String? text, List<String> tags}) parseEntryNote(String? note) {
    if (note == null || note.trim().isEmpty) {
      return (text: null, tags: const []);
    }
    try {
      final raw = jsonDecode(note);
      if (raw is Map && raw['tags'] is List) {
        final tags = (raw['tags'] as List)
            .whereType<String>()
            .map((t) => t.trim().toLowerCase())
            .where((t) => t.isNotEmpty)
            .toList();
        final text = (raw['text'] as String?)?.trim();
        return (
          text: (text == null || text.isEmpty) ? null : text,
          tags: tags,
        );
      }
    } catch (_) {}
    return (text: note.trim(), tags: const []);
  }
}
