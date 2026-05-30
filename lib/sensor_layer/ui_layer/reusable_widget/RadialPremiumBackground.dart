import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';

class RadialPremiumBackground extends StatelessWidget {
  final Widget child;
  final bool showGlow;
  final Alignment center;
  final double radius;
  /// When set, overrides [Theme.colorScheme.primary] for the radial glow.
  final Color? glowColor;
  /// When set, overrides themed scaffold background for the base fill.
  final Color? baseColor;

  const RadialPremiumBackground({
    super.key,
    required this.child,
    this.showGlow = true,
    this.center = Alignment.center,
    this.radius = 1.5,
    this.glowColor,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = glowColor ?? colorScheme.primary;
    final themedBase = baseColor ?? theme.scaffoldBackgroundColor;

    return Stack(
      children: [
        // L0 shell — glacial night gradient when [baseColor] is set.
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: baseColor != null
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: const Alignment(0.4, 1.0),
                    colors: [
                      HealthMetricColors.iceBgDeep,
                      baseColor!,
                      HealthMetricColors.iceBgMid,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themedBase,
                      Color.lerp(
                            themedBase,
                            colorScheme.surfaceContainerHighest,
                            0.35,
                          ) ??
                          themedBase,
                    ],
                  ),
                ),
        ),
        
        // Dynamic Glow Layer
        if (showGlow)
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: center,
                  radius: radius,
                  colors: [
                    primaryColor.withValues(alpha: 0.12),
                    primaryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

        // Subtle Hardware Texture Layer (Optional: could add noise or grain)
        
        // The actual content
        child,
      ],
    );
  }
}
