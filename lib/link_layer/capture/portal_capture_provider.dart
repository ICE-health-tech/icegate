import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/link_layer/capture/capture_provider.dart';

/// Cross-app capture on Linux via the XDG desktop portal
/// (org.freedesktop.portal.Screenshot).
///
/// The portal is the correct path under Wayland, where unrestricted root-window
/// capture is blocked by design: the portal may prompt the user, and may
/// decline. A decline is a normal no-capture, never an error.
///
/// Returns isSupported == false on every other platform.
class PortalCaptureProvider implements CaptureProvider {
  static const MethodChannel _channel = MethodChannel('duylong.art/portal');

  @override
  CaptureSourceKind get kind => CaptureSourceKind.linuxPortal;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// The portal does not require a separate consent call: the screenshot
  /// request itself is the consent prompt.
  @override
  Future<bool> requestConsent() async => isSupported;

  @override
  Future<CaptureResult?> capture() async {
    if (!isSupported) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('capture');
      if (result == null) return null;

      final bytes = result['bytes'];
      if (bytes is! Uint8List || bytes.isEmpty) return null;

      return CaptureResult(
        pngBytes: bytes,
        sourceKind: CaptureSourceKind.linuxPortal,
        // The portal returns pixels only, not the owning window's identity.
        appLabel: 'unknown_app',
        route: null,
      );
    } on PlatformException catch (e) {
      // Includes the user dismissing the portal dialog.
      debugPrint('PortalCapture: capture unavailable — ${e.message}');
      return null;
    } on MissingPluginException {
      // No portal daemon (bare X11 without the portal service).
      return null;
    }
  }
}
