import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/docs/v1.dart' as docs;
import 'package:http/http.dart' as http;
import 'package:ice_gate/link_layer/note_export/NoteExportPreferences.dart';

/// Same OAuth client IDs as [GoogleDriveService] so the user can reuse Google login.
const String _kGoogleWebClientId =
    '1076295055088-s88o9d59unnd0p68be5pmsiv6h2a0rgo.apps.googleusercontent.com';
const String _kGoogleDarwinClientId =
    '807274985161-2tgda6mbjop0k2vnf85q5plac7t6d1aq.apps.googleusercontent.com';

bool _useDarwinGoogleClientId() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

final GoogleSignIn _docsGoogleSignIn = GoogleSignIn(
  clientId: _useDarwinGoogleClientId()
      ? _kGoogleDarwinClientId
      : _kGoogleWebClientId,
  scopes: const [
    docs.DocsApi.documentsScope,
    docs.DocsApi.driveFileScope,
  ],
);

/// Push note text to Notion (database row) or Google Docs from the Flutter app after save.
class NoteExportService {
  NoteExportService._();

  static List<String> _chunks(String s, int max) {
    if (s.isEmpty) return [''];
    final out = <String>[];
    for (var i = 0; i < s.length; i += max) {
      final end = i + max > s.length ? s.length : i + max;
      out.add(s.substring(i, end));
    }
    return out;
  }

  static List<Map<String, dynamic>> _notionParagraphBlocks(String body) {
    final lines = body.split('\n');
    final blocks = <Map<String, dynamic>>[];
    for (final line in lines) {
      final pieces = _chunks(line, 1800);
      for (final chunk in pieces) {
        blocks.add({
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': chunk.isEmpty ? ' ' : chunk},
              },
            ],
          },
        });
      }
    }
    if (blocks.isEmpty) {
      blocks.add({
        'object': 'block',
        'type': 'paragraph',
        'paragraph': {
          'rich_text': [
            {
              'type': 'text',
              'text': {'content': ' '},
            },
          ],
        },
      });
    }
    return blocks;
  }

  /// Creates a row in the configured Notion database with [title] and paragraph blocks from [body].
  static Future<void> exportToNotion({
    required String integrationSecret,
    required String databaseId,
    required String titlePropertyName,
    required String title,
    required String body,
  }) async {
    final uri = Uri.parse('https://api.notion.com/v1/pages');
    final blocks = _notionParagraphBlocks(body);
    const firstBatch = 90;
    final initialChildren = blocks.length > firstBatch
        ? blocks.sublist(0, firstBatch)
        : blocks;
    final remaining = blocks.length > firstBatch
        ? blocks.sublist(firstBatch)
        : <Map<String, dynamic>>[];

    final payload = <String, dynamic>{
      'parent': {'database_id': databaseId.trim()},
      'properties': {
        titlePropertyName.trim(): {
          'title': [
            {
              'type': 'text',
              'text': {'content': title},
            },
          ],
        },
      },
      'children': initialChildren,
    };

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $integrationSecret',
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Notion ${res.statusCode}: ${res.body}',
      );
    }

    if (remaining.isEmpty) return;

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final pageId = map['id'] as String?;
    if (pageId == null) return;

    const appendBatch = 100;
    for (var i = 0; i < remaining.length; i += appendBatch) {
      final batch = remaining.sublist(
        i,
        i + appendBatch > remaining.length ? remaining.length : i + appendBatch,
      );
      final appendUri = Uri.parse(
        'https://api.notion.com/v1/blocks/$pageId/children',
      );
      final appendRes = await http.patch(
        appendUri,
        headers: {
          'Authorization': 'Bearer $integrationSecret',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'children': batch}),
      );
      if (appendRes.statusCode < 200 || appendRes.statusCode >= 300) {
        throw Exception(
          'Notion append ${appendRes.statusCode}: ${appendRes.body}',
        );
      }
    }
  }

  static Future<void> exportToGoogleDoc({
    required String title,
    required String body,
    bool interactive = true,
  }) async {
    GoogleSignInAccount? account =
        await _docsGoogleSignIn.signInSilently();
    if (account == null && interactive) {
      account = await _docsGoogleSignIn.signIn();
    }
    if (account == null) {
      throw Exception('Google sign-in was cancelled or failed.');
    }

    final client = _GoogleAuthHttpClient(account);
    try {
      final api = docs.DocsApi(client);
      final created = await api.documents.create(docs.Document(title: title));
      final docId = created.documentId;
      if (docId == null || docId.isEmpty) {
        throw Exception('Google Docs created document had no id.');
      }
      if (body.isEmpty) return;

      await api.documents.batchUpdate(
        docs.BatchUpdateDocumentRequest(
          requests: [
            docs.Request(
              insertText: docs.InsertTextRequest(
                location: docs.Location(index: 1),
                text: body,
              ),
            ),
          ],
        ),
        docId,
      );
    } finally {
      client.close();
    }
  }

  /// Runs exports according to [prefs] (typically after save when auto-export is on).
  static Future<void> runPostSaveExports({
    required NoteExportPreferences prefs,
    required String title,
    required String body,
  }) async {
    if (!prefs.autoExportAfterSave) return;

    if (prefs.notionEnabled && prefs.hasNotionConfig) {
      final secret = await NoteExportPreferences.readNotionSecret();
      if (secret != null) {
        try {
          await exportToNotion(
            integrationSecret: secret,
            databaseId: prefs.notionDatabaseId,
            titlePropertyName: prefs.notionTitlePropertyName,
            title: title,
            body: body,
          );
          debugPrint('✅ [NoteExport] Notion export OK');
        } catch (e, st) {
          debugPrint('❌ [NoteExport] Notion: $e\n$st');
        }
      }
    }

    if (prefs.googleDocsEnabled) {
      try {
        await exportToGoogleDoc(
          title: title,
          body: body,
          interactive: false,
        );
        debugPrint('✅ [NoteExport] Google Doc export OK');
      } catch (e, st) {
        debugPrint('❌ [NoteExport] Google Doc: $e\n$st');
      }
    }
  }

  static Future<void> exportNotionIfConfigured(
    NoteExportPreferences prefs, {
    required String title,
    required String body,
  }) async {
    if (!prefs.hasNotionConfig) {
      throw Exception('Notion integration token or database id is missing.');
    }
    final secret = await NoteExportPreferences.readNotionSecret();
    if (secret == null) {
      throw Exception('Notion integration secret not stored.');
    }
    await exportToNotion(
      integrationSecret: secret,
      databaseId: prefs.notionDatabaseId,
      titlePropertyName: prefs.notionTitlePropertyName,
      title: title,
      body: body,
    );
  }
}

class _GoogleAuthHttpClient extends http.BaseClient {
  _GoogleAuthHttpClient(this._account);
  final GoogleSignInAccount _account;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await _account.authHeaders;
    request.headers.addAll(headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
