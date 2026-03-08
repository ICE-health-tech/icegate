import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserObjectResource {
  final String avatarImage;
  final String coverImage;
  static String baseObjectUrl = 'https://backend.duylong.art';
  UserObjectResource({required this.avatarImage, required this.coverImage});
}

class ObjectDatabaseBlock {
  final userObjectResource = signal<UserObjectResource>(
    UserObjectResource(avatarImage: '', coverImage: ''),
  );

  final _imagePicker = ImagePicker();

  /// Save a picked image to a specific subfolder in the application's permanent document directory.
  /// If personId is provided, creates nested folder structure: {personId}/{subFolder}/
  /// returns a relative path from the app documents directory (e.g., "userId/subFolder/filename").
  Future<String> saveAnyLocalImage(
    XFile pickedFile, {
    String? customFileName,
    String subFolder = 'general_images',
    String? personId,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Create nested folder structure if personId is provided
      final targetFolder = personId != null
          ? Directory(p.join(appDir.path, personId, subFolder))
          : Directory(p.join(appDir.path, subFolder));

      if (!await targetFolder.exists()) {
        await targetFolder.create(recursive: true);
      }

      // If no custom name provided, keep original name but sanitize
      final fileName = customFileName ?? p.basename(pickedFile.path);
      final localPath = p.join(targetFolder.path, fileName);

      // Overwrite if exists
      final oldFile = File(localPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      final savedFile = await File(pickedFile.path).copy(localPath);
      print('📂 [ObjectDB] Saved universal image to: ${savedFile.path}');

      // Evict from Flutter image cache to ensure UI updates
      await imageCache.evict(FileImage(File(localPath)));

      // Return structured relative path for better identification
      if (personId != null) {
        return p.join(personId, subFolder, p.basename(savedFile.path));
      }
      return p.join(subFolder, p.basename(savedFile.path));
    } catch (e) {
      print('❌ [ObjectDB] saveAnyLocalImage failed: $e');
      rethrow;
    }
  }

  /// Legacy wrapper for backward compatibility with avatar/cover logic
  Future<String> _saveLocalImage(XFile pickedFile, String fileName) async {
    final user = Supabase.instance.client.auth.currentUser;
    final personId = user?.id;

    // Returns "personId/profile_images/fileName"
    return saveAnyLocalImage(
      pickedFile,
      customFileName: fileName,
      subFolder: 'profile_images',
      personId: personId,
    );
  }

  /// Upload an image file to MinIO via the backend.
  ///
  /// [alias] - The user's alias (bucket folder)
  /// [fileName] - The target filename (e.g. 'admin.png' or 'cover.png')
  /// [imageFile] - The local image file to upload
  /// [token] - JWT auth token for the backend
  /// Upload an image file to the Java Backend.
  /// Uses specific endpoints for avatar, cover, and general media.
  Future<bool> uploadImageToBackend({
    required File imageFile,
    required String token,
    String? type, // 'avatar', 'cover', or null for general
  }) async {
    try {
      final baseUrl = UserObjectResource.baseObjectUrl.endsWith('/')
          ? UserObjectResource.baseObjectUrl.substring(
              0,
              UserObjectResource.baseObjectUrl.length - 1,
            )
          : UserObjectResource.baseObjectUrl;

      String endpoint;
      if (type == 'avatar') {
        endpoint = '/backend/person/avatar/update';
      } else if (type == 'cover') {
        endpoint = '/backend/person/cover/update';
      } else {
        endpoint = '/backend/person/app/upload';
      }

      final uploadUrl = Uri.parse('$baseUrl$endpoint');
      final fileName = p.basename(imageFile.path);

      debugPrint('📤 [ObjectDB] Uploading $fileName to $uploadUrl');

      final request = http.MultipartRequest('POST', uploadUrl);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '✅ [ObjectDB] $fileName uploaded successfully: ${response.body}',
        );
        return true;
      } else {
        debugPrint('❌ [ObjectDB] Upload failed status: ${response.statusCode}');
        debugPrint('❌ [ObjectDB] Error Body: ${response.body}');
        throw Exception('Upload Failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [ObjectDB] Upload error: $e');
      rethrow;
    }
  }

  // Legacy compatibility / Helper for existing calls
  Future<bool> uploadImageToMinio({
    required String userId,
    required String fileName,
    required File imageFile,
    required String token,
  }) async {
    // Determine type from fileName for backward compatibility
    String? type;
    if (fileName == 'avatar.png' || fileName == 'admin.png') type = 'avatar';
    if (fileName == 'cover.png') type = 'cover';

    return uploadImageToBackend(imageFile: imageFile, token: token, type: type);
  }

