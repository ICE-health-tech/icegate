import 'dart:io';
import 'dart:async';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:ice_gate/link_layer/storage_services/MediaS3Paths.dart';
import 'package:ice_gate/link_layer/storage_services/MediaSync.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryImage.dart';
import 'package:drift/drift.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/utils/app_log.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageBlock {
  final MinioService _minioService = MinioService();
  final LocalMediaIndexDAO _mediaIndexDao;
  
  // State signals
  final isUploading = signal<bool>(false);
  final uploadProgress = signal<double>(0.0);
  final lastUploadUrl = signal<String?>(null);

  Timer? _scanTimer;
  String? _activePersonId;
  bool _storyBackfillRunning = false;

  StorageBlock({required LocalMediaIndexDAO mediaIndexDao})
      : _mediaIndexDao = mediaIndexDao;

  Future<void> init() async {
    await _minioService.initBucket();
  }

  /// Auto scan local image folders and persist paths into Drift.
  /// This is local-only indexing (foundation for later background sync).
  Future<void> scanAndIndexLocalImages({
    required String personId,
    List<String> subFolders = const [
      'profile_images',
      'user_markdown_documentation',
      'meals',
      'quests',
      'memories',
      'general_images',
    ],
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final rows = <LocalMediaIndexTableCompanion>[];

      for (final sub in subFolders) {
        final dir = Directory(p.join(appDir.path, personId, sub));
        if (!await dir.exists()) continue;

        final entities = dir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is! File) continue;
          final ext = p.extension(entity.path).toLowerCase();
          final isImage = ext == '.png' ||
              ext == '.jpg' ||
              ext == '.jpeg' ||
              ext == '.heic' ||
              ext == '.webp' ||
              ext == '.gif';
          if (!isImage) continue;

          final rel = p.join(
            personId,
            sub,
            p.relative(entity.path, from: p.join(appDir.path, personId, sub)),
          );
          final stat = entity.statSync();
          final id = LocalMediaIndexDAO.deterministicId(
            personId: personId,
            relativePath: rel,
          );

          rows.add(
            LocalMediaIndexTableCompanion(
              id: Value(id),
              personID: Value(personId),
              relativePath: Value(rel),
              subFolder: Value(sub),
              fileName: Value(p.basename(entity.path)),
              fileBytes: Value(stat.size),
              lastModifiedAt: Value(stat.modified),
              updatedAt: Value(now),
            ),
          );
        }
      }

      await _mediaIndexDao.upsertMany(rows);
      appLog('🧾 [StorageBlock] Indexed ${rows.length} local images for $personId');
    } catch (e) {
      appLog('❌ [StorageBlock] scanAndIndexLocalImages failed: $e');
    }
  }

  /// Starts periodic scanning (safe to call multiple times; will restart if person changes).
  void startAutoScan({
    required String personId,
    Duration interval = const Duration(minutes: 2),
  }) {
    if (_activePersonId == personId && _scanTimer != null) return;
    _activePersonId = personId;
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(interval, (_) {
      final pid = _activePersonId;
      if (pid == null || pid.isEmpty) return;
      unawaited(scanAndIndexLocalImages(personId: pid));
    });
    // Kick once immediately, then sync indexed files with S3.
    unawaited(() async {
      await scanAndIndexLocalImages(personId: personId);
      await syncIndexedMediaWithS3(personId: personId);
    }());
  }

  /// Upload local indexed images missing on S3; download S3 objects missing locally.
  /// Optionally pushes profile/cover URLs to Supabase `profiles`.
  Future<int> syncIndexedMediaWithS3({
    required String personId,
    bool autoFix = true,
    bool pushProfileUrlsToSupabase = true,
  }) async {
    if (personId.isEmpty) return 0;
    try {
      final rows = await _mediaIndexDao.getAllByPerson(personId);
      if (rows.isEmpty) {
        await scanAndIndexLocalImages(personId: personId);
      }
      final indexed = rows.isEmpty
          ? await _mediaIndexDao.getAllByPerson(personId)
          : rows;

      final appDir = await getApplicationDocumentsDirectory();
      var fixed = 0;

      for (final row in indexed) {
        final rel = row.relativePath.replaceAll('\\', '/').trim();
        if (rel.isEmpty) continue;

        final localRel = canonicalLocalMediaPath(rel);
        final localFile = File(p.join(appDir.path, localRel));
        final existsLocal = await localFile.exists();
        final s3Keys = mediaS3KeysForRelativePath(localRel);
        var existsS3 = false;
        for (final key in s3Keys) {
          if (await _minioService.objectExists(key)) {
            existsS3 = true;
            break;
          }
        }

        if (!autoFix) continue;

        if (existsLocal && !existsS3) {
          try {
            for (final key in s3Keys) {
              if (!await _minioService.objectExists(key)) {
                await _minioService.uploadFileAtKey(localFile, objectKey: key);
              }
            }
            fixed++;
          } catch (e) {
            appLog('syncIndexedMedia upload failed ($localRel): $e');
          }
        } else if (!existsLocal && existsS3) {
          try {
            for (final key in s3Keys) {
              if (await _minioService.downloadToFile(
                objectName: key,
                outFile: localFile,
              )) {
                fixed++;
                break;
              }
            }
          } catch (e) {
            appLog('syncIndexedMedia download failed ($localRel): $e');
          }
        }
      }

      // Pull S3 prefixes that may exist without a local index row yet.
      fixed += await MediaSync.pullS3PrefixToLocal(
        personId: personId,
        subFolder: 'food',
        mapToLocalRelative: canonicalLocalMediaPath,
      );
      for (final sub in const [
        'profile_images',
        'user_markdown_documentation',
        'memories',
      ]) {
        fixed += await MediaSync.pullS3PrefixToLocal(
          personId: personId,
          subFolder: sub,
        );
      }

      if (pushProfileUrlsToSupabase) {
        await MediaSync.pushProfileMediaUrlsToSupabase(personId: personId);
      }

      appLog(
        '🔄 [StorageBlock] syncIndexedMediaWithS3 fixed $fixed file(s) for $personId',
      );
      return fixed;
    } catch (e) {
      appLog('❌ [StorageBlock] syncIndexedMediaWithS3 failed: $e');
      return 0;
    }
  }

  /// Upload a file using its app-documents relative path as the S3 object key.
  Future<String?> uploadRelativePath(File file, String relativePath) async {
    final key = relativePath.replaceAll('\\', '/').trim();
    if (key.isEmpty || !await file.exists()) return null;
    isUploading.value = true;
    try {
      final url = await MediaSync.uploadRelativePath(key);
      lastUploadUrl.value = url;
      return url;
    } finally {
      isUploading.value = false;
    }
  }

  Future<String?> uploadFile(
    File file, {
    String? fileName,
    String? subFolder,
  }) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    try {
      final url = await _minioService.uploadFile(
        file,
        fileName: fileName,
        subFolder: subFolder,
      );
      lastUploadUrl.value = url;
      return url;
    } catch (e) {
      appLog('StorageBlock Upload Error: $e');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<String?> uploadBytes(
    List<int> bytes,
    String fileName, {
    String? subFolder,
  }) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    try {
      final url = await _minioService.uploadBytes(
        bytes,
        fileName,
        subFolder: subFolder,
      );
      lastUploadUrl.value = url;
      return url;
    } catch (e) {
      appLog('StorageBlock Upload Error: $e');
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> deleteObject(String objectName) async {
    try {
      await _minioService.deleteFile(objectName);
      return true;
    } catch (e) {
      appLog('StorageBlock Delete Error: $e');
      return false;
    }
  }

  /// Keeps pushing the same row until Supabase returns the expected `image_s3_path`.
  /// Useful when client is flaky/offline and PostgREST briefly returns null/mismatch.
  Future<bool> repushStorySyncUntilMatched({
    required String achievementId,
    required String personId,
    required String title,
    required DateTime storyDatetime,
    required String imageS3Path,
    bool isUploading = false,
    int maxAttempts = 6,
  }) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return false;

    Duration backoff = const Duration(milliseconds: 250);
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Push (idempotent) — relies on unique index (achievement_id).
        await client.from('achievement_story_sync').upsert(
          {
            'achievement_id': achievementId,
            'person_id': personId,
            'title': title,
            'story_datetime': storyDatetime.toIso8601String(),
            'image_s3_path': imageS3Path,
            'is_uploading': isUploading,
            'user_id': uid,
          },
          onConflict: 'achievement_id',
        );

        // Read-back to confirm.
        final row = await client
            .from('achievement_story_sync')
            .select('image_s3_path')
            .eq('achievement_id', achievementId)
            .maybeSingle();

        final current = row?['image_s3_path']?.toString();
        if (current != null && current == imageS3Path) return true;
      } catch (e) {
        appLog('repushStorySyncUntilMatched attempt $attempt failed: $e');
      }

      // Backoff before retry.
      await Future.delayed(backoff);
      backoff = Duration(milliseconds: (backoff.inMilliseconds * 2).clamp(250, 4000));
    }
    return false;
  }

  /// When local Drift has photo stories but Supabase `achievement_story_sync`
  /// is empty/stale, upload missing S3 objects and repush rows until matched.
  Future<int> backfillStorySyncFromLocal({
    required String personId,
    required List<AchievementData> achievements,
  }) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty || personId.isEmpty) return 0;
    if (_storyBackfillRunning) return 0;

    final stories = achievements.where((a) {
      final path = a.localImagePath;
      return path != null && path.trim().isNotEmpty;
    }).toList();
    if (stories.isEmpty) return 0;

    _storyBackfillRunning = true;
    try {
      final remoteRows = await client
          .from('achievement_story_sync')
          .select('achievement_id, image_s3_path')
          .eq('person_id', personId);

      final remotePaths = <String, String?>{};
      for (final row in remoteRows) {
        final id = row['achievement_id']?.toString();
        if (id == null || id.isEmpty) continue;
        remotePaths[id] = row['image_s3_path']?.toString();
      }

      final appDir = await getApplicationDocumentsDirectory();
      var synced = 0;

      for (final story in stories) {
        final rel = story.localImagePath!.trim();
        if (remotePaths[story.id] == rel) continue;

        final localFile = File(p.join(appDir.path, rel));
        if (await localFile.exists()) {
          var onS3 = false;
          for (final key in achievementStoryS3Keys(rel)) {
            if (await _minioService.objectExists(key)) {
              onS3 = true;
              break;
            }
          }
          if (!onS3) {
            await _minioService.uploadFileAtKey(localFile, objectKey: rel);
          }
        }

        final ok = await repushStorySyncUntilMatched(
          achievementId: story.id,
          personId: personId,
          title: story.title,
          storyDatetime: story.createdAt,
          imageS3Path: rel,
        );
        if (ok) synced++;
      }

      appLog(
        '📤 [StorageBlock] Backfilled $synced/${stories.length} '
        'achievement_story_sync rows for $personId',
      );
      return synced;
    } catch (e) {
      appLog('❌ [StorageBlock] backfillStorySyncFromLocal failed: $e');
      return 0;
    } finally {
      _storyBackfillRunning = false;
    }
  }

  /// Pull `achievement_story_sync` rows from Supabase → local Drift + download S3 images.
  Future<int> pullStorySyncFromCloud({
    required String personId,
    required AchievementsDAO achievementsDao,
  }) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty || personId.isEmpty) return 0;

    try {
      final remoteRows = await client
          .from('achievement_story_sync')
          .select(
            'achievement_id, title, story_datetime, image_s3_path, is_uploading',
          )
          .eq('person_id', personId);

      final appDir = await getApplicationDocumentsDirectory();
      var pulled = 0;

      for (final row in remoteRows) {
        final id = row['achievement_id']?.toString();
        final rawPath = row['image_s3_path']?.toString();
        if (id == null || id.isEmpty || rawPath == null || rawPath.isEmpty) {
          continue;
        }
        if (row['is_uploading'] == true) continue;

        final localPath = normalizeAchievementStoryLocalPath(rawPath);
        final title = row['title']?.toString() ?? 'Story';
        final createdAt = row['story_datetime'] != null
            ? DateTime.tryParse(row['story_datetime'].toString()) ??
                DateTime.now()
            : DateTime.now();

        final localFile = File(p.join(appDir.path, localPath));
        if (!await localFile.exists()) {
          var downloaded = false;
          for (final key in achievementStoryS3Keys(rawPath)) {
            if (await _minioService.downloadToFile(
              objectName: key,
              outFile: localFile,
            )) {
              downloaded = true;
              break;
            }
          }
          if (!downloaded) continue;
        }

        final existing = await achievementsDao.getAchievementById(id);
        if (existing == null ||
            (existing.localImagePath ?? '').trim() != localPath) {
          await achievementsDao.upsertPhotoStoryLocal(
            id: id,
            personId: personId,
            title: title,
            localImagePath: localPath,
            createdAt: createdAt,
          );
        }
        pulled++;
      }

      appLog(
        '📥 [StorageBlock] Pulled $pulled achievement photo stories for $personId',
      );
      return pulled;
    } catch (e) {
      appLog('❌ [StorageBlock] pullStorySyncFromCloud failed: $e');
      return 0;
    }
  }

  /// Push local stories up, then pull cloud rows + S3 images down.
  Future<void> syncAchievementStories({
    required String personId,
    required List<AchievementData> achievements,
    required AchievementsDAO achievementsDao,
  }) async {
    await backfillStorySyncFromLocal(
      personId: personId,
      achievements: achievements,
    );
    await pullStorySyncFromCloud(
      personId: personId,
      achievementsDao: achievementsDao,
    );
  }

  /// Compare DB `relativePath`s vs S3 objects under `<personId>/memories/`.
  /// Optionally auto-fix by uploading/downloading best-effort.
  Future<MemoriesSyncReport> syncMemoriesWithS3({
    required String personId,
    required List<String> dbRelativePaths,
    bool autoFix = true,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final dbSet = dbRelativePaths
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final s3Prefix = '$personId/memories/';
    final s3Keys = await _minioService.listObjectNames(prefix: s3Prefix);
    final s3Set = s3Keys.toSet();

    final missingOnS3 = <String>[];
    final missingLocal = <String>[];

    for (final rel in dbSet) {
      final existsLocal = await File(p.join(appDir.path, rel)).exists();
      final existsS3 = s3Set.contains(rel) || await _minioService.objectExists(rel);

      if (!existsS3) missingOnS3.add(rel);
      if (!existsLocal) missingLocal.add(rel);

      if (!autoFix) continue;

      // Fix #1: local exists but S3 missing -> upload.
      if (existsLocal && !existsS3) {
        try {
          await uploadFile(
            File(p.join(appDir.path, rel)),
            fileName: p.basename(rel),
            subFolder: '$personId/memories',
          );
        } catch (_) {}
      }

      // Fix #2: S3 exists but local missing -> download.
      if (!existsLocal && existsS3) {
        try {
          await _minioService.downloadToFile(
            objectName: rel,
            outFile: File(p.join(appDir.path, rel)),
          );
        } catch (_) {}
      }
    }

    final orphanOnS3 = s3Set.difference(dbSet).toList()..sort();
    missingOnS3.sort();
    missingLocal.sort();

    return MemoriesSyncReport(
      dbCount: dbSet.length,
      s3Count: s3Set.length,
      missingOnS3: missingOnS3,
      missingLocal: missingLocal,
      orphanOnS3: orphanOnS3,
    );
  }

  void dispose() {
    _scanTimer?.cancel();
    isUploading.dispose();
    uploadProgress.dispose();
    lastUploadUrl.dispose();
  }
}

class MemoriesSyncReport {
  final int dbCount;
  final int s3Count;
  final List<String> missingOnS3;
  final List<String> missingLocal;
  final List<String> orphanOnS3;

  const MemoriesSyncReport({
    required this.dbCount,
    required this.s3Count,
    required this.missingOnS3,
    required this.missingLocal,
    required this.orphanOnS3,
  });
}
