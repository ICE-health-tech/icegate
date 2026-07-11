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
    remoteUrl: row.remoteUrl,
    sortOrder: row.sortOrder,
    isPinned: row.isPinned,
    username: row.username,
    password: row.password,
    passkey: row.passkey,
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
      if (tab.username.isEmpty &&
          tab.password.isEmpty &&
          tab.passkey.isEmpty) {
        continue;
      }
      for (final host in tab.allHosts) {
        if (!seen.add(host)) continue;
        final existing = await store.readHostCredentials(host);
        await store.saveHostCredentials(
          host: host,
          username: tab.username.isNotEmpty ? tab.username : existing.username,
          password: tab.password.isNotEmpty ? tab.password : existing.password,
          passkey: tab.passkey.isNotEmpty ? tab.passkey : existing.passkey,
          sslTrusted: existing.sslTrusted,
          loginType: DevQuickTabLoginType.fromStorage(tab.loginType),
        );
      }
    }

    // SSL trust on one host (LAN or Tailscale) applies to every host on the tab.
    for (final tab in tabs) {
      final hosts = tab.allHosts.toList();
      if (hosts.length < 2) continue;
      var anyTrusted = false;
      for (final h in hosts) {
        if (await store.isHomelabSslTrusted(h)) {
          anyTrusted = true;
          break;
        }
      }
      if (!anyTrusted) continue;
      for (final h in hosts) {
        await store.setHomelabSslTrusted(h, true);
      }
    }

    // Bearer token / SSL saved for Tailscale must work when LAN URL opens.
    for (final tab in tabs) {
      final hosts = tab.allHosts.toList();
      if (hosts.length < 2) continue;
      WebViewHostCredentials? source;
      for (final h in hosts) {
        final c = await store.readHostCredentials(h);
        if (c.passkey.isNotEmpty || c.password.isNotEmpty) {
          source = c;
          break;
        }
        source ??= c;
      }
      if (source == null) continue;
      for (final h in hosts) {
        final existing = await store.readHostCredentials(h);
        await store.saveHostCredentials(
          host: h,
          username: source.username.isNotEmpty
              ? source.username
              : existing.username,
          password: source.password.isNotEmpty
              ? source.password
              : existing.password,
          passkey:
              source.passkey.isNotEmpty ? source.passkey : existing.passkey,
          sslTrusted: source.sslTrusted || existing.sslTrusted,
          loginType: source.loginType,
        );
      }
    }
  }

  /// Before opening [openUrl], copy SSL trust from a sibling host on the same tab.
  static Future<void> syncSslTrustForOpenUrl(
    AppDatabase db,
    String personId,
    String openUrl,
  ) async {
    final openHost = Uri.tryParse(openUrl)?.host ?? '';
    if (personId.isEmpty || openHost.isEmpty) return;
    final store = WebViewCredentialStore();
    if (await store.isHomelabSslTrusted(openHost)) return;

    final rows = await db.devQuickTabsDAO.listForPerson(personId);
    for (final row in rows) {
      final tab = _fromRow(row);
      if (!tab.allHosts.contains(openHost)) continue;
      for (final h in tab.allHosts) {
        if (h != openHost && await store.isHomelabSslTrusted(h)) {
          await store.setHomelabSslTrusted(openHost, true);
          return;
        }
      }
    }
  }

  /// After saving credentials for [host], mirror SSL trust to sibling tab hosts.
  static Future<void> propagateSslTrustForTabHosts(
    AppDatabase db,
    String personId, {
    required String host,
    required bool trusted,
  }) async {
    if (personId.isEmpty || host.isEmpty || !trusted) return;
    final store = WebViewCredentialStore();
    final rows = await db.devQuickTabsDAO.listForPerson(personId);
    for (final row in rows) {
      final tab = _fromRow(row);
      if (!tab.allHosts.contains(host)) continue;
      for (final h in tab.allHosts) {
        await store.setHomelabSslTrusted(h, true);
      }
    }
  }

  /// Copy saved creds + SSL trust from [host] to every other host on the tab.
  static Future<void> propagateCredentialsToTabSiblingHosts(
    AppDatabase db,
    String personId, {
    required String host,
  }) async {
    if (personId.isEmpty || host.isEmpty) return;
    final store = WebViewCredentialStore();
    final source = await store.readHostCredentials(host);
    final rows = await db.devQuickTabsDAO.listForPerson(personId);
    for (final row in rows) {
      final tab = _fromRow(row);
      if (!tab.allHosts.contains(host)) continue;
      for (final h in tab.allHosts) {
        if (h == host) continue;
        final existing = await store.readHostCredentials(h);
        await store.saveHostCredentials(
          host: h,
          username:
              source.username.isNotEmpty ? source.username : existing.username,
          password:
              source.password.isNotEmpty ? source.password : existing.password,
          passkey: source.passkey.isNotEmpty ? source.passkey : existing.passkey,
          sslTrusted: source.sslTrusted || existing.sslTrusted,
          loginType: source.loginType,
        );
      }
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
    required String passkey,
    required String loginType,
  }) async {
    if (personId.isEmpty || host.isEmpty) return;
    // Read rows directly (list() would mirror stale row creds to secure store).
    final rows = await db.devQuickTabsDAO.listForPerson(personId);
    for (final row in rows) {
      final tab = _fromRow(row);
      if (!tab.allHosts.contains(host)) continue;
      await update(
        db,
        personId,
        _fromRow(row).copyWith(
          username: username,
          password: password,
          passkey: passkey,
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
        remoteUrl: Value(tab.remoteUrl),
        sortOrder: Value(tab.sortOrder),
        isPinned: Value(tab.isPinned),
        username: Value(tab.username),
        password: Value(tab.password),
        passkey: Value(tab.passkey),
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
      remoteUrl: tab.remoteUrl,
      sortOrder: tab.sortOrder,
      isPinned: tab.isPinned,
      username: tab.username,
      password: tab.password,
      passkey: tab.passkey,
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
          if (tab.id.isEmpty || !tab.hasAnyUrl) continue;
          await create(db, personId, tab);
        }
      }
    } catch (_) {}

    await prefs.remove(_legacyPrefsKey(personId));
  }
}
