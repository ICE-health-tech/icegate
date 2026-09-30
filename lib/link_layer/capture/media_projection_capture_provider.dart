import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/link_layer/capture/capture_provider.dart';

/// Cross-app capture on Android via MediaProjection.
///
/// The only supported way to read another app's pixels on Android. The system
/// consent dialog cannot be persisted, so [requestConsent] must succeed on
/// every cold start; a declined or revoked grant makes [capture] return null
/// rather than retry.
///
/// Returns isSupported == false on every other platform, so callers can
/// register it unconditionally.
class MediaProjectionCaptureProvider implements CaptureProvider {
  static const MethodChannel _channel = MethodChannel(
    'duylong.art/mediaprojection',
  );

  /// Label recorded when the foreground app cannot be determined; MediaProjection
  /// returns pixels only, not the owning app's identity.
  static const String unknownAppLabel = 'unknown_app';

  @override
  CaptureSourceKind get kind => CaptureSourceKind.androidProjection;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> requestConsent() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestConsent') ?? false;
    } on PlatformException catch (e) {
      debugPrint('MediaProjection: consent request failed — ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<CaptureResult?> capture() async {
    if (!isSupported) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('capture');
      if (result == null) return null;

      final encoded = result['bytes'] as String?;
      if (encoded == null || encoded.isEmpty) return null;

      return CaptureResult(
        pngBytes: Uint8List.fromList(base64Decode(encoded)),
        sourceKind: CaptureSourceKind.androidProjection,
        appLabel: unknownAppLabel,
        route: null,
        width: result['width'] as int?,
        height: result['height'] as int?,
      );
    } on PlatformException catch (e) {
      debugPrint('MediaProjection: capture failed — ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
