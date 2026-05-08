
import 'package:audioplayers/audioplayers.dart';

/// Global background music service (keeps playing across navigation).
///
/// This is a pure-Dart service (no native platform channels needed).
class IceMusic {
  IceMusic._();
  static final IceMusic instance = IceMusic._();

  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

  String? _currentAsset;
  String? get currentAsset => _currentAsset;

  Future<void> playLoopAsset(
    String asset, {
    double volume = 0.25,
  }) async {
    _currentAsset = asset;
    await _player.setVolume(volume);
    await _player.play(AssetSource(asset));
  }

  Future<void> stop() async {
    _currentAsset = null;
    await _player.stop();
  }
}
