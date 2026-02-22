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
  final int? currentProjectId;
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
  int _currentPersonId;
  set personId(int id) => _currentPersonId = id;
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
  final selectedProjectId = signal<int?>(null);
  final selectedTaskId = signal<int?>(null);
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
  DateTime? _startTime;
  bool _isStarting = false;

  final FocusAudioHandler? _audioHandler;

  // Live Activity
  final _liveActivities = LiveActivities();
  String? _activityId;

  FocusBlock({
    required FocusSessionsDAO focusSessionDao,
    required HealthLogsDAO healthLogsDao,
    required HealthMetricsDAO healthMetricsDao,
    required int personId,
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
      await fetchDailyStats();

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // Use correct bundle ID for app group
        await _liveActivities.init(appGroupId: 'group.duylong.art.iceshield');
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
      _startTime ??= DateTime.now();

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

      if (!isRunning.value) {
        print(
          "FocusBlock: startTimer aborted early - user requested pause during setup.",
        );
        return;
      }

      _timer?.cancel(); // Safety cancel before creating new
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime.value > 0) {
          remainingTime.value--;
          try {
            _updateLiveActivity();
          } catch (e) {
            print("FocusBlock: Live Activity Update Error: $e");
          }
          try {
            _updateMediaMetadata();
          } catch (e) {
            print("FocusBlock: Media Metadata Update Error: $e");
          }
        } else {
          completeSession();
        }
      });
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _createLiveActivity() async {
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
    _timer?.cancel();
    _timer = null;

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

    String title = songDisplayName;
    String artist =
        "${currentSessionType.value} | Time Left: ${_formatTime(remainingTime.value)}";

    final totalSecs = _getDurationForType(currentSessionType.value);
    _audioHandler.updateMetadata(
      title: title,
      artist: artist,
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
        await _audioHandler.stop(); // Ensure silence
        return false; // Valid, but no "playback" needed
      }

      Source targetSource;
      if (customSoundPath.value != null) {
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
        return 'sounds/forest_stream';
    }
  }

  void resetTimer() {
    pauseTimer();
    remainingTime.value = _getDurationForType(currentSessionType.value);
    _startTime = null;
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

  Future<void> finishAndSaveSession(String finalNotes) async {
    sessionNotes.value = finalNotes;
    await _saveSession(status: 'completed');

    // Update stats immediately
    if (currentSessionType.value == 'Focus') {
      int duration = _getDurationForType('Focus');
      totalStudyTimeToday.value += duration;
      sessionsCompletedToday.value++;

      // Automation - Complete task and increase points
      if (selectedTaskId.value != null && growthBlock != null) {
        await growthBlock!.completeGoalByIntId(
          selectedTaskId.value!,
          scoreBlock: scoreBlock,
        );
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

  void setProject(int? projectId) {
    selectedProjectId.value = projectId;
    selectedTaskId.value = null; // Reset task when project changes
  }

  void setTask(int? taskId) {
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
    if (_startTime == null) return;

    final duration =
        _getDurationForType(currentSessionType.value) - remainingTime.value;

    // Only save significant sessions (e.g., > 1 minute)
    if (duration < 60) return;

    final session = FocusSessionsTableCompanion.insert(
      id: IDGen.generateUuid(),
      personID: _currentPersonId,
      projectID: drift.Value(selectedProjectId.value),
      taskID: drift.Value(selectedTaskId.value),
      startTime: _startTime!,
      endTime: drift.Value(DateTime.now()),
      durationSeconds: duration,
      status: status, // 'completed' or 'interrupted'
      notes: drift.Value(
        sessionNotes.value.isNotEmpty ? sessionNotes.value : null,
      ),
    );

    await _focusSessionDao.insertSession(session);

    // Record to Health Metrics
    final normalizedToday = DateTime(
      _startTime!.year,
      _startTime!.month,
      _startTime!.day,
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

  Future<void> fetchDailyStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // We need a query for today's sessions.
    // Since DAO only has watchSessionsByPerson, we might need to filter manually or add a specific query.
    // For simplicity, let's filter the stream or assume we add a getTodaySessions to DAO later.
    // Here we'll just use the stream subscription approach or a one-time fetch if we add that to DAO.

    // Ideally, we should add `getSessionsForDateRange` to DAO.
    // Without it, we can't easily get *just* today without fetching all.
    // Let's rely on the stream in the UI for history,
    // and for stats, maybe we listen to the stream once.

    // Implementing a simple listener on the full stream for now (not efficient for large data, but works for MVP).
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
          // Assume 'Focus' sessions are roughly this length or marked?
          // Actually, we should check duration or have a type field.
          // For 'Study Time', sum durationSeconds.
          todayDuration += session.durationSeconds;
          todayCount++;
        } else if (session.status == 'completed') {
          todayDuration += session.durationSeconds;
          // maybe count breaks? usually not as "sessions".
        }
      }
    }

    totalStudyTimeToday.value = todayDuration;
    sessionsCompletedToday.value = todayCount;
  }

  void dispose() {
    _timer?.cancel();
    if (_activityId != null) {
      _liveActivities.endActivity(_activityId!);
    }
  }
}
