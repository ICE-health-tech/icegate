import 'dart:io';
import 'package:minio/minio.dart';
import 'package:minio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:ice_gate/utils/app_log.dart';

class MinioService {
  static final MinioService _instance = MinioService._internal();
  factory MinioService() => _instance;
  MinioService._internal() {
    _init();
  }

  late Minio minio;
  final String bucketName = dotenv.env['S3_BUCKET'] ?? 'food-images';
  final String region = dotenv.env['S3_REGION'] ?? 'ap-southeast-2';
  final String endpoint = dotenv.env['S3_ENDPOINT'] ?? 's3.ap-southeast-2.amazonaws.com';

  void _init() {
    final endpoint = dotenv.env['S3_ENDPOINT'] ?? 's3.ap-southeast-2.amazonaws.com';
    final accessKey = dotenv.env['S3_ACCESS_KEY'] ?? '';
    final secretKey = dotenv.env['S3_SECRET_KEY'] ?? '';
    final useSSL = dotenv.env['S3_USE_SSL']?.toLowerCase() == 'true';
    final port = int.tryParse(dotenv.env['S3_PORT'] ?? '443') ?? 443;
    final region = dotenv.env['S3_REGION'] ?? 'ap-southeast-2';

    minio = Minio(
      endPoint: endpoint,
      accessKey: accessKey,
      secretKey: secretKey,
      useSSL: useSSL,
      port: port,
      region: region,
    );
  }

  Future<void> initBucket() async {
    try {
      bool exists = await minio.bucketExists(bucketName);
      if (!exists) {
        await minio.makeBucket(bucketName, region);
      }
    } catch (e) {
      // For S3 Access Points or restricted IAM roles, bucketExists/makeBucket might fail.
      // We log the error but allow the service to continue as the bucket likely exists.
      appLog('MinioService: Bucket initialization skipped/failed (expected for some S3 setups): $e');
    }
  }

  /// Public URL for an object key (same layout as [uploadFileAtKey] return value).
  String publicUrlForKey(String objectKey) {
    final key = objectKey.replaceAll('\\', '/').trim();
    if (endpoint.contains('amazonaws.com')) {
      return 'https://$bucketName.s3.$region.amazonaws.com/$key';
    }
    final port = dotenv.env['S3_PORT'] ?? '443';
    final proto =
        (dotenv.env['S3_USE_SSL']?.toLowerCase() == 'true') ? 'https' : 'http';
    final portString = (port == '443' || port == '80') ? '' : ':$port';
    return '$proto://$endpoint$portString/$bucketName/$key';
  }

  /// Upload using the exact object key stored in Drift / Supabase (e.g. `personId/memories/foo.png`).
  Future<String> uploadFileAtKey(File file, {required String objectKey}) async {
    final key = objectKey.replaceAll('\\', '/').trim();
    await minio.fPutObject(bucketName, key, file.path);
    return publicUrlForKey(key);
  }

  Future<String> uploadFile(File file, {String? fileName, String? subFolder}) async {
    final baseName = fileName ?? p.basename(file.path);
    final fullName = subFolder != null ? '$subFolder/$baseName' : baseName;
    
    await minio.fPutObject(bucketName, fullName, file.path);
    
    // Construct URL for AWS S3
    if (endpoint.contains('amazonaws.com')) {
      return 'https://$bucketName.s3.$region.amazonaws.com/$fullName';
    }
    
    final port = dotenv.env['S3_PORT'] ?? '443';
    final proto = (dotenv.env['S3_USE_SSL']?.toLowerCase() == 'true') ? 'https' : 'http';
    final portString = (port == '443' || port == '80') ? '' : ':$port';
    return '$proto://$endpoint$portString/$bucketName/$fullName';
  }

  Future<String> uploadBytes(List<int> bytes, String fileName, {String? subFolder, String? contentType}) async {
    final uint8List = Uint8List.fromList(bytes);
    final stream = Stream.value(uint8List);
    final fullName = subFolder != null ? '$subFolder/$fileName' : fileName;
    
    await minio.putObject(bucketName, fullName, stream, onProgress: (progress) {
      appLog('Upload progress: $progress');
    });
 
    if (endpoint.contains('amazonaws.com')) {
      return 'https://$bucketName.s3.$region.amazonaws.com/$fullName';
    }
 
    final port = dotenv.env['S3_PORT'] ?? '443';
    final proto = (dotenv.env['S3_USE_SSL']?.toLowerCase() == 'true') ? 'https' : 'http';
    final portString = (port == '443' || port == '80') ? '' : ':$port';
    return '$proto://$endpoint$portString/$bucketName/$fullName';
  }

  Future<void> deleteFile(String fileName) async {
    await minio.removeObject(bucketName, fileName);
  }

  /// Returns true if object exists in bucket.
  Future<bool> objectExists(String objectName) async {
    try {
      await minio.statObject(bucketName, objectName);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lists object names under a prefix, e.g. `<userId>/memories/`.
  Future<List<String>> listObjectNames({
    required String prefix,
    bool recursive = true,
  }) async {
    final names = <String>[];
    try {
      final stream = minio.listObjects(
        bucketName,
        prefix: prefix,
        recursive: recursive,
      );
      await for (final chunk in stream) {
        for (final obj in chunk.objects) {
          final key = obj.key;
          if (key != null && key.isNotEmpty) names.add(key);
        }
      }
    } catch (e) {
      appLog('MinioService listObjectNames failed ($prefix): $e');
    }
    return names;
  }

  /// Download an object to [outFile]. Returns true if it was written.
  Future<bool> downloadToFile({
    required String objectName,
    required File outFile,
  }) async {
    try {
      final parent = outFile.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
      if (await outFile.exists()) {
        return true;
      }

      final stream = await minio.getObject(bucketName, objectName);
      final sink = outFile.openWrite();
      await stream.pipe(sink);
      await sink.flush();
      await sink.close();
      return await outFile.exists();
    } catch (e) {
      appLog('MinioService downloadToFile failed ($objectName): $e');
      return false;
    }
  }
}
