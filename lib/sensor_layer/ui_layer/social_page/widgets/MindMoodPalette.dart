import 'package:flutter/material.dart';

/// Consistent mood colors for charts, icons, and journal cards (scores 1–5).
/// Aligned with [HealthMetricColors] pillar accents (red → orange → grey → green → cyan).
Color mindMoodAccent(int moodScore) {
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
