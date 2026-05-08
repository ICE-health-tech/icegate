import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores optional credentials and toggles for post-save export (Notion / Google Docs).
class NoteExportPreferences {
  NoteExportPreferences._({
    required this.autoExportAfterSave,
    required this.notionEnabled,
    required this.googleDocsEnabled,
    required this.notionDatabaseId,
    required this.notionTitlePropertyName,
    required this.notionSecretPresent,
  });

  final bool autoExportAfterSave;
  final bool notionEnabled;
  final bool googleDocsEnabled;
  final String notionDatabaseId;
  /// Must match your Notion database's title column name (often "Name" or "Title").
  final String notionTitlePropertyName;
  final bool notionSecretPresent;

  bool get hasNotionConfig =>
      notionSecretPresent &&
      notionDatabaseId.trim().isNotEmpty &&
      notionTitlePropertyName.trim().isNotEmpty;

  static const _kAuto = 'note_export_auto_after_save';
  static const _kNotionOn = 'note_export_notion_enabled';
  static const _kGdocsOn = 'note_export_gdocs_enabled';
  static const _kDbId = 'note_export_notion_database_id';
  static const _kTitleProp = 'note_export_notion_title_property';

  static const _secureTokenKey = 'note_export_notion_integration_secret';

  static Future<NoteExportPreferences> load() async {
    final sp = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage();
    final token = await secure.read(key: _secureTokenKey);
    return NoteExportPreferences._(
      autoExportAfterSave: sp.getBool(_kAuto) ?? false,
      notionEnabled: sp.getBool(_kNotionOn) ?? false,
      googleDocsEnabled: sp.getBool(_kGdocsOn) ?? false,
      notionDatabaseId: sp.getString(_kDbId) ?? '',
      notionTitlePropertyName: sp.getString(_kTitleProp) ?? 'Name',
      notionSecretPresent: token != null && token.trim().isNotEmpty,
    );
  }

  static Future<String?> readNotionSecret() async {
    const secure = FlutterSecureStorage();
    return secure.read(key: _secureTokenKey);
  }

  /// [notionSecret]: `null` = leave unchanged, empty string = clear, non-empty = save.
  static Future<void> save({
    required bool autoExportAfterSave,
    required bool notionEnabled,
    required bool googleDocsEnabled,
    required String notionDatabaseId,
    required String notionTitlePropertyName,
    String? notionSecret,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAuto, autoExportAfterSave);
    await sp.setBool(_kNotionOn, notionEnabled);
    await sp.setBool(_kGdocsOn, googleDocsEnabled);
    await sp.setString(_kDbId, notionDatabaseId.trim());
    await sp.setString(_kTitleProp, notionTitlePropertyName.trim());
    const secure = FlutterSecureStorage();
    if (notionSecret != null) {
      final t = notionSecret.trim();
      if (t.isEmpty) {
        await secure.delete(key: _secureTokenKey);
      } else {
        await secure.write(key: _secureTokenKey, value: t);
      }
    }
  }

  static Future<void> clearNotionSecret() async {
    const secure = FlutterSecureStorage();
    await secure.delete(key: _secureTokenKey);
  }
}
