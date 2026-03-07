import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';

class BlockReminderPage extends StatefulWidget {
  const BlockReminderPage({super.key});

  @override
  State<BlockReminderPage> createState() => _BlockReminderPageState();
}

class _BlockReminderPageState extends State<BlockReminderPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final focusBlock = context.watch<FocusBlock>();
    final isRunning = focusBlock.isRunning.watch(context);
    final remaining = focusBlock.remainingTime.watch(context);
    final intensity = focusBlock.muskHapticIntensity.watch(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Cyber Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                color: colorScheme.primary.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Minimal Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, color: Colors.white60),
                      ),
                      const Spacer(),
                      Text(
                        "BLOCK REMINDER",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // The 5-Minute Block Display
                GestureDetector(
                  onTap: () {
                    if (!isRunning) {
                      focusBlock.startMuskFocus();
                    } else {
                      focusBlock.pauseTimer();
                    }
                    HapticFeedback.mediumImpact();
                  },
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: isRunning
                                ? colorScheme.primary.withOpacity(
                                    0.3 + (_controller.value * 0.4),
                                  )
                                : Colors.white10,
                            width: 2,
                          ),
                          boxShadow: isRunning
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(remaining),
                              style: TextStyle(
                                color: isRunning
                                    ? Colors.white
                                    : Colors.white38,
                                fontSize: 72,
                                fontWeight: FontWeight.w100,
                                fontFamily: 'monospace',
                                letterSpacing: -2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRunning ? "REMINDER ACTIVE" : "START 5m BLOCK",
                              style: TextStyle(
                                color: isRunning
                                    ? colorScheme.primary
                                    : Colors.white24,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(),

                // Haptic Intensity Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "REMIND INTENSITY",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "LVL $intensity",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: intensity.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: colorScheme.primary,
                        inactiveColor: Colors.white10,
                        onChanged: (val) {
                          focusBlock.muskHapticIntensity.value = val.toInt();
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Manual Vibrate Test
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      () => HapticFeedback.vibrate(),
                    );
                  },
                  icon: const Icon(Icons.vibration, size: 16),
                  label: const Text("TEST REMINDER"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
