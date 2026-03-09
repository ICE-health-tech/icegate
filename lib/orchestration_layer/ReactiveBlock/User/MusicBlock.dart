import 'dart:async';
import 'package:signals/signals.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ice_gate/data_layer/Services/YoutubeService.dart';
import 'package:ice_gate/initial_layer/FocusAudioHandler.dart';

class MusicBlock {
  // Dependencies
  final FocusAudioHandler? _audioHandler;
  final _youtubeService = YoutubeService();

  // Signals - Settings
  final timerTheme = signal<String>('Default');
  final customSoundPath = signal<String?>(null);
  final isCustomSoundLocal = signal<bool>(false);
  final youtubeUrl = signal<String?>(null);
  final isStreamingYoutube = signal<bool>(false);
  final currentTrackTitle = signal<String?>(null);

  // Enhancement Signals
  final isShuffleEnabled = signal<bool>(false);
  final isDownloading = signal<bool>(false);
  final downloadProgress = signal<double>(0.0);

  MusicBlock({FocusAudioHandler? audioHandler}) : _audioHandler = audioHandler;

  static const String SILENT_MODE = 'SILENT';

  // --- Theme Mapping ---

  String _getThemeSoundAsset(String themeName) {
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
        return 'sounds/default_theme.mp3';
    }
  }

  // --- Actions ---

  void setTimerTheme(String theme, {bool isRunning = false}) {
    timerTheme.value = theme;
    youtubeUrl.value = null;
    currentTrackTitle.value = null;
    isStreamingYoutube.value = false;
    customSoundPath.value = null;
    if (isRunning) {
      updateAudioSource(isRunning: true);
    }
  }

  void setCustomSound(
    String path, {
    bool isLocal = false,
    bool isRunning = false,
  }) {
    customSoundPath.value = path;
    isCustomSoundLocal.value = isLocal;
    youtubeUrl.value = null;
    currentTrackTitle.value = null;
    isStreamingYoutube.value = false;
    if (isRunning) {
      updateAudioSource(isRunning: true);
    }
  }

  void clearCustomSound() {
    customSoundPath.value = null;
    isCustomSoundLocal.value = false;
  }

  Future<void> playYoutube(String url, {bool isRunning = false}) async {
    youtubeUrl.value = url;
    customSoundPath.value = null;
    final metadata = await _youtubeService.getVideoMetadata(url);
    if (metadata != null) {
      currentTrackTitle.value = metadata.title;
    }
    if (isRunning) {
      await updateAudioSource(isRunning: true);
      _audioHandler?.play();
    }
  }

  void clearYoutube({bool isRunning = false}) {
    youtubeUrl.value = null;
    currentTrackTitle.value = null;
    isStreamingYoutube.value = false;
    if (isRunning) {
      updateAudioSource(isRunning: true);
    }
  }

  // --- Audio Engine ---

  Future<bool> updateAudioSource({required bool isRunning}) async {
    if (_audioHandler == null) return false;

    try {
      if (youtubeUrl.value != null) {
        final streamUrl = await _youtubeService.getAudioStreamUrl(
          youtubeUrl.value!,
        );
        if (streamUrl != null) {
          await _audioHandler.setSource(UrlSource(streamUrl));
          isStreamingYoutube.value = true;
          return true;
        }
      }
      isStreamingYoutube.value = false;

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
        targetSource = soundAsset.startsWith('http')
            ? UrlSource(soundAsset)
            : AssetSource(soundAsset);
      }

      await _audioHandler.setSource(targetSource);
      return true;
    } catch (e) {
      print("MusicBlock: Audio setup failed ($e)");
      return false;
    }
  }

  void updateMediaMetadata({
    required bool isRunning,
    required String sessionType,
    required int remainingTime,
    required int totalDuration,
  }) {
    if (_audioHandler == null) return;

    String rawSongName;
    if (customSoundPath.value != null) {
      rawSongName = customSoundPath.value!.split('/').last;
    } else {
      rawSongName = _getThemeSoundAsset(timerTheme.value).split('/').last;
    }

    if (rawSongName.contains('.')) {
      rawSongName = rawSongName.substring(0, rawSongName.lastIndexOf('.'));
    }

    final songDisplayName = rawSongName
        .replaceAll('_', ' ')
        .split(' ')
        .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
        .join(' ');

    final title = currentTrackTitle.value ?? songDisplayName;
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final artist = "$sessionType | Time Left: $timeStr";

    _audioHandler.updateMetadata(
      title: title,
      artist: artist,
      playing: isRunning,
      duration: Duration(seconds: totalDuration),
      position: Duration(seconds: totalDuration - remainingTime),
    );
  }

  void play() => _audioHandler?.play();
  void pause() => _audioHandler?.pause();
  void setVolume(double volume) => _audioHandler?.setVolume(volume);

  void dispose() {
    _youtubeService.dispose();
  }
}
