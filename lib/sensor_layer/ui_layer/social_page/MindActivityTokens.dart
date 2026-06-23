import 'dart:convert';

import 'package:ice_gate/l10n/app_localizations.dart';

/// Tokens for [mind_logs.activities] JSON arrays: built-in `act_*`, synced custom `act_user_ref:<uuid>`.
abstract final class MindActivityTokens {
  MindActivityTokens._();

  static const userRefPrefix = 'act_user_ref:';

  static String refToken(String optionId) => '$userRefPrefix$optionId';

  /// Skill Boost session tokens — not shown on NHẬT KÝ / journal cards.
  static bool isInternalSessionToken(String token) {
    return token.startsWith('skill:') ||
        token.startsWith('learn:') ||
        token.startsWith('project:');
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
      case 'act_gaming':
        return l10n.act_gaming;
      case 'act_reading':
        return l10n.act_reading;
      case 'act_cinema':
        return l10n.act_cinema;
      case 'act_walking':
        return l10n.act_walking;
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
}
