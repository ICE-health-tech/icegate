import 'package:flutter/material.dart';

/// Dashboard palette — health grid + home (duylongart_glass_ui.md).
abstract final class HealthMetricColors {
  static const Color pageBackground = Color.fromARGB(255, 72, 95, 128);
  static const Color iceBgDeep = Color.fromARGB(255, 76, 109, 161);
  static const Color iceBgMid = Color.fromARGB(255, 51, 86, 131);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textEtched = Color.fromRGBO(173, 216, 230, 0.5);
  static const Color textEtchedStrong = Color.fromRGBO(173, 216, 230, 0.7);

  static const Color glassElevated = Color.fromRGBO(255, 255, 255, 0.055);
  static const Color glassChip = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color borderBright = Color.fromRGBO(255, 255, 255, 0.14);

  static const Color progressGreen = Color(0xFF4CD964);
  static const Color cardBorder = Color(0x14FFFFFF);

  /// MainShell Dynamic Island fill (dark).
  static const Color shellIslandFill = Color(0xFF141A22);

  /// Page scaffold background — dark immersive base, light matches HealthPage.
  static Color pageBackgroundColor(ColorScheme cs, {required bool isDark}) =>
      isDark ? pageBackground : cs.surface;

  /// Primary text/icons on health subpages.
  static Color ink(ColorScheme cs, {required bool isDark}) =>
      isDark ? textPrimary : cs.onSurface;

  /// Secondary labels (section headers, subtitles).
  static Color mutedInk(ColorScheme cs, {required bool isDark}) =>
      isDark ? textSecondary : cs.onSurfaceVariant;

  /// Faint placeholders / empty states.
  static Color faintInk(
    ColorScheme cs, {
    required bool isDark,
    double darkAlpha = 0.38,
    double lightAlpha = 0.45,
  }) =>
      isDark
          ? Colors.white.withValues(alpha: darkAlpha)
          : cs.onSurface.withValues(alpha: lightAlpha);

  /// Glass card fill — dark: white overlay, light: surface container.
  static Color glassFill(
    ColorScheme cs, {
    required bool isDark,
    double darkAlpha = 0.05,
  }) =>
      isDark
          ? Colors.white.withValues(alpha: darkAlpha)
          : cs.surfaceContainerHighest.withValues(alpha: 0.55);

  /// Glass card border.
  static Color glassBorder(
    ColorScheme cs, {
    required bool isDark,
    double darkAlpha = 0.1,
  }) =>
      isDark
          ? Colors.white.withValues(alpha: darkAlpha)
          : cs.outline.withValues(alpha: 0.35);

  /// Icon button chip behind back/settings.
  static Color iconChipFill(ColorScheme cs, {required bool isDark}) =>
      isDark
          ? Colors.white.withValues(alpha: 0.05)
          : cs.surfaceContainerHighest.withValues(alpha: 0.6);

  /// Bottom sheet / modal fill.
  static Color sheetFill(ColorScheme cs, {required bool isDark}) =>
      isDark ? const Color(0xFF1A1A1A) : cs.surfaceContainerHigh;

