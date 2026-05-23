import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/AppleHealthServices.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "weight",
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      destination: "/health/weight",
      size: size,
      icon: Icons.scale,
      mainFunction: () {
        context.go("/health/weight/log");
      },
    );
  }
}

class _WeightPageState extends State<WeightPage> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    if (!_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncSmartScale(showFeedback: false);
      });
    }
  }

  bool get _isDesktop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  Future<void> _syncSmartScale({bool showFeedback = true}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isDesktop) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.health_smart_scale_desktop)),
        );
      }
      return;
    }

    setState(() => _syncing = true);
    final healthBlock = context.read<HealthBlock>();

    try {
      final authorized = await HealthService.requestPermissions();
      if (!authorized) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.health_smart_scale_sync_denied)),
          );
        }
        return;
      }

      final weight = await healthBlock.syncFromSmartScale();
      if (!mounted) return;

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              weight > 0
                  ? l10n.health_smart_scale_sync_ok
                  : l10n.health_smart_scale_sync_empty,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";
    final l10n = AppLocalizations.of(context)!;
    final healthBlock = context.watch<HealthBlock>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: _AmbientGlow(color: Colors.purple.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _AmbientGlow(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                actions: [
                  IconButton(
                    tooltip: l10n.health_smart_scale_sync,
                    onPressed: _syncing ? null : () => _syncSmartScale(),
                    icon: _syncing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _SmartScaleCard(
                    syncing: _syncing,
                    latestKg: healthBlock.todayWeight.value,
                    isLoading: healthBlock.isWeightLoading.value,
                    isDesktop: _isDesktop,
                    onSync: () => _syncSmartScale(),
                  ),
                ),
              ),
              StreamBuilder<List<HealthMetricsLocal>>(
                stream: db.healthMetricsDAO.watchAllMetrics(personId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data =
                      snapshot.data!.where((m) => (m.weightKg ?? 0) > 0).toList()
                        ..sort((a, b) => b.date.compareTo(a.date));

                  if (data.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monitor_weight_outlined,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                l10n.health_smart_scale_sync_empty,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _WeightListItem(metric: data[index]);
                      }, childCount: data.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartScaleCard extends StatelessWidget {
  final bool syncing;
  final double latestKg;
  final bool isLoading;
  final bool isDesktop;
  final VoidCallback onSync;

  const _SmartScaleCard({
    required this.syncing,
    required this.latestKg,
    required this.isLoading,
    required this.isDesktop,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bluetooth_rounded,
                      color: Colors.purpleAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.health_smart_scale_title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.health_smart_scale_desc,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (latestKg > 0) ...[
                const SizedBox(height: 16),
                Text(
                  '${latestKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  l10n.health_subtitle_current_weight.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (syncing || isLoading) ? null : onSync,
                  icon: syncing || isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    syncing || isLoading
                        ? l10n.health_smart_scale_syncing
                        : l10n.health_smart_scale_sync,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.health_smart_scale_desktop,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightListItem extends StatelessWidget {
  final HealthMetricsLocal metric;
  const _WeightListItem({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_rounded,
                    color: Colors.purpleAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'MMMM d, yyyy',
                        ).format(metric.date).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(metric.weightKg ?? 0.0).toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  const _AmbientGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }
}
