import 'dart:math' as math;
import 'package:flutter/material.dart';

class SimpleLineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;

  const SimpleLineChart({
    super.key,
    required this.data,
    this.color = Colors.blue,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LineChartPainter(data, color)),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce(math.max);
    final double minVal = data.reduce(math.min);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y =
          size.height -
          ((data[i] - minVal) / range * size.height * 0.8) -
          (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimplePieChart extends StatelessWidget {
  final Map<String, double> data;
  final List<Color> colors;
  final double size;

  const SimplePieChart({
    super.key,
    required this.data,
    required this.colors,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(painter: _PieChartPainter(data, colors)),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final List<Color> colors;

  _PieChartPainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final holeRadius = radius * 0.6; // Consistent donut hole

    int i = 0;
    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * math.pi;
      if (sweepAngle > 0) {
        final paint = Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius - holeRadius;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: (radius + holeRadius) / 2),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
      startAngle += sweepAngle;
      i++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
