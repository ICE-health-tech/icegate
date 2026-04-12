import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/health_page/models/HealthMetric.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HealthMetricCard extends StatefulWidget {
  final HealthMetric metrics;

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
      default:
        return metricName.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.06) // Reduced from 0.08
                    : Colors.white.withValues(alpha: 0.5), // Reduced from 0.6
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: widget.metrics.isFuture
                      ? (isDark ? Colors.white24 : Colors.grey.withAlpha(50))
                      : (isDark 
                          ? Colors.white.withValues(alpha: 0.1) // Reduced from 0.12
                          : colorScheme.primary.withValues(alpha: 0.08)), // Reduced from 0.1
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.metrics.color.withValues(alpha: 0.05), // Reduced from 0.1
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03), // Reduced from 0.05
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle background accent glow
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.metrics.color.withValues(alpha: 0.04), // Reduced from 0.08
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: widget.metrics.color.withValues(alpha: 0.1), // Reduced from 0.15
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  Icon(
                                    widget.metrics.icon,
                                    color: widget.metrics.isFuture 
                                        ? colorScheme.onSurface.withValues(alpha: 0.2) // Reduced from 0.3
                                        : widget.metrics.color,
                                    size: compact ? 22 : 26,
                                  ),
                                  if (widget.metrics.isFuture)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock_rounded,
                                          size: 10,
                                          color: colorScheme.onSurface.withValues(alpha: 0.4), // Reduced from 0.5
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (widget.metrics.isFuture)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface.withValues(alpha: 0.03), // Reduced from 0.05
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'FUTURE',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(alpha: 0.3), // Reduced from 0.4
                                    fontWeight: FontWeight.w900,
                                    fontSize: 8,
                                    letterSpacing: 1,
                                  ),
                                ),
                              )
                            else if (widget.metrics.trend != null)
                              _buildTrendChip(widget.metrics.trend!, widget.metrics.trendPositive ?? true),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _localizedMetricName(context, widget.metrics.name).toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.25), // Reduced from 0.4
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                  Expanded(
                                  child: AutoSizeText(
                                    widget.metrics.value,
                                    style: TextStyle(
                                      color: widget.metrics.isFuture
                                          ? colorScheme.onSurface.withValues(alpha: 0.15) // Reduced from 0.2
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                      fontSize: compact ? 26 : 30,
                                      letterSpacing: -1,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.metrics.unit,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(alpha: 0.25), // Reduced from 0.4
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        if (widget.metrics.progress != null) ...[
                          const SizedBox(height: 16),
                          _buildProgressBar(widget.metrics.progress!, widget.metrics.color),
                        ],
                      ],
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
        color: color.withValues(alpha: 0.05), // Reduced from 0.1
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1), // Reduced from 0.2
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 11,
            color: color.withValues(alpha: 0.8), // Reduced from 1.0 to be slightly softer
          ),
          const SizedBox(width: 4),
          Text(
            trend,
            style: TextStyle(
              color: color.withValues(alpha: 0.8), // Reduced from 1.0
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
        color: color.withValues(alpha: 0.05), // Reduced from 0.1
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
