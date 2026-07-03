import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanDiagramLayout.dart';

/// Draws flow connectors between diagram blocks.
class PlanDiagramEdgesPainter extends CustomPainter {
  PlanDiagramEdgesPainter({
    required this.edges,
    required this.color,
  });

  final List<PlanDiagramEdge> edges;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final path = Path()..moveTo(edge.from.dx, edge.from.dy);

      final midY = (edge.from.dy + edge.to.dy) / 2;
      path.cubicTo(
        edge.from.dx,
        midY,
        edge.to.dx,
        midY,
        edge.to.dx,
        edge.to.dy,
      );
      canvas.drawPath(path, paint);

      _drawArrow(canvas, edge.to, paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset tip, Paint paint) {
    const size = 6.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - size, tip.dy - size)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + size, tip.dy - size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PlanDiagramEdgesPainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.color != color;
  }
}
