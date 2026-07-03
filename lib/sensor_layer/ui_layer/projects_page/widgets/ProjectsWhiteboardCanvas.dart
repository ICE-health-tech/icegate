import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/Services/WhiteboardPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/DotGridPainter.dart';

/// Freehand drawing surface — repaints strokes and captures pan gestures.
class ProjectsWhiteboardCanvas extends StatefulWidget {
  const ProjectsWhiteboardCanvas({
    super.key,
    required this.strokes,
    required this.penColor,
    required this.penWidth,
    required this.onStrokesChanged,
    required this.boardColor,
    required this.isDark,
  });

  final List<WhiteboardStroke> strokes;
  final Color penColor;
  final double penWidth;
  final ValueChanged<List<WhiteboardStroke>> onStrokesChanged;
  final Color boardColor;
  final bool isDark;

  @override
  State<ProjectsWhiteboardCanvas> createState() =>
      _ProjectsWhiteboardCanvasState();
}

class _ProjectsWhiteboardCanvasState extends State<ProjectsWhiteboardCanvas> {
  List<Offset>? _activePoints;

  void _finishStroke() {
    final points = _activePoints;
    if (points == null || points.length < 2) {
      _activePoints = null;
      return;
    }
    final next = List<WhiteboardStroke>.from(widget.strokes)
      ..add(
        WhiteboardStroke(
          points: List<Offset>.from(points),
          colorArgb: widget.penColor.toARGB32(),
          width: widget.penWidth,
        ),
      );
    _activePoints = null;
    widget.onStrokesChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final gridColor = widget.isDark ? Colors.white : const Color(0xFF9CA3AF);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (d) {
            setState(() => _activePoints = [d.localPosition]);
          },
          onPanUpdate: (d) {
            setState(() => _activePoints?.add(d.localPosition));
          },
          onPanEnd: (_) {
            setState(_finishStroke);
          },
          onPanCancel: () {
            setState(() => _activePoints = null);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _WhiteboardPainter(
                strokes: widget.strokes,
                activePoints: _activePoints,
                activeColor: widget.penColor,
                activeWidth: widget.penWidth,
                boardColor: widget.boardColor,
                gridColor: gridColor,
                isDark: widget.isDark,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  _WhiteboardPainter({
    required this.strokes,
    required this.activePoints,
    required this.activeColor,
    required this.activeWidth,
    required this.boardColor,
    required this.gridColor,
    required this.isDark,
  });

  final List<WhiteboardStroke> strokes;
  final List<Offset>? activePoints;
  final Color activeColor;
  final double activeWidth;
  final Color boardColor;
  final Color gridColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = boardColor);

    final grid = DotGridPainter(
      color: gridColor,
      opacity: isDark ? 0.09 : 0.06,
      spacing: 25,
    );
    grid.paint(canvas, size);

    for (final stroke in strokes) {
      _paintStroke(
        canvas,
        stroke.points,
        Color(stroke.colorArgb),
        stroke.width,
      );
    }
    if (activePoints != null && activePoints!.length >= 2) {
      _paintStroke(canvas, activePoints!, activeColor, activeWidth);
    }
  }

  void _paintStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activePoints != activePoints ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.activeWidth != activeWidth ||
        oldDelegate.boardColor != boardColor;
  }
}
