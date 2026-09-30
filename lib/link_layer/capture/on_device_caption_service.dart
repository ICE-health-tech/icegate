import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// On-device image captioning via Apple's Foundation Models (iOS 26+,
/// A17 Pro / M-series silicon).
///
/// This is the iOS path for turning a captured screen into memory text. iOS
/// exposes no API to capture other apps' pixels, so the only frames available
/// are the app's own — and captioning those locally means no screenshot leaves
/// the device on iOS.
///
/// Every method is a safe no-op on unsupported devices: [isAvailable] returns
/// false and [caption] returns null rather than throwing, so callers can use
/// it unconditionally and fall back to the remote agent.
class OnDeviceCaptionService {
  static const MethodChannel _channel = MethodChannel(
    'duylong.art/ondevice_caption',
  );

  /// True when the OS and device both support on-device captioning.
  static Future<bool> isAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException catch (e) {
      debugPrint('OnDeviceCaptionService: availability check failed — $e');
      return false;
    } on MissingPluginException {
      // Native plugin not linked (e.g. a test or a stripped build).
      return false;
    }
  }

  /// Captions the image at [path]. Returns null when on-device captioning is
  /// unavailable or the model fails — callers should fall back to the agent.
  static Future<String?> caption(String path) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    if (!File(path).existsSync()) return null;
    try {
      return await _channel.invokeMethod<String>('caption', {'path': path});
    } on PlatformException catch (e) {
      debugPrint('OnDeviceCaptionService: caption failed — ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Captions if possible, otherwise reports that the caller needs the remote
  /// agent path. Keeps the fallback decision in one place.
  static Future<OnDeviceCaptionResult> captionOrSignalFallback(
    String path,
  ) async {
    if (!await isAvailable()) {
      return const OnDeviceCaptionResult.unavailable();
    }
    final text = await caption(path);
    if (text == null || text.trim().isEmpty) {
      return const OnDeviceCaptionResult.failed();
    }
    return OnDeviceCaptionResult.success(text.trim());
  }
}

class OnDeviceCaptionResult {
  final String? caption;
  final bool available;
  final bool failed;

  const OnDeviceCaptionResult.success(String this.caption)
    : available = true,
      failed = false;

  const OnDeviceCaptionResult.unavailable()
    : caption = null,
      available = false,
      failed = false;

  const OnDeviceCaptionResult.failed()
    : caption = null,
      available = true,
      failed = true;

  bool get hasCaption => caption != null;
}
