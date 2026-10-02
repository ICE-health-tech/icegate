import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/Services/TaskPeriodWindow.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-defined focus area (gym week, learn week, invest week, …).
class MindFocusTrend {
  final String id;
  final String name;
  final int iconCodePoint;
  final List<String> activityTokens;
  final int weeklyGoal;
  final int colorArgb;
  final String? linkedProjectId;

  const MindFocusTrend({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.activityTokens,
    this.weeklyGoal = 3,
    this.colorArgb = 0xFF42A5F5,
    this.linkedProjectId,
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
    if (linkedProjectId != null && linkedProjectId!.isNotEmpty)
      'linkedProjectId': linkedProjectId,
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
      linkedProjectId: json['linkedProjectId'] as String?,
    );
  }

  MindFocusTrend copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    List<String>? activityTokens,
    int? weeklyGoal,
    int? colorArgb,
    String? linkedProjectId,
  }) {
    return MindFocusTrend(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      activityTokens: activityTokens ?? this.activityTokens,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      colorArgb: colorArgb ?? this.colorArgb,
      linkedProjectId: linkedProjectId ?? this.linkedProjectId,
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

/// Per-window focus to-do caps and completion tracking (local prefs).
abstract final class MindFocusDailyTodosPrefs {
  MindFocusDailyTodosPrefs._();

  static const minAddsPerDay = 2;
  static const maxAddsPerDay = 5;
  static const moodRewardMinCompletions = 3;

  static String _prefix(
    String personId,
    String trendId,
    TaskPeriod period,
    DateTime reference,
  ) {
    final window = TaskPeriodWindow.windowKeySuffix(period, reference);
    return 'mind_focus_${period.name}_${personId}_${trendId}_$window';
  }

  static Future<MindFocusDailyTodosSnapshot> load({
    required String personId,
    required String trendId,
    TaskPeriod period = TaskPeriod.daily,
    DateTime? reference,
  }) async {
    if (personId.isEmpty || trendId.isEmpty) {
      return const MindFocusDailyTodosSnapshot();
    }
    final prefs = await SharedPreferences.getInstance();
    final ref = reference ?? DateTime.now();
    final prefix = _prefix(personId, trendId, period, ref);
    final ids = prefs.getStringList('${prefix}_ids') ?? const [];
    return MindFocusDailyTodosSnapshot(
      taskIds: ids,
      completedCount: prefs.getInt('${prefix}_done') ?? 0,
      moodAwarded: prefs.getBool('${prefix}_mood6') ?? false,
      period: period,
    );
  }

  static bool canAdd(MindFocusDailyTodosSnapshot snap) =>
      snap.addedCount < maxAddsPerDay;

  static Future<void> registerAddedTask({
    required String personId,
    required String trendId,
    required String taskId,
    TaskPeriod period = TaskPeriod.daily,
  }) async {
    if (personId.isEmpty || trendId.isEmpty || taskId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(personId, trendId, period, DateTime.now());
    final key = '${prefix}_ids';
    final ids = <String>[
      ...?prefs.getStringList(key),
      taskId,
    ];
    await prefs.setStringList(key, ids);
  }

  static Future<int> registerCompletion({
    required String personId,
    required String trendId,
    TaskPeriod period = TaskPeriod.daily,
  }) async {
    if (personId.isEmpty || trendId.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(personId, trendId, period, DateTime.now());
    final key = '${prefix}_done';
    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    return next;
  }

  static Future<void> markMoodAwarded({
    required String personId,
    required String trendId,
    TaskPeriod period = TaskPeriod.daily,
  }) async {
    if (personId.isEmpty || trendId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(personId, trendId, period, DateTime.now());
    await prefs.setBool('${prefix}_mood6', true);
  }
}

class MindFocusDailyTodosSnapshot {
  const MindFocusDailyTodosSnapshot({
    this.taskIds = const [],
    this.completedCount = 0,
    this.moodAwarded = false,
    this.period = TaskPeriod.daily,
  });

  final List<String> taskIds;
  final int completedCount;
  final bool moodAwarded;
  final TaskPeriod period;

  int get addedCount => taskIds.length;

  bool get canEarnMood =>
      addedCount >= MindFocusDailyTodosPrefs.minAddsPerDay && !moodAwarded;

  bool get shouldAwardMoodNow =>
      canEarnMood &&
      completedCount > MindFocusDailyTodosPrefs.moodRewardMinCompletions;
}
