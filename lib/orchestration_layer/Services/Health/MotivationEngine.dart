import 'package:ice_gate/l10n/app_localizations.dart';

/// Daily pillar progress tiers (Motivation Engine).
enum DailyMotivationTier { empty, low, mid, strong, allDone }

/// SpO₂ reading tiers — shared with Oxygen detail UI.
enum Spo2MotivationTier { empty, low, near, onTarget, high, peak }

/// Snapshot inputs for daily motivation (no Flutter UI deps).
class DailyMotivationInput {
  const DailyMotivationInput({
    required this.steps,
    required this.stepGoal,
    required this.waterMl,
    required this.waterGoal,
    required this.sleepHours,
    required this.sleepGoal,
    required this.exerciseMinutes,
    required this.exerciseGoal,
  });

  final int steps;
  final int stepGoal;
  final int waterMl;
  final int waterGoal;
  final double sleepHours;
  final double sleepGoal;
  final int exerciseMinutes;
  final int exerciseGoal;
}

class PillarProgress {
  const PillarProgress({required this.id, required this.progress});

  final String id;
  final double progress;
}

class DailyMotivationResult {
  const DailyMotivationResult({
    required this.tier,
    required this.averageProgress,
    required this.pillars,
  });

  final DailyMotivationTier tier;
  final double averageProgress;
  final List<PillarProgress> pillars;
}

