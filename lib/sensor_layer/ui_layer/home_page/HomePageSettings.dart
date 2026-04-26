import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomePageSettings extends StatelessWidget {
  final ConfigBlock configBlock;

  const HomePageSettings({super.key, required this.configBlock});

  static void show(BuildContext context, ConfigBlock configBlock) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HomePageSettings(configBlock: configBlock),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settings_title ?? "Home Page Settings",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildToggleTile(
            context,
            icon: Icons.air_rounded,
            title: l10n.health_metrics_air_quality,
            value: configBlock.showAqi.watch(context),
            onChanged: (val) => configBlock.setAqiVisibility(val),
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildToggleTile(
            context,
            icon: Icons.wb_sunny_rounded,
            title: l10n.health_metrics_weather,
            value: configBlock.showWeather.watch(context),
            onChanged: (val) => configBlock.setWeatherVisibility(val),
            color: Colors.orange,
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.common_done ?? "Done",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: SwitchListTile.adaptive(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
    );
  }
}
