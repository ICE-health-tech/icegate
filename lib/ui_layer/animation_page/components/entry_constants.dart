import 'package:flutter/material.dart';

class EntryColors {
  // Arctic / Ice Palette (Neutral Silver)
  static const Color obsidianBase = Color(0xFF030303); // Total Black/Obsidian
  static const Color arcticSilver = Color(0xFFD1D1D6); // Bright Silver
  static const Color frostedWhite = Color(0xFFF2F2F7);
  static const Color iceBlue = Color(0xFF8E8E93); // Muted Silver/Grey
  static const Color deepGlacier = Color(0xFF1C1C1E); // Dark Graphite

  // Accents
  static const Color neonSilver = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF); // 20% Silver
  static const Color auroraGlow = Color(0x1AFFFFFF); // 10% Silver

  // Secondary Silvers
  static const Color darkSilver = Color(0xFF3A3A3C);
  static const Color midSilver = Color(0xFF636366);

  static Color? get electricViolet => null;
}

class EntryStyles {
  static const double glassBlur = 20.0;
  static const double borderOpacity = 0.15;
  static const double glassOpacity = 0.05;

  static const TextStyle premiumLabel = TextStyle(
    color: EntryColors.arcticSilver,
    fontSize: 13,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle authStatus = TextStyle(
    color: Colors.white,
    fontSize: 10,
    letterSpacing: 4,
  );
}
