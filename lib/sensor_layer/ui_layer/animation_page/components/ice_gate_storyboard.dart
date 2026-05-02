import 'package:flutter/material.dart';

import 'entry_constants.dart';

// -----------------------------------------------------------------------------
// Ice Gate — 10-frame exit storyboard (design ↔ code / Rive)
//
// Map ONE master progress `t` in [0, 1] across the whole exit. Each frame gets a
// sub-interval; use localProgress(t, frame) for that frame’s 0→1 curve inside Rive
// state machine or CustomPainter.
//
// Rive: one Timeline with markers at boundaryFractions[i], or boolean gates
// phaseAt(t) == IceGateExitPhase.impact, etc.
//
// Flutter: AnimationController(duration: 3s).drive(Tween(begin: 0, end: 1));
//          IceGateStoryboard.localProgress(controller.value, IceGateExitPhase.web)
// -----------------------------------------------------------------------------

/// Exit phases aligned with the 10-key storyboard (Frame 1 = seed at t≈0).
enum IceGateExitPhase {
  /// Frame 1 — total darkness; single pin cyan pixel (optional flash before charge).
  seed,

  /// Frame 2 — soft pulsing radial glow; navy + neon cyan.
  charge,

  /// Frame 3 — first 3–4 primary cracks; sharp white, toward center.
  impact,

  /// Frame 4 — more radials (8–12), ~halfway to corners.
  bloom,

  /// Frame 5 — radials to edges; starburst.
  fullRadial,

  /// Frame 6 — first inner ring connects radials (small polygon).
  ring,

  /// Frame 7 — two more rings; spider web / shattered glass lattice.
  web,

  /// Frame 8 — lines brighten / vibrate; hairline secondary cracks.
  stress,

  /// Frame 9 — polygons separate; triangular shards move outward.
  shatter,

  /// Frame 10 — shards fly past camera (scale > 2×); fade to dashboard.
  reveal,
}

/// Boundaries on [0, 1] — `boundaryFractions[i]` is the **end** of phase `i`
/// (phase index matches [IceGateExitPhase.values] order).
abstract final class IceGateStoryboard {
  /// Monotonic increasing; last element is 1.0.
  static const List<double> boundaryFractions = <double>[
    0.04, // end seed
    0.12, // end charge
    0.18, // end impact
    0.30, // end bloom
    0.42, // end fullRadial
    0.52, // end ring
    0.64, // end web
    0.74, // end stress
    0.88, // end shatter
    1.00, // end reveal
  ];

  static IceGateExitPhase phaseAt(double t) {
    final x = t.clamp(0.0, 1.0);
    for (var i = 0; i < boundaryFractions.length; i++) {
      if (x <= boundaryFractions[i]) {
        return IceGateExitPhase.values[i];
      }
    }
    return IceGateExitPhase.reveal;
  }

  /// Local 0→1 progress **within** [phase], given global `t`.
  static double localProgress(double t, IceGateExitPhase phase) {
    final x = t.clamp(0.0, 1.0);
    final i = phase.index;
    final start = i == 0 ? 0.0 : boundaryFractions[i - 1];
    final end = boundaryFractions[i];
    if (end <= start) return 0.0;
    return ((x - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Whether global `t` lies inside [phase]’s interval.
  static bool isInPhase(double t, IceGateExitPhase phase) {
    return phaseAt(t) == phase;
  }
}

/// Frame 1 — single cyan “pin” (use sized ~2–4 logical px).
class IceGateSeedDot extends StatelessWidget {
  const IceGateSeedDot({super.key, this.size = 3});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: EntryColors.iceCyan,
            boxShadow: [
              BoxShadow(
                color: EntryColors.iceCyan.withValues(alpha: 0.85),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
