import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Services/AutoCaptureJob.dart';

/// Drains the capture queue on a background cadence.
///
/// Foreground-only by design: a `Timer.periodic` is not an OS background job,
/// iOS gives no reliable one, and on Linux the process dies with the window.
/// Real background execution is separate native work per platform.
class CaptureSyncJob {
  static final CaptureSyncJob instance = CaptureSyncJob._();
  CaptureSyncJob._();

  static const Duration syncInterval = Duration(minutes: 15);

  /// Rows pulled per drain. Keeps one slow upload from blocking a whole tick.
  static const int batchSize = 5;

  Timer? _timer;
  String? _personId;
  AppDatabase? _db;

  /// Reentrancy guard. A 15-minute timer can easily overlap a slow upload, and
  /// without this the same row is processed twice and the extraction endpoint
  /// is billed twice.
  bool _draining = false;

  bool get isDraining => _draining;

  void init(AppDatabase db, String personId) {
    _db = db;
    _personId = personId;
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(syncInterval, (_) => unawaited(drain()));
    unawaited(drain());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  /// Processes pending captures oldest-first. Safe to call concurrently.
  Future<void> drain() async {
    if (_draining) return;
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return;

    _draining = true;
    try {
      final pending = await db.captureQueueDAO.getPending(
        personId,
        limit: batchSize,
      );
      if (pending.isEmpty) return;

      debugPrint(
        '🔄 [CaptureSync] Draining ${pending.length} pending capture(s).',
      );

      for (final row in pending) {
        final localPath = row.localPath;
        if (localPath == null || !File(localPath).existsSync()) {
          // The PNG is gone; the row cannot be retried. Mark it so it stops
          // being picked up instead of retrying forever.
          await db.captureQueueDAO.markFailed(
            row.id,
            'Local capture file is missing',
          );
          continue;
        }
        await AutoCaptureJob.processQueueItem(
          db,
          personId,
          row.id,
          File(localPath),
        );
      }
    } catch (e) {
      debugPrint('🔄 [CaptureSync] drain failed — $e');
    } finally {
      _draining = false;
    }
  }
}
