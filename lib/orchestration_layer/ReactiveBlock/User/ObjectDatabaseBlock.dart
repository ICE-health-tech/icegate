import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// Save a picked image to the application's permanent document directory.
  Future<String> _saveLocalImage(XFile pickedFile, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final localFolder = Directory(p.join(appDir.path, 'profile_images'));
    if (!await localFolder.exists()) {
      await localFolder.create(recursive: true);
    }

    final localPath = p.join(localFolder.path, fileName);
    final savedFile = await File(pickedFile.path).copy(localPath);
    debugPrint('📂 [ObjectDB] Saved local image to: ${savedFile.path}');
    return savedFile.path;
  }

  /// Upload an image file to MinIO via the backend.
  ///
  /// [alias] - The user's alias (bucket folder)
  /// [fileName] - The target filename (e.g. 'admin.png' or 'cover.png')
  /// [imageFile] - The local image file to upload
  /// [token] - JWT auth token for the backend
  Future<bool> uploadImageToMinio({
    required String userId,
    required String fileName,
    required File imageFile,
    required String token,
  }) async {
    try {
      final baseUrl = UserObjectResource.baseObjectUrl.endsWith('/')
          ? UserObjectResource.baseObjectUrl.substring(
              0,
              UserObjectResource.baseObjectUrl.length - 1,
            )
          : UserObjectResource.baseObjectUrl;

      final uploadUrl = Uri.parse(
        '$baseUrl/object/duylongwebappobjectdatabase/$userId/$fileName',
      );

      debugPrint('📤 [ObjectDB] Uploading $fileName for userId: $userId');
      debugPrint('📤 [ObjectDB] Upload URL: $uploadUrl');

      // Detect content type
      String contentType = 'application/octet-stream';
      if (fileName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      }

      // Send direct PUT request with raw bytes
      final response = await http.put(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': contentType,
        },
        body: await imageFile.readAsBytes(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [ObjectDB] $fileName uploaded successfully');
        return true;
      } else {
        debugPrint(
          '❌ [ObjectDB] Upload failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ [ObjectDB] Upload error: $e');
      return false;
    }
  }

  /// Pick an image from gallery and upload it as avatar (admin.png)
  /// Returns the local path if successful.
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

      final localPath = await _saveLocalImage(pickedFile, 'admin.png');

      final file = File(localPath);
      final success = await uploadImageToMinio(
        userId: userId,
        fileName: 'admin.png',
        imageFile: file,
        token: token,
      );

      if (success) {
        _refreshUrls(userId);
      }

      return localPath;
    } catch (e) {
      debugPrint('❌ [ObjectDB] pickAndUploadAvatar error: $e');
      return null;
    }
  }

  /// Pick an image from gallery and upload it as cover (cover.png)
  /// Returns the local path if successful.
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

      final localPath = await _saveLocalImage(pickedFile, 'cover.png');

      final file = File(localPath);
      final success = await uploadImageToMinio(
        userId: userId,
        fileName: 'cover.png',
        imageFile: file,
        token: token,
      );

      if (success) {
        _refreshUrls(userId);
      }

      return localPath;
    } catch (e) {
      debugPrint('❌ [ObjectDB] pickAndUploadCover error: $e');
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
          "$baseUrl/object/duylongwebappobjectdatabase/$userId/admin.png?v=$cacheBuster",
      coverImage:
          "$baseUrl/object/duylongwebappobjectdatabase/$userId/cover.png?v=$cacheBuster",
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
      avatarImage:
          "$baseUrl/object/duylongwebappobjectdatabase/$pathId/admin.png",
      coverImage:
          "$baseUrl/object/duylongwebappobjectdatabase/$pathId/cover.png",
    );
  }
}
