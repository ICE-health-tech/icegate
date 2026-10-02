import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'
    hide ThemeData;
import 'package:ice_gate/orchestration_layer/ThemeLayer/CurrentThemeData.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/Protocol/Theme/ThemeAdapter.dart';

class ThemeManager {
  static Widget icon(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.palette),
      tooltip: "Change Theme",
      onPressed: () => {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showThemeSelectionDialog(context);
          }
        }),
      },
    );
  }

  static void showThemeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final size = MediaQuery.of(dialogContext).size;
        final textTheme = Theme.of(dialogContext).textTheme;

        return Center(
          child: Container(
            width: size.width * 0.8, // Slightly wider for better text fit
            height: size.height * 0.7, // Prevent screen overflow
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24), // Softer, modern corners
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Appearance",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable List
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    "Watch-style",
                                    style: textTheme.labelLarge?.copyWith(
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Watchface Noir ⌚',
                            'assets/WatchfaceNoir.json',
                            Icons.watch_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Watchface Rose Gold',
                            'assets/WatchfaceRoseGold.json',
                            Icons.diamond_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Watchface Sterling',
                            'assets/WatchfaceSterling.json',
                            Icons.schedule_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Watchface Midnight Navy',
                            'assets/WatchfaceMidnightNavy.json',
                            Icons.water_drop_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Watchface Forest Night',
                            'assets/WatchfaceForestNight.json',
                            Icons.forest_rounded,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    "Presets",
                                    style: textTheme.labelLarge?.copyWith(
                                          letterSpacing: 0.8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Data Dashboard 📊',
                            'assets/DataDenseDashboard.json',
                            Icons.dashboard_customize_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Haven',
                            'assets/DefaultTheme.json',
                            Icons.security_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Nostalgia 📼',
                            'assets/NostalgiaTheme.json',
                            Icons.settings_backup_restore_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Cyberpunk 2077 ',
                            'assets/Cyberpunk.json',
                            Icons.bolt_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Sakura Zen 🌸',
                            'assets/SakuraZen.json',
                            Icons.spa_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Emerald Forest 🌲',
                            'assets/EmeraldForest.json',
                            Icons.forest_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Nordic Night ❄️',
                            'assets/NordicNight.json',
                            Icons.ac_unit_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Royal Velvet 👑',
                            'assets/RoyalVelvet.json',
                            Icons.workspace_premium_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Midnight Gold',
                            'assets/MidnightGold.json',
                            Icons.star_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Deep Sea',
                            'assets/DeepSea.json',
                            Icons.waves_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Frosty Morning',
                            'assets/Frosty.json',
                            Icons.wb_sunny_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Light Purple',
                            'assets/LightThemePurple.json',
                            Icons.auto_awesome_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Purple Seed',
                            'assets/PurpleSeed.json',
                            Icons.egg_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Midnight Nebula',
                            'assets/MidnightNebula.json',
                            Icons.cloud_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Sunset Horizon',
                            'assets/SunsetHorizon.json',
                            Icons.wb_twilight_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Forest Whisper',
                            'assets/ForestWhisper.json',
                            Icons.eco_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Volcano 🌋',
                            'assets/Volcano.json',
                            Icons.volcano_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Ocean Deep 🌊',
                            'assets/OceanDeep.json',
                            Icons.waves_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Cyberpunk Pink 💖',
                            'assets/CyberpunkPink.json',
                            Icons.flash_on_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Enchanted Forest ✨',
                            'assets/EnchantedForest.json',
                            Icons.nature_people_rounded,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    "Core Colors",
                                    style: textTheme.bodySmall,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                          ),

                          _buildThemeOption(
                            dialogContext,
                            'Seed Blue',
                            'assets/SeedBlue.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Seed Green',
                            'assets/SeedGreen.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Seed Orange',
                            'assets/SeedOrange.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Seed Pink (Dark)',
                            'assets/SeedPink.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Seed Red',
                            'assets/SeedRed.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Seed Teal',
                            'assets/SeedTeal.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            dialogContext,
                            'Seed Indigo',
                            'assets/SeedIndigo.json',
                            Icons.palette_rounded,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<_ThemePreview?> _loadThemePreview(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final scheme = json['color_scheme'] as Map<String, dynamic>?;
      Color parse(String? hex, String fallback) {
        if (hex == null || hex.isEmpty) return _parseHexColor(fallback);
        return _parseHexColor(hex);
      }

      final seed = json['seed_color']?.toString() ?? '0xFF6200EE';
      return _ThemePreview(
        primary: parse(scheme?['primary']?.toString(), seed),
        secondary: parse(scheme?['secondary']?.toString(), seed),
        surface: parse(scheme?['surface']?.toString(), '0xFFF5F5F5'),
        isDark: (json['brightness']?.toString().toLowerCase() ?? 'light') ==
            'dark',
      );
    } catch (_) {
      return null;
    }
  }

  static Color _parseHexColor(String hex) {
    var clean = hex.trim().replaceAll(RegExp(r'[^\dA-Fa-f0-9xX]'), '');
    if (clean.startsWith('0x') || clean.startsWith('0X')) {
      clean = clean.substring(2);
    }
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  }

  static Widget _buildThemeOption(
    BuildContext context,
    String name,
    String assetPath,
    IconData iconData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: FutureBuilder<_ThemePreview?>(
        future: _loadThemePreview(assetPath),
        builder: (context, snapshot) {
          final preview = snapshot.data;
          final primary = preview?.primary ?? colorScheme.primary;
          final secondary = preview?.secondary ?? colorScheme.secondary;
          final iconOnSwatch =
              primary.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

          return Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Provider.of<ThemeStore>(context, listen: false)
                    .loadTheme(assetPath);
                final themeDAO = LegacyThemeDAO(context.read<AppDatabase>());
                themeDAO.saveCurrentTheme(CurrentThemeData(themePath: assetPath));
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, secondary],
                        ),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(iconData, size: 22, color: iconOnSwatch),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (preview != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              preview.isDark ? 'Dark theme' : 'Light theme',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      preview?.isDark == true
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemePreview {
  const _ThemePreview({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.isDark,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final bool isDark;
}
