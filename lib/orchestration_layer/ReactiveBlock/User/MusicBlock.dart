import 'dart:math';
import 'package:signals/signals.dart';
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

  static const Map<String, List<String>> themeTracks = {
    'Emerald Haven': ['sounds/forest_stream.mp3', 'sounds/birds.mp3'],
    'Emerald Forest': ['sounds/birds.mp3', 'sounds/forest_wind.mp3'],
    'Sakura Zen': ['sounds/zen_garden.mp3', 'sounds/koto.mp3'],
    'Deep Sea': ['sounds/ocean_waves.mp3', 'sounds/whale_songs.mp3'],
    'Frosty Morning': ['sounds/snow_wind.mp3', 'sounds/ice_crackle.mp3'],
    'Sunset': ['sounds/crickets.mp3', 'sounds/evening_breeze.mp3'],
    'Cyberpunk 2077': ['sounds/cyber_ambience.mp3', 'sounds/neon_city.mp3'],
    'Cyberpunk Pink': ['sounds/synthwave.mp3', 'sounds/retro_future.mp3'],
    'Volcano': ['sounds/lava_flow.mp3', 'sounds/earth_rumble.mp3'],
    'Ocean Deep': ['sounds/deep_ocean.mp3', 'sounds/submarine_sonar.mp3'],
    'Enchanted Forest': ['sounds/magic_forest.mp3', 'sounds/fairy_dust.mp3'],
    'Nordic Night': ['sounds/campfire.mp3', 'sounds/night_owls.mp3'],
    'Royal Velvet': ['sounds/lofi.mp3', 'sounds/jazz_vinyl.mp3'],
    'Midnight Gold': ['sounds/space_drone.mp3', 'sounds/star_drift.mp3'],
    'Light Purple': ['sounds/bubbles.mp3', 'sounds/soft_water.mp3'],
    'Nebula': ['sounds/nebula_hum.mp3', 'sounds/cosmic_waves.mp3'],
    'Cherry': ['sounds/fire_crackle.mp3', 'sounds/wood_burning.mp3'],
    'Default': ['sounds/rain.mp3', 'sounds/thunder_soft.mp3'],
  };

  String _getThemeSoundAsset(String themeName) {
    final tracks = themeTracks[themeName] ?? themeTracks['Default']!;
    if (isShuffleEnabled.value) {
      return tracks[Random().nextInt(tracks.length)];
    }
    return tracks.first;
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

  Future<void> playYoutube(
    String url, {
    String? alias,
    bool isRunning = false,
  }) async {
    youtubeUrl.value = url;
    customSoundPath.value = null;

    isDownloading.value = true;
    downloadProgress.value = 0.0;

    final metadata = await _youtubeService.getVideoMetadata(url);
    if (metadata != null) {
      currentTrackTitle.value = metadata.title;
    }

    // Try to download first for local playback
    final file = await _youtubeService.downloadAudio(
      url,
      subFolder: alias,
      onProgress: (p) => downloadProgress.value = p,
    );

    isDownloading.value = false;

    if (file != null) {
      setCustomSound(file.path, isLocal: true, isRunning: isRunning);
    } else if (isRunning) {
      // Fallback to stream if download fails
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
          await _audioHandler.setSource(streamUrl);
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

      if (customSoundPath.value != null &&
          customSoundPath.value != SILENT_MODE) {
        final path = customSoundPath.value!;
        if (path.startsWith('http')) {
          await _audioHandler.setSource(path);
        } else {
          await _audioHandler.setSource(
            path,
            isFile: isCustomSoundLocal.value,
            isAsset: !isCustomSoundLocal.value,
          );
        }
      } else {
        final soundAsset = _getThemeSoundAsset(timerTheme.value);
        if (soundAsset.startsWith('http')) {
          await _audioHandler.setSource(soundAsset);
        } else {
          await _audioHandler.setSource(soundAsset, isAsset: true);
        }
      }
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

  String getDisplaySongName() {
    String rawSongName;
    if (currentTrackTitle.value != null) {
      return currentTrackTitle.value!.toUpperCase();
    }

    if (customSoundPath.value != null) {
      rawSongName = customSoundPath.value!.split('/').last;
    } else {
      rawSongName = _getThemeSoundAsset(timerTheme.value).split('/').last;
    }

    if (rawSongName.contains('.')) {
      rawSongName = rawSongName.substring(0, rawSongName.lastIndexOf('.'));
    }

    return rawSongName.replaceAll('_', ' ').toUpperCase();
  }

  void dispose() {
    _youtubeService.dispose();
  }
}
