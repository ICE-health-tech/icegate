import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

    if (widget.metrics.detailPage != null) {
      context.go(widget.metrics.detailPage!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detail page for ${widget.metrics.name} coming soon!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.0),
            child: Stack(
              children: [
                // Subtle background glow
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.metrics.color.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0), // Reduced from 24
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                              10,
                            ), // Reduced from 12
                            decoration: BoxDecoration(
                              color: widget.metrics.color.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // Reduced from 20
                            ),
                            child: Icon(
                              widget.metrics.icon,
                              color: widget.metrics.color,
                              size: compact ? 20 : 24, // Reduced sizes
                            ),
                          ),
                          if (widget.metrics.trend != null)
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      ((widget.metrics.trendPositive ?? true)
                                              ? Colors.green
                                              : Colors.red)
                                          .withValues(alpha: 0.1),
                                      ((widget.metrics.trendPositive ?? true)
                                              ? Colors.green
                                              : Colors.red)
                                          .withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        ((widget.metrics.trendPositive ?? true)
                                                ? Colors.green
                                                : Colors.red)
                                            .withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          ((widget.metrics.trendPositive ??
                                                      true)
                                                  ? Colors.green
                                                  : Colors.red)
                                              .withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      spreadRadius: -1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (widget.metrics.trendPositive ?? true)
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                      size:
                                          10, // Slightly smaller for premium feel
                                      color:
                                          (widget.metrics.trendPositive ?? true)
                                          ? Colors.green.withValues(alpha: 0.9)
                                          : Colors.red.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        widget.metrics.trend!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                           ((widget.metrics.trendPositive ??
                                                      true)
                                                  ? Colors.green
                                                  : Colors.red),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12), // Reduced from 20
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.metrics.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                fontSize: 9, // Reduced from 10
                              ),
                            ),
                            const SizedBox(height: 2), // Reduced from 4
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: AutoSizeText(
                                    widget.metrics.value,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w900,
                                      fontSize: compact
                                          ? 22
                                          : 26, // Reduced from 24:28
                                    ),
                                    maxLines: 1,
                                    minFontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 2), // Reduced from 4
                                Text(
                                  widget.metrics.unit,
                                  style: textTheme.labelSmall?.copyWith(
                                    // Changed from labelMedium
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.metrics.progress != null) ...[
                        const SizedBox(height: 8), // Reduced from 16
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: widget.metrics.progress!.clamp(0.0, 1.0),
                            minHeight: 6, // Reduced from 8
                            backgroundColor: widget.metrics.color.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.metrics.color,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
