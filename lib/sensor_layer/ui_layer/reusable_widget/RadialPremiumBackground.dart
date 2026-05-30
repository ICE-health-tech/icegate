import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

class RadialPremiumBackground extends StatelessWidget {
  final Widget child;
  final bool showGlow;
  final Alignment center;
  final double radius;
  /// When set, overrides [Theme.colorScheme.primary] for the radial glow.
  final Color? glowColor;
  /// When set, overrides [EntryColors.obsidianBase] for the base fill.
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
    final primaryColor = glowColor ?? Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // Base Foundation: Deep Obsidian
        Container(
          width: double.infinity,
          height: double.infinity,
          color: baseColor ?? EntryColors.obsidianBase,
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
