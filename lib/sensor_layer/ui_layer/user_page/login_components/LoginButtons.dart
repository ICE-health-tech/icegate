import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

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

/// A flat, premium icon button with subtle 3D lift (no heavy glass blur).
class AuthIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLargeIcon;
  final Color? color;

  static const double _radius = 16;
  static const double _height = 62;

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
    final enabled = onPressed != null;
    // Raised "3D box" surface tuned to the provided reference image.
    // We lightly tint a dark base with the activeColor so each provider keeps its identity.
    final base = const Color(0xFF0B1524);
    final surface = Color.lerp(base, activeColor, 0.18) ?? base;
    final surfaceTop = Color.lerp(surface, Colors.white, 0.12) ?? surface;
    final surfaceBottom = Color.lerp(surface, Colors.black, 0.22) ?? surface;
    final borderDark = Color.lerp(surface, Colors.black, 0.45) ?? surface;

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 180),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: enabled
              ? [
                  // Soft lift shadow.
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    offset: const Offset(0, 10),
                    blurRadius: 18,
                    spreadRadius: -10,
                  ),
                  // Key shadow (tighter) for the 3D edge.
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    offset: const Offset(0, 6),
                    blurRadius: 10,
                    spreadRadius: -6,
                  ),
                  // Subtle colored bounce light on top edge.
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.10),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                    spreadRadius: -12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  surfaceTop.withValues(alpha: enabled ? 0.96 : 0.9),
                  surface.withValues(alpha: enabled ? 0.92 : 0.86),
                  surfaceBottom.withValues(alpha: enabled ? 0.92 : 0.86),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(
                // Slightly crisper rim to sell "box edge".
                color: borderDark.withValues(alpha: enabled ? 0.55 : 0.35),
                width: 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Crisp top highlight (reference-like bevel).
                Positioned(
                  left: 10,
                  right: 10,
                  top: 1.5,
                  height: 1,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0.5),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(
                              alpha: enabled ? 0.38 : 0.16,
                            ),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom inner shadow (adds box depth).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 10,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(
                              alpha: enabled ? 0.20 : 0.14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: enabled
                        ? () {
                            HapticFeedback.lightImpact();
                            onPressed?.call();
                          }
                        : null,
                    borderRadius: BorderRadius.circular(_radius),
                    splashColor: activeColor.withValues(alpha: 0.10),
                    highlightColor: activeColor.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            color: Color.lerp(activeColor, Colors.white, 0.06)
                                ?.withValues(alpha: 0.94) ??
                                activeColor.withValues(alpha: 0.94),
                            size: isLargeIcon ? 24 : 22,
                          ),
                          if (label.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  label.toUpperCase(),
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: Color.lerp(activeColor, Colors.white, 0.06)
                                            ?.withValues(alpha: 0.94) ??
                                        activeColor.withValues(alpha: 0.94),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
