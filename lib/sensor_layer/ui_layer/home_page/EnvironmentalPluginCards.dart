import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/UIConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AQIPluginCard extends StatelessWidget {
  final EnvironmentalBlock envBlock;
  const AQIPluginCard({super.key, required this.envBlock});

  @override
  Widget build(BuildContext context) {
    final envData = envBlock.currentData.watch(context);
    final isLoading = envBlock.isLoading.watch(context);
    final l10n = AppLocalizations.of(context)!;
    final aqi = envData?.aqi ?? 0;

    return _BasePluginCard(
      pluginId: 'aqi',
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => AQISourceSheet(),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            Text(
              envData?.aqi.toString() ?? '--',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: HealthMetricColors.aqiColor(aqi),
              ),
            ),
            const SizedBox(height: 2),
            AutoSizeText(
              l10n.health_metrics_air_quality.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 9,
                color: HealthMetricColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}

class WeatherPluginCard extends StatelessWidget {
  final EnvironmentalBlock envBlock;
  const WeatherPluginCard({super.key, required this.envBlock});

  @override
  Widget build(BuildContext context) {
    final envData = envBlock.currentData.watch(context);
    final isLoading = envBlock.isLoading.watch(context);
    final l10n = AppLocalizations.of(context)!;

    return _BasePluginCard(
      pluginId: 'weather',
      onTap: () => context.push('/health/temperature'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  envData?.temperature.toStringAsFixed(0) ?? '--',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: HealthMetricColors.tempAccent,
                  ),
                ),
                const Text(
                  '°',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: HealthMetricColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            AutoSizeText(
              l10n.health_metrics_weather.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 9,
                color: HealthMetricColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _BasePluginCard extends StatelessWidget {
  final String pluginId;
  final Widget child;
  final VoidCallback onTap;

  const _BasePluginCard({
    required this.pluginId,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sizeOfWidget = UIConstants.getSizeOfWidget(context);
    final tint = HealthMetricColors.pluginCardTint(pluginId);
    final accent = HealthMetricColors.pluginAccent(pluginId);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: sizeOfWidget,
        height: sizeOfWidget,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: HealthMetricColors.cardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class AQISourceSheet extends StatelessWidget {
  const AQISourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AQI Data Sources",
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "View detailed air quality analysis from trusted sources in Hanoi.",
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _SourceButton(
            title: "IQAir Hanoi",
            subtitle: "Global standard for air quality monitoring",
            url: "https://www.iqair.com/vi/vietnam/ha-noi/hanoi",
            icon: Icons.analytics_rounded,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          _SourceButton(
            title: "AQICN Vietnam",
            subtitle: "World Air Quality Index Project",
            url: "https://aqicn.org/api/vn/",
            icon: Icons.public_rounded,
            color: Colors.teal,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final Color color;

  const _SourceButton({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        if (context.mounted) Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
