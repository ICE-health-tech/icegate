import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'entry_constants.dart';

// --- Models ---

class PrismShard {
  final Offset startOffset;
  final Offset targetOffset;
  final double size;
  final Color color;
  final double rotation;
  final double delay;
  final double speed;

  /// Hexagonal “ice flake”; otherwise classic triangular shard (vụn kính → bông tuyết/băng).
  final bool isIceFlake;

  PrismShard({
    required this.startOffset,
    required this.targetOffset,
    required this.size,
    required this.color,
    required this.rotation,
    required this.delay,
    required this.speed,
    this.isIceFlake = false,
  });
}

class FlowerPetalData {
  final int flowerIndex;
  final Offset centerOffset;
  final double angle;
  final double size;
  final double opacity;
  final Color color;
  final double rotationOffset;
  FlowerPetalData({
    required this.flowerIndex,
    required this.centerOffset,
    required this.angle,
    required this.size,
    required this.opacity,
    required this.color,
    required this.rotationOffset,
  });
}

/// Role in the ice-gate sequence: inward radials first, then ring chords, then capillary frost.
enum IceCrackRole { primaryInward, circumferentialRing, capillary }

class GlassCrackData {
  final List<Offset> points;
  /// Path order: **outer edge first → center** so partial growth "zips" toward the impact.
  final bool growsFromEdge;
  /// Thicker at the start of the path (edge) and needle-thin at the end (center).
  final bool tapered;
  final IceCrackRole role;
  /// For [IceCrackRole.circumferentialRing]: 0 = inner polygon first, higher = outer (staggered wave).
  final double ringStagger;

  GlassCrackData({
    required this.points,
    this.growsFromEdge = false,
    this.tapered = false,
    this.role = IceCrackRole.primaryInward,
    this.ringStagger = 0.0,
  });
}

enum ParticleTier { large, dust, shrapnel }

class ScatteringParticleData {
  final double angle;
  final double velocity;
  final List<Offset> points;
  final double rotationSpeed;
  final Color color;
  final double delay;
  final double initialDistance;
  final double distRank; // Normalized distance (0-1) for wave effects
  final ParticleTier tier;
  final double noiseSeed; // For unique turbulence paths

  ScatteringParticleData({
    required this.angle,
    required this.velocity,
    required this.points,
    required this.rotationSpeed,
    required this.color,
    required this.delay,
    this.initialDistance = 0.0,
    this.distRank = 0.0,
    this.tier = ParticleTier.large,
    this.noiseSeed = 0.0,
  });
}

// --- Painters ---

// --------------------------------------------------------------------------
// BROKEN GLASS PANE MODEL (ICE-SHARP EDITION)
// Generates irregular, sharp-edged ice shard polygons via Voronoi + edge notching.
// --------------------------------------------------------------------------
class BrokenGlassPaneData {
  final List<Offset> polygon; // normalized 0-1 vertices (already jagged)
  final Offset centroid;
  final Offset slideDir;
  final double tiltAxis;
  final double speed;
  final double delay;
  final double shimmerAngle;
  // Pre-baked interior facet lines (normalized, relative to centroid)
  final List<(Offset, Offset)> facetLines;
  final List<Offset> frostPoints;
  final Offset sharpTip;

  BrokenGlassPaneData({
    required this.polygon,
    required this.centroid,
    required this.slideDir,
    required this.tiltAxis,
    required this.speed,
    required this.delay,
    required this.shimmerAngle,
    required this.facetLines,
    required this.frostPoints,
    required this.sharpTip,
  });

  static List<BrokenGlassPaneData> generate({int seed = 42}) {
    final rng = math.Random(seed);

    // --- Seed points: mix of random + structured grid for nice coverage ---
    const int seedCount = 22;
    final seeds = List.generate(
      seedCount,
      (_) => Offset(rng.nextDouble(), rng.nextDouble()),
    );
    final corners = [
      const Offset(0.0, 0.0),
      const Offset(1.0, 0.0),
      const Offset(1.0, 1.0),
      const Offset(0.0, 1.0),
      const Offset(0.5, 0.0),
      const Offset(0.5, 1.0),
      const Offset(0.0, 0.5),
      const Offset(1.0, 0.5),
      const Offset(0.25, 0.25),
      const Offset(0.75, 0.25),
      const Offset(0.25, 0.75),
      const Offset(0.75, 0.75),
    ];
    final allSeeds = [...corners, ...seeds];

    // --- Voronoi approximation via 80×80 grid ---
    const int gridRes = 80;
    final Map<int, List<Offset>> regionSamples = {};
    for (int r = 0; r < gridRes; r++) {
      for (int c = 0; c < gridRes; c++) {
        final pt = Offset((c + 0.5) / gridRes, (r + 0.5) / gridRes);
        int nearest = 0;
        double best = double.infinity;
        for (int k = 0; k < allSeeds.length; k++) {
          final d = (pt - allSeeds[k]).distanceSquared;
          if (d < best) {
            best = d;
            nearest = k;
          }
        }
        regionSamples.putIfAbsent(nearest, () => []).add(pt);
      }
    }

    return regionSamples.entries
        .map((entry) {
          final pts = entry.value;
          if (pts.length < 3) return null;

          final hull = _convexHull(pts);
          if (hull.length < 3) return null;

          // --- Centroid ---
          double cx = 0, cy = 0;
          for (final p in hull) {
            cx += p.dx;
            cy += p.dy;
          }
          cx /= hull.length;
          cy /= hull.length;
          final centroid = Offset(cx, cy);

          // --- JAGGED NOTCHING: bisect each hull edge and push midpoint inward ---
          // This creates the sharp angular "broken ice" silhouette
          final jagged = <Offset>[];
          for (int i = 0; i < hull.length; i++) {
            final a = hull[i];
            final b = hull[(i + 1) % hull.length];
            jagged.add(a);

            // Midpoint of edge
            final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
            // Direction toward centroid (inward)
            final toCentre = Offset(cx - mid.dx, cy - mid.dy);
            final len = toCentre.distance;
            if (len > 0.001) {
              // Notch depth: 5-25% of centroid distance, randomised per edge
              final notchDepth = (0.05 + rng.nextDouble() * 0.20) * len;
              // Also add lateral jitter for a more chaotic ice feel
              final perp = Offset(-toCentre.dy / len, toCentre.dx / len);
              final lateralJitter = (rng.nextDouble() - 0.5) * 0.015;
              jagged.add(
                Offset(
                  mid.dx +
                      (toCentre.dx / len) * notchDepth +
                      perp.dx * lateralJitter,
                  mid.dy +
                      (toCentre.dy / len) * notchDepth +
                      perp.dy * lateralJitter,
                ),
              );
            }
          }

          // --- Interior facet lines (1-3 diagonal streaks across the pane) ---
          final facetLines = <(Offset, Offset)>[];
          final facetCount = 1 + rng.nextInt(2);
          for (int f = 0; f < facetCount; f++) {
            final angle = _randShimmerAngle(rng) + f * math.pi / 3;
            final r1 = 0.03 + rng.nextDouble() * 0.12;
            final r2 = 0.03 + rng.nextDouble() * 0.12;
            facetLines.add((
              Offset(cx + math.cos(angle) * r1, cy + math.sin(angle) * r1),
              Offset(
                cx + math.cos(angle + math.pi) * r2,
                cy + math.sin(angle + math.pi) * r2,
              ),
            ));
          }

          // --- Internal Frost Points ---
          final frostPoints = <Offset>[];
          final frostCount = 5 + rng.nextInt(15);
          for (int i = 0; i < frostCount; i++) {
            // Randomly pick a point from the grid samples that belongs to this region
            frostPoints.add(pts[rng.nextInt(pts.length)]);
          }

          // --- Physics ---
          final fromCenter = centroid - const Offset(0.5, 0.5);
          final dist = fromCenter.distance;
          final dir = dist > 0.01
              ? Offset(fromCenter.dx / dist, fromCenter.dy / dist)
              : Offset(rng.nextDouble() * 2 - 1, rng.nextDouble() * 2 - 1);
          final slideDir = Offset(dir.dx * 0.7, dir.dy * 0.7 + 0.35);

          // Identify "sharpTip" (vertex closest to impact center (0.5, 0.5))
          Offset sharpTip = jagged[0];
          double minDistToCenter = double.infinity;
          for (final v in jagged) {
            final d = (v - const Offset(0.5, 0.5)).distanceSquared;
            if (d < minDistToCenter) {
              minDistToCenter = d;
              sharpTip = v;
            }
          }

          return BrokenGlassPaneData(
            polygon: jagged,
            centroid: centroid,
            slideDir: slideDir,
            tiltAxis: (rng.nextDouble() - 0.5) * math.pi * 0.6,
            speed: 0.55 + rng.nextDouble() * 0.45,
            delay: rng.nextDouble() * 0.30,
            shimmerAngle: rng.nextDouble() * math.pi,
            facetLines: facetLines,
            frostPoints: frostPoints,
            sharpTip: sharpTip,
          );
        })
        .whereType<BrokenGlassPaneData>()
        .toList();
  }