  /// Panel surfaces synced with MainShell — light: white panels, dark: island fill.
  static BoxDecoration shellPanel(
    ColorScheme cs, {
    required bool isDark,
    double radius = 18,
    Color? accent,
  }) {
    return BoxDecoration(
      color: isDark
          ? shellIslandFill
          : cs.surfaceContainerHighest.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent != null
            ? accent.withValues(alpha: isDark ? 0.48 : 0.5)
            : (isDark ? borderBright : cs.outline.withValues(alpha: 0.44)),
        width: isDark ? 1.0 : 1.2,
      ),
    );
  }
  static const Color tempAccent = Color(0xFF64D2FF);
  static const Color aqiModerate = Color(0xFFFFB703);
  static const Color linkAccent = Color(0xFF64D2FF);

  /// Shared dashboard accent palette (health / finance / mind / projects).
  static const Color pillarGreen = Color(0xFF34C759);
  static const Color pillarBlue = Color(0xFF0A84FF);
  static const Color pillarViolet = Color(0xFFBF5AF2);
  static const Color pillarYellow = Color(0xFFFFD60A);
  static const Color pillarOrange = Color(0xFFFF9500);

  /// Health metric cards: subtle green outline.
  static Color metricCardBorder({required bool isDark}) => isDark
      ? progressGreen.withValues(alpha: 0.38)
      : pillarGreen.withValues(alpha: 0.42);

  static Color metricCardFill(ColorScheme cs, {required bool isDark}) => isDark
      ? Color.alphaBlend(
          pillarGreen.withValues(alpha: 0.04),
          glassChip,
        )
      : cs.surfaceContainerHighest.withValues(alpha: 0.55);

  static const List<Color> pillarAccents = [
    pillarGreen,
    pillarBlue,
    pillarViolet,
    pillarYellow,
  ];

  static Color pillarAccentAt(int index) =>
      pillarAccents[index % pillarAccents.length];

  static Color pillarCardTintAt(int index) =>
      _cardTintForAccent(pillarAccentAt(index));

  static Color _cardTintForAccent(Color accent) =>
      Color.alphaBlend(accent.withValues(alpha: 0.16), const Color(0xFF0D1218));

  /// AQI value color (matches health + home weather pill).
  static Color aqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF30D158);
    if (aqi <= 100) return aqiModerate;
    if (aqi <= 150) return const Color(0xFFFF9F0A);
    if (aqi <= 200) return const Color(0xFFFF453A);
    if (aqi <= 300) return const Color(0xFFBF5AF2);
    return const Color(0xFFAC8E68);
  }

  /// Dark card fill per metric category.
  static Color cardTintForId(String id) =>
      _cardTintForAccent(accentForId(id));

  /// Icon / progress accent per metric.
  static Color accentForId(String id) {
    switch (id.toLowerCase()) {
      case 'food':
      case 'calories':
      case 'net_calories':
      case 'steps':
      case 'air_quality':
        return pillarGreen;
      case 'water':
      case 'weight':
      case 'focus':
      case 'oxygen':
      case 'oxygen_saturation':
        return pillarBlue;
      case 'sleep':
      case 'heart_rate':
        return pillarViolet;
      case 'exercise':
      case 'weather':
        return pillarYellow;
      default:
        return textSecondary;
    }
  }

  /// Progress bar fill — steps/food use system green; others use accent.
  static Color progressColorForId(String id) {
    switch (id.toLowerCase()) {
      case 'steps':
      case 'food':
      case 'calories':
        return progressGreen;
      default:
        return accentForId(id);
    }
  }

  /// Home "4 phía cạnh" pillar card background.
  static Color homePillarCardTint(String pillar) =>
      _cardTintForAccent(homePillarAccent(pillar));

  /// Home pillar icon / glow accent.
  static Color homePillarAccent(String pillar) {
    switch (pillar) {
      case 'health':
        return pillarGreen;
      case 'finance':
        return const Color.fromARGB(255, 52, 146, 218);
      case 'mind':
        return pillarViolet;
      case 'projects':
        return const Color.fromARGB(255, 252, 120, 38);
      default:
        return textSecondary;
    }
  }

  static String homePillarKeyFromRoute(String route) {
    switch (route) {
      case '/health':
        return 'health';
      case '/finance':
        return 'finance';
      case '/social':
        return 'mind';
      case '/projects':
        return 'projects';
      default:
        return 'default';
    }
  }

  /// L3 plugin dock tile background.
  static Color pluginCardTint(String pluginId) {
    switch (pluginId.toLowerCase()) {
      case 'aqi':
      case 'air_quality':
        return cardTintForId('air_quality');
      case 'weather':
        return cardTintForId('weather');
      case 'health':
        return homePillarCardTint('health');
      case 'finance':
        return homePillarCardTint('finance');
      case 'social':
        return homePillarCardTint('mind');
      case 'projects':
        return homePillarCardTint('projects');
      case 'focus':
        return cardTintForId('focus');
      case 'google':
        return const Color(0xFF1C1E22);
      case 'integrations':
        return cardTintForId('focus');
      default:
        return const Color(0xFF151A22);
    }
  }

  static Color pluginAccent(String pluginId) {
    switch (pluginId.toLowerCase()) {
      case 'aqi':
      case 'air_quality':
        return aqiModerate;
      case 'weather':
        return tempAccent;
      case 'google':
        return const Color(0xFFFFD60A);
      case 'integrations':
        return linkAccent;
      case 'health':
        return homePillarAccent('health');
      case 'finance':
        return homePillarAccent('finance');
      case 'social':
        return homePillarAccent('mind');
      case 'projects':
        return homePillarAccent('projects');
      case 'focus':
        return accentForId('focus');
      default:
        return tempAccent;
    }
  }

  static Color pluginCardTintFromName(String name) =>
      pluginCardTint(name.toLowerCase().split(' ').first);

  static Color pluginAccentFromName(String name) =>
      pluginAccent(name.toLowerCase().split(' ').first);
}
