import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'; // Import generated code
import 'package:signals/signals.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ice_gate/orchestration_layer/IDGen.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/JobWorkLogBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/FocusAudioHandler.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MusicBlock.dart';
import 'package:live_activities/live_activities.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/AppleHealthServices.dart';
import 'package:ice_gate/utils/app_log.dart';

enum FocusStatus { idle, running, paused, completed }

class FocusSessionState {
  final int remainingSeconds;
  final int totalDuration;
  final FocusStatus status;
  final String? currentProjectId;
  final String? notes;

  const FocusSessionState({
    required this.remainingSeconds,
    required this.totalDuration,
    required this.status,
    this.currentProjectId,
    this.notes,
  });

  double get progress => totalDuration > 0
      ? (totalDuration - remainingSeconds) / totalDuration
      : 0.0;
}

class FocusBlock {
  // Dependencies
  final FocusSessionsDAO _focusSessionDao;
  final HealthLogsDAO _healthLogsDao;
  final HealthMetricsDAO _healthMetricsDao;
  String _currentPersonId;
  String get currentPersonId => _currentPersonId;
  set personId(String id) => _currentPersonId = id;
  final LocalNotificationService? _notificationService;

  /// When set, completing/stopping a [startJobWorkFocus] session logs job minutes.
  JobWorkLogBlock? jobWorkLogBlock;

  // Configuration (Defaults)
  static const int _initialFocusMin = 25;
  static const int _initialShortBreakMin = 5;
  static const int _initialLongBreakMin = 15;

  void setProject(String? projectId) {
    selectedProjectId.value = projectId;
    selectedTaskId.value = null; // Reset task when project changes
  }

  void setTask(String? taskId) {
    selectedTaskId.value = taskId;
  }

  // Durations (in minutes) - Managed as signals for reactivity
  final focusDuration = signal<int>(_initialFocusMin);
  final shortBreakDuration = signal<int>(_initialShortBreakMin);
  final longBreakDuration = signal<int>(_initialLongBreakMin);

  // Signals
  final remainingTime = signal<int>(_initialFocusMin * 60);
  final isRunning = signal<bool>(false);
  final currentSessionType = signal<String>(
    'Focus',
  ); // Focus, Short Break, Long Break
  final selectedProjectId = signal<String?>(null);
  final selectedTaskId = signal<String?>(null);
  final sessionNotes = signal<String>('');
  final showSummary = signal<bool>(false);

  // Exercise Mode Signals
  final isExerciseMode = signal<bool>(false);
  final isJobWorkMode = signal<bool>(false);
  bool _deferJobWorkFinalize = false;
  final isStopwatchMode = signal<bool>(false);
  final exerciseType = signal<String>('');
  final stopwatchElapsedSeconds = signal<int>(0);

  /// Set when an `exercise_logs` row is written from a focus timer; [ExercisePage] shows mood then clears.
  final pendingExerciseLogForMood = signal<String?>(null);

  void clearPendingExerciseLogForMood() {
    pendingExerciseLogForMood.value = null;
  }

  // Elon Musk 5-Minute Block Mode Signals
  final isMuskMode = signal<bool>(false);
  final muskHapticIntensity = signal<int>(3); // 1-5
  final muskFocusDuration = signal<int>(5); // Default 5 mins
  final muskRepeatReminder = signal<bool>(true);
  final isMuskMusicEnabled = signal<bool>(true);
  final isSyncingWithClock = signal<bool>(false);

  // Stats
  final totalStudyTimeToday = signal<int>(0); // In seconds
  final sessionsCompletedToday = signal<int>(0);

  // Theme
  // Theme
  // External Blocks for Automation
  GrowthBlock? growthBlock;

  // Timer
  Timer? _timer;
  DateTime? _actualStartTime; // Absolute start of the session
  DateTime? _lastStartTime;   // Start of current running segment (for pause support)
  int _accumulatedSeconds = 0; // Sum of durations of all segments before the current one
  DateTime? _targetEndTime;
  String? _activeSessionId;
  bool _isStarting = false;
  bool _isLiveActivityInitialized = false;
  /// Throttles lock-screen / audio metadata updates (was firing ~10×/s).
  int? _lastMetadataSecond;

