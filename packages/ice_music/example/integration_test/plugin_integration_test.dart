// Integration test for the pure-Dart ice_music service.
//
// ice_music is no longer a method-channel plugin, so there is no host side to
// talk to: this exercises the singleton and its playback state transitions
// against the real audioplayers plugin running in the host app.

import 'package:flutter_test/flutter_test.dart';
import 'package:ice_music/ice_music.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('instance is a singleton', (WidgetTester tester) async {
    expect(IceMusic.instance, same(IceMusic.instance));
  });

  testWidgets('currentAsset tracks play then stop', (
    WidgetTester tester,
  ) async {
    final music = IceMusic.instance;

    await music.playLoopAsset('assets/audio/bgm.mp3', volume: 0.1);
    expect(music.currentAsset, 'assets/audio/bgm.mp3');

    await music.stop();
    expect(music.currentAsset, isNull);
  });
}