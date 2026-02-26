import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

class FocusAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  // Internal player for actual sound playback
  final AudioPlayer _player = AudioPlayer();

  // Back-reference to the block to sync state
  dynamic _focusBlock;
  set focusBlock(dynamic block) => _focusBlock = block;

  FocusAudioHandler() {
    _player.setReleaseMode(ReleaseMode.loop);
    print("🎧 [AudioHandler-${identityHashCode(this)}] Initialized");
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

  Future<void> setSource(Source source) async {
    await _player.setSource(source);
  }

  @override
  Future<void> play() async {
    print("🎧 [AudioHandler-${identityHashCode(this)}] play() received");
    // 1. Update State FIRST to responsive UI
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: [MediaControl.pause, MediaControl.stop],
        processingState: AudioProcessingState.ready,
        speed: 1.0,
      ),
    );

    // 2. Try to play actual audio (if source is valid)
    try {
      await _player.resume();
    } catch (e) {
      print(
        "FocusAudioHandler: Internal player resume failed (Source might be empty): $e",
      );
      // Don't revert state; we want "silent playback" to continue for lock screen controls
    }

    // 3. Sync back to block
    try {
      _focusBlock?.startTimer(fromSystem: true);
    } catch (e) {
      print("FocusAudioHandler: Error syncing play: $e");
    }
  }

  @override
  Future<void> pause() async {
    print("⏸️ [AudioHandler-${identityHashCode(this)}] pause() received");
    // 1. Update State FIRST
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: [MediaControl.play, MediaControl.stop],
      ),
    );

    // 2. Try to pause actual audio
    try {
      await _player.pause();
    } catch (e) {
      print("FocusAudioHandler: Internal player pause failed: $e");
    }

    // 3. Sync back to block
    try {
      _focusBlock?.pauseTimer(fromSystem: true);
    } catch (e) {
      print("FocusAudioHandler: Error syncing pause: $e");
    }
  }

  @override
  Future<void> stop() async {
    print("🛑 [AudioHandler-${identityHashCode(this)}] stop() received");
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
        controls: [MediaControl.play, MediaControl.stop],
      ),
    );

    // Sync back to block
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
    print(
      "FocusAudioHandler: updateMetadata - $title, $artist, playing: $playing, dur: $duration, pos: $position",
    );

    // Update MediaItem (Static info)
    mediaItem.add(
      MediaItem(
        id: 'focus_session',
        album: 'ICE Gate Focus',
        title: title,
        artist: artist,
        duration: duration,
      ),
    );

    // Update PlaybackState (Dynamic info)
    final isPlaying = playing ?? playbackState.value.playing;

    // Check if we actually need to update the playback state.
    // Constantly updating playbackState with new updatePosition causes "snapping"
    // because the app's clock might be slightly behind the system's interpolated clock.
    final bool stateChanged = isPlaying != playbackState.value.playing;

    // Remove the 3-second guard to allow second-by-second updates for the timer
    if (stateChanged || position != null) {
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
          queueIndex: 0,
        ),
      );
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}
