import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _gridController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gridController.dispose();
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
    // Force Premium Theme integrated with System
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor.withValues(alpha: 0.5);
    final isRunning = focusBlock.isRunning.watch(context);
    final remaining = focusBlock.remainingTime.watch(context);
    final intensity = focusBlock.muskHapticIntensity.watch(context);
    final duration = focusBlock.muskFocusDuration.watch(context);
    final repeat = focusBlock.muskRepeatReminder.watch(context);
    final isMusicEnabled = focusBlock.isMuskMusicEnabled.watch(context);

    // Use a neon cyan if the theme primary isn't high-contrast enough
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // 1. Dynamic Parallax Grid
          AnimatedBuilder(
            animation: _gridController,
            builder: (context, child) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: ParallaxGridPainter(
                    progress: _gridController.value,
                    color: primaryColor.withValues(alpha: 0.08),
                  ),
                ),
              );
            },
          ),

          // 2. Scanline Effect Overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/system_hud.png', // Assuming this asset exists from previous UI work
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Minimal Header
                      _buildHeader(context, primaryColor),

                      const Spacer(),

                      // Main Timer & Progress Ring
                      _buildMainTimer(
                        context,
                        isRunning,
                        remaining,
                        duration,
                        primaryColor,
                        focusBlock,
                      ),

                      const Spacer(),

                      if (isRunning) ...[
                        _buildStopButton(context, focusBlock, primaryColor),
                        const SizedBox(height: 20),
                      ],

                      // Controls Section
                      _buildControls(
                        context,
                        focusBlock,
                        intensity,
                        duration,
                        repeat,
                        isMusicEnabled,
                        primaryColor,
                        cardBg,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).iconTheme.color ?? Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                "SYSTEM INTERFACE",
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Time Block Reminder",
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.titleLarge?.color ??
                      Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildMainTimer(
    BuildContext context,
    bool isRunning,
    int remaining,
    int duration,
    Color primaryColor,
    FocusBlock focusBlock,
  ) {
    final totalSeconds = duration * 60;
    final progress = 1.0 - (remaining / totalSeconds);

    return GestureDetector(
      onTap: () {
        if (!isRunning) {
          focusBlock.startMuskFocus();
        } else {
          focusBlock.pauseTimer();
        }
        HapticFeedback.lightImpact();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(
                        alpha: isRunning
                            ? (0.1 + _pulseController.value * 0.1)
                            : 0,
                      ),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),

          // Progress Arc
          SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: NeonRingPainter(
                progress: progress,
                color: primaryColor,
                trackColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.1),
                isRunning: isRunning,
              ),
            ),
          ),

          // Inner Display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(remaining),
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.displayLarge?.color ??
                      Colors.white,
                  fontSize: 84,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'monospace',
                  letterSpacing: -4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isRunning
                      ? primaryColor.withValues(alpha: 0.1)
                      : Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isRunning
                        ? primaryColor.withValues(alpha: 0.3)
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  isRunning ? "ENGAGED" : "INITIATE",
                  style: TextStyle(
                    color: isRunning ? primaryColor : Colors.white38,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    FocusBlock focusBlock,
    int intensity,
    int duration,
    bool repeat,
    bool isMusicEnabled,
    Color primaryColor,
    Color cardBg,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Duration and Frequency
          Row(
            children: [
              Expanded(
                child: _buildGlassTile(
                  title: "BLOCK TIME",
                  value: "${duration}m",
                  icon: Icons.hourglass_top_rounded,
                  cardBg: cardBg,
                  onTap: () {
                    // Cycle: 1 -> 2 -> 5 -> 10 -> 15 -> 1
                    final next = duration == 1
                        ? 2
                        : (duration == 2
                              ? 5
                              : (duration == 5
                                    ? 10
                                    : (duration == 10 ? 15 : 1)));
                    focusBlock.muskFocusDuration.value = next;
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassTile(
                  title: "FREQUENCY",
                  value: repeat ? "ALWAYS" : "1 TIME",
                  icon: repeat
                      ? Icons.repeat_one_rounded
                      : Icons.looks_one_rounded,
                  active: repeat,
                  cardBg: cardBg,
                  onTap: () {
                    focusBlock.muskRepeatReminder.value = !repeat;
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Music Tile
          _buildGlassTile(
            title: "BG FOCUS MUSIC",
            value: isMusicEnabled
                ? "CYBERPUNK"
                : "SILENT",
            icon: isMusicEnabled
                ? Icons.music_note_rounded
                : Icons.music_off_rounded,
            active: isMusicEnabled,
            cardBg: cardBg,
            onTap: () {
              focusBlock.isMuskMusicEnabled.value = !isMusicEnabled;
              HapticFeedback.selectionClick();
            },
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 12),

          // Intensity Slider
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "PULSE INTENSITY",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "LVL $intensity",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                    thumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Slider(
                    value: intensity.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (val) {
                      focusBlock.muskHapticIntensity.value = val.toInt();
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton(
    BuildContext context,
    FocusBlock focusBlock,
    Color primaryColor,
  ) {
    return TextButton(
      onPressed: () {
        focusBlock.stopTimer();
        HapticFeedback.heavyImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          color: Colors.redAccent.withValues(alpha: 0.05),
        ),
        child: const Text(
          "TERMINATE SEQUENCE",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTile({
    required String title,
    required String value,
    required IconData icon,
    required Color cardBg,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color?.withOpacity(0.3) ??
                        Colors.white24,
              size: 20,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(0.5) ??
                    Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTERS ---

class NeonRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final bool isRunning;

  NeonRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Background Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Neon Arc
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      // Inner Arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5 * math.pi,
        2 * math.pi * progress,
        false,
        arcPaint,
      );

      // Glow Layer
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5 * math.pi,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(NeonRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isRunning != isRunning ||
      oldDelegate.trackColor != trackColor;
}

class ParallaxGridPainter extends CustomPainter {
  final double progress;
  final Color color;

  ParallaxGridPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 40.0;
    final offset = progress * gridSize;

    // Subtler Grid for Premium Feel
    final gridOpacity = color.opacity * 0.4;
    final subtlePaint = Paint()
      ..color = color.withValues(alpha: gridOpacity)
      ..strokeWidth = 0.5;

    // Vertical Lines
    for (double i = 0; i <= size.width + gridSize; i += gridSize) {
      canvas.drawLine(
        Offset(i - offset, 0),
        Offset(i - offset, size.height),
        subtlePaint,
      );
    }

    // Horizontal Lines
    for (double i = 0; i <= size.height + gridSize; i += gridSize) {
      canvas.drawLine(
        Offset(0, i - offset / 2),
        Offset(size.width, i - offset / 2),
        subtlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(ParallaxGridPainter oldDelegate) => true;
}
