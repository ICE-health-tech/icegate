import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ice_music_platform_interface.dart';

/// An implementation of [IceMusicPlatform] that uses method channels.
class MethodChannelIceMusic extends IceMusicPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ice_music');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
