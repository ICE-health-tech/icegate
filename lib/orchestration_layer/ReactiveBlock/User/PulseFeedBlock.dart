import 'dart:math';

import 'package:signals/signals.dart';

/// A single event that appears in the home pulse feed.
class PulseFeedItem {
  final String id;
  final PulseEventType type;
  final String title;
  final String? subtitle;
  final DateTime timestamp;

  /// True when the variable-reward dice roll fires (≈25% of actions).
  final bool isBonus;
  final String? bonusLabel;

  const PulseFeedItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.timestamp,
    this.isBonus = false,
    this.bonusLabel,
  });
}

enum PulseEventType {
  questCompleted,
  moodLogged,
  focusSessionDone,
  streakMilestone,
  musicSuggestion,
}

/// In-memory event bus for the Play / AdSMind layer.
///
/// Any part of the app calls [emit]. The home [PulseFeedCard] watches [feed].
/// No DB persistence needed — this is intentionally ephemeral (session-only).
class PulseFeedBlock {
  static const _maxItems = 20;

  // 25 % of actions get a variable-reward "bonus" label.
  static const _bonusChance = 0.25;

  final feed = listSignal<PulseFeedItem>([]);

  final _rng = Random();

  static const _bonusLabels = [
    '✦ Rare drop',
    '⚡ Power surge',
    '🔥 On fire',
    '💎 Lucky streak',
    '🌟 Spotlight moment',
  ];

  /// Emit a new event. Automatically rolls for variable-reward bonus.
  void emit(PulseFeedItem item) {
    final isBonus = _rng.nextDouble() < _bonusChance;
    final enriched = isBonus
        ? PulseFeedItem(
            id: item.id,
            type: item.type,
            title: item.title,
            subtitle: item.subtitle,
            timestamp: item.timestamp,
            isBonus: true,
            bonusLabel: _bonusLabels[_rng.nextInt(_bonusLabels.length)],
          )
        : item;

    final updated = [enriched, ...feed.value];
    feed.value =
        updated.length > _maxItems ? updated.sublist(0, _maxItems) : updated;
  }

  void clear() => feed.value = [];
}
