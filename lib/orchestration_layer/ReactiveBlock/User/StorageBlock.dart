import 'dart:io';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:signals/signals.dart';

class StorageBlock {
  final MinioService _minioService = MinioService();
  
  // State signals
  final isUploading = signal<bool>(false);
  final uploadProgress = signal<double>(0.0);
  final lastUploadUrl = signal<String?>(null);

  StorageBlock();

  Future<void> init() async {
    await _minioService.initBucket();
  }

  Future<String?> uploadFile(File file, {String? fileName}) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    try {
      final url = await _minioService.uploadFile(file, fileName: fileName);
      lastUploadUrl.value = url;
      return url;
    } catch (e) {
      print('StorageBlock Upload Error: $e');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<String?> uploadBytes(List<int> bytes, String fileName) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    try {
      final url = await _minioService.uploadBytes(bytes, fileName);
      lastUploadUrl.value = url;
      return url;
    } catch (e) {
      print('StorageBlock Upload Error: $e');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  void dispose() {
    isUploading.dispose();
    uploadProgress.dispose();
    lastUploadUrl.dispose();
  }
}
