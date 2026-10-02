import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

/// Brief full-screen celebration with confetti burst + card copy.
void showSavingsCelebration(
  BuildContext context, {
  String? bannerTitle,
  required String body,
  Duration duration = const Duration(milliseconds: 1500),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _CelebrationLayer(
      bannerTitle: bannerTitle,
      body: body,
      onDone: () {
        entry.remove();
      },
      duration: duration,
    ),
  );
  overlay.insert(entry);
}

class _CelebrationLayer extends StatefulWidget {
  final String? bannerTitle;
  final String body;
  final VoidCallback onDone;
  final Duration duration;

  const _CelebrationLayer({
    required this.bannerTitle,
    required this.body,
    required this.onDone,
    required this.duration,
  });

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward();

  @override
  void initState() {
    super.initState();
    Timer(widget.duration, widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(progress: _c.value),
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: EntryColors.financeSilverAccent.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EntryColors.financeSilverAccent.withValues(alpha: 0.15),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.bannerTitle != null) ...[
                      Text(
                        widget.bannerTitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: EntryColors.financeSilverAccent.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      widget.body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final _random = Random(42);

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final n = 42;
    for (var i = 0; i < n; i++) {
      final x = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height * 0.5;
      final y = baseY + progress * size.height * 0.55;
      final r = Rect.fromCenter(
        center: Offset(x, y),
        width: 4 + _random.nextDouble() * 6,
        height: 5 + _random.nextDouble() * 8,
      );
      final colors = [
        EntryColors.financeSilverAccent,
        Colors.greenAccent,
        EntryColors.financeSilverAccent,
        Colors.white70,
      ];
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.55 + progress * 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
