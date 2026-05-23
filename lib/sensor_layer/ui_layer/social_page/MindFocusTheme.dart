import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';

/// Applies the active focus area accent across [ThemeData] for the Mind page.
ThemeData mindFocusThemed(ThemeData base, MindFocusTrend? focus) {
  if (focus == null) return base;

  final accent = focus.color;
  final onAccent = accent.computeLuminance() > 0.45
      ? const Color(0xFF0D1117)
      : Colors.white;
  final cs = base.colorScheme;

  return base.copyWith(
    colorScheme: cs.copyWith(
      primary: accent,
      onPrimary: onAccent,
      secondary: Color.lerp(accent, cs.secondary, 0.25) ?? accent,
      onSecondary: onAccent,
      tertiary: Color.lerp(accent, cs.tertiary, 0.4) ?? accent,
      primaryContainer: accent.withValues(alpha: 0.22),
      onPrimaryContainer: accent,
      secondaryContainer: accent.withValues(alpha: 0.14),
      surfaceTint: accent,
    ),
  );
}
