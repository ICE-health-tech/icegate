import 'package:flutter/material.dart';

class EntryFlashEffect extends StatelessWidget {
  final Animation<double> crackAnimation;
  final bool isCracking;

  const EntryFlashEffect({
    super.key,
    required this.crackAnimation,
    required this.isCracking,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCracking) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: crackAnimation,
      builder: (context, child) {
        final double flashOpacity = Curves.easeInQuint.transform(
          ((crackAnimation.value - 0.85) / 0.15).clamp(0.0, 1.0),
        );
        return Container(
          color: Colors.white.withValues(alpha: flashOpacity),
        );
      },
    );
  }
}
