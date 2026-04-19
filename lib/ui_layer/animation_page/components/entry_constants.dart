import 'package:flutter/material.dart';

class EntryColors {
  // --- Silver Elegance Palette ---
  static const Color arcticSilver = Color(0xFFE5E5EA);    // Brightest metallic
  static const Color midSilver   = Color(0xFFA1A1A6);    // Neutral metallic
  static const Color frostedWhite = Color(0xFFF2F2F7);    // Lightest crystalline highlight
  static const Color deepGlacier = Color(0xFF1C1C1E);    // Dark silver / gunmetal
  static const Color obsidianBase = Color(0xFF030303);    // Deep black foundation
  static const Color darkSilver   = Color(0xFF8E8E93);    // Muted grey-silver
  static const Color neonSilver   = Color(0xFFD1D1D6);    // High-contrast silver for accents
  static const Color glassBorder  = Color(0x40FFFFFF);    // Translucent white for glass edges

  // --- "Previous Bro" Cyberpunk Palette ---
  static const Color electricViolet = Color(0xFFBF5AF2);  // iOS Vivid Purple
  static const Color cyberMagenta  = Color(0xFFFF00FF);  // Vivid Magenta
  static const Color cyberCyan     = Color(0xFF00FFFF);  // Vivid Cyan
  static const Color neonPurple    = Color(0xFF8A2BE2);

  // --- Crystal Compass Logo Palette (Department Coding) ---
  static const Color financeYellow = Color(0xFFFFD60A);  // Crystalline Gold
  static const Color healthGreen   = Color(0xFF32D74B);  // Crystalline Emerald
  static const Color projectBlue   = Color(0xFF0A84FF);  // Crystalline Sapphire
  static const Color socialPurple  = Color(0xFFBF5AF2);  // Crystalline Amethyst

  // --- Visual Excellence Tokens ---
  static const Gradient obsidianGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      deepGlacier,  // Subtle metallic center highlight
      obsidianBase, // Deep void edges
    ],
    stops: [0.0, 0.8],
  );
  
  static const Color accentSilver = Color(0xFFC7C7CC); 
}

class EntryStyles {
  static const TextStyle authStatus = TextStyle(
    color: EntryColors.midSilver,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: 4.0,
    shadows: [
      Shadow(
        color: EntryColors.arcticSilver,
        blurRadius: 8,
      ),
    ],
  );
}
