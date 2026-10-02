import 'package:flutter/material.dart';

/// Square line grid — Lucidchart / FigJam style canvas background.
class GridLinePainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double opacity;
  final double strokeWidth;

  GridLinePainter({
    required this.color,
    this.spacing = 24,
    this.opacity = 0.12,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.opacity != opacity;
  }
}
