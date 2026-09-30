import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/link_layer/capture/capture_provider.dart';
import 'package:ice_gate/link_layer/capture/media_projection_capture_provider.dart';
import 'package:ice_gate/link_layer/capture/portal_capture_provider.dart';
import 'package:ice_gate/link_layer/capture/repaint_capture_provider.dart';
import 'package:ice_gate/link_layer/storage_services/minio_service.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Services/ScreenshotMemoryService.dart';
import 'package:path/path.dart' as p;

/// A weighted importance signal and whether it fired.
class ScoreSignal {
  final String name;
  final double weight;
  final bool fired;

  const ScoreSignal({
    required this.name,
    required this.weight,
    required this.fired,
  });
}

/// The result of scoring a screen, with the reasons kept for the UI so
/// "why was this captured?" is answerable rather than guessed at.
class CaptureScore {
  final double score;
  final List<String> reasons;

  const CaptureScore(this.score, this.reasons);

  static const empty = CaptureScore(0, []);
}

/// Tunable scoring weights, overridable from `ConfigsTable` so behaviour can
/// change without shipping a release.
class CaptureScoringConfig {
  final double dwellWeight;
  final double highValueRouteWeight;
  final double dataEntryWeight;
  final double firstVisitWeight;
  final double repeatVisitWeight;
  final double threshold;

  /// Seconds of dwell that count as full weight on the dwell signal.
  final int dwellSecondsForFullWeight;

  static const defaults = CaptureScoringConfig();

  const CaptureScoringConfig({
    this.dwellWeight = 0.4,
    this.highValueRouteWeight = 0.3,
    this.dataEntryWeight = 0.2,
    this.firstVisitWeight = 0.1,
    this.repeatVisitWeight = 0.2,
    this.threshold = 0.6,
    this.dwellSecondsForFullWeight = 60,
  });

  factory CaptureScoringConfig.fromConfig(ConfigData? config) {
    if (config == null) return defaults;
    final values = <String, double>{};
    for (final pair in config.configValue.split(',')) {
      final kv = pair.split('=');
      if (kv.length == 2) {
        final parsed = double.tryParse(kv[1].trim());
        if (parsed != null) values[kv[0].trim()] = parsed;
      }
    }
    return CaptureScoringConfig(
      dwellWeight: values['dwell'] ?? defaults.dwellWeight,
      highValueRouteWeight:
          values['high_value_route'] ?? defaults.highValueRouteWeight,
      dataEntryWeight: values['data_entry'] ?? defaults.dataEntryWeight,
      firstVisitWeight: values['first_visit'] ?? defaults.firstVisitWeight,
      repeatVisitWeight: values['repeat_visit'] ?? defaults.repeatVisitWeight,
      threshold: values['threshold'] ?? defaults.threshold,
    );
  }
}

/// A screen worth capturing, as reported by the route/lifecycle observer.
class BehaviourSignal {
  final String route;
  final int dwellSeconds;
  final bool hasDataEntry;
  final String? foregroundApp;

  const BehaviourSignal({
    required this.route,
    this.dwellSeconds = 0,
    this.hasDataEntry = false,
    this.foregroundApp,
  });
}

/// Foreground-only periodic screen-capture job.
///
/// Triggers are fed in from `ActivityTrackerService` (the existing route +
/// lifecycle observer) rather than a second `WidgetsBindingObserver`, because
/// two observers drift out of sync.
///
/// Everything here is gated on explicit user opt-in. Auto-capture records what
/// the user is doing, so it ships disabled and stays disabled until the user
/// turns it on in settings.
class AutoCaptureJob {
  static final AutoCaptureJob instance = AutoCaptureJob._();
  AutoCaptureJob._();

  /// Routes treated as high-value. Deliberately conservative: capturing too
  /// much is the failure mode that makes the memory useless.
  static const Set<String> highValueRoutes = {
    '/health',
    '/finance',
    '/projects',
    '/quests',
    '/personal-info',
  };

  static const int defaultDailyCap = 10;
  static const int minDailyCap = 1;
  static const int maxDailyCap = 50;

  static const String configEnabled = 'auto_capture_enabled';
  static const String configDailyCap = 'auto_capture_daily_cap';
  static const String configThreshold = 'auto_capture_threshold';

  AppDatabase? _db;
  String? _personId;
  Timer? _timer;
  GlobalKey? _captureBoundaryKey;
  String _currentRoute = '';

  /// Route visit counts for the current session, for first/repeat scoring.
  final Map<String, int> _sessionVisits = {};
  final Set<String> _sessionSeenRoutes = {};

  CaptureScoringConfig _scoring = CaptureScoringConfig.defaults;
  int _dailyCap = defaultDailyCap;
  bool _consentGranted = false;
  bool _crossAppConsentGranted = false;
  bool _isGuest = false;

