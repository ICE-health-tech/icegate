import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Theme/JsonThemeAdapter.dart';
import 'package:signals/signals.dart';

// --- ThemeAdapter (Utility remains static, but its usage moves into the store) ---

class ThemeAdapter {
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color darkPrimaryColor = Color(0xFFBB86FC);

  // Load Neumorphic theme from asset utility
  static Future<ThemeData> parse(String assetPath) async {
    // ⚠️ Ensure JsonThemeAdapter.loadThemeFromAsset returns NeumorphicThemeData
    ThemeData themeData = await JsonThemeAdapter.loadThemeFromAsset(assetPath);
    return themeData;
  }

  // Static Material Theme Getters (remain the same)
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      // ... rest of lightTheme implementation ...
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      useMaterial3: true,
      // ... rest of darkTheme implementation ...
    );
  }
}

// --- Signals Theme Store ---

class ThemeStore {
  // 2. SIGNAL STATE: The current theme data that the UI will react to
  final currentMaterialTheme = signal<ThemeData>(ThemeAdapter.lightTheme);

  final currentTheme = signal<ThemeData?>(null); // Nullable until loaded

  // Signal to track the current mode (useful for UI buttons/toggles)
  final currentThemeMode = signal<ThemeMode>(ThemeMode.system);

  // 3. ACTIONS: Functions that change the signal state
  void setMaterialThemeMode(ThemeMode mode) {
    currentThemeMode.value = mode;
    if (mode == ThemeMode.light) {
      currentMaterialTheme.value = ThemeAdapter.lightTheme;
    } else if (mode == ThemeMode.dark) {
      currentMaterialTheme.value = ThemeAdapter.darkTheme;
    }
    // If ThemeMode.system, the MaterialApp will handle it automatically
  }

  Future<void> loadTheme(String assetPath) async {
    try {
      // Set the signal state after loading the theme asynchronously
      currentTheme.value = await ThemeAdapter.parse(assetPath);
    } catch (e) {
      print("Error loading Neumorphic theme: $e");
      // Handle error (e.g., set to a default theme)
    }
  }

  ThemeStore();
}
