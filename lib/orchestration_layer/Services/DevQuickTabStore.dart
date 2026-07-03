import 'dart:convert';

import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/WebPlugin/HomelabWebPlugins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CRUD persistence for [DevQuickTabProtocol] (SharedPreferences v0).
abstract final class DevQuickTabStore {
  DevQuickTabStore._();

  static String _storageKey(String personId) => 'dev_quick_tabs_$personId';

  // STORY: Read all rows for this person from the JSON list in prefs.
  static Future<List<DevQuickTabProtocol>> list(String personId) async {
    if (personId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(personId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => DevQuickTabProtocol.fromJson(Map<String, dynamic>.from(e)))
          .where((t) => t.id.isNotEmpty && t.fullUrl.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // STORY: Find one tab by id, or null if missing.
  static Future<DevQuickTabProtocol?> read(String personId, String id) async {
    if (personId.isEmpty || id.isEmpty) return null;
    final rows = await list(personId);
    for (final row in rows) {
      if (row.id == id) return row;
    }
    return null;
  }

  // STORY: Append a new tab; generates id when empty.
  static Future<DevQuickTabProtocol> create(
    String personId,
    DevQuickTabProtocol tab,
  ) async {
    final rows = await list(personId);
    final next = tab.id.isEmpty
        ? tab.copyWith(id: IDGen.generateUuid())
        : tab;
    rows.add(next);
    await _writeAll(personId, rows);
    return next;
  }

  // STORY: Replace the row with the same id; returns null when not found.
  static Future<DevQuickTabProtocol?> update(
    String personId,
    DevQuickTabProtocol tab,
  ) async {
    if (personId.isEmpty || tab.id.isEmpty) return null;
    final rows = await list(personId);
    final idx = rows.indexWhere((r) => r.id == tab.id);
    if (idx < 0) return null;
    rows[idx] = tab;
    await _writeAll(personId, rows);
    return tab;
  }

  // STORY: Remove one row by id; false when id was not in the list.
  static Future<bool> delete(String personId, String id) async {
    if (personId.isEmpty || id.isEmpty) return false;
    final rows = await list(personId);
    final before = rows.length;
    rows.removeWhere((r) => r.id == id);
    if (rows.length == before) return false;
    await _writeAll(personId, rows);
    return true;
  }

  /// First open: seed homelab catalog when list is empty.
  static Future<List<DevQuickTabProtocol>> listOrSeed(String personId) async {
    var rows = await list(personId);
    if (rows.isNotEmpty || personId.isEmpty) return rows;
    rows = HomelabWebPlugins.catalog
        .map(DevQuickTabProtocol.fromPlugin)
        .toList(growable: false);
    await _writeAll(personId, rows);
    return rows;
  }

  static Future<void> _writeAll(
    String personId,
    List<DevQuickTabProtocol> tabs,
  ) async {
    if (personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(personId),
      jsonEncode(tabs.map((t) => t.toJson()).toList()),
    );
  }
}