  /// Guards against overlapping capture runs. Without this a slow upload can
  /// be started twice by the next tick.
  bool _capturing = false;

  // --- lifecycle ---

  void init(AppDatabase db, String personId) {
    _db = db;
    _personId = personId;
    // Mirrors the guard in ActivityTrackerService: Guest users are not
    // rewarded/tracked, and must not be captured either.
    _isGuest = personId.isEmpty;
  }

  /// Set by the auth layer. Guest sessions are never captured.
  set isGuestSession(bool value) => _isGuest = value;

  void attachCaptureBoundary(GlobalKey key) {
    _captureBoundaryKey = key;
  }

  /// Reads the opt-in flag and cap. Safe to call on every resume.
  Future<void> loadSettings() async {
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return;
    if (_isGuest) {
      await stop();
      return;
    }

    final enabled = await db.configsDAO.getConfig(personId, configEnabled);
    // Absent config means opt-in was never given: default to off.
    if (enabled == null || enabled.configValue != 'true') {
      await stop();
      return;
    }

    final cap = await db.configsDAO.getConfig(personId, configDailyCap);
    final parsedCap = int.tryParse(cap?.configValue ?? '');
    _dailyCap = (parsedCap ?? defaultDailyCap).clamp(minDailyCap, maxDailyCap);

    final threshold = await db.configsDAO.getConfig(personId, configThreshold);
    final parsedThreshold = double.tryParse(threshold?.configValue ?? '');
    _scoring = CaptureScoringConfig(
      dwellWeight: CaptureScoringConfig.defaults.dwellWeight,
      highValueRouteWeight: CaptureScoringConfig.defaults.highValueRouteWeight,
      dataEntryWeight: CaptureScoringConfig.defaults.dataEntryWeight,
      firstVisitWeight: CaptureScoringConfig.defaults.firstVisitWeight,
      repeatVisitWeight: CaptureScoringConfig.defaults.repeatVisitWeight,
      threshold: parsedThreshold ?? CaptureScoringConfig.defaults.threshold,
    );

    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(tick()),
    );
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _sessionSeenRoutes.clear();
    _sessionVisits.clear();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  // --- signal intake ---

  /// Feeds a route change in. Called from the shell, alongside the existing
  /// ActivityTrackerService hook.
  void onRouteChanged(String route) {
    _currentRoute = route;
    _sessionVisits[route] = (_sessionVisits[route] ?? 0) + 1;
    _sessionSeenRoutes.add(route);
  }

  // --- scoring ---

  CaptureScore score(BehaviourSignal signal) {
    final reasons = <String>[];
    var total = 0.0;

    final dwellFired = signal.dwellSeconds > 0;
    if (dwellFired) {
      final ratio = (signal.dwellSeconds / _scoring.dwellSecondsForFullWeight)
          .clamp(0.0, 1.0);
      total += _scoring.dwellWeight * ratio;
      reasons.add('dwell:${signal.dwellSeconds}s');
    }

    final highValue = highValueRoutes.contains(signal.route);
    if (highValue) {
      total += _scoring.highValueRouteWeight;
      reasons.add('high_value_route');
    }

    if (signal.hasDataEntry) {
      total += _scoring.dataEntryWeight;
      reasons.add('data_entry');
    }

    if (!_sessionSeenRoutes.contains(signal.route)) {
      total += _scoring.firstVisitWeight;
      reasons.add('first_visit');
    }

    final visits = _sessionVisits[signal.route] ?? 0;
    if (visits > 3) {
      total += _scoring.repeatVisitWeight;
      reasons.add('repeat_visit:$visits');
    }

    return CaptureScore(total, reasons);
  }

  // --- budget ---

  Future<bool> hasBudgetRemaining() async {
    final db = _db;
    final personId = _personId;
    if (db == null || personId == null) return false;
    final used = await db.captureQueueDAO.countCreatedToday(personId);
    return used < _dailyCap;
  }

  int get dailyCap => _dailyCap;

  // --- capture ---

  /// One capture cycle. Safe to call on a timer; reentrancy-guarded.
  Future<void> tick({BehaviourSignal? signal}) async {
    if (_capturing) return;
    final db = _db;
    final personId = _personId;
    final boundaryKey = _captureBoundaryKey;
    if (db == null || personId == null || boundaryKey == null) return;
    if (_isGuest) return;

    _capturing = true;
    try {
      final effective = signal ??
          BehaviourSignal(route: _currentRoute, dwellSeconds: 60);

      final score = score(effective);
      if (score.score < _scoring.threshold) return;

      if (!await hasBudgetRemaining()) {
        debugPrint(
          '📷 [AutoCapture] Daily cap reached ($_dailyCap); skipping.',
        );
        return;
      }

      // Cross-app providers are preferred where they exist: the whole point of
      // the feature is observing other apps. In-app capture is the fallback and
      // the only option on iOS, which exposes no API to read another app's
      // pixels.
      final result = await _captureCrossApp(effective) ??
          await _captureInApp(boundaryKey, effective);
      if (result == null) return;

      await _persistCapture(db, personId, result, score);
    } catch (e) {
      debugPrint('📷 [AutoCapture] tick failed — $e');
    } finally {
      _capturing = false;
    }
  }