/// Pure motivation logic — UI and notification layers resolve copy via [AppLocalizations]
/// or [MotivationEngine.nudgeCopy] when no [BuildContext] exists.
abstract final class MotivationEngine {
  static double _progress(num value, num goal) =>
      goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0);

  static DailyMotivationResult evaluateDaily(DailyMotivationInput input) {
    final pillars = [
      PillarProgress(
        id: 'steps',
        progress: _progress(input.steps, input.stepGoal),
      ),
      PillarProgress(
        id: 'water',
        progress: _progress(input.waterMl, input.waterGoal),
      ),
      PillarProgress(
        id: 'sleep',
        progress: _progress(input.sleepHours, input.sleepGoal),
      ),
      PillarProgress(
        id: 'exercise',
        progress: _progress(input.exerciseMinutes, input.exerciseGoal),
      ),
    ];

    if (pillars.every((p) => p.progress <= 0)) {
      return DailyMotivationResult(
        tier: DailyMotivationTier.empty,
        averageProgress: 0,
        pillars: pillars,
      );
    }

    if (pillars.every((p) => p.progress >= 1)) {
      return DailyMotivationResult(
        tier: DailyMotivationTier.allDone,
        averageProgress: 1,
        pillars: pillars,
      );
    }

    final avg =
        pillars.map((p) => p.progress).reduce((a, b) => a + b) / pillars.length;

    final tier = avg >= 0.75
        ? DailyMotivationTier.strong
        : avg >= 0.35
        ? DailyMotivationTier.mid
        : DailyMotivationTier.low;

    return DailyMotivationResult(
      tier: tier,
      averageProgress: avg,
      pillars: pillars,
    );
  }

  static DailyMotivationResult fromHealthSignals({
    required int steps,
    required int stepGoal,
    required int waterMl,
    required int waterGoal,
    required double sleepHours,
    required double sleepGoal,
    required int exerciseMinutes,
    required int exerciseGoal,
  }) {
    return evaluateDaily(
      DailyMotivationInput(
        steps: steps,
        stepGoal: stepGoal,
        waterMl: waterMl,
        waterGoal: waterGoal,
        sleepHours: sleepHours,
        sleepGoal: sleepGoal,
        exerciseMinutes: exerciseMinutes,
        exerciseGoal: exerciseGoal,
      ),
    );
  }

  static String resolveDailyMessage(
    AppLocalizations l10n,
    DailyMotivationTier tier,
  ) {
    return switch (tier) {
      DailyMotivationTier.empty => l10n.health_motivation_empty,
      DailyMotivationTier.allDone => l10n.health_motivation_all_done,
      DailyMotivationTier.strong => l10n.health_motivation_strong,
      DailyMotivationTier.mid => l10n.health_motivation_mid,
      DailyMotivationTier.low => l10n.health_motivation_low,
    };
  }

  /// Forward-looking copy after reviewing yesterday (morning briefing).
  static String resolveMorningMotivation(
    AppLocalizations l10n,
    DailyMotivationResult yesterday,
  ) {
    return switch (yesterday.tier) {
      DailyMotivationTier.empty => l10n.morning_briefing_motivation_empty,
      DailyMotivationTier.allDone => l10n.morning_briefing_motivation_all_done,
      DailyMotivationTier.strong => l10n.morning_briefing_motivation_strong,
      DailyMotivationTier.mid => l10n.morning_briefing_motivation_mid,
      DailyMotivationTier.low => l10n.morning_briefing_motivation_low,
    };
  }

  static Spo2MotivationTier evaluateSpo2Tier(double value, int target) {
    if (value <= 0) return Spo2MotivationTier.empty;
    if (value >= 98) return Spo2MotivationTier.peak;
    if (value >= 96) return Spo2MotivationTier.high;
    if (value >= target) return Spo2MotivationTier.onTarget;
    if (value >= target - 3) return Spo2MotivationTier.near;
    return Spo2MotivationTier.low;
  }

  static String resolveSpo2Message(
    AppLocalizations l10n,
    Spo2MotivationTier tier,
  ) {
    return switch (tier) {
      Spo2MotivationTier.empty => l10n.health_spo2_motivation_empty,
      Spo2MotivationTier.peak => l10n.health_spo2_motivation_peak,
      Spo2MotivationTier.high => l10n.health_spo2_motivation_high,
      Spo2MotivationTier.onTarget => l10n.health_spo2_motivation_on_target,
      Spo2MotivationTier.near => l10n.health_spo2_motivation_near,
      Spo2MotivationTier.low => l10n.health_spo2_motivation_low,
    };
  }

  /// Pillar with lowest progress — used by [NotificationEngine] for targeted nudges.
  static PillarProgress? weakestPillar(DailyMotivationResult result) {
    if (result.tier == DailyMotivationTier.empty ||
        result.tier == DailyMotivationTier.allDone) {
      return null;
    }
    PillarProgress? weakest;
    for (final p in result.pillars) {
      if (p.progress >= 1) continue;
      if (weakest == null || p.progress < weakest.progress) {
        weakest = p;
      }
    }
    return weakest;
  }

  /// Local notification copy (no [BuildContext] at schedule time).
  static ({String title, String body}) nudgeCopy({
    required String pillarId,
    required bool vietnamese,
  }) {
    if (vietnamese) {
      return switch (pillarId) {
        'steps' => (
          title: 'Bước chân hôm nay',
          body: 'Bạn còn xa mục tiêu bước chân — một vòng đi bộ ngắn cũng đủ.',
        ),
        'water' => (
          title: 'Uống nước nhé',
          body: 'Cơ thể cần nước — ghi nhanh một ly trên Ice Gate.',
        ),
        'sleep' => (
          title: 'Giấc ngủ',
          body: 'Ngủ đủ giúp hồi phục — chuẩn bị nghỉ sớm tối nay.',
        ),
        'exercise' => (
          title: 'Vận động nhẹ',
          body: 'Mười phút stretching hoặc đi bộ — tích lũy từng chút.',
        ),
        _ => (
          title: 'Chăm sức khỏe',
          body: 'Một hành động nhỏ hôm nay — Ice Gate cùng bạn.',
        ),
      };
    }
    return switch (pillarId) {
      'steps' => (
        title: 'Steps today',
        body: 'Still short of your step goal — a short walk counts.',
      ),
      'water' => (
        title: 'Hydration check',
        body: 'Log a glass of water on Ice Gate — small sips add up.',
      ),
      'sleep' => (
        title: 'Sleep matters',
        body: 'Recovery starts tonight — wind down a little earlier.',
      ),
      'exercise' => (
        title: 'Move a little',
        body: 'Ten minutes of movement — stack another small win.',
      ),
      _ => (
        title: 'Health nudge',
        body: 'One small action today — Ice Gate is with you.',
      ),
    };
  }
}
