import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/HealthSourceService.dart';
import 'package:ice_gate/data_layer/Protocol/Health/HealthMetricProtocol.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HealthMetricCard extends StatefulWidget {
  final HealthMetricProtocol metrics;

  const HealthMetricCard({super.key, required this.metrics});

  @override
  State<HealthMetricCard> createState() => _HealthMetricCardState();
}

class _HealthMetricCardState extends State<HealthMetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Fast response
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    _navigateToDetailPage();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _navigateToDetailPage() {
    // Haptic feedback for tactile feel
    HapticFeedback.lightImpact();

    if (widget.metrics.isFuture) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.metrics.availabilityMessage ?? 'Feature coming soon',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: widget.metrics.color.withAlpha(200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (widget.metrics.detailPage != null) {
      context.go(widget.metrics.detailPage!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.health_metrics_detail_coming_soon(widget.metrics.name),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Maps health metric internal name (e.g. "steps") to the localized display name
  String _localizedMetricName(BuildContext context, String metricName) {
    final l10n = AppLocalizations.of(context)!;
    switch (metricName.toLowerCase()) {
      case "steps":
        return l10n.health_metrics_steps;
      case "heart_rate":
        return l10n.health_metrics_heart_rate;
      case "sleep":
        return l10n.health_metrics_sleep;
      case "water":
        return l10n.health_metrics_water;
      case "exercise":
        return l10n.health_metrics_exercise;
      case "focus":
        return l10n.health_metrics_focus;
      case "distance":
        return l10n.health_metrics_distance;
      case "calories":
        return l10n.health_metrics_calories;
      case "active_time":
        return l10n.health_metrics_active_time;
      case "calories_burned":
        return l10n.health_metrics_calories_burned;
      case "weight":
        return l10n.health_metrics_weight;
      case "net_calories":
        return l10n.health_metrics_net_calories;
      case "food":
        return l10n.health_metrics_calories_consumed;
      case "oxygen":
      case "oxygen_saturation":
        return l10n.health_metrics_oxygen_saturation;
      case "weather":
        return l10n.health_metrics_weather;
      case "air_quality":
        return l10n.health_metrics_air_quality;
      default:
        return metricName.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final desktopDense = MediaQuery.sizeOf(context).width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final outerR = desktopDense ? 20.0 : 32.0;
    final pad = desktopDense ? 12.0 : 16.0;
    final title = _localizedMetricName(context, widget.metrics.name);
    final displayValue = widget.metrics.value.trim().isEmpty
        ? '--'
        : widget.metrics.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outerR),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.06) 
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(outerR),
                border: Border.all(
                  color: widget.metrics.isFuture
                      ? (isDark ? Colors.white24 : Colors.grey.withAlpha(50))
                      : (isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : colorScheme.primary.withValues(alpha: 0.08)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.metrics.color.withValues(alpha: 0.05),
                    blurRadius: desktopDense ? 12 : 20,
                    offset: Offset(0, desktopDense ? 4 : 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: desktopDense ? 24 : 40,
                    offset: Offset(0, desktopDense ? 8 : 15),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Metric tint + logo watermark
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.metrics.color.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -8,
                    child: Opacity(
                      opacity: 0.07,
                      child: Image.asset(
                        'assets/images/iceflowerlogo.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        color: widget.metrics.color,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tight = constraints.maxHeight < 130;
                        final iconBoxSize = tight
                            ? 34.0
                            : (desktopDense ? 40.0 : 44.0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: iconBoxSize,
                                  height: iconBoxSize,
                                  padding: EdgeInsets.all(tight ? 7 : 9),
                                  decoration: BoxDecoration(
                                    color: widget.metrics.color.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      tight ? 11 : 14,
                                    ),
                                  ),
                                  child: Center(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          widget.metrics.icon,
                                          color: widget.metrics.isFuture
                                              ? colorScheme.onSurface
                                                  .withValues(alpha: 0.35)
                                              : widget.metrics.color,
                                          size: tight ? 20 : 24,
                                        ),
                                        if (widget.metrics.isFuture)
                                          Positioned(
                                            right: -4,
                                            bottom: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.surface,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.lock_rounded,
                                                size: 10,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.45),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title.toUpperCase(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.88),
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                          fontSize: tight ? 10 : 11,
                                          height: 1.15,
                                        ),
                                      ),
                                      if (widget.metrics.subtitle != null &&
                                          widget.metrics.subtitle!
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.metrics.subtitle!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.45),
                                            fontSize: tight ? 8 : 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (widget.metrics.isFuture)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'FUTURE',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.45),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 7,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  )
                                else if (widget.metrics.trend != null)
                                  _buildTrendChip(
                                    widget.metrics.trend!,
                                    widget.metrics.trendPositive ?? true,
                                  ),
                              ],
                            ),
                            if (widget.metrics.source != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: HealthSourceService.getSourceColor(
                                    widget.metrics.source,
                                    colorScheme,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      HealthSourceService.getIcon(
                                        widget.metrics.source,
                                      ),
                                      size: 10,
                                      color: HealthSourceService.getSourceColor(
                                        widget.metrics.source,
                                        colorScheme,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      HealthSourceService.getLabel(
                                        widget.metrics.source,
                                      ).toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            HealthSourceService.getSourceColor(
                                          widget.metrics.source,
                                          colorScheme,
                                        ),
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: widget.metrics.isLoading
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 2,
                                          ),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                widget.metrics.color
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                        )
                                      : AutoSizeText(
                                          displayValue,
                                          style: TextStyle(
                                            color: widget.metrics.isFuture
                                                ? colorScheme.onSurface
                                                    .withValues(alpha: 0.25)
                                                : colorScheme.onSurface,
                                            fontWeight: FontWeight.w900,
                                            fontSize: tight
                                                ? 22
                                                : (desktopDense ? 24 : 28),
                                            height: 1.0,
                                            letterSpacing: -0.5,
                                          ),
                                          maxLines: 1,
                                          minFontSize: 14,
                                        ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.metrics.unit,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.45,
                                    ),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.metrics.progress != null) ...[
                              const SizedBox(height: 8),
                              _buildProgressBar(
                                widget.metrics.progress!,
                                widget.metrics.color,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChip(String trend, bool positive) {
    final color = positive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 11,
            color: color.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            trend,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w900,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
