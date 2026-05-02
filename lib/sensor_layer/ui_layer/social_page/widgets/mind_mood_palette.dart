import 'package:flutter/material.dart';

/// Consistent mood colors for charts, icons, and journal cards (scores 1–5).
Color mindMoodAccent(int moodScore) {
  switch (moodScore.clamp(1, 5)) {
    case 1:
      return const Color(0xFFE57373); // soft red
    case 2:
      return const Color(0xFFFFB74D); // amber
    case 3:
      return const Color(0xFFB0BEC5); // blue-grey (neutral)
    case 4:
      return const Color(0xFF69F0AE); // mint green
    case 5:
      return const Color(0xFF64FFDA); // cyan “awesome”
    default:
      return const Color(0xFFB0BEC5);
  }
}

/// Secondary tone for gradients / area fills under the line chart.
Color mindMoodSoft(int moodScore) {
  return mindMoodAccent(moodScore).withValues(alpha: 0.28);
}
