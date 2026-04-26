import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';

class FocusAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  // Internal player for actual sound playback (KMPlayer-style engine)
  final Player _player = Player();

  // Back-reference to the block to sync state
  dynamic _focusBlock;
  set focusBlock(dynamic block) => _focusBlock = block;

  FocusAudioHandler() {
    _player.setPlaylistMode(PlaylistMode.single);
    print("🎧 [AudioHandler-MediaKit] Initialized");

    // Listen to changes in the player state to update system notifications if needed
    _player.stream.playing.listen((playing) {
      if (playbackState.value.playing != playing) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: playing,
            controls: playing
                ? [MediaControl.pause, MediaControl.stop]
                : [MediaControl.play, MediaControl.stop],
          ),
        );
      }
    });

    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.pause, MediaControl.play, MediaControl.stop],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: false,
      ),
    );
  }

  Future<void> setSource(
    String source, {
    bool isAsset = false,
    bool isFile = false,
  }) async {
    try {
      if (isAsset) {
        await _player.open(Media('asset:///$source'));
      } else if (isFile) {
        await _player.open(Media('file://$source'));
      } else {
        await _player.open(Media(source));
      }
    } catch (e) {
      print("FocusAudioHandler: Failed to set source: $e");
    }
  }

  @override
  Future<void> play() async {
    print("🎧 [AudioHandler] play() received");
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: [MediaControl.pause, MediaControl.stop],
        processingState: AudioProcessingState.ready,
      ),
    );

    try {
      await _player.play();
    } catch (e) {
      print("FocusAudioHandler: play failed: $e");
    }

    try {
      _focusBlock?.startTimer(fromSystem: true);
    } catch (e) {
      print("FocusAudioHandler: Error syncing play: $e");
    }
  }

  @override
  Future<void> pause() async {
    print("⏸️ [AudioHandler] pause() received");
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: [MediaControl.play, MediaControl.stop],
      ),
    );

    try {
      await _player.pause();
    } catch (e) {
      print("FocusAudioHandler: pause failed: $e");
    }

    try {
      _focusBlock?.pauseTimer(fromSystem: true);
    } catch (e) {
      print("FocusAudioHandler: Error syncing pause: $e");
    }
  }

  @override
  Future<void> stop() async {
    print("🛑 [AudioHandler] stop() received");
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
        controls: [MediaControl.play, MediaControl.stop],
      ),
    );

    try {
      _focusBlock?.stopTimer();
    } catch (e) {
      print("FocusAudioHandler: Error syncing stop: $e");
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await _player.dispose();
    return super.onTaskRemoved();
  }

  void updateMetadata({
    required String title,
    required String artist,
    bool? playing,
    Duration? duration,
    Duration? position,
  }) {
    mediaItem.add(
      MediaItem(
        id: 'focus_session',
        album: 'ICE Gate Focus',
        title: title,
        artist: artist,
        duration: duration,
      ),
    );

    final isPlaying = playing ?? playbackState.value.playing;

    if (isPlaying != playbackState.value.playing || position != null) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position ?? playbackState.value.updatePosition,
          bufferedPosition: position ?? playbackState.value.bufferedPosition,
          playing: isPlaying,
          processingState: AudioProcessingState.ready,
          controls: isPlaying
              ? [MediaControl.pause, MediaControl.stop]
              : [MediaControl.play, MediaControl.stop],
          speed: 1.0,
        ),
      );
    }
  }

  Future<void> setVolume(double volume) async {
    // MediaKit volume is 0.0 to 100.0, AudioPlayers was 0.0 to 1.0
    await _player.setVolume(volume * 100.0);
  }
}