  /// Pick an image from gallery and upload it as avatar (admin.png)
  /// Returns the local path if successful (local save).
  Future<String?> pickAndUploadAvatar({
    required String userId,
    required String token,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('⚠️ [ObjectDB] Avatar pick cancelled');
        return null;
      }

      // 1. Save locally FIRST (Ensures offline persistence)
      final localPath = await _saveLocalImage(pickedFile, 'avatar.png');
      final file = File(localPath);

      // 2. Attempt upload in background/try-catch
      try {
        final success = await uploadImageToMinio(
          userId: userId,
          fileName: 'admin.png',
          imageFile: file,
          token: token,
        );

        if (success) {
          _refreshUrls(userId);
        }
      } catch (e) {
        print('⚠️ [ObjectDB] Server upload failed, but kept local copy: $e');
        // We continue because we have the local copy stored
      }

      return localPath;
    } catch (e) {
      debugPrint('❌ [ObjectDB] pickAndUploadAvatar fatal error: $e');
      return null;
    }
  }

  /// Pick an image from gallery and upload it as cover (cover.png)
  /// Returns the local path if successful (local save).
  Future<String?> pickAndUploadCover({
    required String userId,
    required String token,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('⚠️ [ObjectDB] Cover pick cancelled');
        return null;
      }

      // 1. Save locally FIRST
      final localPath = await _saveLocalImage(pickedFile, 'cover.png');
      final file = File(localPath);

      // 2. Attempt upload
      try {
        final success = await uploadImageToMinio(
          userId: userId,
          fileName: 'cover.png',
          imageFile: file,
          token: token,
        );

        if (success) {
          _refreshUrls(userId);
        }
      } catch (e) {
        print('⚠️ [ObjectDB] Server upload failed, but kept local copy: $e');
      }

      return localPath;
    } catch (e) {
      debugPrint('❌ [ObjectDB] pickAndUploadCover fatal error: $e');
      return null;
    }
  }

  /// Refresh image URLs with cache-busting timestamp
  void _refreshUrls(String userId) {
    final baseUrl = UserObjectResource.baseObjectUrl.endsWith('/')
        ? UserObjectResource.baseObjectUrl.substring(
            0,
            UserObjectResource.baseObjectUrl.length - 1,
          )
        : UserObjectResource.baseObjectUrl;

    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    userObjectResource.value = UserObjectResource(
      avatarImage:
          "$baseUrl/object/profiles/$userId/avatars/avatar.png?v=$cacheBuster",
      coverImage:
          "$baseUrl/object/profiles/$userId/covers/cover.png?v=$cacheBuster",
    );
  }

  Future<void> updateUrlOfUser(PersonBlock personBlock) async {
    final profile = personBlock.information.value.profiles;
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    final String username = profile.username;

    print("userId: $userId, username: $username");

    if (userId == null && username.isEmpty) {
      userObjectResource.value = UserObjectResource(
        avatarImage: '',
        coverImage: '',
      );
      return;
    }

    final pathId = userId ?? username;

    // Ensure baseObjectUrl doesn't end with slash, prevent double slashes
    final baseUrl = UserObjectResource.baseObjectUrl.endsWith('/')
        ? UserObjectResource.baseObjectUrl.substring(
            0,
            UserObjectResource.baseObjectUrl.length - 1,
          )
        : UserObjectResource.baseObjectUrl;

    if (username == 'Guest-Shield') {
      userObjectResource.value = UserObjectResource(
        avatarImage:
            "https://ui-avatars.com/api/?name=Guest+User&background=6366F1&color=fff",
        coverImage:
            "https://images.unsplash.com/photo-1614850523296-d8c1af93d400?q=80&w=1000&auto=format&fit=crop",
      );
      return;
    }

    userObjectResource.value = UserObjectResource(
      avatarImage: "$baseUrl/object/profiles/$pathId/avatars/avatar.png",
      coverImage: "$baseUrl/object/profiles/$pathId/covers/cover.png",
    );
  }

  /// Logs all files in a folder to a text file within that folder for debugging.
  Future<void> logFolderContents(String subFolder) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(appDir.path, subFolder));

      if (!await folder.exists()) {
        debugPrint('❌ [ObjectDB] Folder does not exist: $subFolder');
        return;
      }

      final List<FileSystemEntity> files = await folder.list().toList();
      final StringBuffer logBuf = StringBuffer();
      logBuf.writeln('📅 Folder Log: $subFolder at ${DateTime.now()}');
      logBuf.writeln('------------------------------------------');

      for (var file in files) {
        if (file is File) {
          final size = await file.length();
          logBuf.writeln('${p.basename(file.path)} - $size bytes');
        } else {
          logBuf.writeln('${p.basename(file.path)} [DIR]');
        }
      }

      final logFile = File(p.join(folder.path, 'manifest.txt'));
      await logFile.writeAsString(logBuf.toString());
      debugPrint(
        '📝 [ObjectDB] Logged ${files.length} items to ${logFile.path}',
      );
    } catch (e) {
      debugPrint('❌ [ObjectDB] logFolderContents failed: $e');
    }
  }
}
