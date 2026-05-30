import 'package:flutter/material.dart';

/// Dashboard palette — health grid + home (duylongart_glass_ui.md).
abstract final class HealthMetricColors {
  static const Color pageBackground = Color(0xFF0B121C);
  static const Color iceBgDeep = Color(0xFF060B13);
  static const Color iceBgMid = Color(0xFF0D1622);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textEtched = Color.fromRGBO(173, 216, 230, 0.5);
  static const Color textEtchedStrong = Color.fromRGBO(173, 216, 230, 0.7);

  static const Color glassElevated = Color.fromRGBO(255, 255, 255, 0.055);
  static const Color glassChip = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color borderBright = Color.fromRGBO(255, 255, 255, 0.14);

  static const Color progressGreen = Color(0xFF4CD964);
  static const Color cardBorder = Color(0x14FFFFFF);
  static const Color tempAccent = Color(0xFF64D2FF);
  static const Color aqiModerate = Color(0xFFFFB703);
  static const Color linkAccent = Color(0xFF64D2FF);

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
  static Color cardTintForId(String id) {
    switch (id.toLowerCase()) {
      case 'food':
      case 'calories':
      case 'net_calories':
        return const Color(0xFF16221F);
      case 'steps':
        return const Color(0xFF141E28);
      case 'weight':
        return const Color(0xFF182129);
      case 'water':
        return const Color(0xFF152028);
      case 'exercise':
        return const Color(0xFF1E1A24);
      case 'heart_rate':
        return const Color(0xFF1F1B26);
      case 'sleep':
        return const Color(0xFF1C1828);
      case 'focus':
        return const Color(0xFF151D2A);
      case 'oxygen':
      case 'oxygen_saturation':
        return const Color(0xFF182129);
      case 'weather':
        return const Color(0xFF1C1E22);
      case 'air_quality':
        return const Color(0xFF1A2218);
      default:
        return const Color(0xFF151A22);
    }
  }

  /// Icon / progress accent per metric.
  static Color accentForId(String id) {
    switch (id.toLowerCase()) {
      case 'food':
      case 'calories':
      case 'net_calories':
        return const Color(0xFF4CD964);
      case 'steps':
        return const Color(0xFF34C759);
      case 'weight':
        return const Color(0xFF5AC8FA);
      case 'water':
        return const Color(0xFF64D2FF);
      case 'exercise':
        return const Color(0xFFFF9F0A);
      case 'heart_rate':
        return const Color(0xFFFF375F);
      case 'sleep':
        return const Color(0xFFBF5AF2);
      case 'focus':
        return const Color(0xFF0A84FF);
      case 'oxygen':
      case 'oxygen_saturation':
        return const Color(0xFF64D2FF);
      case 'weather':
        return const Color(0xFFFFD60A);
      case 'air_quality':
        return const Color(0xFF30D158);
      default:
        return const Color(0xFF8E8E93);
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
  static Color homePillarCardTint(String pillar) {
    switch (pillar) {
      case 'health':
        return cardTintForId('steps');
      case 'finance':
        return cardTintForId('water');
      case 'mind':
        return cardTintForId('sleep');
      case 'projects':
        return const Color(0xFF1F1C18);
      default:
        return const Color(0xFF151A22);
    }
  }

  /// Home pillar icon / glow accent.
  static Color homePillarAccent(String pillar) {
    switch (pillar) {
      case 'health':
        return accentForId('steps');
      case 'finance':
        return accentForId('water');
      case 'mind':
        return accentForId('sleep');
      case 'projects':
        return accentForId('weather');
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
