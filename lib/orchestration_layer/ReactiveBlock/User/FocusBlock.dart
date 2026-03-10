import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'; // Import generated code
import 'package:signals/signals.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ice_gate/orchestration_layer/IDGen.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/initial_layer/FocusAudioHandler.dart';
import 'package:ice_gate/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MusicBlock.dart';
import 'package:live_activities/live_activities.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';

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
  final exerciseType = signal<String>('');

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
  ScoreBlock? scoreBlock;

  // Timer
  Timer? _timer;
  DateTime? _actualStartTime; // Persists across pauses for logging
  DateTime? _targetEndTime;
  String? _activeSessionId;
  bool _isStarting = false;
  bool _isLiveActivityInitialized = false;

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
    print("FocusBlock Checking: MusicBlock injected: ${_musicBlock != null}");
  }

  // --- Initialization ---
  Future<void> init() async {
    print(
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
        print("FocusBlock: personId is empty, skipping daily stats fetch.");
      } else {
        await fetchDailyStats();
      }

      // Register this block with the audio handler for two-way sync
      _audioHandler?.focusBlock = this;
    } catch (e) {
      print("FocusBlock init error: $e");
    }
  }

  // --- Timer Actions ---

  void startTimer({bool fromSystem = false}) async {
    print(
      "FocusBlock(${identityHashCode(this)}): startTimer called. isRunning: ${isRunning.value}, fromSystem: $fromSystem, _isStarting: $_isStarting",
    );
    if (isRunning.value || _isStarting) return;

    _isStarting = true;
    try {
      isRunning.value = true;
      _actualStartTime ??= DateTime.now();
      _targetEndTime = DateTime.now().add(
        Duration(seconds: remainingTime.value),
      );

      // Force immediate metadata update for instant play/pause button toggle
      _updateMediaMetadata();

      // 1. START TIMER IMMEDIATELY
      _timer?.cancel();
      final totalSeconds = remainingTime.value;
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_targetEndTime == null) return;
        final now = DateTime.now();
        final remaining = _targetEndTime!.difference(now);
        if (remaining.inMilliseconds <= 0) {
          remainingTime.value = 0;
          if (isSyncingWithClock.value) {
            // Wait period over, start the actual session
            isSyncingWithClock.value = false;
            _actualStartTime =
                DateTime.now(); // Reset start time for the real block
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
          } else {
            completeSession();
          }
        } else {
          final newSeconds = remaining.inSeconds;
          if (newSeconds != remainingTime.value) {
            remainingTime.value = newSeconds;

            // --- Periodic Haptics for Musk Mode ---
            if (isMuskMode.value) {
              final elapsedSeconds = totalSeconds - newSeconds;
              if (elapsedSeconds > 0 && elapsedSeconds % 60 == 0) {
                final elapsedMinutes = elapsedSeconds ~/ 60;
                if (elapsedMinutes % 5 == 0) {
                  _triggerIntervalHaptics(strong: true);
                } else {
                  _triggerIntervalHaptics(strong: false);
                }
              }
            }

            // Only update Live Activity every 5 seconds to avoid iOS throttling
            if (newSeconds % 5 == 0) {
              _updateLiveActivity();
            }

            _updateMediaMetadata();
          }
        }
      });

      // 2. RUN SETUP IN BACKGROUND
      Future.microtask(() async {
        if (!fromSystem) {
          try {
            await _musicBlock?.updateAudioSource(isRunning: true);
            if (isRunning.value) {
              _musicBlock?.play();
            }
          } catch (audioError) {
            print(
              "FocusBlock: Audio setup failed ($audioError), proceeding with silent timer.",
            );
          }
        }

        try {
          await _createLiveActivity();
        } catch (e) {
          print("FocusBlock: Live Activity skipped: $e");
        }
      });
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _createLiveActivity() async {
    if (!_isLiveActivityInitialized) {
      print("FocusBlock: Live Activity skipped (Not initialized yet)");
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
        print(
          "FocusBlock: Live Activity not available (Widget Extension missing). Skipping.",
        );
      } else {
        print("FocusBlock: Error creating Live Activity: $e");
      }
    }
  }

  void _updateLiveActivity() {
    if (_activityId != null) {
      final songName = _musicBlock?.getDisplaySongName() ?? "Focus Music";

      try {
        _liveActivities.updateActivity(_activityId!, {
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
        print("FocusBlock: Live Activity update failed (quietly skipped): $e");
      }
    }
  }

  void pauseTimer({bool fromSystem = false}) {
    print(
      "FocusBlock(${identityHashCode(this)}): pauseTimer called. isRunning: ${isRunning.value}, fromSystem: $fromSystem",
    );
    if (!isRunning.value) return;

    isRunning.value = false;
    isSyncingWithClock.value = false;
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

  void _updateMediaMetadata() {
    _musicBlock?.updateMediaMetadata(
      isRunning: isRunning.value,
      sessionType: currentSessionType.value,
      remainingTime: remainingTime.value,
      totalDuration: _getDurationForType(currentSessionType.value),
    );
  }

  void resetTimer() {
    pauseTimer();
    _actualStartTime = null;
    _targetEndTime = null;
    _activeSessionId = null;
    remainingTime.value = _getDurationForType(currentSessionType.value);

    // Ensure metadata is updated with reset time and paused state
    _updateMediaMetadata();
  }

  void stopTimer() {
    // Save as 'interrupted' if desired, or just reset
    _saveSession(status: 'interrupted');
    resetTimer();
  }

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

    // Update stats immediately
    if (currentSessionType.value == 'Focus') {
      int duration = _getDurationForType('Focus');
      totalStudyTimeToday.value += duration;
      sessionsCompletedToday.value++;

      // Automation - Only complete task if explicitly requested
      if (markTaskDone && selectedTaskId.value != null && growthBlock != null) {
        await growthBlock!.completeGoalByGoalId(
          selectedTaskId.value!,
          scoreBlock: scoreBlock,
        );
      }

      // Add focus session bonus points
      if (scoreBlock != null && !isExerciseMode.value) {
        scoreBlock!.addPoints(FOCUS_SESSION_POINTS.toDouble());
      }

      // We keep the selectedTaskId so they can run another session on the same task,
      // UNLESS they explicitly marked it as done.
      if (markTaskDone) {
        selectedTaskId.value = null;
      }
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
    isMuskMode.value = false; // Reset musk mode when manually shifting types
    resetTimer();
  }

  void startMuskFocus() {
    print(
      "🚀 [FocusBlock] Alignment Musk Focus for: ${muskFocusDuration.value}m",
    );
    currentSessionType.value = 'Focus';
    isMuskMode.value = true;
    isExerciseMode.value = false;
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

  void startExercise(String type, int minutes) {
    print("🚀 [FocusBlock] Starting Exercise: $type for $minutes min");
    currentSessionType.value = 'Focus';
    isExerciseMode.value = true;
    exerciseType.value = type;
    remainingTime.value = minutes * 60;
    startTimer();
  }

  // --- Database Actions ---

  Future<String?> _saveSession({required String status}) async {
    if (_currentPersonId.isEmpty) return null;

    final totalDuration = _getDurationForType(currentSessionType.value);
    final duration = totalDuration - remainingTime.value;

    // Only save significant sessions (e.g., > 1 minute)
    if (duration < 60) return null;

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
    );

    await _focusSessionDao.insertSession(session);

    // Record to Health Metrics
    final normalizedToday = DateTime(
      _actualStartTime!.year,
      _actualStartTime!.month,
      _actualStartTime!.day,
    );
    await _healthMetricsDao.insertOrUpdateMetrics(
      HealthMetricsTableCompanion(
        personID: drift.Value(_currentPersonId),
        date: drift.Value(normalizedToday),
        focusMinutes: drift.Value(duration ~/ 60),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    // Record Exercise Log if in Exercise Mode
    if (isExerciseMode.value && status == 'completed') {
      final exerciseLog = ExerciseLogsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: drift.Value(_currentPersonId),
        type: exerciseType.value,
        durationMinutes: duration ~/ 60,
        timestamp: drift.Value(DateTime.now()),
      );
      await _healthLogsDao.insertExerciseLog(exerciseLog);
      print("✅ [FocusBlock] Exercise log recorded: ${exerciseType.value}");

      // Auto-increase points for exercise bonus
      if (scoreBlock != null) {
        scoreBlock!.addPoints(
          25.0,
        ); // Keep old bonus or use new constant if requested
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
          session.startTime.isBefore(todayEnd)) {
        if (session.status == 'completed' &&
            session.durationSeconds >= 25 * 60) {
          todayDuration += session.durationSeconds;
          todayCount++;
        } else if (session.status == 'completed') {
          todayDuration += session.durationSeconds;
        }
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
