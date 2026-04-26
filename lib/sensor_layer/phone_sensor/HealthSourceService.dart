import 'package:flutter/material.dart';

/// Standardized data sources for health metrics
enum HealthDataSource { gt6, appleHealth, manual, app }

/// Service to manage and identify the source of health data.
/// Located in sensor_layer as it bridges physical devices/platform APIs with the app.
class HealthSourceService {
  // Constant strings to match database entries
  static const String sourceGT6 = 'GT6';
  static const String sourceAppleHealth = 'AppleHealth';
  static const String sourceManual = 'Manual';
  static const String sourceApp = 'App';

  /// Returns the standardized label for a given source string
  static String getLabel(String? source) {
    if (source == null) return "DEVICE (GT6)";

    final s = source.toLowerCase();
    if (s.contains('applehealth') || s.contains('apple'))
      return "PHONE (APPLE)";
    if (s.contains('gt6')) return "DEVICE (GT6)";
    if (s.contains('manual')) return "MANUAL";
    if (s.contains('app')) return "SYSTEM";

    return source.toUpperCase();
  }

  /// Returns the appropriate icon for a given source string
  static IconData getIcon(
    String? source, {
    IconData fallback = Icons.watch_rounded,
  }) {
    final label = getLabel(source);

    switch (label) {
      case "PHONE (APPLE)":
        return Icons.smartphone_rounded;
      case "DEVICE (GT6)":
        return Icons.watch_rounded;
      case "MANUAL":
        return Icons.edit_note_rounded;
      case "SYSTEM":
        return Icons.apps_rounded;
      default:
        return fallback;
    }
  }

  /// Returns the signature brand color for each data source
  static Color getSourceColor(String? source, ColorScheme colorScheme) {
    final s = source?.toLowerCase() ?? '';
    if (s.contains('applehealth') || s.contains('apple')) {
      return const Color(0xFFFF2D55); // Apple Red
    }
    if (s.contains('gt6')) {
      return const Color(0xFFFF9500); // GT6 Orange/Gold
    }
    if (s.contains('manual')) {
      return const Color(0xFF34C759); // Manual Green
    }
    if (s.contains('app')) {
      return const Color(0xFF5856D6); // App Indigo/Purple
    }
    return colorScheme.primary;
  }

  /// Helper to determine if a source is a physical wearable
  static bool isWearable(String? source) {
    final label = getLabel(source);
    return label == sourceGT6;
  }
}
