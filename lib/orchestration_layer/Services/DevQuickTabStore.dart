import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabLoginType.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Services/WebViewCredentialStore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CRUD for [DevQuickTabProtocol] — Drift local + Supabase push via DAO.
abstract final class DevQuickTabStore {
  DevQuickTabStore._();

  static String _legacyPrefsKey(String personId) => 'dev_quick_tabs_$personId';

  static DevQuickTabProtocol _fromRow(DevQuickTabData row) => DevQuickTabProtocol(
    id: row.id,
    title: row.title,
    fullUrl: row.fullUrl,
    sortOrder: row.sortOrder,
    isPinned: row.isPinned,
    username: row.username,
    password: row.password,
    loginType: row.loginType,
  );

  // STORY: Read all tabs for person; one-time import from legacy SharedPreferences.
  static Future<List<DevQuickTabProtocol>> list(
    AppDatabase db,
    String personId,
  ) async {
    if (personId.isEmpty) return const [];
    await db.ensureDevQuickTabsTableReady();
    await _migrateLegacyPrefsIfNeeded(db, personId);
    final rows = await db.devQuickTabsDAO.listForPerson(personId);
    final tabs = rows.map(_fromRow).toList(growable: false);
    // Synced-down rows may carry credentials from another device —
    // mirror them into the per-host secure store for WebView autofill.
    await mirrorCredentialsToSecureStore(tabs);
    return tabs;
  }

  /// Writes tab-row credentials into [WebViewCredentialStore] (per host).
  /// Row is the synced source of truth; secure-store-only fields
  /// (passkey, SSL trust) are preserved.
  static Future<void> mirrorCredentialsToSecureStore(
    List<DevQuickTabProtocol> tabs,
  ) async {
    final store = WebViewCredentialStore();
    final seen = <String>{};
    for (final tab in tabs) {
      if (tab.username.isEmpty && tab.password.isEmpty) continue;
      final host = Uri.tryParse(tab.fullUrl)?.host ?? '';
      if (host.isEmpty || !seen.add(host)) continue;
      final existing = await store.readHostCredentials(host);
      await store.saveHostCredentials(
        host: host,
        username: tab.username.isNotEmpty ? tab.username : existing.username,
        password: tab.password.isNotEmpty ? tab.password : existing.password,
        passkey: existing.passkey,
        sslTrusted: existing.sslTrusted,
        loginType: DevQuickTabLoginType.fromStorage(tab.loginType),
      );
    }
  }

  /// Copies host credentials into every tab row matching [host] so they
  /// push to Supabase (credentials sheet → dev table sync).
  static Future<void> applyHostCredentialsToTabs(
    AppDatabase db,
    String personId, {
    required String host,
    required String username,
    required String password,
    required String loginType,
  }) async {
    if (personId.isEmpty || host.isEmpty) return;
    // Read rows directly (list() would mirror stale row creds to secure store).
    final rows = await db.devQuickTabsDAO.listForPerson(personId);
    for (final row in rows) {
      final tabHost = Uri.tryParse(row.fullUrl)?.host ?? '';
      if (tabHost != host) continue;
      await update(
        db,
        personId,
        _fromRow(row).copyWith(
          username: username,
          password: password,
          loginType: loginType,
        ),
      );
    }
  }

  static Future<DevQuickTabProtocol?> read(
    AppDatabase db,
    String personId,
    String id,
  ) async {
    if (personId.isEmpty || id.isEmpty) return null;
    final row = await db.devQuickTabsDAO.readForPerson(personId, id);
    return row == null ? null : _fromRow(row);
  }

  static Future<DevQuickTabProtocol> create(
    AppDatabase db,
    String personId,
    DevQuickTabProtocol tab,
  ) async {
    final id = tab.id.isEmpty ? IDGen.generateUuid() : tab.id;
    final now = DateTime.now();
    final row = await db.devQuickTabsDAO.insertTab(
      DevQuickTabsTableCompanion.insert(
        id: id,
        personId: personId,
        title: tab.title,
        fullUrl: tab.fullUrl,
        sortOrder: Value(tab.sortOrder),
        isPinned: Value(tab.isPinned),
        username: Value(tab.username),
        password: Value(tab.password),
        loginType: Value(tab.loginType),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return _fromRow(row);
  }

  static Future<DevQuickTabProtocol?> update(
    AppDatabase db,
    String personId,
    DevQuickTabProtocol tab,
  ) async {
    if (personId.isEmpty || tab.id.isEmpty) return null;
    final existing = await db.devQuickTabsDAO.readForPerson(personId, tab.id);
    if (existing == null) return null;
    final next = existing.copyWith(
      title: tab.title,
      fullUrl: tab.fullUrl,
      sortOrder: tab.sortOrder,
      isPinned: tab.isPinned,
      username: tab.username,
      password: tab.password,
      loginType: tab.loginType,
      updatedAt: DateTime.now(),
    );
    final saved = await db.devQuickTabsDAO.updateTab(next);
    return saved == null ? null : _fromRow(saved);
  }

  static Future<bool> delete(
    AppDatabase db,
    String personId,
    String id,
  ) async {
    if (personId.isEmpty || id.isEmpty) return false;
    return db.devQuickTabsDAO.deleteTab(personId, id);
  }

  static Future<void> _migrateLegacyPrefsIfNeeded(
    AppDatabase db,
    String personId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyPrefsKey(personId));
    if (raw == null || raw.isEmpty) return;

    final existing = await db.devQuickTabsDAO.listForPerson(personId);
    if (existing.isNotEmpty) {
      await prefs.remove(_legacyPrefsKey(personId));
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map>()) {
          final tab = DevQuickTabProtocol.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (tab.id.isEmpty || tab.fullUrl.isEmpty) continue;
          await create(db, personId, tab);
        }
      }
    } catch (_) {}

    await prefs.remove(_legacyPrefsKey(personId));
  }
}
