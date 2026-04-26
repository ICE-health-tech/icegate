import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';

/// A premium button with a crystal shimmer effect and high-fidelity haptics.
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

class _ShimmerButtonState extends State<ShimmerButton> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [EntryColors.iceCyan, EntryColors.glacierBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: EntryColors.iceCyan.withValues(alpha: 0.4),
                blurRadius: _isPressed ? 10 : 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(4, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Stack(
            children: [
              // Shimmer Overlay
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      size: const Size(double.infinity, 60),
                      painter: _ShimmerPainter(progress: _shimmerController.value),
                    ),
                  );
                },
              ),
              
              // Button Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading ? null : () {
                    HapticFeedback.heavyImpact();
                    widget.onPressed?.call();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black87,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            widget.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                              color: Colors.black87,
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

class _ShimmerPainter extends CustomPainter {
  final double progress;
  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH((progress * size.width * 3) - size.width, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) => oldDelegate.progress != progress;
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
