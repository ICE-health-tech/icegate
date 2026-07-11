import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlanAction {
  const PlanAction({
    required this.id,
    required this.title,
    required this.expectedPoints,
    required this.createdAt,
    this.realPoints,
    this.completedAt,
  });

  final String id;
  final String title;
  final int expectedPoints;
  final int? realPoints;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isDone => realPoints != null;

  int? get delta => realPoints != null ? realPoints! - expectedPoints : null;

  PlanAction copyWith({
    String? title,
    int? expectedPoints,
    int? realPoints,
    DateTime? completedAt,
    bool clearReal = false,
  }) {
    return PlanAction(
      id: id,
      title: title ?? this.title,
      expectedPoints: expectedPoints ?? this.expectedPoints,
      createdAt: createdAt,
      realPoints: clearReal ? null : (realPoints ?? this.realPoints),
      completedAt: clearReal ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'expected': expectedPoints,
        if (realPoints != null) 'real': realPoints,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (completedAt != null)
          'completedAt': completedAt!.toUtc().toIso8601String(),
      };

  factory PlanAction.fromJson(Map<String, dynamic> json) {
    return PlanAction(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      expectedPoints: (json['expected'] as num?)?.toInt() ?? 0,
      realPoints: (json['real'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String).toLocal(),
    );
  }
}

/// Local plan → act → score log (expected vs real points).
abstract final class PlanActionStore {
  PlanActionStore._();

  static String _key(String personId) => 'plan_action_v1_$personId';

  static Future<List<PlanAction>> all(String personId) async {
    if (personId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(personId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PlanAction.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(String personId, List<PlanAction> items) async {
    if (personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key(personId), encoded);
  }

  static Future<void> add(String personId, PlanAction action) async {
    final items = await all(personId);
    items.insert(0, action);
    await _save(personId, items);
  }

  static Future<void> update(String personId, PlanAction action) async {
    final items = await all(personId);
    final i = items.indexWhere((a) => a.id == action.id);
    if (i < 0) return;
    items[i] = action;
    await _save(personId, items);
  }

  static Future<void> remove(String personId, String id) async {
    final items = await all(personId);
    items.removeWhere((a) => a.id == id);
    await _save(personId, items);
  }

  static Future<void> logReal(
    String personId,
    String id,
    int realPoints,
  ) async {
    final items = await all(personId);
    final i = items.indexWhere((a) => a.id == id);
    if (i < 0) return;
    items[i] = items[i].copyWith(
      realPoints: realPoints,
      completedAt: DateTime.now(),
    );
    await _save(personId, items);
  }
}
