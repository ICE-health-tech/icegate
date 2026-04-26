import 'package:flutter/material.dart';
import 'dart:math' show pi;

// --- StatusCircle and Painter ---

class StatusCircle extends StatelessWidget {
  final double strengthPercentage;
  static const double circleSize = 100.0;
  static const double strokeWidth = 8.0;

  const StatusCircle({
    super.key,
    required this.strengthPercentage,
  });

  Color get indicatorColor {
    if (strengthPercentage < 0.3) {
      return Colors.red;
    } else if (strengthPercentage < 0.7) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: CustomPaint(
        painter: CircleStrengthPainter(
          percentage: strengthPercentage,
          indicatorColor: indicatorColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Text(
            '${(strengthPercentage * 100).toInt()}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: indicatorColor,
            ),
          ),
        ),
      ),
    );
  }
}

class CircleStrengthPainter extends CustomPainter {
  final double percentage;
  final Color indicatorColor;
  final double strokeWidth;

  CircleStrengthPainter({
    required this.percentage,
    required this.indicatorColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = indicatorColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double sweepAngle = 2 * pi * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircleStrengthPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.indicatorColor != indicatorColor;
  }
}

// --- Helper Build Methods ---

Widget _buildBarText(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    ),
  );
}

Widget _buildPointWidget() {
  return const StatusCircle(strengthPercentage: 0.65);
}

Widget _buildMainIcon(BuildContext context, IconData icon, double width) {
  return Center(child: Icon(icon, size: width, color: Colors.black26));
}

Widget _buildRowIndex(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(child: _buildPointWidget()),
        Flexible(child: _buildPointWidget()),
        Flexible(child: const StatusCircle(strengthPercentage: 0.25)),
      ],
    ),
  );
}

// --- DepartmentCard Widget (Stateless, no internal state) ---

class DepartmentCard extends StatelessWidget {
  final String title;
  final double cardWidth;
  final double cardHeight;

  const DepartmentCard({
    super.key,
    required this.title,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final mainIconSize = cardWidth * 0.25;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.blueGrey.shade100, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildBarText(context, title)),
          Center(child: _buildRowIndex(context)),
          Expanded(
            child: Center(
              child: _buildMainIcon(
                context,
                Icons.health_and_safety,
                mainIconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}