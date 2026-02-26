import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart'; // Import generated code
import 'package:signals/signals.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ice_shield/orchestration_layer/IDGen.dart';

import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_shield/initial_layer/FocusAudioHandler.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:live_activities/live_activities.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ice_shield/data_layer/Services/YoutubeService.dart';

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

  // Stats
  final totalStudyTimeToday = signal<int>(0); // In seconds
  final sessionsCompletedToday = signal<int>(0);

  // Theme
  // Theme
  final timerTheme = signal<String>('Default');

  // Audio Customization
  final customSoundPath = signal<String?>(null);
  final isCustomSoundLocal = signal<bool>(false);
  final youtubeUrl = signal<String?>(null);
  final isStreamingYoutube = signal<bool>(false);
  final currentTrackTitle = signal<String?>(null);

  final _youtubeService = YoutubeService();

  // External Blocks for Automation
  GrowthBlock? growthBlock;
  ScoreBlock? scoreBlock;

  // Timer
  Timer? _timer;
  DateTime? _actualStartTime; // Persists across pauses for logging
  DateTime? _targetEndTime;
  bool _isStarting = false;
  bool _isLiveActivityInitialized = false;

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
    FocusAudioHandler? audioHandler,
    LocalNotificationService? notificationService,
  }) : _focusSessionDao = focusSessionDao,
       _healthLogsDao = healthLogsDao,
       _healthMetricsDao = healthMetricsDao,
       _currentPersonId = personId,
       _audioHandler = audioHandler,
       _notificationService = notificationService {
    print(
      "FocusBlock Checking: AudioHandler injected: ${_audioHandler != null}",
    );
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
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_targetEndTime == null) return;
        final now = DateTime.now();
        final remaining = _targetEndTime!.difference(now);
        if (remaining.inMilliseconds <= 0) {
          remainingTime.value = 0;
          completeSession();
        } else {
          final newSeconds = remaining.inSeconds;
          if (newSeconds != remainingTime.value) {
            remainingTime.value = newSeconds;

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
            await _updateAudioSource();
            if (isRunning.value) {
              _audioHandler?.play();
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
      String songName;
      if (customSoundPath.value != null) {
        songName = customSoundPath.value!.split('/').last;
      } else {
        songName = _getThemeSoundAsset(timerTheme.value).split('/').last;
      }
      if (songName.contains('.')) {
        songName = songName.substring(0, songName.lastIndexOf('.'));
      }
      songName = songName.replaceAll('_', ' ').toUpperCase();

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
      String songName;
      if (customSoundPath.value != null) {
        songName = customSoundPath.value!.split('/').last;
      } else {
        songName = _getThemeSoundAsset(timerTheme.value).split('/').last;
      }
      if (songName.contains('.')) {
        songName = songName.substring(0, songName.lastIndexOf('.'));
      }
      songName = songName.replaceAll('_', ' ').toUpperCase();

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

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  void pauseTimer({bool fromSystem = false}) {
    print(
      "FocusBlock(${identityHashCode(this)}): pauseTimer called. isRunning: ${isRunning.value}, fromSystem: $fromSystem",
    );
    if (!isRunning.value) return;

    isRunning.value = false;
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
      _audioHandler?.pause();
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
    if (_audioHandler == null) return;

    String songDisplayName;
    String rawSongName;
    if (customSoundPath.value != null) {
      rawSongName = customSoundPath.value!.split('/').last;
    } else {
      rawSongName = _getThemeSoundAsset(timerTheme.value).split('/').last;
    }

    if (rawSongName.contains('.')) {
      rawSongName = rawSongName.substring(0, rawSongName.lastIndexOf('.'));
    }
    songDisplayName = rawSongName
        .replaceAll('_', ' ')
        .split(' ')
        .map((s) {
          if (s.isEmpty) return s;
          return s[0].toUpperCase() + s.substring(1);
        })
        .join(' ');

    String title = currentTrackTitle.value ?? songDisplayName;
    String artist =
        "${currentSessionType.value} | Time Left: ${_formatTime(remainingTime.value)}";

    final totalSecs = _getDurationForType(currentSessionType.value);
    // Add is playing
    _audioHandler.updateMetadata(
      title: title,
      artist: artist,
      playing: isRunning.value,
      duration: Duration(seconds: totalSecs),
      position: Duration(seconds: totalSecs - remainingTime.value),
    );
  }

  static const String SILENT_MODE = 'SILENT';

  Future<bool> _updateAudioSource() async {
    if (_audioHandler == null) {
      print(
        "FocusBlock: AudioHandler is null (Background Audio Service not ready).",
      );
      return false;
    }

    try {
      // 0. Check for YouTube Streaming
      if (youtubeUrl.value != null) {
        final streamUrl = await _youtubeService.getAudioStreamUrl(
          youtubeUrl.value!,
        );
        if (streamUrl != null) {
          final targetSource = UrlSource(streamUrl);
          await _audioHandler.setSource(targetSource);
          isStreamingYoutube.value = true;
          return true;
        }
      }
      isStreamingYoutube.value = false;

      // 1. Check for Silent Mode
      if (customSoundPath.value == SILENT_MODE) {
        await _audioHandler.setVolume(0.0);
      } else {
        await _audioHandler.setVolume(1.0);
      }

      Source targetSource;
      if (customSoundPath.value != null &&
          customSoundPath.value != SILENT_MODE) {
        if (customSoundPath.value!.startsWith('http')) {
          targetSource = UrlSource(customSoundPath.value!);
        } else {
          targetSource = isCustomSoundLocal.value
              ? DeviceFileSource(customSoundPath.value!)
              : AssetSource(customSoundPath.value!);
        }
      } else {
        final soundAsset = _getThemeSoundAsset(timerTheme.value);
        if (soundAsset.startsWith('http')) {
          targetSource = UrlSource(soundAsset);
        } else {
          targetSource = AssetSource(soundAsset);
        }
      }

      // 2. Attempt to check if asset exists (Pseudo-check)
      // Since we can't easily check assets synchronously without context, we rely on try-catch

      await _audioHandler.setSource(targetSource);
      return true;
    } catch (e) {
      // Suppress full stack trace for known "empty asset" issue during development
      print("FocusBlock: Audio playback skipped (Source Error: $e)");
      // Optional: fallback to silent if audio fails?
      return false;
    }
  }

  String _getThemeSoundAsset(String themeName) {
    // This should ideally be shared with FocusPage
    switch (themeName) {
      case 'Emerald Haven':
        return 'sounds/forest_stream.mp3';
      case 'Emerald Forest':
        return 'sounds/birds.mp3';
      case 'Sakura Zen':
        return 'sounds/zen_garden.mp3';
      case 'Deep Sea':
        return 'sounds/ocean_waves.mp3';
      case 'Frosty Morning':
        return 'sounds/snow_wind.mp3';
      case 'Sunset':
        return 'sounds/crickets.mp3';
      case 'Cyberpunk 2077':
        return 'sounds/cyber_ambience.mp3';
      case 'Cyberpunk Pink':
        return 'sounds/synthwave.mp3';
      case 'Volcano':
        return 'sounds/lava_flow.mp3';
      case 'Ocean Deep':
        return 'sounds/deep_ocean.mp3';
      case 'Enchanted Forest':
        return 'sounds/magic_forest.mp3';
      case 'Nordic Night':
        return 'sounds/campfire.mp3';
      case 'Royal Velvet':
        return 'sounds/lofi.mp3';
      case 'Midnight Gold':
        return 'sounds/space_drone.mp3';
      case 'Light Purple':
        return 'sounds/bubbles.mp3';
      case 'Nebula':
        return 'sounds/nebula_hum.mp3';
      case 'Cherry':
        return 'sounds/fire_crackle.mp3';
      case 'Default':
      default:
        // Use a remote URL because local assets are corrupted (0 bytes)
        return 'sounds/default_theme.mp3';
    }
  }

  void resetTimer() {
    pauseTimer();
    _actualStartTime = null;
    _targetEndTime = null;
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
    // Trigger Summary UI - actual saving happens when user confirms in dialog
    showSummary.value = true;

    // Notify User
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

  Future<void> finishAndSaveSession(
    String finalNotes, {
    bool markTaskDone = false,
  }) async {
    sessionNotes.value = finalNotes;
    await _saveSession(status: 'completed');

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
    isExerciseMode.value =
        false; // Reset exercise mode when manually shifting types
    resetTimer();
  }

  void startExercise(String type, int minutes) {
    print("🚀 [FocusBlock] Starting Exercise: $type for $minutes min");
    currentSessionType.value = 'Focus';
    isExerciseMode.value = true;
    exerciseType.value = type;
    remainingTime.value = minutes * 60;
    startTimer();
  }

  void setTimerTheme(String theme) {
    timerTheme.value = theme;
    // Clear other audio sources when a theme is explicitly selected
    youtubeUrl.value = null;
    currentTrackTitle.value = null;
    isStreamingYoutube.value = false;
    customSoundPath.value = null;
    if (isRunning.value) {
      _updateAudioSource();
    }
  }

  void setCustomSound(String path, {bool isLocal = false}) {
    customSoundPath.value = path;
    isCustomSoundLocal.value = isLocal;
    // Clear YouTube if custom sound is set
    youtubeUrl.value = null;
    currentTrackTitle.value = null;
    isStreamingYoutube.value = false;
    if (isRunning.value) {
      _updateAudioSource();
    }
  }

  void clearCustomSound() {
    customSoundPath.value = null;
    isCustomSoundLocal.value = false;
  }

  void setProject(String? projectId) {
    selectedProjectId.value = projectId;
    selectedTaskId.value = null; // Reset task when project changes
  }

  void setTask(String? taskId) {
    selectedTaskId.value = taskId;
  }

  Future<void> playYoutube(String url) async {
    youtubeUrl.value = url;
    customSoundPath.value = null; // Clear custom sounds when playing YouTube
    final metadata = await _youtubeService.getVideoMetadata(url);
    if (metadata != null) {
      currentTrackTitle.value = metadata.title;
    }
    if (isRunning.value) {
      await _updateAudioSource();
      _audioHandler?.play();
    }
  }

  void clearYoutube() {
    youtubeUrl.value = null;
    currentTrackTitle.value = null;
    isStreamingYoutube.value = false;
    if (isRunning.value) {
      _updateAudioSource();
    }
  }

  // --- Database Actions ---

  Future<void> _saveSession({required String status}) async {
    if (_currentPersonId.isEmpty) return;

    final totalDuration = _getDurationForType(currentSessionType.value);
    final duration = totalDuration - remainingTime.value;

    // Only save significant sessions (e.g., > 1 minute)
    if (duration < 60) return;

    final session = FocusSessionsTableCompanion.insert(
      id: IDGen.generateUuid(),
      personID: _currentPersonId,
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
        id: IDGen.generateUuid(),
        personID: _currentPersonId,
        type: exerciseType.value,
        durationMinutes: duration ~/ 60,
        timestamp: drift.Value(DateTime.now()),
      );
      await _healthLogsDao.insertExerciseLog(exerciseLog);
      print("✅ [FocusBlock] Exercise log recorded: ${exerciseType.value}");

      // Auto-increase points for exercise
      if (scoreBlock != null) {
        scoreBlock!.addPoints(25); // Bonus for exercise completion
      }
    }

    await fetchDailyStats();
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
