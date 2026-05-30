import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

/// Finance module chrome — black borders on light, silver borders on dark.
abstract final class FinanceSurface {
  static Color border({required bool isDark}) => isDark
      ? EntryColors.neonSilver.withValues(alpha: 0.62)
      : EntryColors.deepGlacier.withValues(alpha: 0.78);

  static Color ink({required bool isDark}) =>
      isDark ? EntryColors.frostedWhite : EntryColors.deepGlacier;

  static Color mutedInk({required bool isDark}) => isDark
      ? EntryColors.darkSilver
      : EntryColors.polishedSteel;

  static Color silverAccent() => EntryColors.financeSilverAccent;

  static Color currencyPillBackground({
    required bool isDark,
    required bool active,
  }) =>
      active ? ink(isDark: isDark) : Colors.transparent;

  static Color currencyPillForeground({
    required bool isDark,
    required bool active,
  }) =>
      active
          ? (isDark ? EntryColors.obsidianBase : EntryColors.frostedWhite)
          : mutedInk(isDark: isDark);

  static BoxDecoration panel(
    ColorScheme cs, {
    required bool isDark,
    double radius = 18,
  }) {
    return BoxDecoration(
      color: isDark
          ? EntryColors.obsidianBase.withValues(alpha: 0.94)
          : EntryColors.frostedWhite.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: border(isDark: isDark),
        width: isDark ? 1.0 : 1.15,
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? EntryColors.neonSilver : EntryColors.deepGlacier)
              .withValues(alpha: isDark ? 0.07 : 0.09),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
