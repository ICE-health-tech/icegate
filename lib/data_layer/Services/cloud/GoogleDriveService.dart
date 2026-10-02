import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:ice_gate/data_layer/Services/cloud/GoogleSignInHub.dart';

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
  static const String googleWebClientId = GoogleSignInHub.webClientId;
  static const String googleDarwinClientId = GoogleSignInHub.darwinClientId;

  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;

  drive.DriveApi? get driveApi => _driveApi;

  /// Try to sign in silently first, then fallback to interactive sign-in if [interactive] is true.
  Future<bool> signIn({bool interactive = true}) async {
    try {
      _account = await GoogleSignInHub.silentAccount();
      if (_account == null && interactive) {
        _account = await GoogleSignInHub.interactiveSignIn();
      }
      if (_account == null) return false;

      final scopesOk = await GoogleSignInHub.ensureScopes([
        drive.DriveApi.driveFileScope,
        drive.DriveApi.driveMetadataReadonlyScope,
      ]);
      if (!scopesOk) return false;

      _driveApi = drive.DriveApi(GoogleAuthorizedClient(_account!));
      return true;
    } catch (e) {
      debugPrint('Drive Sign-In Error: $e');
      return false;
    }
  }

  /// Explicitly check if the user is already signed in and restore session
  Future<void> restoreSession() async {
    await signIn(interactive: false);
  }

  Future<void> signOut() async {
    await GoogleSignInHub.signIn.signOut();
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

  Future<void> downloadFile(String fileId, File localFile, {String? mimeType}) async {
    if (_driveApi == null) throw Exception('Not signed in');

    drive.Media response;

    // Handle Google Docs Editors files (Doc, Sheet, Slide) which require 'export'
    if (mimeType != null && mimeType.startsWith('application/vnd.google-apps.')) {
      String exportMimeType = 'text/plain'; // Default for documents
      if (mimeType == 'application/vnd.google-apps.spreadsheet') {
        exportMimeType = 'text/csv';
      } else if (mimeType == 'application/vnd.google-apps.presentation') {
        exportMimeType = 'application/pdf';
      }

      try {
        response = await _driveApi!.files.export(
          fileId,
          exportMimeType,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;
      } catch (e) {
        debugPrint('Failed to export Google Doc ($mimeType): $e');
        rethrow;
      }
    } else {
      // Regular binary files
      response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
    }

    final fileSink = localFile.openWrite();
    await fileSink.addStream(response.stream);
    await fileSink.close();
  }

  Future<void> uploadFile(File localFile, String fileName, {String? parentId, String? fileId}) async {
    if (_driveApi == null) throw Exception('Not signed in');

    final driveFile = drive.File()
      ..name = fileName
      ..modifiedTime = localFile.lastModifiedSync().toUtc();
    
    final media = drive.Media(localFile.openRead(), localFile.lengthSync());

    if (fileId != null) {
      // Rule: 'parents' field is not writable in update requests.
      await _driveApi!.files.update(driveFile, fileId, uploadMedia: media);
    } else {
      if (parentId != null) {
        driveFile.parents = [parentId];
      }
      await _driveApi!.files.create(driveFile, uploadMedia: media);
    }
  }
}

