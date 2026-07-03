import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';

/// Primary login CTA: premium + minimalist (transparent, crisp border).
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
  static const double _height = 52;
  static const BorderRadius _pill = BorderRadius.all(Radius.circular(999));

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = HealthMetricColors.tempAccent;

    final outerBorder = accent.withValues(alpha: isDark ? 0.55 : 0.42);
    final innerBorder = Colors.white.withValues(alpha: isDark ? 0.16 : 0.10);
    final pressedFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : cs.surfaceContainerHighest.withValues(alpha: 0.35);
    final textColor = isDark ? Colors.white : cs.onSurface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: double.infinity,
          height: _height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      widget.onPressed?.call();
                    },
              borderRadius: _pill,
              splashColor:
                  (isDark ? Colors.white : cs.primary).withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: _pill,
                  color: _isPressed ? pressedFill : Colors.transparent,
                  border: Border.all(color: outerBorder, width: 1.6),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _pill,
                    border: Border.all(color: innerBorder, width: 1.0),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: textColor,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            widget.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              height: 1.0,
                              color: textColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// L3 glass chip for Face ID / Apple / Google (duylongart_glass_ui.md).
class AuthIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback? onPressed;

  /// Maps to [HealthMetricColors.pluginCardTint] keys: health, mind, google, …
  final String pillarKey;

  const AuthIconButton({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    this.onPressed,
    required this.pillarKey,
  });

  static Widget googleMark({double size = 22}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          color: const Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: size * 0.58,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final tint = HealthMetricColors.pluginCardTint(pillarKey);
    final accent = HealthMetricColors.pluginAccent(pillarKey);

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.45,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 76,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: HealthMetricColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: enabled ? 0.12 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading ??
                    Icon(
                      icon ?? Icons.login_rounded,
                      color: accent,
                      size: 26,
                    ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HealthMetricColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
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
