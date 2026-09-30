import 'dart:typed_data';

/// Where a captured frame came from.
enum CaptureSourceKind {
  /// RepaintBoundary of our own widget tree. Works on every platform.
  inApp,

  /// Android MediaProjection virtual display. Requires per-session consent.
  androidProjection,

  /// Linux xdg-desktop-portal screenshot.
  linuxPortal;

  String get wireName => switch (this) {
    inApp => 'in_app',
    androidProjection => 'android_projection',
    linuxPortal => 'linux_portal',
  };
}

/// A single captured frame plus enough provenance to score and store it.
class CaptureResult {
  final Uint8List pngBytes;
  final CaptureSourceKind sourceKind;

  /// Foreground app name; equals the route for in-app captures.
  final String appLabel;
  final String? route;
  final int? width;
  final int? height;

  const CaptureResult({
    required this.pngBytes,
    required this.sourceKind,
    required this.appLabel,
    this.route,
    this.width,
    this.height,
  });
}

/// Platform capture strategy.
///
/// [isSupported] gates registration so the job degrades to a no-op on
/// platforms that cannot provide a given source, rather than throwing. iOS in
/// particular cannot capture other apps at all — no API exists for it — so
/// only [CaptureSourceKind.inApp] is available there.
abstract class CaptureProvider {
  CaptureSourceKind get kind;

  /// False when this platform cannot provide this source. Checked before
  /// consent or capture is attempted.
  bool get isSupported;

  /// Asks the OS for permission. Returns false if declined. On Android
  /// MediaProjection this must be re-requested every cold start — the grant
  /// cannot be persisted across reboot or app restart.
  Future<bool> requestConsent();

  /// Captures one frame, or null if the user declined, no frame was
  /// available, or the platform declined the request. A null return is a
  /// normal outcome, never an error.
  Future<CaptureResult?> capture();
}