  /// Tries each cross-app provider on this platform. Returns null when none is
  /// supported, consent was declined, or the platform declined the request —
  /// all normal outcomes, never errors.
  Future<CaptureResult?> _captureCrossApp(BehaviourSignal signal) async {
    final providers = <CaptureProvider>[
      MediaProjectionCaptureProvider(),
      PortalCaptureProvider(),
    ];
    for (final provider in providers) {
      if (!provider.isSupported) continue;
      if (!_crossAppConsentGranted) {
        _crossAppConsentGranted = await provider.requestConsent();
        if (!_crossAppConsentGranted) continue;
      }
      final result = await provider.capture();
      if (result != null) {
        return CaptureResult(
          pngBytes: result.pngBytes,
          sourceKind: result.sourceKind,
          appLabel: result.appLabel,
          route: signal.route,
          width: result.width,
          height: result.height,
        );
      }
    }
    return null;
  }

  Future<CaptureResult?> _captureInApp(
    GlobalKey boundaryKey,
    BehaviourSignal signal,
  ) async {
    final provider = RepaintCaptureProvider(
      repaintBoundaryKey: boundaryKey,
      route: signal.route,
    );
    if (!provider.isSupported) return null;
    if (!_consentGranted) {
      _consentGranted = await provider.requestConsent();
      if (!_consentGranted) return null;
    }
    return provider.capture();
  }

  Future<void> _persistCapture(
    AppDatabase db,
    String personId,
    CaptureResult result,
    CaptureScore score,
  ) async {
    final tempDir = Directory.systemTemp;
    final fileName = '${IDGen.UUIDV7()}.png';
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(result.pngBytes);

    final queueId = IDGen.UUIDV7();
    await db.captureQueueDAO.enqueue(
      CaptureQueueTableCompanion.insert(
        id: queueId,
        personID: personId,
        sourceKind: result.sourceKind.wireName,
        appLabel: result.appLabel,
        route: Value(result.route),
        localPath: Value(file.path),
        score: Value(score.score),
        scoreReasons: Value(jsonEncode(score.reasons)),
      ),
    );

    // Extract immediately so the memory exists before the next sync tick.
    // A failure here leaves the row pending for CaptureSyncJob to retry.
    await processQueueItem(db, personId, queueId, file);
  }

  /// Uploads + extracts a single queued capture and writes the memory row.
  /// Shared by the inline path and CaptureSyncJob so both behave identically.
  static Future<void> processQueueItem(
    AppDatabase db,
    String personId,
    String queueId,
    File file,
  ) async {
    final row = await (db.select(db.captureQueueTable)
          ..where((t) => t.id.equals(queueId)))
        .getSingleOrNull();
    if (row == null) return;

    // Max 3 attempts, then stop. A permanently failing row stays visible in the
    // review UI rather than being dropped.
    if (row.attempts >= 3) {
      await db.captureQueueDAO.updateRow(
        queueId,
        const CaptureQueueTableCompanion(status: Value('failed')),
      );
      return;
    }

    try {
      final outcome = await ScreenshotMemoryService.captureAndAnalyze(
        file,
        uploader: (f, {subFolder}) =>
            MinioService().uploadFile(f, subFolder: subFolder),
        subFolder: '$personId/screenshots',
        route: row.route,
      );

      if (!outcome.requestOk) {
        await db.captureQueueDAO.markFailed(
          queueId,
          outcome.error ?? 'unknown error',
        );
        return;
      }

      final memory = outcome.memory;
      await db.aiMemoryDAO.insertMemory(
        AiMemoriesTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: Value(personId),
          // Left as 'draft': nothing reaches a prompt until the user confirms.
          title: memory.title.isEmpty ? 'Screen' : memory.title,
          content: memory.memory,
          summary: Value(memory.summary),
          tags: Value(jsonEncode(memory.tags)),
          sourceImageUrl: Value(row.imageUrl),
          sourceRoute: Value(row.route),
          sourceKind: Value(row.sourceKind),
          aiModel: Value(memory.aiModel),
        ),
      );

      await db.captureQueueDAO.updateRow(
        queueId,
        const CaptureQueueTableCompanion(status: Value('analyzed')),
      );
    } catch (e) {
      await db.captureQueueDAO.markFailed(queueId, e.toString());
    }
  }
}