  static double _randShimmerAngle(math.Random rng) =>
      rng.nextDouble() * math.pi;

  static List<Offset> _convexHull(List<Offset> pts) {
    if (pts.length < 3) return pts;
    final sorted = [...pts]
      ..sort((a, b) {
        if (a.dx != b.dx) return a.dx.compareTo(b.dx);
        return a.dy.compareTo(b.dy);
      });

    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

    final lower = <Offset>[];
    for (final p in sorted) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <Offset>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    upper.removeLast();
    lower.removeLast();
    return [...lower, ...upper];
  }
}

// --------------------------------------------------------------------------
// BROKEN GLASS PANE PAINTER — ICE SHARD EDITION
//
// Visual language: thin, nearly transparent body · concentrated edge glow
// with sharp specular · interior facet streaks · hot-white glint points.
// --------------------------------------------------------------------------
class BrokenGlassPanePainter extends CustomPainter {
  final double progress;
  final List<BrokenGlassPaneData> panes;
  final Offset pointerOffset;

  BrokenGlassPanePainter({
    required this.progress,
    required this.panes,
    required this.pointerOffset,
  });

  // Ice color palette
  static const Color _iceWhite = Color(0xFFE8F4FF);
  static const Color _iceCyan = Color(0xFF88CCEE);
  static const Color _iceDeep = Color(0xFF3A7ABF);
  static const Color _hotGlint = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || panes.isEmpty) return;

    for (final pane in panes) {
      final double localProgress =
          ((progress - pane.delay) / (1.0 - pane.delay * 0.5)).clamp(0.0, 1.0) *
          pane.speed;
      if (localProgress <= 0) continue;

      final double ease = Curves.easeInCubic.transform(
        (localProgress / pane.speed).clamp(0.0, 1.0),
      );

      // Opacity: sharp snap-in, long visible, quick fade-out
      final double opacity =
          (localProgress < 0.12
                  ? localProgress /
                        0.12 // fast snap-in
                  : 1.0 - (localProgress - 0.12) / 0.88)
              .clamp(0.0, 1.0);
      if (opacity <= 0.005) continue;

      // --- Transform: slide + tilt around centroid ---
      final double cx = pane.centroid.dx * size.width;
      final double cy = pane.centroid.dy * size.height;
      final double travel = ease * size.height * 0.70;

      // --- RADIAL ALIGNMENT: Point sharpTip to center ---
      // We calculate the pivot needed so the pane's inner tip faces (0.5, 0.5)
      final double targetAngle = math.atan2(
        0.5 - pane.centroid.dy,
        0.5 - pane.centroid.dx,
      );
      final double currentTipAngle = math.atan2(
        pane.sharpTip.dy - pane.centroid.dy,
        pane.sharpTip.dx - pane.centroid.dx,
      );
      // STRICT ALIGNMENT: No ease here, they should be pointed from the moment they break
      final double alignmentRotation = (targetAngle - currentTipAngle);

      canvas.save();
      canvas.translate(
        cx + pane.slideDir.dx * travel,
        cy + pane.slideDir.dy * travel,
      );
      // Combine radial alignment with zero random deviation for a clean "point-to-center" look
      canvas.rotate(alignmentRotation);
      canvas.translate(-cx, -cy);

      // --- Build sharp polygon path ---
      final path = Path();
      for (int i = 0; i < pane.polygon.length; i++) {
        final v = pane.polygon[i];
        final sx = v.dx * size.width;
        final sy = v.dy * size.height;
        if (i == 0) {
          path.moveTo(sx, sy);
        } else {
          path.lineTo(sx, sy);
        }
      }
      path.close();
      final bounds = path.getBounds();

      // Light direction influenced by pointer for parallax shimmer
      final double lx = math.cos(pane.shimmerAngle + pointerOffset.dx * 2.0);
      final double ly = math.sin(pane.shimmerAngle + pointerOffset.dy * 2.0);

      // ==================================================================
      // PASS 1: Thin ice-body fill — nearly transparent, strong at edges
      // Real ice is clear; colour lives at thickness/edges, not the face.
      // ==================================================================
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(lx - 0.5, ly - 0.5),
            end: Alignment(-lx + 0.5, -ly + 0.5),
            colors: [
              _iceWhite.withValues(alpha: opacity * 0.22), // bright face
              _iceCyan.withValues(alpha: opacity * 0.08), // mid
              _iceDeep.withValues(alpha: opacity * 0.04), // deep shadow
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds)
          ..style = PaintingStyle.fill,
      );

      // ==================================================================
      // PASS 2: Outer edge — sharper frosted bloom
      // ==================================================================
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = _iceCyan.withValues(alpha: opacity * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.butt,
      );

      // ==================================================================
      // PASS 3: Razor specular edge
      // ==================================================================
      canvas.drawPath(
        path,
        Paint()
          ..color = _hotGlint.withValues(alpha: opacity * 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..strokeCap = StrokeCap.butt,
      );

      // ==================================================================
      // PASS 4: Second inner specular trace — offset 1px inward simulation
      // Gives the double-edge look of thick broken glass.
      // ==================================================================
      // We approximate with a slightly smaller path (scale around centroid)
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(0.96, 0.96);
      canvas.translate(-cx, -cy);
      canvas.drawPath(
        path,
        Paint()
          ..color = _iceCyan.withValues(alpha: opacity * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4
          ..strokeCap = StrokeCap.butt,
      );
      canvas.restore();

      // ==================================================================
      // PASS 5: Interior ice facet streaks
      // Diagonal white lines across the shard — internal light reflecting
      // through anisotropic ice crystal structure.
      // ==================================================================
      for (final facet in pane.facetLines) {
        final p1 = Offset(facet.$1.dx * size.width, facet.$1.dy * size.height);
        final p2 = Offset(facet.$2.dx * size.width, facet.$2.dy * size.height);

        // Only draw if both endpoints are roughly inside bounds
        if (!bounds.inflate(20).contains(p1) &&
            !bounds.inflate(20).contains(p2)) {
          continue;
        }

        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = _hotGlint.withValues(alpha: opacity * 0.30)
            ..strokeWidth = 0.6
            ..strokeCap = StrokeCap.butt,
        );
        // Soft glow version underneath
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = _iceWhite.withValues(alpha: opacity * 0.12)
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // ==================================================================
      // PASS 6: Internal Frost & Rainbow Glints
      // ==================================================================
      for (final fp in pane.frostPoints) {
        final fpx = fp.dx * size.width;
        final fpy = fp.dy * size.height;

        final double shimmer =
            (math.sin(progress * 15 + fp.dx * 100) + 1.0) / 2.0;
        if (shimmer > 0.7) {
          canvas.drawCircle(
            Offset(fpx, fpy),
            0.8 * shimmer,
            Paint()..color = Colors.white.withValues(alpha: opacity * shimmer),
          );
        }
      }

      // ==================================================================
      // PASS 7: Hot-white glint point at the sharpest vertex
      // ==================================================================
      Offset? sharpTip;
      double maxDist = 0;
      for (final v in pane.polygon) {
        final d = (v - pane.centroid).distanceSquared;
        if (d > maxDist) {
          maxDist = d;
          sharpTip = v;
        }
      }
      if (sharpTip != null) {
        final tipSx = sharpTip.dx * size.width;
        final tipSy = sharpTip.dy * size.height;
        // Soft halo
        canvas.drawCircle(
          Offset(tipSx, tipSy),
          6,
          Paint()
            ..color = _hotGlint.withValues(alpha: opacity * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        // Sharp pinpoint
        canvas.drawCircle(
          Offset(tipSx, tipSy),
          1.2,
          Paint()..color = _hotGlint.withValues(alpha: opacity * 0.9),
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(BrokenGlassPanePainter old) =>
      old.progress != progress || old.pointerOffset != pointerOffset;
}

class SymmetricPetalPainter extends CustomPainter {
  final Color color;
  final double pulse;
  final double transformProgress;

  SymmetricPetalPainter({
    required this.color,
    required this.pulse,
    this.transformProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // SCALE DOWN to 45% to ensure the logo is compact and premium
    const double viewScale = 0.45;

    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.width / 2) * viewScale;

    // 1. DRAW 4-SHARD CRYSTALLINE STRUCTURE
    const int shardCount = 4;
    for (int i = 0; i < shardCount; i++) {
      final double angle = (i * 90) * math.pi / 180;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      _drawCrystallineShard(canvas, r, pulse);

      canvas.restore();
    }

    // 3. DRAW RADIANT CORE (Soft white glow from image)
    _drawPremiumCore(canvas, center, r * 0.2, r, pulse);
  }

  void _drawCrystallineShard(Canvas canvas, double r, double pulse) {
    // Dynamic geometry based on pulse
    final double shardWidth = r * (0.35 + (pulse * 0.05));
    final double shoulderY = -r * 0.4;
    final double tipY =
        -r * (1.15 + (pulse * 0.08) + (transformProgress * 0.25));
    final double innerNotchY = -r * 0.12;
    final double baseWidth = shardWidth * 0.25;

    // LEFT FACET PATH
    final leftFacetPath = Path()
      ..moveTo(0, innerNotchY)
      ..lineTo(-baseWidth, 0)
      ..lineTo(-shardWidth * 0.5, shoulderY)
      ..lineTo(0, tipY)
      ..close();

    // RIGHT FACET PATH
    final rightFacetPath = Path()
      ..moveTo(0, innerNotchY)
      ..lineTo(baseWidth, 0)
      ..lineTo(shardWidth * 0.5, shoulderY)
      ..lineTo(0, tipY)
      ..close();

    // LEFT SHADING (Lighter, catching "light")
    final leftPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(-shardWidth * 0.5, shoulderY),
        Offset(0, tipY),
        [
          Colors.white.withValues(alpha: 0.95),
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.2),
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;

    // RIGHT SHADING (Deeper blue, depth)
    final rightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(shardWidth * 0.5, shoulderY),
        Offset(0, tipY),
        [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0.1),
        ],
        [0.0, 0.6, 1.0],
      )
      ..style = PaintingStyle.fill;

    // RIDGE & EDGE HIGHLIGHTS
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 + (pulse * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeJoin = StrokeJoin.round;

    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 + (pulse * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    // DRAW FACETS
    canvas.drawPath(leftFacetPath, leftPaint);
    canvas.drawPath(rightFacetPath, rightPaint);

    // DRAW OUTLINES
    canvas.drawPath(leftFacetPath, strokePaint);
    canvas.drawPath(rightFacetPath, strokePaint);

    // DRAW CENTRAL RIDGE
    canvas.drawLine(Offset(0, innerNotchY), Offset(0, tipY), ridgePaint);

    // --- CRACKER TEXTURE: POROUS PITS ---
    _drawCrackerPits(canvas, leftFacetPath, isLeft: true);
    _drawCrackerPits(canvas, rightFacetPath, isLeft: false);

    // INNER GLINT (Sparkle effect)
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 + (pulse * 0.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(0, shoulderY), shardWidth * 0.2, glintPaint);
  }

  void _drawCrackerPits(Canvas canvas, Path path, {required bool isLeft}) {
    // Deterministic random for consistent pit placement
    final math.Random pitRandom = math.Random(isLeft ? 42 : 1337);
    final pitPaint = Paint()
      ..color = EntryColors.pitShadow.withValues(
        alpha: 0.4 * (1.1 - transformProgress),
      )
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 * (1.1 - transformProgress))
      ..style = PaintingStyle.fill;

    final bounds = path.getBounds();
    // Increase density to match the high-fidelity cracker image
    for (int i = 0; i < 15; i++) {
      final px = bounds.left + pitRandom.nextDouble() * bounds.width;
      final py = bounds.top + pitRandom.nextDouble() * bounds.height;
      final pos = Offset(px, py);

      if (path.contains(pos)) {
        final double pitSize = 0.8 + pitRandom.nextDouble() * 1.2;
        // Deep pit shadow
        canvas.drawCircle(pos, pitSize, pitPaint);
        // Rim highlight to give 3D depth
        canvas.drawCircle(
          pos + const Offset(0.5, 0.5),
          pitSize * 0.5,
          highlightPaint,
        );
      }
    }
  }

  void _drawPremiumCore(
    Canvas canvas,
    Offset center,
    double size,
    double r,
    double pulse,
  ) {
    // Radiant Soft Core Glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size * 2.5,
        [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, size * 2.0, glowPaint);

    // Sharp Core Star
    final starPath = Path();
    const int points = 4; // 4-pointed star to match shards
    for (int i = 0; i < points * 2; i++) {
      final double angle = (i * math.pi) / points - (math.pi / 2);
      final double radius = i.isEven ? size : size * 0.25;
      final px = center.dx + math.cos(angle) * radius;
      final py = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        starPath.moveTo(px, py);
      } else {
        starPath.lineTo(px, py);
      }
    }
    starPath.close();

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(starPath, starPaint);

    // 4. PRISMATIC OVERCHARGE (New light beams during charge/crack)
    if (transformProgress > 0.05) {
      final double beamOpacity =
          (transformProgress * 3.0).clamp(0.0, 1.0) * (1.0 - transformProgress);
      final beamPaint = Paint()
        ..shader = ui.Gradient.linear(center, center + Offset(0, -r * 1.5), [
          EntryColors.sapphireBlue.withValues(alpha: beamOpacity),
          EntryColors.arcticSilver.withValues(alpha: beamOpacity * 0.5),
          Colors.transparent,
        ])
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      for (int i = 0; i < 8; i++) {
        final double angle = (i * 45 + pulse * 20) * math.pi / 180;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.drawLine(
          Offset.zero,
          Offset(0, -r * 2.0 * transformProgress),
          beamPaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is! SymmetricPetalPainter) return true;
    return oldDelegate.pulse != pulse ||
        oldDelegate.color != color ||
        oldDelegate.transformProgress != transformProgress;
  }
}

class TacticalGridPainter extends CustomPainter {
  final double scanProgress;
  final double auroraProgress;
  final Offset pointerOffset;
  TacticalGridPainter({
    required this.scanProgress,
    required this.auroraProgress,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final auroraPaint = Paint();
    final center = Offset(
      size.width / 2 + pointerOffset.dx * 30,
      size.height / 2 + pointerOffset.dy * 30,
    );

    for (int i = 0; i < 3; i++) {
      final double angle = (auroraProgress * 2 * math.pi) + (i * math.pi * 0.6);
      final double x =
          center.dx + math.cos(angle) * 120 + pointerOffset.dx * 100;
      final double y =
          center.dy + math.sin(angle * 1.5) * 60 + pointerOffset.dy * 100;

      final gradient = RadialGradient(
        colors: [
          EntryColors.winterMoonCore.withValues(alpha: 0.07),
          EntryColors.primaryIceLight.withValues(alpha: 0.032),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 320));

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        auroraPaint..shader = gradient,
      );
    }

    final paint = Paint()
      ..color = EntryColors.frostedWhite.withValues(alpha: 0.028)
      ..strokeWidth = 0.48;

    /// Clear radius around focal center so grid lines don’t stack into a harsh “+”.
    const double gridHoleRadius = 172.0;
    final cx = center.dx;
    final cy = center.dy;

    const double step = 76.0;
    for (double i = -100; i < size.width + 100; i += step) {
      final double x = i + pointerOffset.dx * 40;
      final dx = x - cx;
      if (dx.abs() >= gridHoleRadius) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      } else {
        final h = math.sqrt(gridHoleRadius * gridHoleRadius - dx * dx);
        final yTop = cy - h;
        final yBot = cy + h;
        if (yTop > 0) {
          canvas.drawLine(Offset(x, 0), Offset(x, yTop.clamp(0.0, size.height)), paint);
        }
        if (yBot < size.height) {
          canvas.drawLine(
            Offset(x, yBot.clamp(0.0, size.height)),
            Offset(x, size.height),
            paint,
          );
        }
      }
    }
    for (double i = -100; i < size.height + 100; i += step) {
      final double y = i + pointerOffset.dy * 40;
      final dy = y - cy;
      if (dy.abs() >= gridHoleRadius) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      } else {
        final w = math.sqrt(gridHoleRadius * gridHoleRadius - dy * dy);
        final xLeft = cx - w;
        final xRight = cx + w;
        if (xLeft > 0) {
          canvas.drawLine(Offset(0, y), Offset(xLeft.clamp(0.0, size.width), y), paint);
        }
        if (xRight < size.width) {
          canvas.drawLine(
            Offset(xRight.clamp(0.0, size.width), y),
            Offset(size.width, y),
            paint,
          );
        }
      }
    }

    // Concentric HUD rings (ref: faint cyan tactical circles behind cracks).
    final double maxRingR =
        math.min(size.width, size.height) * 0.485;
    const int ringSteps = 8;
    final ringPaint = Paint()..style = PaintingStyle.stroke;
    for (int r = 0; r < ringSteps; r++) {
      final double t = r / (ringSteps - 1);
      final double radius =
          gridHoleRadius + 22 + (maxRingR - gridHoleRadius - 22) * t;
      final pulse =
          0.52 +
              0.48 * math.sin(scanProgress * math.pi * 2 + r * 0.7);
      ringPaint
        ..strokeWidth = 0.42 + 0.22 * (1.0 - t)
        ..color = EntryColors.iceCyan.withValues(
          alpha: (0.028 + 0.036 * (1.0 - t)) * pulse,
        );
      canvas.drawCircle(center, radius, ringPaint);
      ringPaint.color = EntryColors.winterMoonCore.withValues(
        alpha: (0.018 + 0.015 * (1.0 - t)) * pulse,
      );
      canvas.drawCircle(center, radius + 0.75, ringPaint);
    }

    final scanlineY = size.height * scanProgress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          EntryColors.winterMoonCore.withValues(alpha: 0.055),
          EntryColors.frostBloomMist.withValues(alpha: 0.038),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, scanlineY - 40, size.width, 80));

    canvas.drawRect(
      Rect.fromLTWH(0, scanlineY - 40, size.width, 80),
      scanPaint,
    );

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          EntryColors.winterDeepHorizon.withValues(alpha: 0.88),
          EntryColors.winterEdge.withValues(alpha: 0.98),
        ],
        stops: const [0.28, 0.72, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant TacticalGridPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.auroraProgress != auroraProgress;
}

class FlowerPainter extends CustomPainter {
  final double progress;
  final List<FlowerPetalData> petals;
  final Offset pointerOffset;

  FlowerPainter({
    required this.progress,
    required this.petals,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress > 0.85) return;

    final center = Offset(
      size.width / 2 + pointerOffset.dx * 15,
      size.height / 2 + pointerOffset.dy * 15,
    );

    for (var petal in petals) {
      final double startT = petal.flowerIndex * 0.2;
      final double bloomT = ((progress - startT) / 0.25).clamp(0.0, 1.0);
      if (bloomT <= 0) continue;

      final double easeBloom = Curves.easeOutBack.transform(bloomT);
      final double shatterFade = ((progress - 0.7) / 0.15).clamp(0.0, 1.0);
      final double opacity = (1.0 - shatterFade).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = petal.color.withValues(alpha: petal.opacity * opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        center.dx + petal.centerOffset.dx,
        center.dy + petal.centerOffset.dy,
      );
      canvas.rotate(petal.angle + (bloomT * 0.1) + petal.rotationOffset);
      canvas.scale(easeBloom);

      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          -petal.size * 0.6,
          -petal.size * 0.4,
          -petal.size * 0.5,
          -petal.size * 0.7,
        )
        ..quadraticBezierTo(
          -petal.size * 0.3,
          -petal.size * 1.2,
          0,
          -petal.size * 1.5,
        )
        ..quadraticBezierTo(
          petal.size * 0.3,
          -petal.size * 1.2,
          petal.size * 0.5,
          -petal.size * 0.7,
        )
        ..quadraticBezierTo(petal.size * 0.6, -petal.size * 0.4, 0, 0)
        ..close();

      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..color = petal.color.withValues(alpha: petal.opacity * 0.3 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(path, glowPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FlowerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class GlassCrackPainter extends CustomPainter {
  final double progress;
  final List<GlassCrackData> cracks;
  final Offset pointerOffset;

  /// Softer, thinner passes — for entry / premium transitions (no stress vents / core flare).
  final bool refined;

  GlassCrackPainter({
    required this.progress,
    required this.cracks,
    required this.pointerOffset,
    this.refined = false,
  });

  /// Staggered reveal: primaries zip in first, then circumferential chords (inner rings earlier), then capillary frost.
  double _growthForCrack(GlassCrackData crack, double progress) {
    switch (crack.role) {
      case IceCrackRole.primaryInward:
        // Legacy center→out cracks (e.g. EntryGeometry): faster window.
        if (!crack.growsFromEdge) {
          return (progress / 0.25).clamp(0.0, 1.0);
        }
        return (progress / 0.22).clamp(0.0, 1.0);
      case IceCrackRole.circumferentialRing:
        final double start = 0.14 + crack.ringStagger * 0.16;
        return ((progress - start) / 0.4).clamp(0.0, 1.0);
      case IceCrackRole.capillary:
        return ((progress - 0.24) / 0.34).clamp(0.0, 1.0);
    }
  }

  double _roleOpacityMul(IceCrackRole role) {
    switch (role) {
      case IceCrackRole.capillary:
        return 0.72;
      case IceCrackRole.circumferentialRing:
        return 1.0;
      case IceCrackRole.primaryInward:
        return 1.0;
    }
  }

  void _drawTaperedSpecularBand(
    Canvas canvas,
    Path path,
    Color color,
    double alpha,
    double thickOuter,
    double thinInner,
  ) {
    for (final metric in path.computeMetrics()) {
      final double len = metric.length;
      if (len < 0.5) continue;
      final int steps = (len / 5).ceil().clamp(10, 56);
      for (int i = 0; i < steps; i++) {
        final double t0 = i / steps;
        final double t1 = (i + 1) / steps;
        final tangent0 = metric.getTangentForOffset(len * t0);
        final tangent1 = metric.getTangentForOffset(len * t1);
        if (tangent0 == null || tangent1 == null) continue;
        final double tm = (t0 + t1) / 2;
        final double sw = thickOuter * (1.0 - tm) + thinInner * tm;
        canvas.drawLine(
          tangent0.position,
          tangent1.position,
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..strokeWidth = sw.clamp(0.18, thickOuter)
            ..strokeCap = StrokeCap.butt
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Rings + capillaries need a slightly longer window than legacy center-out cracks.
    if (progress > 0.66) return;

    final center = Offset(
      size.width / 2 + pointerOffset.dx * 15,
      size.height / 2 + pointerOffset.dy * 15,
    );

    if (refined && progress > 0.02 && progress < 0.52) {
      _drawRadialStressRays(canvas, center, size, progress);
    }

    // 3-STAGE CRACKING SEQUENCE
    // Stage 1: Growth (0.0-0.15) - Cracks extend from center
    // Stage 2: Deepen (0.15-0.25) - Cracks thicken, shadows darken, and stress webbing appears
    // Stage 3: Shatter Surge (0.25+) - Cracks fade as pieces fly

    double crackOpacity = 1.0;
    double crackThicknessFactor = 1.0;
    double stressWebAlpha = 0.0;

    if (progress < 0.25) {
      crackOpacity = (progress / 0.25).clamp(0.0, 1.0);
    } else if (progress < 0.45) {
      // Deepen phase: subtle thickening only
      final double deepenT = (progress - 0.25) / 0.2;
      crackThicknessFactor = 1.0 + deepenT * 1.92;
      stressWebAlpha = (deepenT * 0.5).clamp(
        0.0,
        0.4,
      ); // was 1.5 — very subtle webbing
    } else {
      // Fade out as shatter reaches full momentum
      crackOpacity = (1.0 - (progress - 0.48) / 0.26).clamp(0.0, 1.0);
      crackThicknessFactor = 2.65;
    }

    if (crackOpacity <= 0) return;

    final double ra = refined ? 0.78 : 1.0; // global alpha scale for refined

    for (var crack in cracks) {
      final path = Path();
      bool first = true;

      for (int i = 0; i < crack.points.length; i++) {
        final p = crack.points[i];
        final pos =
            center + Offset(p.dx * size.width * 0.5, p.dy * size.height * 0.5);

        if (first) {
          path.moveTo(pos.dx, pos.dy);
          first = false;
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }

      final double growthT = _growthForCrack(crack, progress);
      if (growthT <= 0) continue;

      final extractPath = _extractPartialPath(path, growthT);
      final double roleMul = _roleOpacityMul(crack.role);
      final double capStroke =
          crack.role == IceCrackRole.capillary ? 0.38 : 1.0;
      final double combinedOpacity = crackOpacity * ra * roleMul;

      final bool isPrimaryRadial =
          crack.role == IceCrackRole.primaryInward &&
          crack.growsFromEdge &&
          crack.tapered;
      final double geomStrokeMul =
          isPrimaryRadial
              ? 1.22
              : crack.role == IceCrackRole.capillary
              ? 0.85
              : crack.role == IceCrackRole.circumferentialRing
              ? 0.62
              : 1.0;

      // --- HIGH-FIDELITY CINEMATIC PASSES ---

      // PASS 1: Frost Bloom (Feathered ice growth simulation)
      _drawFrostBloom(
        canvas,
        extractPath,
        combinedOpacity,
        (refined ? crackThicknessFactor * 0.72 : crackThicknessFactor) *
            capStroke *
            geomStrokeMul,
        refined,
      );

      // PASS 1b: Thick electric cyan / ice-blue glass body (ref: layered translucency).
      if (refined && isPrimaryRadial && growthT > 0.06) {
        canvas.drawPath(
          extractPath,
          Paint()
            ..color = EntryColors.iceCyan.withValues(
              alpha: combinedOpacity * 0.24,
            )
            ..strokeWidth =
                6.2 *
                    crackThicknessFactor *
                    capStroke *
                    geomStrokeMul
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8)
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(
          extractPath,
          Paint()
            ..color = EntryColors.primaryIceBlue.withValues(
              alpha: combinedOpacity * 0.2,
            )
            ..strokeWidth =
                3.6 *
                    crackThicknessFactor *
                    capStroke *
                    geomStrokeMul
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5)
            ..style = PaintingStyle.stroke,
        );
      }

      // Pass 2: Depth Shadow (Deep Sapphire/Navy)
      canvas.save();
      // Parallax shift based on pointer
      final Offset depthShift = Offset(
        (refined ? 0.9 : 1.5) * crackThicknessFactor + pointerOffset.dx * 3,
        (refined ? 1.1 : 2.0) * crackThicknessFactor + pointerOffset.dy * 3,
      );
      canvas.translate(depthShift.dx, depthShift.dy);
      canvas.drawPath(
        extractPath,
        Paint()
          ..color = EntryColors.winterDeepHorizon.withValues(
            alpha: combinedOpacity * (refined ? 0.48 : 0.55),
          )
          ..strokeWidth =
              (refined ? 1.52 : 2.5) *
                  crackThicknessFactor *
                  capStroke *
                  geomStrokeMul
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            refined ? 3 : 4,
          ),
      );
      canvas.restore();

      // Pass 3: Prismatic Aberration (Prismatic bleed at the edges)
      canvas.save();
      final double aberration =
          (refined ? 0.45 : 1.0) * crackThicknessFactor;
      canvas.translate(aberration, aberration * 0.5);
      canvas.drawPath(
        extractPath,
        Paint()
          ..color = (refined && isPrimaryRadial
                  ? EntryColors.iceCyan
                  : EntryColors.primaryIceLight)
              .withValues(
            alpha: combinedOpacity *
                (refined ? (isPrimaryRadial ? 0.28 : 0.2) : 0.22),
          )
          ..strokeWidth =
              (refined ? 0.78 : 1.2) *
                  crackThicknessFactor *
                  capStroke *
                  geomStrokeMul
          ..style = PaintingStyle.stroke,
      );
      canvas.translate(-aberration * 2, -aberration);
      canvas.drawPath(
        extractPath,
        Paint()
            ..color = EntryColors.primaryIceBlue.withValues(
              alpha: combinedOpacity * (refined ? 0.14 : 0.18),
            )
            ..strokeWidth =
                (refined ? 0.68 : 1.2) *
                    crackThicknessFactor *
                    capStroke *
                    geomStrokeMul
            ..style = PaintingStyle.stroke,
      );
      canvas.restore();

      // Pass 4: Sharp specular — tapered wide-at-edge → thin-at-center for inward radials
      if (crack.tapered) {
        _drawTaperedSpecularBand(
          canvas,
          extractPath,
          EntryColors.platinumSilver,
          combinedOpacity * (refined ? 0.78 : 0.65),
          (refined ? 3.35 : 3.1) *
              crackThicknessFactor *
              capStroke *
              geomStrokeMul,
          (refined ? 0.38 : 0.52) *
              crackThicknessFactor *
              capStroke *
              geomStrokeMul,
        );
      } else {
        canvas.drawPath(
          extractPath,
          Paint()
              ..color = EntryColors.platinumSilver.withValues(
                alpha: combinedOpacity * (refined ? 0.62 : 0.65),
              )
              ..strokeWidth =
                  (refined ? 0.66 : 0.8) *
                      crackThicknessFactor *
                      capStroke *
                      geomStrokeMul
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.butt,
        );
      }

      if (refined && isPrimaryRadial && growthT > 0.35) {
        canvas.drawPath(
          extractPath,
          Paint()
            ..color = EntryColors.iceSparkle.withValues(
              alpha: combinedOpacity * 0.46,
            )
            ..strokeWidth =
                math.max(
                  0.9,
                  1.05 * crackThicknessFactor * geomStrokeMul,
                )
            ..strokeCap = StrokeCap.butt
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(
          extractPath,
          Paint()
            ..color = EntryColors.winterMoonCore.withValues(
              alpha: combinedOpacity * 0.26,
            )
            ..strokeWidth =
                math.max(
                  1.6,
                  2.2 * crackThicknessFactor * geomStrokeMul,
                )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
            ..style = PaintingStyle.stroke,
        );
        canvas.drawPath(
          extractPath,
          Paint()
            ..color = EntryColors.frostedWhite.withValues(
              alpha: combinedOpacity * 0.58,
            )
            ..strokeWidth =
                math.max(
                  0.42,
                  0.52 * crackThicknessFactor * geomStrokeMul,
                )
            ..strokeCap = StrokeCap.butt
            ..style = PaintingStyle.stroke,
        );
      }

      // Pass 5: Inner Radiant Highlight
      // canvas.drawPath(
      //   extractPath,
      //   Paint()
      //     ..color = Colors.white.withValues(alpha: crackOpacity * 0.7)
      //     ..strokeWidth = 0.35 * crackThicknessFactor
      //     ..style = PaintingStyle.stroke,
      // );

      // PASS 5: STRESS WEBBING (High-frequency micro-fractures)
      // if (stressWebAlpha > 0) {
      //   _drawStressWebbing(canvas, extractPath, stressWebAlpha * crackOpacity);
      // }

      // Pass 6: Jagged Origin Glints
      if (!refined &&
          math.Random(path.hashCode).nextDouble() > 0.4) {
        final p = crack.points[0];
        final pos =
            center + Offset(p.dx * size.width * 0.5, p.dy * size.height * 0.5);
        canvas.drawCircle(
          pos,
          1.5 * crackThicknessFactor,
          Paint()
            ..color = EntryColors.iceSparkle.withValues(alpha: crackOpacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }

      // Pass 7: Energy Vents (Pulse)
      if (!refined) {
        _drawCrackVents(canvas, extractPath, crackOpacity, progress);
      }
    }

    // PASS 8: Center Bloom (Core Explosion Aura)
    if (!refined && progress < 0.15) {
      _drawCoreFlare(canvas, center, 1.0 - (progress / 0.15));
    }
  }

  /// Sharp light rays through fractured ice (reference: radial beams behind cracks).
  void _drawRadialStressRays(
    Canvas canvas,
    Offset center,
    Size size,
    double progress,
  ) {
    final short = size.shortestSide;
    final fade = (1.0 - (progress / 0.52)).clamp(0.0, 1.0);
    final baseA = 0.14 + 0.24 * fade;
    const int n = 16;
    for (int i = 0; i < n; i++) {
      final ang = (i / n) * math.pi * 2 + progress * 0.15;
      final cardinal = i % 4 == 0;
      final lenMul = cardinal ? 1.22 : 1.0;
      final aMul = cardinal ? 1.35 : 1.0;
      final len =
          short *
          (0.46 + 0.06 * math.sin(progress * math.pi)) *
          lenMul;
      final outer = center + Offset(math.cos(ang), math.sin(ang)) * len;
      final rect = Rect.fromPoints(center, outer);
      canvas.drawLine(
        center,
        outer,
        Paint()
          ..shader = LinearGradient(
            colors: [
              EntryColors.iceSparkle.withValues(alpha: baseA * aMul),
              EntryColors.iceCyan.withValues(alpha: baseA * 0.55 * aMul),
              EntryColors.primaryIceBlue.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.32, 1.0],
          ).createShader(rect)
          ..strokeWidth =
              (cardinal ? 1.55 : 1.15) + 0.55 * fade
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  void _drawFrostBloom(
    Canvas canvas,
    Path path,
    double opacity,
    double thickness,
    bool refined,
  ) {
    final double h = refined ? 0.72 : 1.0;
    // 1. Massive frosted haze (The "Cloud" around the crack)
    canvas.drawPath(
      path,
      Paint()
        ..color = EntryColors.frostedWhite.withValues(alpha: opacity * 0.14 * h)
        ..strokeWidth = (refined ? 8.0 : 15.0) * thickness
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          refined ? 8 : 12,
        ),
    );

    // 2. Crystalline Core (The "Grainy" silver-white part)
    canvas.drawPath(
      path,
      Paint()
        ..color = EntryColors.neonSilver.withValues(alpha: opacity * 0.38 * h)
        ..strokeWidth = (refined ? 3.5 : 6.0) * thickness
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, refined ? 2 : 3),
    );

    // 3. Sharp Structural Fracture (The actual "Line")
    canvas.drawPath(
      path,
      Paint()
        ..color = EntryColors.platinumSilver.withValues(alpha: opacity * 0.82 * h)
        ..strokeWidth = (refined ? 0.75 : 1.2) * thickness
        ..strokeCap = refined ? StrokeCap.butt : StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawStressWebbing(Canvas canvas, Path path, double opacity) {
    final random = math.Random(path.hashCode + 50);
    final metrics = path.computeMetrics();
    final webPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.4)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    for (var metric in metrics) {
      final double len = metric.length;
      // Reduced frequency micro-fractures for a cleaner look
      int webCount = (len / 25.0).floor().clamp(4, 15);

      for (int i = 0; i < webCount; i++) {
        final double t = random.nextDouble();
        final tangent = metric.getTangentForOffset(len * t);
        if (tangent == null) continue;

        final pos = tangent.position;
        // Jittered orientation
        final angle =
            tangent.vector.direction +
            (math.pi / 2) +
            (random.nextDouble() - 0.5) * 0.8;

        final webPath = Path();
        webPath.moveTo(pos.dx, pos.dy);

        // Micro jagged line
        final double dist = 4.0 + random.nextDouble() * 12.0;
        final jitter = (random.nextDouble() - 0.5) * 8.0;
        webPath.lineTo(
          pos.dx + math.cos(angle) * dist + jitter,
          pos.dy + math.sin(angle) * dist + jitter,
        );
        canvas.drawPath(webPath, webPaint);
      }
    }
  }

  void _drawCrackVents(
    Canvas canvas,
    Path path,
    double opacity,
    double progress,
  ) {
    final random = math.Random(path.hashCode);
    final ventPaint = Paint()
      ..color = EntryColors.sapphireBlue.withValues(alpha: opacity * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < 2; i++) {
      final double t = (progress * 15 + i * 0.3) % 1.0;
      final bounds = path.getBounds();
      final pos = Offset(
        bounds.left + random.nextDouble() * bounds.width,
        bounds.top + random.nextDouble() * bounds.height,
      );
      if (path.contains(pos)) {
        canvas.drawCircle(
          pos - Offset(0, t * 15),
          0.5 + (1.0 - t) * 1.5,
          ventPaint,
        );
      }
    }
  }

  void _drawCoreFlare(Canvas canvas, Offset center, double opacity) {
    final flarePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity * 0.8),
          EntryColors.sapphireBlue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 50))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 30, flarePaint);
  }

  Path _extractPartialPath(Path path, double factor) {
    if (factor >= 1.0) return path;
    final extractPath = Path();
    for (final metric in path.computeMetrics()) {
      extractPath.addPath(
        metric.extractPath(0, metric.length * factor),
        Offset.zero,
      );
    }
    return extractPath;
  }

  @override
  bool shouldRepaint(GlassCrackPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.refined != refined ||
      oldDelegate.pointerOffset != pointerOffset;
}

class GlassShatterPainter extends CustomPainter {
  final double progress;
  final List<ScatteringParticleData> particles;
  final Offset pointerOffset;

  /// Softer shard opacity / omit heavy glints when true.
  final bool refined;

  GlassShatterPainter({
    required this.progress,
    required this.particles,
    required this.pointerOffset,
    this.refined = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.0) return;

    final double opacityMul = refined ? 0.64 : 1.0;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final center = Offset(
        size.width / 2 + pointerOffset.dx * 20,
        size.height / 2 + pointerOffset.dy * 20,
      );

      // WAVE TRIGGER LOGIC:
      // Shards closest to core (distRank ~0.0) shatter earlier than those at edges (distRank ~1.0)
      // Core start: 0.45 (matches crack deepen end), Edge start: 0.8
      // Earlier trigger: Shards start flying at 15% instead of 45%
      final double waveStart = 0.15 + (particle.distRank * 0.30);

      // Shards remain completely invisible until their wave hits for a cleaner 'pop'
      if (progress < waveStart) {
        continue;
      }

      final double shardProgress = ((progress - waveStart) / (1.0 - waveStart))
          .clamp(0.0, 1.0);
      final double ease = Curves.easeOutQuart.transform(shardProgress);

      // --- TURBULENCE & DRIFT ---
      // Adding a non-linear drift influenced by the noise seed
      final double turbulence =
          math.sin(shardProgress * 12 + particle.noiseSeed) * 18 * shardProgress;
      final double driftAngle = particle.angle + (math.sin(shardProgress * 5 + particle.noiseSeed) * 0.15);

      // PERSPECTIVE DEPTH: Shards move outward and "backwards"
      final double zDepth = 1.0 + (ease * 4.5); 
      final double velocityMultiplier = 2.15;
      final double distance =
          (particle.initialDistance +
              particle.velocity * velocityMultiplier * ease) /
          zDepth;

      final double opacity =
          ((1.0 - shardProgress).clamp(0.0, 1.0)) * opacityMul;

      // Soft frost dispersion offsets (drawn after [path] is built).
      final double ghostShift = (1.0 - ease) * 5.0;

      canvas.save();
      final particleCenter = Offset(
        center.dx + math.cos(driftAngle) * distance + math.cos(driftAngle + math.pi/2) * turbulence,
        center.dy + math.sin(driftAngle) * distance + math.sin(driftAngle + math.pi/2) * turbulence,
      );

      canvas.translate(particleCenter.dx, particleCenter.dy);

      // Shard tip (local −Y) aims at screen center — not emission angle (avoids “sideways” glass).
      final toCenter = center - particleCenter;
      final inward = toCenter.distance < 1.5
          ? driftAngle + math.pi
          : math.atan2(toCenter.dy, toCenter.dx);
      canvas.rotate(inward + math.pi / 2);

      // TUMBLING ROTATION (3D-Simulation)
      // We oscillate the scale on Y-axis to simulate a rotating flat shard
      final double tumbleY = math.cos(shardProgress * 18 + particle.noiseSeed);
      final double baseScale = (particle.tier == ParticleTier.dust
          ? 0.5 + ease * 0.5
          : 1.0 - ease * 0.80);

      canvas.scale(baseScale.clamp(0.02, 1.5), (baseScale * tumbleY.abs()).clamp(0.02, 1.5));

      final path = Path();
      bool first = true;
      for (var p in particle.points) {
        if (first) {
          path.moveTo(p.dx, p.dy);
          first = false;
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();

      // Subtle ice dispersion (large shards only, early flight).
      if (shardProgress < 0.5 && particle.tier == ParticleTier.large) {
        canvas.save();
        canvas.translate(ghostShift * 0.55, ghostShift * 0.32);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = EntryColors.primaryIceLight.withValues(alpha: opacity * 0.07),
        );
        canvas.translate(-ghostShift * 0.85, -ghostShift * 0.42);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color =
                EntryColors.winterMoonCore.withValues(alpha: opacity * 0.055),
        );
        canvas.restore();
      }

      // Base cracker body (Premium Frozen Glass)
      final bodyPaint = Paint()
        ..color =
            (particle.initialDistance > 50
                    ? EntryColors.primaryIceBlue
                    : EntryColors.frostedWhite)
                .withValues(
                  alpha:
                      opacity *
                      (particle.tier == ParticleTier.dust ? 0.22 : 0.38),
                )
        ..style = PaintingStyle.fill;

      if (particle.tier == ParticleTier.dust) {
        bodyPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      } else {
        // FROZEN GLASS SHADER: Specular lighting with primaryIceBlue tint
        bodyPaint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EntryColors.iceSparkle.withValues(alpha: opacity * 0.68),
            EntryColors.primaryIceLight.withValues(alpha: opacity * 0.4),
            EntryColors.primaryIceBlue.withValues(alpha: opacity * 0.2),
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(path.getBounds());
      }

      canvas.drawPath(path, bodyPaint);

      // --- CRYSTALLINE DETAILS: BUBBLES & GRAINS ---
      // if (particle.tier != ParticleTier.dust) {
      //   _drawShardDetails(canvas, path, opacity, shardProgress);
      //   _drawFragmentHoles(canvas, path, particle, opacity);
      // }

      // --- DYNAMIC SPECULAR SHEEN (Responding to Pointer) ---
      if (particle.tier == ParticleTier.large) {
        _drawDynamicSheen(
          canvas,
          path,
          opacity,
          pointerOffset,
          shardProgress,
          particle.angle,
        );
      }

      // --- CRYSTALLINE SPARKLES ---
      // if (particle.tier == ParticleTier.large && i % 3 == 0) {
      //   _drawFragmentSparkle(canvas, path, particle, opacity, shardProgress);
      // }

      // High-fidelity Specular Highlights and Edge Glints for Large Shards
      // ?if (particle.tier == ParticleTier.large) {
      //   // ULTRA-PREMIUM TRIPLE-PASS BEVEL
      //   // 1. Iridescent Edge (Thin-film spectral Shift - Silver/Blue/Violet)
      //   _drawIridescentEdge(
      //     canvas,
      //     path,
      //     opacity,
      //     shardProgress,
      //     particle.angle,
      //   );

      //   // 2. Hairline edge (subtle)
      //   canvas.drawPath(
      //     path,
      //     Paint()
      //       ..color = Colors.white.withValues(alpha: opacity * 0.42)
      //       ..style = PaintingStyle.stroke
      //       ..strokeWidth = 0.35
      //       ..strokeJoin = StrokeJoin.miter,
      //   );

      //   // 3. Soft outer bloom
      //   canvas.drawPath(
      //     path,
      //     Paint()
      //       ..color = EntryColors.primaryIceBlue.withValues(
      //         alpha: opacity * 0.1,
      //       )
      //       ..style = PaintingStyle.stroke
      //       ..strokeWidth = 1.6
      //       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      //   );

      //   // Directional 'glint' (a bright streak across the shard)
      //   if (i % 2 == 0) {
      //     // More frequent glints for that anime sparkle
      //     final bounds = path.getBounds();
      //     final glintPath = Path()
      //       ..moveTo(
      //         bounds.left - bounds.width,
      //         bounds.top + bounds.height * 0.5,
      //       )
      //       ..lineTo(
      //         bounds.right + bounds.width,
      //         bounds.bottom - bounds.height * 0.5,
      //       );

      //     final glintStroke = Paint()
      //       ..color = Colors.white.withValues(alpha: opacity * 0.28)
      //       ..style = PaintingStyle.stroke
      //       ..strokeWidth = 1.1
      //       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      //     canvas.save();
      //     canvas.clipPath(path);
      //     canvas.drawPath(glintPath, glintStroke);
      //     canvas.restore();
      //   }

      //   // KINETIC ICE TRAILS (Crystalline trail effect)
      //   if (shardProgress < 0.6) {
      //     final double trailLength = 220 * shardProgress;
      //     final trailPaint = Paint()
      //       ..shader = ui.Gradient.linear(
      //         Offset.zero,
      //         Offset(
      //           -math.cos(driftAngle) * trailLength,
      //           -math.sin(driftAngle) * trailLength,
      //         ),
      //         [
      //           EntryColors.iceCyan.withValues(alpha: opacity * 0.22),
      //           EntryColors.primaryIceBlue.withValues(alpha: 0.0),
      //         ],
      //       )
      //       ..strokeWidth = 1.0 * (1.0 - shardProgress)
      //       ..style = PaintingStyle.stroke;

      //     canvas.drawLine(
      //       Offset.zero,
      //       Offset(
      //         -math.cos(driftAngle) * trailLength,
      //         -math.sin(driftAngle) * trailLength,
      //       ),
      //       trailPaint,
      //     );

      //     // Frost Mist (Particle emission simulation)
      //     if (i % 4 == 0) {
      //       final double mistSize = 4.0 + math.sin(shardProgress * 40) * 2.0;
      //       canvas.drawCircle(
      //         Offset(
      //           -math.cos(driftAngle) * trailLength * 0.5,
      //           -math.sin(driftAngle) * trailLength * 0.5,
      //         ),
      //         mistSize,
      //         Paint()
      //           ..color = Colors.white.withValues(alpha: opacity * 0.2)
      //           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      //       );
      //     }
      //   }
      // }

      canvas.restore();
    }
  }

  void _drawFragmentSparkle(
    Canvas canvas,
    Path path,
    ScatteringParticleData p,
    double opacity,
    double shardProgress,
  ) {
    // Intermittent pop-in based on time and rotation
    final double sparkleT =
        (math.sin(shardProgress * 30 + p.angle * 10) + 1.0) / 2.0;
    if (sparkleT < 0.85) return;

    final bounds = path.getBounds();
    final center = bounds.center;

    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * sparkleT)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(center, 2.5 * sparkleT, sparklePaint);
    canvas.drawCircle(center, 1.0 * sparkleT, Paint()..color = Colors.white);
  }

  void _drawFragmentHoles(
    Canvas canvas,
    Path path,
    ScatteringParticleData p,
    double opacity,
  ) {
    final math.Random holeRandom = math.Random(p.velocity.toInt() + 100);
    final bounds = path.getBounds();
    final int count = p.tier == ParticleTier.large ? 4 : 2;

    for (int i = 0; i < count; i++) {
      final px = bounds.left + holeRandom.nextDouble() * bounds.width;
      final py = bounds.top + holeRandom.nextDouble() * bounds.height;
      final pos = Offset(px, py);

      if (path.contains(pos)) {
        // HIGH-FIDELITY 3D PIT: Shadow + Light Catch
        // A. Dark pit depth
        canvas.drawCircle(
          pos,
          0.8 + holeRandom.nextDouble() * 0.5,
          Paint()
            ..color = EntryColors.pitShadow.withValues(alpha: opacity * 0.7),
        );
        // B. Light catch on the "upper" rim to simulate 3D recess
        canvas.drawCircle(
          pos - const Offset(0.4, 0.4),
          0.3,
          Paint()..color = Colors.white.withValues(alpha: opacity * 0.4),
        );
      }
    }
  }

  void _drawIridescentEdge(
    Canvas canvas,
    Path path,
    double opacity,
    double t,
    double angle,
  ) {
    // Spectral shift logic for premium "Gemstone" glints
    final double shift = (math.sin(t * 15 + angle) + 1.0) / 2.0;
    final iridescentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..shader = ui.Gradient.linear(
        path.getBounds().topLeft,
        path.getBounds().bottomRight,
        [
          Colors.white.withValues(alpha: opacity * 0.32),
          const ui.Color.fromARGB(
            255,
            98,
            133,
            229,
          ).withValues(alpha: opacity * 0.22 * shift),
          const ui.Color.fromARGB(255, 52, 142, 183).withValues(alpha: opacity * 0.16 * (1.0 - shift)),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawPath(path, iridescentPaint);
  }

  void _drawShardDetails(
    Canvas canvas,
    Path path,
    double opacity,
    double shardProgress,
  ) {
    final random = math.Random(path.hashCode + 77);
    final bounds = path.getBounds();
    final Paint grainPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.3)
      ..strokeWidth = 0.5;

    // A. Internal Grains (Tiny white dots)
    for (int i = 0; i < 5; i++) {
      final pos = Offset(
        bounds.left + random.nextDouble() * bounds.width,
        bounds.top + random.nextDouble() * bounds.height,
      );
      if (path.contains(pos)) {
        canvas.drawCircle(pos, 0.4, grainPaint);
      }
    }

    // B. Internal Fractures (Thin striations)
    if (shardProgress < 0.5) {
      final striationPaint = Paint()
        ..color = EntryColors.primaryIceLight.withValues(alpha: opacity * 0.2)
        ..strokeWidth = 0.3;
      final p1 = Offset(bounds.left, bounds.top + bounds.height * 0.3);
      final p2 = Offset(bounds.right, bounds.top + bounds.height * 0.7);
      canvas.save();
      canvas.clipPath(path);
      canvas.drawLine(p1, p2, striationPaint);
      canvas.restore();
    }
  }

  void _drawDynamicSheen(
    Canvas canvas,
    Path path,
    double opacity,
    Offset pointer,
    double t,
    double angle,
  ) {
    final bounds = path.getBounds();
    // Sheen moves based on pointer position relative to center
    // Normalizing pointer range roughly
    final double sheenX = (pointer.dx + 1.0) * 0.5;
    final double sheenY = (pointer.dy + 1.0) * 0.5;

    final sheenGradient = ui.Gradient.linear(
      Offset(
        bounds.left + bounds.width * sheenX,
        bounds.top + bounds.height * sheenY,
      ),
      Offset(
        bounds.left + bounds.width * (sheenX + 0.2),
        bounds.bottom + bounds.height * (sheenY + 0.2),
      ),
      [
        Colors.transparent,
        Colors.white.withValues(alpha: opacity * 0.6),
        Colors.transparent,
      ],
      [0.0, 0.5, 1.0],
    );

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(bounds, Paint()..shader = sheenGradient);
    canvas.restore();
  }

  @override
  bool shouldRepaint(GlassShatterPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.refined != refined ||
      oldDelegate.pointerOffset != pointerOffset;
}

class ShockwavePainter extends CustomPainter {
  final double progress;
  final bool refined;

  ShockwavePainter({required this.progress, this.refined = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 0.7) return;

    final center = Offset(size.width / 2, size.height / 2);
    final double radius = progress * size.width * 1.8;
    final double m = refined ? 0.62 : 1.0;
    final double opacity = (1.0 - (progress / 0.7)).clamp(0.0, 1.0) * m;

    // Pass 1: Refractive Distortion Ring — whisper-soft
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = EntryColors.primaryIceBlue.withValues(
          alpha: opacity * (refined ? 0.08 : 0.08),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = (refined ? 5.5 : 8.0) * (1.0 - progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Pass 2: Concussive Edge — subtle hairline
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = EntryColors.iceSparkle
            .withValues(alpha: opacity * (refined ? 0.15 : 0.18))
        ..style = PaintingStyle.stroke
        ..strokeWidth = refined ? 0.58 : 0.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.refined != refined;
}

class PrismPainter extends CustomPainter {
  final List<PrismShard> shards;
  final double progress;
  final double pulse;
  final Offset pointerOffset;
  final bool isExploded;

  PrismPainter({
    required this.shards,
    required this.progress,
    required this.pulse,
    required this.pointerOffset,
    this.isExploded = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2 + pointerOffset.dx * 20,
      size.height / 2 + pointerOffset.dy * 20,
    );

    final double shortest = size.shortestSide;
    // Radial assembly: keep a moonlit “void” at center (ref: shattered glass ring).
    // Slightly larger dead zone + softer band tracks TacticalGridPainter hole growth.
    final double focalDead = shortest * 0.145;
    final double focalFadeBand = shortest * 0.078;

    for (var shard in shards) {
      final double adjustedT = ((progress - shard.delay) / shard.speed).clamp(
        0.0,
        1.0,
      );
      if (adjustedT <= 0) continue;

      final double ease = Curves.easeInQuint.transform(adjustedT);
      final rel =
          Offset.lerp(shard.startOffset, shard.targetOffset, ease)!;
      final currentPos = center + rel;
      final double currentOpacity = (1.0 - ease).clamp(0.0, 1.0);

      // Tip (local −Y) aims at screen center — rel is center→shard, so −rel is shard→center.
      final toCenter = Offset(-rel.dx, -rel.dy);
      final dist = toCenter.distance;
      final double focalFactor =
          ((dist - focalDead) / focalFadeBand).clamp(0.0, 1.0);
      if (focalFactor <= 0) {
        continue;
      }

      final double alpha = currentOpacity * focalFactor;

      final paint = Paint()
        ..color = shard.color.withValues(alpha: alpha * 0.48)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      final inward = math.atan2(toCenter.dy, toCenter.dx);
      canvas.rotate(inward + math.pi / 2);

      final Path path = shard.isIceFlake
          ? _hexPath(shard.size)
          : (Path()
              ..moveTo(0, -shard.size)
              ..lineTo(shard.size, shard.size / 2)
              ..lineTo(-shard.size, shard.size / 2)
              ..close());

      canvas.drawPath(path, paint);

      // Bright cut-glass rim (refs: high-luminance shard outlines).
      final double rim = (alpha * focalFactor * 0.62).clamp(0.0, 1.0);
      canvas.drawPath(
        path,
        Paint()
          ..color = EntryColors.arcticSilver.withValues(alpha: rim * 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.4, shard.size * 0.09),
      );

      if (adjustedT > 0.85) {
        final glowPaint = Paint()
            ..color = shard.color.withValues(alpha: alpha * 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawPath(path, glowPaint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PrismPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pointerOffset != pointerOffset;

  /// Flat-top hexagon, circumradius [r].
  static Path _hexPath(double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * math.pi / 3) - math.pi / 6;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}

class IceFlashPainter extends CustomPainter {
  final double progress;
  final Color flashColor;

  /// Dimmer prismatic burst for refined transitions.
  final bool refined;

  IceFlashPainter({
    required this.progress,
    this.flashColor = EntryColors.iceSparkle,
    this.refined = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = size.center(Offset.zero);

    // 1. Central Radial Flash — The Portal / Gateway
    final double rf = refined ? 0.52 : 1.0;
    final flashOpacity = ((1.0 - progress).clamp(0.0, 1.0)) * rf;
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          EntryColors.frostedWhite.withValues(alpha: flashOpacity * 0.88),
          EntryColors.primaryIceBlue.withValues(alpha: flashOpacity * 0.52),
          EntryColors.winterSkyBand.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5))
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        (refined ? 26.0 : 30.0) * (1.0 - progress),
      );

    canvas.drawCircle(
      center,
      size.width * (refined ? 0.62 : 0.8) * progress,
      radialPaint,
    );

    // Secondary Crystalline Ring (Prismatic halo)
    if (!refined && progress < 0.4) {
      final ringOpacity = (1.0 - progress * 2.5).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        size.width * 0.8 * progress,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const ui.Color.fromARGB(255, 75, 104, 232).withValues(alpha: ringOpacity * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // 2. Bloom — very gentle
    final double bloomT = progress < 0.5 ? (1.0 - progress * 2.0) : 0.0;
    if (bloomT > 0 && !refined) {
      canvas.drawCircle(
        center,
        size.width * 0.5 * bloomT,
        Paint()
          ..color = flashColor
              .withValues(alpha: flashOpacity * bloomT * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
      );
    }

    // 3. Shockwave ring — thin elegant halo
    final ringOpacity = (1.0 - math.pow(progress, 0.4))
            .clamp(0.0, refined ? 0.09 : 0.2)
            .toDouble();
    final ringPaint = Paint()
      ..color = flashColor.withValues(alpha: ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (refined ? 5.0 : 12.0) * (1 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(
      center,
      size.width * (refined ? 1.25 : 2.0) * progress,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(IceFlashPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.refined != refined;
}

/// Frame 1 — white impact core → electric cyan / ice-blue halo (**charge** phase).
class IceGateChargePulsePainter extends CustomPainter {
  final double progress;
  final Offset pointerOffset;

  IceGateChargePulsePainter({
    required this.progress,
    required this.pointerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(
      size.width / 2 + pointerOffset.dx * 18,
      size.height / 2 + pointerOffset.dy * 18,
    );
    final pulse = Curves.easeOut.transform(progress);
    final shortSide = size.shortestSide;
    final outerR = shortSide * (0.18 + 0.28 * pulse);

    const rayCount = 14;
    final rayLen = shortSide * (0.32 + 0.14 * pulse);
    final rayAlpha = 0.38 * pulse;
    for (int i = 0; i < rayCount; i++) {
      final ang = (i / rayCount) * math.pi * 2 - pulse * 0.2;
      final p2 = center + Offset(math.cos(ang), math.sin(ang)) * rayLen;
      final rect = Rect.fromPoints(center, p2);
      canvas.drawLine(
        center,
        p2,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: rayAlpha * 1.05),
              EntryColors.iceCyan.withValues(alpha: rayAlpha * 0.88),
              EntryColors.primaryIceBlue.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.22, 1.0],
          ).createShader(rect)
          ..strokeWidth = 1.4 + pulse * 0.9
          ..strokeCap = StrokeCap.butt,
      );
    }

    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.88 * (1.0 - pulse * 0.05)),
            EntryColors.iceCyan.withValues(alpha: 0.72 * pulse),
            EntryColors.frostBloomMist.withValues(alpha: 0.78 * pulse),
            EntryColors.primaryIceBlue.withValues(alpha: 0.68 * pulse),
            EntryColors.winterSkyBand.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.14, 0.28, 0.52, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: outerR))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + 24 * pulse),
    );

    final coreR = shortSide * (0.022 + 0.014 * pulse);
    canvas.drawCircle(
      center,
      coreR,
      Paint()..color = Colors.white.withValues(alpha: 0.98 * pulse),
    );

    final innerR = shortSide * (0.042 + 0.036 * math.sin(progress * math.pi));
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            EntryColors.iceCyan.withValues(alpha: 0.55 * pulse),
            EntryColors.primaryIceLight.withValues(alpha: 0.42 * pulse),
            EntryColors.primaryIceBlue.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: innerR)),
    );
  }

  @override
  bool shouldRepaint(IceGateChargePulsePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pointerOffset != pointerOffset;
}
