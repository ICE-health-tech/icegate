import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Services/AutoCaptureJob.dart';
import 'package:ice_gate/orchestration_layer/Services/CaptureSyncJob.dart';

/// UI state for the screen-memory feature: the review queue, the memory list,
/// and the opt-in settings that gate automatic capture.
///
/// Automatic capture is OFF unless the user turns it on. [isAutoCaptureEnabled]
/// defaults to false here as well as in the config table, so a missing or
/// unreadable config can never result in capture being on.
class AiMemoryBlock {
  final memories = listSignal<AiMemoryData>([]);
  final queue = listSignal<CaptureQueueData>([]);

  final isAutoCaptureEnabled = signal<bool>(false);
  final dailyCap = signal<int>(AutoCaptureJob.defaultDailyCap);
  final threshold = signal<double>(0.6);
  final isSyncing = signal<bool>(false);
  final isOnDeviceCaptionAvailable = signal<bool>(false);
  final lastError = signal<String?>(null);

  StreamSubscription? _memorySub;
  StreamSubscription? _queueSub;

  String? _personId;
  AppDatabase? _db;

  /// Draft memories await review; confirmed ones are injected into prompts.
  int get draftCount => memories.value.where((m) => m.status == 'draft').length;

  int get confirmedCount =>
      memories.value.where((m) => m.status == 'confirmed').length;

  void init(AppDatabase db, String personId) {
    if (personId.isEmpty) {
      debugPrint('AiMemoryBlock: Skipping init, personID is empty.');
      return;
    }
    _db = db;
    _personId = personId;

    _memorySub?.cancel();
    _memorySub = db.aiMemoryDAO
        .watchMemories(personId)
        .listen((rows) => memories.value = List<AiMemoryData>.from(rows));

    _queueSub?.cancel();
    _queueSub = db.captureQueueDAO
        .watchQueue(personId)
        .listen((rows) => queue.value = List<CaptureQueueData>.from(rows));

    AutoCaptureJob.instance.init(db, personId);
    CaptureSyncJob.instance.init(db, personId);
    unawaited(loadSettings());
  }

  Future<void> loadSettings() async {
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return;

    final enabled = await db.configsDAO.getConfig(
      personId,
      AutoCaptureJob.configEnabled,
    );
    isAutoCaptureEnabled.value = enabled?.configValue == 'true';

    final cap = await db.configsDAO.getConfig(
      personId,
      AutoCaptureJob.configDailyCap,
    );
    dailyCap.value =
        int.tryParse(cap?.configValue ?? '') ?? AutoCaptureJob.defaultDailyCap;

    final thr = await db.configsDAO.getConfig(
      personId,
      AutoCaptureJob.configThreshold,
    );
    threshold.value =
        double.tryParse(thr?.configValue ?? '') ??
        CaptureScoringConfig.defaults.threshold;
  }

  /// Turning capture on also starts the job and the sync timer; turning it off
  /// stops both, so opting out takes effect immediately rather than at the next
  /// launch.
  Future<void> setAutoCaptureEnabled(bool value) async {
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return;

    await db.configsDAO.setConfig(
      personId,
      AutoCaptureJob.configEnabled,
      value ? 'true' : 'false',
    );
    isAutoCaptureEnabled.value = value;

    if (value) {
      await AutoCaptureJob.instance.loadSettings();
      CaptureSyncJob.instance.start();
    } else {
      await AutoCaptureJob.instance.stop();
      CaptureSyncJob.instance.stop();
    }
  }

  Future<void> setDailyCap(int value) async {
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return;

    final clamped = value.clamp(
      AutoCaptureJob.minDailyCap,
      AutoCaptureJob.maxDailyCap,
    );
    await db.configsDAO.setConfig(
      personId,
      AutoCaptureJob.configDailyCap,
      '$clamped',
    );
    dailyCap.value = clamped;
    await AutoCaptureJob.instance.loadSettings();
  }

  Future<void> setThreshold(double value) async {
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return;

    final clamped = value.clamp(0.0, 1.0);
    await db.configsDAO.setConfig(
      personId,
      AutoCaptureJob.configThreshold,
      '$clamped',
    );
    threshold.value = clamped;
    await AutoCaptureJob.instance.loadSettings();
  }

  Future<void> confirmMemory(String id) async {
    final db = _db;
    if (db == null) return;
    await db.aiMemoryDAO.setStatus(id, 'confirmed');
  }

  Future<void> discardMemory(String id) async {
    final db = _db;
    if (db == null) return;
    await db.aiMemoryDAO.setStatus(id, 'discarded');
  }

  Future<void> deleteMemory(String id) async {
    final db = _db;
    if (db == null) return;
    await db.aiMemoryDAO.deleteMemory(id);
  }

  /// Backs the "delete all captures" control — a consent requirement.
  Future<void> deleteAllCaptures() async {
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return;
    await db.captureQueueDAO.deleteAllForPerson(personId);
    for (final m in memories.value) {
      await db.aiMemoryDAO.deleteMemory(m.id);
    }
  }

  Future<void> syncNow() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      await CaptureSyncJob.instance.drain();
    } finally {
      isSyncing.value = false;
    }
  }

  void dispose() {
    _memorySub?.cancel();
    _queueSub?.cancel();
    AutoCaptureJob.instance.dispose();
    CaptureSyncJob.instance.dispose();
  }
}
