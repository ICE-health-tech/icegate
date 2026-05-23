import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-defined focus area (gym week, learn week, invest week, …).
class MindFocusTrend {
  final String id;
  final String name;
  final int iconCodePoint;
  final List<String> activityTokens;
  final int weeklyGoal;
  final int colorArgb;

  const MindFocusTrend({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.activityTokens,
    this.weeklyGoal = 3,
    this.colorArgb = 0xFF42A5F5,
  });

  /// Icons users can pick in [MindFocusTrendEditor] — must stay const for release builds.
  static const List<IconData> allowedIcons = [
    Icons.fitness_center_rounded,
    Icons.school_rounded,
    Icons.trending_up_rounded,
    Icons.psychology_rounded,
    Icons.payments_rounded,
    Icons.self_improvement_rounded,
    Icons.menu_book_rounded,
    Icons.track_changes_rounded,
  ];

  /// Resolves a stored code point to a const [IconData] (tree-shake safe).
  static IconData resolveIcon(int codePoint) {
    for (final icon in allowedIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.track_changes_rounded;
  }

  Color get color => Color(colorArgb);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': iconCodePoint,
    'activities': activityTokens,
    'weeklyGoal': weeklyGoal,
    'color': colorArgb,
  };

  factory MindFocusTrend.fromJson(Map<String, dynamic> json) {
    final rawActs = json['activities'];
    final acts = rawActs is List
        ? rawActs.map((e) => e.toString()).toList()
        : <String>[];
    return MindFocusTrend(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconCodePoint: json['icon'] as int? ?? Icons.track_changes_rounded.codePoint,
      activityTokens: acts,
      weeklyGoal: json['weeklyGoal'] as int? ?? 3,
      colorArgb: json['color'] as int? ?? 0xFF42A5F5,
    );
  }

  MindFocusTrend copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    List<String>? activityTokens,
    int? weeklyGoal,
    int? colorArgb,
  }) {
    return MindFocusTrend(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      activityTokens: activityTokens ?? this.activityTokens,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      colorArgb: colorArgb ?? this.colorArgb,
    );
  }
}

abstract final class MindFocusTrendPrefs {
  MindFocusTrendPrefs._();

  static String _storageKey(String personId) => 'mind_focus_trends_$personId';

  static Future<List<MindFocusTrend>> load(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(personId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => MindFocusTrend.fromJson(Map<String, dynamic>.from(e)))
          .where((t) => t.id.isNotEmpty && t.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(String personId, List<MindFocusTrend> trends) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(trends.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey(personId), payload);
  }

  static String _activeKey(String personId) => 'mind_active_focus_$personId';

  static Future<String?> loadActiveFocusId(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey(personId));
  }

  static Future<void> saveActiveFocusId(String personId, String? trendId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _activeKey(personId);
    if (trendId == null || trendId.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, trendId);
    }
  }
}
