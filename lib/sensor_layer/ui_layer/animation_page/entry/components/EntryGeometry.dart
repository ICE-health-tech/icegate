import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'PrismPainters.dart';
import 'EntryConstants.dart';

class EntryGeometry {
  final List<GlassCrackData> glassCracks;
  final List<ScatteringParticleData> particles;
  final List<PrismShard> shards;
  final List<BrokenGlassPaneData> panes;

  EntryGeometry({
    required this.glassCracks,
    required this.particles,
    required this.shards,
    required this.panes,
  });

  /// Shard assembly only — avoids building full crack/particle sets for entry backgrounds.
  static List<PrismShard> generateShardsOnly(
    int count, {
    int seed = 42,
    bool winterShardHints = false,
  }) {
    final random = math.Random(seed);
    final List<PrismShard> list = [];
    for (int i = 0; i < count; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double distance = 600 + random.nextDouble() * 700;
      final Color c =
          winterShardHints
              ? switch (random.nextInt(7)) {
                  0 || 1 => EntryColors.frostedWhite,
                  2 => EntryColors.primaryIceLight,
                  3 => EntryColors.iceCyan,
                  4 => EntryColors.primaryIceBlue,
                  _ => EntryColors.arcticSilver,
                }
              : (random.nextBool()
                  ? EntryColors.arcticSilver
                  : EntryColors.frostedWhite);
      list.add(
        PrismShard(
          startOffset: Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance,
          ),
          targetOffset: Offset.zero,
          size: 2 + random.nextDouble() * 12,
          color: c,
          rotation: random.nextDouble() * 2 * math.pi,
          delay: random.nextDouble() * 0.5,
          speed: 0.4 + random.nextDouble() * 0.5,
        ),
      );
    }
    return list;
  }

  factory EntryGeometry.generate(int shardCount) {
    final random = math.Random(42);
    final List<GlassCrackData> cachedGlassCracks = [];
    final List<ScatteringParticleData> cachedParticles = [];
    final List<PrismShard> cachedShards = generateShardsOnly(shardCount, seed: 42);

    // 2. Glass Cracks
    const int crackCount = 6;
    final List<List<Offset>> allRadialPoints = [];

    void growBranch(
      Offset impactOrigin,
      Offset start,
      double angle,
      double dist,
      int depth, {
      bool isMain = false,
    }) {
      if (depth > 3 || dist > 6.0) return;

      final List<Offset> branchPoints = [start];
      double bDist = dist;
      double bAngle = angle;

      int segments = 8 + random.nextInt(6);
      for (int j = 0; j < segments; j++) {
        final double jitter = 0.15 + (bDist * 0.08);
        bAngle += (random.nextDouble() - 0.5) * jitter;
        bDist += 0.15 + random.nextDouble() * 0.35;

        final nextPoint =
            impactOrigin +
            Offset(math.cos(bAngle) * bDist, math.sin(bAngle) * bDist);
        branchPoints.add(nextPoint);

        if (random.nextDouble() > 0.65 - (depth * 0.12)) {
          growBranch(
            impactOrigin,
            nextPoint,
            bAngle + (random.nextBool() ? 0.45 : -0.45),
            bDist,
            depth + 1,
          );
        }
        if (bDist > 7.0) break;
      }

      if (isMain) allRadialPoints.add(branchPoints);
      cachedGlassCracks.add(GlassCrackData(points: branchPoints));
    }

    for (int i = 0; i < crackCount; i++) {
      growBranch(Offset.zero, Offset.zero, (i / crackCount) * 2 * math.pi, 0.0, 0, isMain: true);
    }

    // Impact Micro-Shatter
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = 0.02 + random.nextDouble() * 0.25;
      final p1 = Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      final p2 = Offset(
        math.cos(angle + (random.nextDouble() - 0.5)) * (dist + 0.15),
        math.sin(angle + (random.nextDouble() - 0.5)) * (dist + 0.15),
      );
      cachedGlassCracks.add(GlassCrackData(points: [p1, p2]));
    }

    // Concentric Stress Rings
    for (int layer = 1; layer < 4; layer++) {
      final double radiusFactor = (layer / 12.0);
      for (int i = 0; i < allRadialPoints.length; i++) {
        final double spawnChance = layer < 4 ? 0.95 : 0.75;
        if (random.nextDouble() < spawnChance) {
          final r1 = allRadialPoints[i];
          final r2 = allRadialPoints[(i + 1) % allRadialPoints.length];
          final p1 = r1[layer.clamp(0, r1.length - 1)];
          final p2 = r2[layer.clamp(0, r2.length - 1)];

          final Offset mid1 = Offset.lerp(p1, p2, 0.33)!;
          final Offset mid2 = Offset.lerp(p1, p2, 0.66)!;
          final Offset normal = Offset(-(p2.dy - p1.dy), p2.dx - p1.dx);
          final double jitterScale = (layer < 4 ? 0.15 : 0.45) * radiusFactor;

          final j1 = mid1 + normal * (random.nextDouble() - 0.5) * jitterScale;
          final j2 = mid2 + normal * (random.nextDouble() - 0.5) * jitterScale;

          cachedGlassCracks.add(GlassCrackData(points: [p1, j1, j2, p2]));
        }
      }
    }

    // 3. Particles
    // Tier 1: Large Splinters
    const int largeParticleCount = 120;
    for (int i = 0; i < largeParticleCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double startDist = 80 + random.nextDouble() * 250;
      final double velocity = 2400 + random.nextDouble() * 3000;
      final double length = 120 + random.nextDouble() * 130;
      final double width = 3.0 + random.nextDouble() * 5.0;

      final List<Offset> points = [
        Offset(0, -length / 2),
        Offset(width / 2 + random.nextDouble() * 4, -length * 0.2),
        Offset(width / 3, length * 0.1),
        Offset(0, length / 2),
        Offset(-width / 3, length * 0.1),
        Offset(-width / 2 - random.nextDouble() * 4, -length * 0.2),
      ];

      cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: points,
          rotationSpeed: (random.nextDouble() - 0.5) * 45,
          color: random.nextBool() ? EntryColors.primaryIceBlue : EntryColors.frostedWhite,
          delay: random.nextDouble() * 0.1,
          initialDistance: startDist,
          distRank: (startDist / 330.0).clamp(0.0, 1.0),
          tier: ParticleTier.large,
          noiseSeed: random.nextDouble() * 100.0,
        ),
      );
    }

    // Tier 2: Micro needle-splinters
    const int dustCount = 120;
    for (int i = 0; i < dustCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 1200 + random.nextDouble() * 2000;
      final double w = 0.5 + random.nextDouble() * 1.0;
      final double l = 8 + random.nextDouble() * 18;
      cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: [Offset(0, -l / 2), Offset(w / 2, 0), Offset(0, l / 2), Offset(-w / 2, 0)],
          rotationSpeed: 80,
          color: EntryColors.iceCyan.withValues(alpha: 0.4),
          delay: random.nextDouble() * 0.4,
          tier: ParticleTier.dust,
          noiseSeed: random.nextDouble() * 100.0,
        ),
      );
    }

    // Tier 3: Shrapnel
    const int shrapnelCount = 35;
    for (int i = 0; i < shrapnelCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double velocity = 1800 + random.nextDouble() * 2500;
      final double size = 12 + random.nextDouble() * 20;

      cachedParticles.add(
        ScatteringParticleData(
          angle: angle,
          velocity: velocity,
          points: [Offset(0, -size / 2), Offset(size / 3, 0), Offset(0, size / 2), Offset(-size / 3, -size / 4)],
          rotationSpeed: (random.nextDouble() - 0.5) * 45,
          color: EntryColors.primaryIceLight,
          delay: random.nextDouble() * 0.2,
          tier: ParticleTier.shrapnel,
          noiseSeed: random.nextDouble() * 100.0,
        ),
      );
    }

    // 4. Panes
    final List<BrokenGlassPaneData> cachedPanes = BrokenGlassPaneData.generate(seed: 7);

    return EntryGeometry(
      glassCracks: cachedGlassCracks,
      particles: cachedParticles,
      shards: cachedShards,
      panes: cachedPanes,
    );
  }
}
