import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart'
    hide ThemeData;
import 'package:ice_shield/initial_layer/ThemeLayer/CurrentThemeData.dart';
import 'package:provider/provider.dart';
import 'package:ice_shield/data_layer/Protocol/Theme/ThemeAdapter.dart';

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
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        final size = MediaQuery.of(context).size;

        return Center(
          child: Container(
            width: size.width * 0.8, // Slightly wider for better text fit
            height: size.height * 0.7, // Prevent screen overflow
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24), // Softer, modern corners
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          _buildThemeOption(
                            context,
                            'Haven',
                            'assets/DefaultTheme.json',
                            Icons.security_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Cyberpunk 2077 ',
                            'assets/Cyberpunk.json',
                            Icons.bolt_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Sakura Zen 🌸',
                            'assets/SakuraZen.json',
                            Icons.spa_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Emerald Forest 🌲',
                            'assets/EmeraldForest.json',
                            Icons.forest_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Nordic Night ❄️',
                            'assets/NordicNight.json',
                            Icons.ac_unit_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Royal Velvet 👑',
                            'assets/RoyalVelvet.json',
                            Icons.workspace_premium_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Midnight Gold',
                            'assets/MidnightGold.json',
                            Icons.nights_stay_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Deep Sea',
                            'assets/DeepSea.json',
                            Icons.waves_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Frosty Morning',
                            'assets/Frosty.json',
                            Icons.wb_sunny_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Light Purple',
                            'assets/LightThemePurple.json',
                            Icons.auto_awesome_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Purple Seed',
                            'assets/PurpleSeed.json',
                            Icons.egg_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Midnight Nebula',
                            'assets/MidnightNebula.json',
                            Icons.cloud_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Sunset Horizon',
                            'assets/SunsetHorizon.json',
                            Icons.wb_twilight_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Forest Whisper',
                            'assets/ForestWhisper.json',
                            Icons.hearing_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Volcano 🌋',
                            'assets/Volcano.json',
                            Icons.volcano_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Ocean Deep 🌊',
                            'assets/OceanDeep.json',
                            Icons.waves_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Cyberpunk Pink 💖',
                            'assets/CyberpunkPink.json',
                            Icons.flash_on_rounded,
                          ),
                          _buildThemeOption(
                            context,
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                          ),

                          _buildThemeOption(
                            context,
                            'Seed Blue',
                            'assets/SeedBlue.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Seed Green',
                            'assets/SeedGreen.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Seed Orange',
                            'assets/SeedOrange.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Seed Pink (Dark)',
                            'assets/SeedPink.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Seed Red',
                            'assets/SeedRed.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            context,
                            'Seed Teal',
                            'assets/SeedTeal.json',
                            Icons.palette_rounded,
                          ),
                          _buildThemeOption(
                            context,
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

  static Widget _buildThemeOption(
    BuildContext context,
    String name,
    String assetPath,
    IconData iconData,
  ) {
    final width = MediaQuery.of(context).size.width;

    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = colorScheme
        .primary; // Use the theme's primary color as default for ElevatedButton

    // Improved luminance check for better contrast
    final double luminance = buttonColor.computeLuminance();
    final Color textColor = luminance > 0.5 ? Colors.black : Colors.white;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // More rounded for attractiveness
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: SizedBox(
        width: width * 0.5,
        child: Row(
          children: [
            Icon(iconData, size: 20, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),

      onPressed: () {
        Provider.of<ThemeStore>(context, listen: false).loadTheme(assetPath);
        ThemeDAO themeDAO = ThemeDAO(context.read<AppDatabase>());
        themeDAO.saveCurrentTheme(CurrentThemeData(themePath: assetPath));

        // var currentThemeData = themeDAO.getCurrentTheme();
        // printCurrentThemeData(context);
        Navigator.of(context).pop();
      },
    );
  }
}
