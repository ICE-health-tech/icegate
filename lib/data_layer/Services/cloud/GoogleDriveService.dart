import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class DriveFile {
  final String id;
  final String name;
  final String mimeType;
  final DateTime? modifiedTime;
  final int? size;

  DriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.modifiedTime,
    this.size,
  });

  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';
}

class GoogleDriveService {
  static const String googleWebClientId =
      '1076295055088-s88o9d59unnd0p68be5pmsiv6h2a0rgo.apps.googleusercontent.com';
  static const String googleDarwinClientId =
      '807274985161-2tgda6mbjop0k2vnf85q5plac7t6d1aq.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (Platform.isIOS || Platform.isMacOS) ? googleDarwinClientId : googleWebClientId,
    scopes: [drive.DriveApi.driveFileScope, drive.DriveApi.driveMetadataReadonlyScope],
  );

  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;

  drive.DriveApi? get driveApi => _driveApi;

  Future<bool> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      if (_account == null) return false;

      final authHeaders = await _account!.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);
      return true;
    } catch (e) {
      debugPrint('Drive Sign-In Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    _driveApi = null;
  }

  /// Fetch folders in a specific parent. Empty parentId means root.
  Future<List<DriveFile>> fetchFolders({String? parentId}) async {
    if (_driveApi == null) throw Exception('Not signed in');

    final parent = parentId ?? 'root';
    final q = "'$parent' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    
    final fileList = await _driveApi!.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id, name, mimeType, modifiedTime, size)',
    );

    return fileList.files
            ?.map((f) => DriveFile(
                  id: f.id!,
                  name: f.name!,
                  mimeType: f.mimeType!,
                  modifiedTime: f.modifiedTime,
                  size: int.tryParse(f.size ?? '0'),
                ))
            .toList() ??
        [];
  }

  /// Optimized Deep Fetch using streams to avoid blocking
  Stream<DriveFile> deepFetchStream(String folderId) async* {
    if (_driveApi == null) throw Exception('Not signed in');

    final queue = <String>[folderId];
    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final q = "'$currentId' in parents and trashed = false";
      
      String? pageToken;
      do {
        final result = await _driveApi!.files.list(
          q: q,
          spaces: 'drive',
          pageToken: pageToken,
          $fields: 'nextPageToken, files(id, name, mimeType, modifiedTime, size)',
        );

        for (final file in result.files ?? []) {
          final driveFile = DriveFile(
            id: file.id!,
            name: file.name!,
            mimeType: file.mimeType!,
            modifiedTime: file.modifiedTime,
            size: int.tryParse(file.size ?? '0'),
          );
          
          yield driveFile;

          if (driveFile.isFolder) {
            queue.add(driveFile.id);
          }
        }
        pageToken = result.nextPageToken;
      } while (pageToken != null);
    }
  }

  Future<drive.File> getFileMetadata(String fileId) async {
    if (_driveApi == null) throw Exception('Not signed in');
    return await _driveApi!.files.get(fileId, $fields: 'id, name, modifiedTime, size, mimeType') as drive.File;
  }

  Future<void> downloadFile(String fileId, File localFile) async {
    if (_driveApi == null) throw Exception('Not signed in');
    
    final response = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.metadata,
    ) as drive.Media;

    final List<int> dataStore = [];
    await for (final data in response.stream) {
      dataStore.addAll(data);
    }
    await localFile.writeAsBytes(dataStore);
  }

  Future<void> uploadFile(File localFile, String fileName, {String? parentId, String? fileId}) async {
    if (_driveApi == null) throw Exception('Not signed in');

    final driveFile = drive.File()
      ..name = fileName
      ..modifiedTime = localFile.lastModifiedSync().toUtc();
    
    if (parentId != null) {
      driveFile.parents = [parentId];
    }

    final media = drive.Media(localFile.openRead(), localFile.lengthSync());

    if (fileId != null) {
      await _driveApi!.files.update(driveFile, fileId, uploadMedia: media);
    } else {
      await _driveApi!.files.create(driveFile, uploadMedia: media);
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
