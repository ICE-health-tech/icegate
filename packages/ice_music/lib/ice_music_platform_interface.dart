import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ice_music_method_channel.dart';

abstract class IceMusicPlatform extends PlatformInterface {
  /// Constructs a IceMusicPlatform.
  IceMusicPlatform() : super(token: _token);

  static final Object _token = Object();

  static IceMusicPlatform _instance = MethodChannelIceMusic();

  /// The default instance of [IceMusicPlatform] to use.
  ///
  /// Defaults to [MethodChannelIceMusic].
  static IceMusicPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IceMusicPlatform] when
  /// they register themselves.
  static set instance(IceMusicPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
