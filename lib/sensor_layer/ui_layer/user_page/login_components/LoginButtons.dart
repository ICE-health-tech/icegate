import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';

/// Primary login CTA: pill-shaped frosted glass, vertical ice gradient, slow shimmer.
class ShimmerButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const ShimmerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  static const double _height = 56;
  static const BorderRadius _pill = BorderRadius.all(Radius.circular(999));

  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowLift = _isPressed ? 6.0 : 14.0;
    final shadowBlur = _isPressed ? 12.0 : 28.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: double.infinity,
          height: _height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _pill,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                            EntryLandscapePalette.icyWhiteBlue,
                            Colors.white,
                            0.35,
                          ) ??
                          EntryLandscapePalette.icyWhiteBlue,
                      EntryLandscapePalette.icyWhiteBlue,
                      EntryLandscapePalette.dustySkyBlue,
                      Color.lerp(
                            EntryLandscapePalette.steelBlue,
                            EntryLandscapePalette.mutedSlateBlue,
                            0.22,
                          ) ??
                          EntryLandscapePalette.steelBlue,
                    ],
                    stops: const [0.0, 0.28, 0.62, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EntryLandscapePalette.midnightNavy.withValues(
                        alpha: 0.45,
                      ),
                      blurRadius: shadowBlur,
                      offset: Offset(0, shadowLift * 0.35),
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: EntryLandscapePalette.steelBlue.withValues(
                        alpha: _isPressed ? 0.12 : 0.28,
                      ),
                      blurRadius: shadowBlur * 0.65,
                      offset: Offset(0, shadowLift * 0.2),
                    ),
                  ],
                ),
              ),
              // Frost lip + inner rim (glass edge)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _pill,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.62),
                    width: 1.25,
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: _pill,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: const Alignment(0, 0.42),
                        colors: [
                          Colors.white.withValues(alpha: _isPressed ? 0.14 : 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: _pill,
                    child: CustomPaint(
                      painter: _ShimmerPainter(
                        progress: _shimmerController.value,
                      ),
                    ),
                  );
                },
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading
                      ? null
                      : () {
                          HapticFeedback.heavyImpact();
                          widget.onPressed?.call();
                        },
                  borderRadius: _pill,
                  splashColor: EntryLandscapePalette.midnightNavy.withValues(
                    alpha: 0.08,
                  ),
                  highlightColor: EntryLandscapePalette.midnightNavy.withValues(
                    alpha: 0.05,
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Color(0xFF0D1117),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            widget.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5.2,
                              height: 1.0,
                              color: Color(0xFF0D1117),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slow horizontal light wash across the pill (keeps motion subtle).
class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final band = w * 0.42;
    final left = (progress * (w + band * 2)) - band;
    final paint = Paint()
      ..blendMode = BlendMode.softLight
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(left, 0, band, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A minimal icon button with a blurred background.
class AuthIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLargeIcon;
  final Color? color;

  const AuthIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLargeIcon = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? EntryColors.arcticSilver;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed?.call();
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: activeColor.withValues(alpha: 0.9),
                  size: isLargeIcon ? 28 : 22,
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    label.split(' ').first.toUpperCase(),
                    style: TextStyle(
                      color: activeColor.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
