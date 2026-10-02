import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalBlock.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Outdoor temperature & air quality from Open-Meteo + WAQI ([EnvironmentalBlock]).
class TemperaturePage extends StatelessWidget {
  const TemperaturePage({super.key});

  static const Color _tempTint = Color(0xFF8BD4F0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final envBlock = context.read<EnvironmentalBlock>();

    return Scaffold(
      backgroundColor: EntryLandscapePalette.midnightNavy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: EntryColors.winterLandscapeRadial,
        ),
        child: SafeArea(
          child: Watch((context) {
            final data = envBlock.currentData.watch(context);
            final loading = envBlock.isLoading.watch(context);
            final err = envBlock.error.watch(context);
            final updated = envBlock.lastUpdated.watch(context);
            final topInset = MediaQuery.paddingOf(context).top;

            return RefreshIndicator(
              color: EntryLandscapePalette.steelBlue,
              backgroundColor: EntryLandscapePalette.midnightNavy,
              onRefresh: () => envBlock.refresh(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topInset + 56)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: _EnvStatusPill(
                              data: data,
                              loading: loading,
                              tempTint: _tempTint,
                              l10n: l10n,
                            ),
                          ),
                          if (err != null && data == null) ...[
                            const SizedBox(height: 24),
                            Text(
                              err,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (data != null) ...[
                            const SizedBox(height: 28),
                            _DetailSection(
                              title: l10n.health_env_condition,
                              child: Text(
                                data.weatherDescription,
                                style: const TextStyle(
                                  color: EntryLandscapePalette.icyWhiteBlue,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _DetailSection(
                              title: l10n.health_env_particles,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: l10n.health_env_pm25,
                                      value: data.pm25 > 0
                                          ? data.pm25.toStringAsFixed(1)
                                          : '—',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MiniStat(
                                      label: l10n.health_env_pm10,
                                      value: data.pm10 > 0
                                          ? data.pm10.toStringAsFixed(1)
                                          : '—',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _DetailSection(
                              title: l10n.health_air_quality,
                              child: Text(
                                data.aqiStatus,
                                style: TextStyle(
                                  color: aqiStatusColor(data.aqi),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            l10n.health_env_sources,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: EntryLandscapePalette.mutedSlateBlue
                                  .withValues(alpha: 0.85),
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (updated != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.health_env_updated(
                                DateFormat('HH:mm · d MMM').format(updated),
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: EntryLandscapePalette.steelBlue
                                    .withValues(alpha: 0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

Color aqiStatusColor(int aqi) {
  if (aqi <= 50) return const Color(0xFF8FD9A8);
  if (aqi <= 100) return const Color(0xFFE6E28A);
  if (aqi <= 150) return const Color(0xFFE8B86D);
  if (aqi <= 200) return const Color(0xFFE88888);
  if (aqi <= 300) return const Color(0xFFD4A5E8);
  return const Color(0xFFC4A882);
}

class _EnvStatusPill extends StatelessWidget {
  const _EnvStatusPill({
    required this.data,
    required this.loading,
    required this.tempTint,
    required this.l10n,
  });

  final EnvironmentalData? data;
  final bool loading;
  final Color tempTint;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tempLabel = loading
        ? '…'
        : (data != null
            ? '${data!.temperature.toStringAsFixed(0)}°C'
            : '--°C');
    final aqiValue = data?.aqi ?? 0;
    final aqiColor =
        data != null ? aqiStatusColor(aqiValue) : tempTint.withValues(alpha: 0.6);
    final aqiLabel = loading
        ? '…'
        : (data != null ? '${l10n.health_aqi_unit} ${data!.aqi}' : '${l10n.health_aqi_unit} --');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: EntryLandscapePalette.midnightNavy.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thermostat_rounded, color: tempTint, size: 22),
          const SizedBox(width: 10),
          Text(
            tempLabel,
            style: TextStyle(
              color: tempTint,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Icon(Icons.air_rounded, color: aqiColor, size: 22),
          const SizedBox(width: 10),
          Text(
            aqiLabel,
            style: TextStyle(
              color: aqiColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: EntryLandscapePalette.midnightNavy.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: EntryLandscapePalette.dustySkyBlue.withValues(alpha: 0.95),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: EntryLandscapePalette.dustySkyBlue.withValues(alpha: 0.92),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: EntryLandscapePalette.icyWhiteBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
