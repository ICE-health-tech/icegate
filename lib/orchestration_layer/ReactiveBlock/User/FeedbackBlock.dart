import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:uuid/uuid.dart';

class FeedbackBlock {
  late FeedbackDAO _dao;
  String? _personId;

  final isLoading = signal<bool>(false);
  final selectedImage = signal<String?>(null);
  
  void init(FeedbackDAO dao, String? personId) {
    _dao = dao;
    _personId = personId;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = image.path;
    }
  }

  void clearImage() {
    selectedImage.value = null;
  }

  Future<Map<String, dynamic>> getSystemContext() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    Map<String, dynamic> context = {
      'app_name': packageInfo.appName,
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'platform': Platform.operatingSystem,
    };

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      context.addAll({
        'device': androidInfo.model,
        'os_version': androidInfo.version.release,
        'sdk_int': androidInfo.version.sdkInt,
      });
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      context.addAll({
        'device': iosInfo.utsname.machine,
        'os_version': iosInfo.systemVersion,
        'model': iosInfo.model,
      });
    } else if (Platform.isMacOS) {
      final macosInfo = await deviceInfo.macOsInfo;
      context.addAll({
        'model': macosInfo.model,
        'os_version': macosInfo.osRelease,
      });
    }

    return context;
  }

  Future<bool> submitFeedback({
    required String message,
    required String type,
  }) async {
    if (message.isEmpty) return false;
    
    isLoading.value = true;
    try {
      final context = await getSystemContext();
      final uuid = const Uuid().v7();
      
      final feedback = FeedbackLocalData(
        id: uuid,
        personID: _personId,
        message: message,
        type: type,
        localImagePath: selectedImage.value,
        systemContext: jsonEncode(context),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _dao.insertFeedback(feedback);
      
      // Reset state after successful local save
      selectedImage.value = null;
      return true;
    } catch (e) {
      print("Error saving feedback: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
