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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? HealthMetricColors.textSecondary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78);

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
          Text(
            isLoading ? '…' : (envData?.aqi.toString() ?? '--'),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: HealthMetricColors.aqiColor(aqi),
            ),
          ),
          const SizedBox(height: 2),
          AutoSizeText(
            l10n.health_metrics_air_quality.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: labelColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? HealthMetricColors.textSecondary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78);
    final tempColor = isDark
        ? HealthMetricColors.tempAccent
        : Theme.of(context).colorScheme.primary;

    return _BasePluginCard(
      pluginId: 'weather',
      onTap: () => context.push('/health/temperature'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoading
                    ? '…'
                    : (envData?.temperature.toStringAsFixed(0) ?? '--'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: tempColor,
                ),
              ),
              Text(
                '°',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          AutoSizeText(
            l10n.health_metrics_weather.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: labelColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class IntegrationHubPluginCard extends StatelessWidget {
  const IntegrationHubPluginCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? HealthMetricColors.linkAccent
        : Theme.of(context).colorScheme.primary;
    final labelColor = isDark
        ? HealthMetricColors.textSecondary
        : colorScheme.onSurface.withValues(alpha: 0.78);

    return _BasePluginCard(
      pluginId: 'integrations',
      onTap: () => context.push('/integrations'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, color: iconColor, size: 28),
          const SizedBox(height: 6),
          AutoSizeText(
            l10n.integration_hub_connect.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: labelColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerHighest;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colorScheme.outline.withValues(alpha: 0.18);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: sizeOfWidget,
        height: sizeOfWidget,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.06),
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
