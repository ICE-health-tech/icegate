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

  // --- Metallic Silver Excellence ---
  static const Color platinumSilver  = Color(0xFFE8E8E8);  // Ultra-bright silver
  static const Color mercurySilver   = Color(0xFFC0C0C0);  // Classic liquid silver
  static const Color polishedSteel   = Color(0xFF848482);  // Deep reflections
  static const Color sapphireBlue    = Color(0xFF007AFF);  // Premium Sapphire Blue
  static const Color deepNavy        = Color(0xFF001A3D);  // Deep context blue
  static const Color pitShadow       = Color(0x802C2C2E);  // Shadow for cracker pits

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

  static const Gradient silverMetallicGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      Color(0xFF2C2C2E), // Metallic gunmetal core
      Color(0xFF1C1C1E), // Deep glacier middle
      Color(0xFF030303), // Deep obsidian edges
    ],
    stops: [0.0, 0.4, 1.0],
  );
  
  static const Color accentSilver = Color(0xFFC7C7CC); 

  // --- Diamond Ice Theme (Crystal Bloom) ---
  static const Color primaryIceBlue  = Color(0xFF839BF3);  // User's preferred light blue
  static const Color primaryIceLight = Color(0xFFA5B4FC);  // Softer highlight variant
  static const Color diamondWhite    = Color(0xFFF0FDFA);  // Crystalline highlight
  static const Color iceCyan         = Color(0xFF00E5FF);  // Luminous pulse
  static const Color glacierBlue     = Color(0xFF839BF3);  // Synchronized with primary
  static const Color sapphireCrystal = Color(0xFF4F46E5);  // Deep crystal depth
  static const Color glacierBase     = Color(0xFF050B18);  // Deep midnight navy base

  static const Gradient iceGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      Color(0xFF0A192F), // Icy core
      Color(0xFF050B18), // Deep glacier base
      Color(0xFF020617), // Deepest midnight navy
    ],
    stops: [0.0, 0.5, 1.0],
  );
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