  final MusicBlock? _musicBlock;
  final FocusAudioHandler? _audioHandler;

  // Live Activity
  final _liveActivities = LiveActivities();
  String? _activityId;
  StreamSubscription? _activitySubscription;

  FocusBlock({
    required FocusSessionsDAO focusSessionDao,
    required HealthLogsDAO healthLogsDao,
    required HealthMetricsDAO healthMetricsDao,
    required String personId,
    MusicBlock? musicBlock,
    FocusAudioHandler? audioHandler,
    LocalNotificationService? notificationService,
  }) : _focusSessionDao = focusSessionDao,
       _healthLogsDao = healthLogsDao,
       _healthMetricsDao = healthMetricsDao,
       _currentPersonId = personId,
       _musicBlock = musicBlock,
       _audioHandler = audioHandler,
       _notificationService = notificationService {
    appLog("FocusBlock Checking: MusicBlock injected: ${_musicBlock != null}");
  }

  // --- Initialization ---
  Future<void> init() async {
    appLog(
      "FocusBlock Checking: init called. AudioHandler is ${_audioHandler != null ? 'PRESENT' : 'NULL'}",
    );
    try {
      // Initialize Live Activities immediately (doesn't require personId)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _liveActivities.init(appGroupId: 'group.duylong.art.iceshield');
        _activitySubscription?.cancel();
        _activitySubscription = _liveActivities.activityUpdateStream.listen((
          event,
        ) {
          event.map(
            active: (active) {},
            ended: (ended) {
              if (isRunning.value) stopTimer();
            },
            stale: (stale) {},
            unknown: (unknown) {},
          );
        });
        _isLiveActivityInitialized = true;
      }

      if (_currentPersonId.isEmpty) {
        appLog("FocusBlock: personId is empty, skipping daily stats fetch.");
      } else {
        await fetchDailyStats();
      }

      // Register this block with the audio handler for two-way sync
      _audioHandler?.focusBlock = this;
    } catch (e) {
      appLog("FocusBlock init error: $e");
    }
  }

  // --- Timer Actions ---

  void startTimer({bool fromSystem = false}) async {
    appLog(
      "FocusBlock(${identityHashCode(this)}): startTimer called. isRunning: ${isRunning.value}, fromSystem: $fromSystem, _isStarting: $_isStarting",
    );
    if (isRunning.value || _isStarting) return;

    _isStarting = true;
    try {
      isRunning.value = true;
      _actualStartTime ??= DateTime.now();
      _lastStartTime = DateTime.now();
      
      if (isStopwatchMode.value) {
        _targetEndTime = null;
      } else {
        _targetEndTime = DateTime.now().add(
          Duration(seconds: remainingTime.value),
        );
      }

      // Force immediate metadata update for instant play/pause button toggle
      _lastMetadataSecond = null;
      _updateMediaMetadata(force: true);

      // 1. START TIMER — 1s tick (UI is second-precision; avoids 10×/s overhead)
      _timer?.cancel();
      final totalSeconds = remainingTime.value;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _onFocusTimerTick(totalSecondsAtStart: totalSeconds);
      });
      _onFocusTimerTick(totalSecondsAtStart: totalSeconds);

      // 2. RUN SETUP IN BACKGROUND
      Timer(Duration.zero, () {
        untracked(() async {
          if (!fromSystem) {
            try {
              await _musicBlock?.updateAudioSource(isRunning: true);
              if (isRunning.value) {
                _musicBlock?.play();
              }
            } catch (audioError) {
              appLog(
                "FocusBlock: Audio setup failed ($audioError), proceeding with silent timer.",
              );
            }
          }

          try {
            await _createLiveActivity();
          } catch (e) {
            appLog("FocusBlock: Live Activity skipped: $e");
          }
        });
      });
    } finally {
      _isStarting = false;
    }
  }

  void _onFocusTimerTick({required int totalSecondsAtStart}) {
    if (isStopwatchMode.value) {
      if (_lastStartTime == null) return;
      final now = DateTime.now();
      final currentSegmentElapsed =
          now.difference(_lastStartTime!).inSeconds;
      final totalElapsed = _accumulatedSeconds + currentSegmentElapsed;

      if (totalElapsed == stopwatchElapsedSeconds.value) return;

      stopwatchElapsedSeconds.value = totalElapsed;
      remainingTime.value = totalElapsed;

      if (totalElapsed % 5 == 0) {
        _updateLiveActivity();
      }
      _updateMediaMetadata();
      return;
    }

    if (_targetEndTime == null) return;
    final now = DateTime.now();
    final remaining = _targetEndTime!.difference(now);
    if (remaining.inMilliseconds <= 0) {
      remainingTime.value = 0;
      if (isSyncingWithClock.value) {
        isSyncingWithClock.value = false;
        _actualStartTime = DateTime.now();
        remainingTime.value = muskFocusDuration.value * 60;
        _targetEndTime = DateTime.now().add(
          Duration(seconds: remainingTime.value),
        );
        _notificationService?.showNotification(
          889,
          "BLOCK INITIATED",
          "Aligned. Sequence starting for ${muskFocusDuration.value} minutes.",
        );
        HapticFeedback.heavyImpact();
        _updateMediaMetadata(force: true);
      } else {
        completeSession();
      }
      return;
    }

    final newSeconds = remaining.inSeconds;
    if (newSeconds == remainingTime.value) return;

    remainingTime.value = newSeconds;

    if (isMuskMode.value) {
      final elapsedSeconds = totalSecondsAtStart - newSeconds;
      if (elapsedSeconds > 0 && elapsedSeconds % 60 == 0) {
        final elapsedMinutes = elapsedSeconds ~/ 60;
        if (elapsedMinutes % 5 == 0) {
          _triggerIntervalHaptics(strong: true);
        } else {
          _triggerIntervalHaptics(strong: false);
        }
      }
    }

    if (newSeconds % 5 == 0) {
      _updateLiveActivity();
    }
    _updateMediaMetadata();
  }

  Future<void> _createLiveActivity() async {
    if (!_isLiveActivityInitialized) {
      appLog("FocusBlock: Live Activity skipped (Not initialized yet)");
      return;
    }
    try {
      final songName = _musicBlock?.getDisplaySongName() ?? "Focus Music";

      _activityId = await _liveActivities
          .createActivity('group.duylong.art.iceshield', {
            'title': "ICE Gate Focus",
            'songName': songName,
            'cover': "music_cover",
            'artist': currentSessionType.value,
            'progress':
                1.0 -
                (remainingTime.value /
                    _getDurationForType(currentSessionType.value)),
          });
    } catch (e) {
      // Check if it's the known "missing widget extension" error
      if (e.toString().contains("ActivityInput error 0") ||
          e.toString().contains("LIVE_ACTIVITY_ERROR")) {
        appLog(
          "FocusBlock: Live Activity not available (Widget Extension missing). Skipping.",
        );
      } else {
        appLog("FocusBlock: Error creating Live Activity: $e");
      }
    }
  }

  void _updateLiveActivity() {
    if (_activityId != null) {
      final songName = _musicBlock?.getDisplaySongName() ?? "Focus Music";

      try {
        _liveActivities.updateActivity(_activityId!, {
          'title': isStopwatchMode.value ? "Exercise Active" : "ICE Gate Focus",
          'songName': isStopwatchMode.value ? exerciseType.value : songName,
          'cover': "music_cover",
          'artist': isStopwatchMode.value ? "Active" : currentSessionType.value,
          'progress': isStopwatchMode.value 
              ? 0.0 // No progress bar for stopwatch
              : (1.0 - (remainingTime.value / _getDurationForType(currentSessionType.value))),
        });
      } catch (e) {
        appLog("FocusBlock: Live Activity update failed (quietly skipped): $e");
      }
    }
  }

  void pauseTimer({bool fromSystem = false}) {
    appLog(
      "FocusBlock(${identityHashCode(this)}): pauseTimer called. isRunning: ${isRunning.value}, fromSystem: $fromSystem",
    );
    if (!isRunning.value) return;

    isRunning.value = false;
    isSyncingWithClock.value = false;
    _lastMetadataSecond = null;

    // Accumulate time spent in current segment
    if (_lastStartTime != null) {
      _accumulatedSeconds += DateTime.now().difference(_lastStartTime!).inSeconds;
      _lastStartTime = null;
    }

    if (_targetEndTime != null) {
      remainingTime.value = _targetEndTime!
          .difference(DateTime.now())
          .inSeconds;
      _targetEndTime = null;
    }
    _timer?.cancel();
    _timer = null;

    // Force metadata update to show "Paused" state immediately
    _updateMediaMetadata();

    if (!fromSystem) {
      _musicBlock?.pause();
    }
    // Cancel fallback notification
    _notificationService?.cancelNotification(888);

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        _activityId != null) {
      _liveActivities.endActivity(_activityId!);
      _activityId = null;
    }
  }

  void _updateMediaMetadata({bool force = false}) {
    final sec = remainingTime.value;
    if (!force &&
        isRunning.value &&
        _lastMetadataSecond == sec &&
        _lastMetadataSecond != null) {
      return;
    }
    _lastMetadataSecond = sec;
    _musicBlock?.updateMediaMetadata(
      isRunning: isRunning.value,
      sessionType: currentSessionType.value,
      remainingTime: sec,
      totalDuration: _getDurationForType(currentSessionType.value),
    );
  }

  void resetTimer() {
    pauseTimer();
    _actualStartTime = null;
    _lastStartTime = null;
    _accumulatedSeconds = 0;
    _targetEndTime = null;
    _activeSessionId = null;
    remainingTime.value = _getDurationForType(currentSessionType.value);

    // Ensure metadata is updated with reset time and paused state
    _updateMediaMetadata();
  }

  /// Persists session (including exercise_logs when [isExerciseMode]) then clears timer state.
  Future<void> stopTimer() async {
    appLog("FocusBlock: stopTimer called. Saving session...");
    pauseTimer();
    if (isJobWorkMode.value) {
      await _finalizeJobWorkSession(sessionNotes.value);
    } else {
      await _finalizeLinkedJobWork();
    }
    await _saveSession(status: 'interrupted');
    resetTimer();
  }

  /// True when there is elapsed time or the timer is still running (exercise save/stop).
  bool get hasActiveClockForSave =>
      _actualStartTime != null &&
      (_accumulatedSeconds > 0 || isRunning.value);

  Future<void> completeSession() async {
    pauseTimer();

    if (isMuskMode.value) {
      _triggerMuskHaptics();
      _notificationService?.showNotification(
        888,
        "BLOCK COMPLETE",
        "Block Sequence Completed.",
      );

      if (muskRepeatReminder.value) {
        // Auto-restart for "Always" frequency
        Future.delayed(const Duration(seconds: 1), () {
          startMuskFocus();
        });
        return; // Don't show summary if auto-repeating
      }
    } else {
      HapticFeedback.heavyImpact();
      _notificationService?.showNotification(
        999,
        currentSessionType.value == 'Focus'
            ? "Focus Session Complete"
            : "Break Over",
        currentSessionType.value == 'Focus'
            ? "Excellent work! Take a well-deserved break."
            : "Time to get back into the flow zone.",
      );
    }

    // Trigger Summary UI - actual saving happens when user confirms in dialog
    _activeSessionId = await _saveSession(status: 'completed');
    if (isJobWorkMode.value) {
      _deferJobWorkFinalize = true;
    } else {
      await _finalizeLinkedJobWork();
    }
    showSummary.value = true;
  }

  void _triggerMuskHaptics() async {
    // Intense vibration pattern for 5-minute block completion
    // User requested "strong enough" haptics
    for (int i = 0; i < muskHapticIntensity.value * 2; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _triggerIntervalHaptics({required bool strong}) async {
    if (strong) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> finishAndSaveSession(
    String finalNotes, {
    bool markTaskDone = false,
  }) async {
    sessionNotes.value = finalNotes;

    if (_deferJobWorkFinalize) {
      _deferJobWorkFinalize = false;
      await _finalizeJobWorkSession(finalNotes);
    }

    if (_activeSessionId != null) {
      await _focusSessionDao.patchSession(
        _activeSessionId!,
        FocusSessionsTableCompanion(
          notes: drift.Value(finalNotes.isNotEmpty ? finalNotes : null),
        ),
      );
    } else {
      await _saveSession(status: 'completed');
    }

    // Stats come from DB (actual elapsed seconds), not planned pomodoro length.
    await fetchDailyStats();

    if (markTaskDone &&
        selectedTaskId.value != null &&
        growthBlock != null) {
      await growthBlock!.completeGoalByGoalId(selectedTaskId.value!);
      selectedTaskId.value = null;
    }

    showSummary.value = false;
    resetTimer();
  }

  int _getDurationForType(String type) {
    switch (type) {
      case 'Short Break':
        return shortBreakDuration.value * 60;
      case 'Long Break':
        return longBreakDuration.value * 60;
      default:
        return focusDuration.value * 60;
    }
  }

  void setDurations({int? focus, int? short, int? long}) {
    if (focus != null) focusDuration.value = focus;
    if (short != null) shortBreakDuration.value = short;
    if (long != null) longBreakDuration.value = long;

    // If not running, update current remaining time
    if (!isRunning.value) {
      remainingTime.value = _getDurationForType(currentSessionType.value);
    }
  }

  void setSessionType(String type) {
    currentSessionType.value = type;
    isExerciseMode.value = false;
    isJobWorkMode.value = false;
    isMuskMode.value = false; // Reset musk mode when manually shifting types
    resetTimer();
  }

  void startMuskFocus() {
    appLog(
      "🚀 [FocusBlock] Alignment Musk Focus for: ${muskFocusDuration.value}m",
    );
    currentSessionType.value = 'Focus';
    isMuskMode.value = true;
    isExerciseMode.value = false;
    isJobWorkMode.value = false;
    focusDuration.value = muskFocusDuration.value;

    // ALIGNMENT LOGIC: Always find the next 5-minute mark (divisible by 5)
    final now = DateTime.now();
    final secondsSinceHour = now.minute * 60 + now.second;
    const intervalSeconds = 5 * 60;
    final nextAlignedSeconds =
        ((secondsSinceHour / intervalSeconds).ceil()) * intervalSeconds;

    final nextAlignedTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      0,
    ).add(Duration(seconds: nextAlignedSeconds));
    final waitDuration = nextAlignedTime.difference(now);

    if (waitDuration.inSeconds > 0) {
      isSyncingWithClock.value = true;
      remainingTime.value = waitDuration.inSeconds;
      _notificationService?.showNotification(
        888,
        "SYNCING WITH TIME",
        "Waiting ${waitDuration.inMinutes}m ${waitDuration.inSeconds % 60}s for clock alignment. PLEASE PREPARE.",
      );
    } else {
      isSyncingWithClock.value = false;
      remainingTime.value = muskFocusDuration.value * 60;
      _notificationService?.showNotification(
        888,
        "BLOCK FOCUS STARTED",
        "Prepare for ${muskFocusDuration.value} minutes.",
      );
    }

    startTimer();
  }

  void startJobWorkFocus({
    required int minutes,
    String? projectId,
    String? notes,
  }) {
    if (isRunning.value) {
      appLog('FocusBlock: startJobWorkFocus ignored — timer already running');
      return;
    }
    appLog('🚀 [FocusBlock] Starting job-work focus for $minutes min');
    isJobWorkMode.value = true;
    isExerciseMode.value = false;
    isMuskMode.value = false;
    isStopwatchMode.value = false;
    stopwatchElapsedSeconds.value = 0;
    currentSessionType.value = 'Focus';
    if (projectId != null && projectId.isNotEmpty) {
      selectedProjectId.value = projectId;
    }
    sessionNotes.value = notes ?? '';
    remainingTime.value = minutes * 60;
    startTimer();
  }

  Future<void> _finalizeLinkedJobWork() async {
    if (!isJobWorkMode.value) return;
    await _finalizeJobWorkSession(sessionNotes.value);
  }

  Future<void> _finalizeJobWorkSession(String notes) async {
    if (!isJobWorkMode.value && !_deferJobWorkFinalize) return;
    isJobWorkMode.value = false;
    final block = jobWorkLogBlock;
    if (block == null) return;

    final minutes = _accumulatedSeconds <= 0
        ? 0
        : ((_accumulatedSeconds + 59) ~/ 60);
    if (minutes > 0) {
      final trimmed = notes.trim();
      await block.stopWork(
        notes: trimmed.isEmpty ? null : trimmed,
        minutesOverride: minutes,
      );
    } else {
      block.cancelWork();
    }
  }

  void startExercise(String type, int minutes) {
    appLog("🚀 [FocusBlock] Starting Exercise: $type for $minutes min");
    currentSessionType.value = 'Focus';
    isJobWorkMode.value = false;
    isExerciseMode.value = true;
    isStopwatchMode.value = false;
    stopwatchElapsedSeconds.value = 0;
    exerciseType.value = type;
    remainingTime.value = minutes * 60;
    startTimer();
  }

  void startStopwatchExercise(String type) {
    appLog("🚀 [FocusBlock] Starting Stopwatch Exercise: $type");
    currentSessionType.value = 'Focus';
    isJobWorkMode.value = false;
    isExerciseMode.value = true;
    isStopwatchMode.value = true;
    stopwatchElapsedSeconds.value = 0;
    exerciseType.value = type;
    remainingTime.value = 0;
    startTimer();
  }

  // --- Database Actions ---

  Future<String?> _saveSession({String status = 'completed'}) async {
    if (_actualStartTime == null) return null;

    // Important: Final accumulation if currently running
    if (isRunning.value && _lastStartTime != null) {
      _accumulatedSeconds += DateTime.now().difference(_lastStartTime!).inSeconds;
      _lastStartTime = DateTime.now(); // Reset for next segment if needed
    }

    final duration = _accumulatedSeconds;
    if (duration == 0 && status == 'interrupted') {
      return null;
    }
    // Manual stop: skip noise for normal focus, but always allow exercise timer saves.
    if (duration < 10 &&
        status == 'interrupted' &&
        !isExerciseMode.value) {
      appLog("FocusBlock: Session too short to save (< 10s).");
      return null;
    }

    final exerciseMinutesLogged = duration <= 0
        ? 0
        : ((duration + 59) ~/ 60); // ceil to minutes for exercise_logs / metrics

    final sessionId = IDGen.UUIDV7();
    final session = FocusSessionsTableCompanion.insert(
      id: sessionId,
      personID: drift.Value(_currentPersonId),
      projectID: drift.Value(selectedProjectId.value),
      taskID: drift.Value(selectedTaskId.value),
      startTime: _actualStartTime!,
      endTime: drift.Value(DateTime.now()),
      durationSeconds: duration,
      status: status, // 'completed' or 'interrupted'
      sessionType: drift.Value(currentSessionType.value),
      notes: drift.Value(
        sessionNotes.value.isNotEmpty ? sessionNotes.value : null,
      ),
      categories: drift.Value(
        isExerciseMode.value
            ? 'health-exercise'
            : (isJobWorkMode.value ? 'job-work' : null),
      ),
    );

    await _focusSessionDao.insertSession(session);

    // Record to Health Metrics
    // Standardize to NOON local to match HealthBlock normalization exactly
    final normalizedToday = DateTime(
      _actualStartTime!.year,
      _actualStartTime!.month,
      _actualStartTime!.day,
      12,
    );
    await _healthMetricsDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        personID: drift.Value(_currentPersonId),
        date: drift.Value(normalizedToday),
        focusMinutes: drift.Value(
          isExerciseMode.value ? 0 : duration ~/ 60,
        ),
        exerciseMinutes: drift.Value(
          isExerciseMode.value ? exerciseMinutesLogged : 0,
        ),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    // Record Exercise Log if in Exercise Mode
    // For exercise, we log even if interrupted (as long as > 1 min)
    if (isExerciseMode.value &&
        duration > 0 &&
        (status == 'completed' || status == 'interrupted')) {
      final exerciseLogId = IDGen.UUIDV7();
      final exerciseLog = ExerciseLogsTableCompanion.insert(
        id: exerciseLogId,
        personID: drift.Value(_currentPersonId),
        type: exerciseType.value,
        durationMinutes: exerciseMinutesLogged,
        intensity: const drift.Value('medium'),
        timestamp: drift.Value(DateTime.now()),
        // Link to the focus_session row so getDailyExerciseWithSession()
        // can JOIN and return the exact duration_seconds instead of the rounded minutes.
        // sessionId is the UUID of the focus_sessions row we just inserted above.
        focusSessionID: drift.Value(sessionId),
      );
      await _healthLogsDao.insertExerciseLog(exerciseLog);
      pendingExerciseLogForMood.value = exerciseLogId;
      appLog("✅ [FocusBlock] Exercise log recorded: ${exerciseType.value}");

      // --- Sync to Apple Health / Google Fit ---
      try {
        final activityType = HealthService.mapStringToActivityType(exerciseType.value);
        final endTime = DateTime.now();
        final startTime = endTime.subtract(Duration(seconds: duration));

        // Use a simple calorie estimation if a HealthBlock reference isn't handy,
        // or just pass null if you prefer Apple Health to calculate it (if possible).
        // For now, we'll do a simple estimation if duration is significant.
        int? estimatedKcal;
        if (duration > 60) {
           // Basic estimation: 5-10 kcal per minute depending on intensity
           estimatedKcal = (exerciseMinutesLogged * 7.0).round();
        }

        HealthService.writeWorkoutData(
          activityType: activityType,
          start: startTime,
          end: endTime,
          totalEnergyBurned: estimatedKcal,
        ).then((success) {
          if (success) {
            appLog("🚀 [FocusBlock] Workout synced to Platform Health.");
          }
        });
      } catch (e) {
        appLog("⚠️ [FocusBlock] Failed to sync workout to platform: $e");
      }

    }

    await fetchDailyStats();
    return sessionId;
  }

  Future<void> deleteSession(String id) async {
    await _focusSessionDao.deleteSession(id);
    await fetchDailyStats();
  }

  Future<void> fetchDailyStats() async {
    if (_currentPersonId.isEmpty) return;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Implementing a simple listener on the full stream for now
    final allSessions = await _focusSessionDao
        .watchSessionsByPerson(_currentPersonId)
        .first;

    int todayDuration = 0;
    int todayCount = 0;

    for (var session in allSessions) {
      if (session.startTime.isAfter(todayStart) &&
          session.startTime.isBefore(todayEnd) &&
          session.status == 'completed' &&
          session.sessionType == 'Focus') {
        todayDuration += session.durationSeconds;
        todayCount++;
      }
    }

    totalStudyTimeToday.value = todayDuration;
    sessionsCompletedToday.value = todayCount;
  }

  void dispose() {
    _timer?.cancel();
    _activitySubscription?.cancel();
    if (_activityId != null) {
      _liveActivities.endActivity(_activityId!);
    }
  }
}
