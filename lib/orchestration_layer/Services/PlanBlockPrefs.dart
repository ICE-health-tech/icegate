import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';

abstract final class PlanBlockPrefs {
  PlanBlockPrefs._();

  static String storageKey(String personId, {String? projectId}) {
    if (projectId != null && projectId.trim().isNotEmpty) {
      return 'plan_board_${personId}_${projectId.trim()}';
    }
    return 'plan_board_$personId';
  }

  static Future<PlanBoard?> load(
    String personId, {
    String? projectId,
  }) async {
    if (personId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey(personId, projectId: projectId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return PlanBoard.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    String personId,
    PlanBoard board, {
    String? projectId,
  }) async {
    if (personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey(personId, projectId: projectId),
      jsonEncode(board.toJson()),
    );
  }

  /// Project ids that have a saved plan board (non-empty columns).
  static Future<List<String>> listProjectIdsWithDiagrams(String personId) async {
    if (personId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'plan_board_${personId}_';
    final ids = <String>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final projectId = key.substring(prefix.length);
      if (projectId.isEmpty) continue;
      final board = await load(personId, projectId: projectId);
      if (board != null && boardHasContent(board)) {
        ids.add(projectId);
      }
    }
    return ids;
  }

  static bool boardHasContent(PlanBoard board) {
    if (board.columns.isEmpty) return false;
    return board.columns.any(
      (c) =>
          !c.hidden &&
          (c.steps.isNotEmpty ||
              c.notesBody.trim().isNotEmpty ||
              c.title.trim().isNotEmpty),
    );
  }
}
