import 'dart:io';
import 'package:minio/minio.dart';
import 'package:minio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

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
      print('MinioService: Bucket initialization skipped/failed (expected for some S3 setups): $e');
    }
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
      print('Upload progress: $progress');
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
}
