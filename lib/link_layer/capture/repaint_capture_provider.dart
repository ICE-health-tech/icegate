import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ice_gate/link_layer/capture/capture_provider.dart';

/// Captures the app's own widget tree via [RepaintBoundary.toImage].
///
/// This is the only provider that works on iOS, because iOS exposes no API to
/// read another app's pixels.
///
/// Capture requirements that are easy to get wrong:
///  - the boundary must already be laid out and painted, so [capture] waits a
///    frame before converting;
///  - capturing the root boundary usually fails or yields a blank/oversized
///    image, so a dedicated boundary with a known key is required;
///  - pixelRatio is clamped, because devicePixelRatio on high-density iOS
///    screens produces very large PNGs.
class RepaintCaptureProvider implements CaptureProvider {
  /// Caps output size; devicePixelRatio on a 3x iOS screen gives large PNGs.
  static const double maxPixelRatio = 3.0;

  final GlobalKey repaintBoundaryKey;
  final String? route;

  RepaintCaptureProvider({required this.repaintBoundaryKey, this.route});

  @override
  CaptureSourceKind get kind => CaptureSourceKind.inApp;

  @override
  bool get isSupported => true;

  /// Nothing to request: capturing our own widget tree needs no permission.
  @override
  Future<bool> requestConsent() async => true;

  @override
  Future<CaptureResult?> capture() async {
    final context = repaintBoundaryKey.currentContext;
    if (context == null) return null;

    final boundary =
        context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // toImage throws if the boundary is mid-composite or not yet painted.
    try {
      await Future<void>.delayed(Duration.zero);
      if (!boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }

      final dpr = View.of(context).devicePixelRatio;
      final ui.Image image = await boundary.toImage(
        pixelRatio: dpr.clamp(1.0, maxPixelRatio),
      );

      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final int width = image.width;
      final int height = image.height;
      image.dispose();

      if (data == null) return null;

      return CaptureResult(
        pngBytes: data.buffer.asUint8List(),
        sourceKind: CaptureSourceKind.inApp,
        appLabel: route ?? 'ice_gate',
        route: route,
        width: width,
        height: height,
      );
    } catch (_) {
      // A failed capture is a normal outcome (route changed, boundary
      // detached). Never surface as an error to the user.
      return null;
    }
  }
}
