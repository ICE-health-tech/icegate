import 'package:flutter/material.dart';

class DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double opacity;

  DotGridPainter({required this.color, this.spacing = 20, this.opacity = 0.1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 2;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
