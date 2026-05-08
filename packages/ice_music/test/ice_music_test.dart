import 'package:flutter_test/flutter_test.dart';
import 'package:ice_music/ice_music.dart';
import 'package:ice_music/ice_music_platform_interface.dart';
import 'package:ice_music/ice_music_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIceMusicPlatform
    with MockPlatformInterfaceMixin
    implements IceMusicPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IceMusicPlatform initialPlatform = IceMusicPlatform.instance;

  test('$MethodChannelIceMusic is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIceMusic>());
  });

  test('getPlatformVersion', () async {
    IceMusic iceMusicPlugin = IceMusic();
    MockIceMusicPlatform fakePlatform = MockIceMusicPlatform();
    IceMusicPlatform.instance = fakePlatform;

    expect(await iceMusicPlugin.getPlatformVersion(), '42');
  });
}
