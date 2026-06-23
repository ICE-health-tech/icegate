import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';

abstract final class PlanBlockPrefs {
  PlanBlockPrefs._();

  static String _storageKey(String personId) => 'plan_board_$personId';

  static Future<PlanBoard?> load(String personId) async {
    if (personId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(personId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return PlanBoard.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String personId, PlanBoard board) async {
    if (personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(personId), jsonEncode(board.toJson()));
  }
}
