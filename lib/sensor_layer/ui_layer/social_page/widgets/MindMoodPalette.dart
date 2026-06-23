import 'package:flutter/material.dart';

/// Consistent mood colors for charts, icons, and journal cards (scores 1–5, boost at 6+).
/// Aligned with [HealthMetricColors] pillar accents (red → orange → grey → green → cyan).
Color mindMoodAccent(int moodScore) {
  if (moodScore >= 6) {
    return const Color(0xFFFFD60A); // focus boost — gold
  }
  switch (moodScore.clamp(1, 5)) {
    case 1:
      return const Color(0xFFFF453A); // awful — system red
    case 2:
      return const Color(0xFFFF9500); // bad — pillar orange
    case 3:
      return const Color(0xFF8E8E93); // meh — neutral grey
    case 4:
      return const Color.fromARGB(255, 151, 243, 255); // good — pillar green
    case 5:
      return const Color.fromARGB(255, 74, 255, 144); // awesome — ice cyan
    default:
      return const Color(0xFF8E8E93);
  }
}

/// Mood color for fractional scores (e.g. daily averages on the chart).
Color mindMoodColorAt(double moodScore) {
  if (moodScore >= 6) return mindMoodAccent(6);
  final clamped = moodScore.clamp(1.0, 5.0);
  final lower = clamped.floor();
  final upper = clamped.ceil();
  if (lower == upper) return mindMoodAccent(lower);
  final t = clamped - lower;
  return Color.lerp(mindMoodAccent(lower), mindMoodAccent(upper), t)!;
}

/// Secondary tone for gradients / area fills under the line chart.
Color mindMoodSoft(double moodScore) {
  return mindMoodColorAt(moodScore).withValues(alpha: 0.28);
}

/// Secondary tone for integer mood scores (icons, chips).
Color mindMoodSoftInt(int moodScore) => mindMoodSoft(moodScore.toDouble());

bool isBoostMoodScore(int moodScore) => moodScore >= 6;

IconData mindMoodIcon(int moodScore) {
  if (moodScore >= 6) return Icons.auto_awesome_rounded;
  switch (moodScore.clamp(1, 5)) {
    case 1:
      return Icons.sentiment_very_dissatisfied_rounded;
    case 2:
      return Icons.sentiment_dissatisfied_rounded;
    case 3:
      return Icons.sentiment_neutral_rounded;
    case 4:
      return Icons.sentiment_satisfied_alt_rounded;
    case 5:
      return Icons.sentiment_very_satisfied_rounded;
    default:
      return Icons.sentiment_neutral_rounded;
  }
}
