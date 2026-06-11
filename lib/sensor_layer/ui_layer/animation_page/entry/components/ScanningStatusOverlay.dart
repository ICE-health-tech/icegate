import 'package:flutter/material.dart';
import 'AuthStatusPulse.dart';

class ScanningStatusOverlay extends StatelessWidget {
  final Animation<double> assemblyAnimation;

  const ScanningStatusOverlay({
    super.key,
    required this.assemblyAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: assemblyAnimation,
          builder: (context, child) {
            final double opacity = Curves.easeIn.transform(
              (assemblyAnimation.value / 0.5).clamp(0.0, 1.0),
            );
            return Opacity(
              opacity: opacity,
              child: const AuthStatusPulse(),
            );
          },
        ),
      ),
    );
  }
}
