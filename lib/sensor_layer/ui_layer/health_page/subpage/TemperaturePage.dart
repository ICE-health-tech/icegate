import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalBlock.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Outdoor temperature & air quality from Open-Meteo + WAQI ([EnvironmentalBlock]).
class TemperaturePage extends StatelessWidget {
  const TemperaturePage({super.key});

  static const Color _tempTint = Color(0xFF8BD4F0);
  static const Color _aqiTint = Color(0xFF8FD9A8);

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

            return RefreshIndicator(
              color: EntryLandscapePalette.steelBlue,
              backgroundColor: EntryLandscapePalette.midnightNavy,
              onRefresh: () => envBlock.refresh(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                      child: Row(
                        children: [
                        SizedBox(width:32),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: EntryLandscapePalette.icyWhiteBlue.withValues(
                                alpha: 0.9,
                              ),
                              size: 20,
                            ),
                            onPressed: () => context.pop(),
                          ),
                          // Expanded(
                          //   child: Text(
                          //     l10n.health_temperature_env_title,
                          //     textAlign: TextAlign.center,
                          //     style: TextStyle(
                          //       color: EntryLandscapePalette.icyWhiteBlue,
                          //       fontWeight: FontWeight.w800,
                          //       fontSize: 17,
                          //       letterSpacing: 0.6,
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: _EnvStatusPill(
                              data: data,
                              loading: loading,
                              tempTint: _tempTint,
                              aqiTint: _aqiTint,
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
                                style: TextStyle(
                                  color: EntryLandscapePalette.dustySkyBlue
                                      .withValues(alpha: 0.95),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 20),
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
    required this.aqiTint,
    required this.l10n,
  });

  final EnvironmentalData? data;
  final bool loading;
  final Color tempTint;
  final Color aqiTint;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tempLabel = loading
        ? '…'
        : (data != null
            ? '${data!.temperature.toStringAsFixed(0)}°C'
            : '--°C');
    final aqiLabel = loading
        ? '…'
        : (data != null ? '${l10n.health_aqi_unit} ${data!.aqi}' : '${l10n.health_aqi_unit} --');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252A38).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thermostat_rounded, color: tempTint, size: 20),
          const SizedBox(width: 8),
          Text(
            tempLabel,
            style: TextStyle(
              color: tempTint,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: 1,
              height: 22,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Icon(Icons.waves_rounded, color: aqiTint, size: 20),
          const SizedBox(width: 8),
          Text(
            aqiLabel,
            style: TextStyle(
              color: aqiTint,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.2,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EntryLandscapePalette.mutedSlateBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.95),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: EntryLandscapePalette.midnightNavy.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EntryLandscapePalette.steelBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: EntryLandscapePalette.dustySkyBlue.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: EntryLandscapePalette.icyWhiteBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
