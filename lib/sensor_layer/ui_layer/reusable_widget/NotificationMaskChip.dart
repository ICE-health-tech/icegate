import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

/// Outlined pill “masks” for notification rows (schedule time + priority/tag), matching the hub visual style.
class NotificationMaskChip extends StatelessWidget {
  const NotificationMaskChip.schedule({
    super.key,
    required this.label,
    this.onTap,
  })  : _mode = _MaskMode.schedule,
        tagAccent = null;

  const NotificationMaskChip.tag({
    super.key,
    required this.label,
    required Color this.tagAccent,
    this.onTap,
  }) : _mode = _MaskMode.tag;

  final _MaskMode _mode;
  final String label;
  final Color? tagAccent;
  final VoidCallback? onTap;

  static const Color _scheduleBorder = Color(0xFF4A4A5C);
  static const Color _scheduleInk = Color(0xFF5EB8FF);

  @override
  Widget build(BuildContext context) {
    final Widget inner = _mode == _MaskMode.schedule
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: _scheduleInk.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _scheduleInk,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: tagAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    final borderColor = _mode == _MaskMode.schedule
        ? _scheduleBorder.withValues(alpha: 0.85)
        : tagAccent!.withValues(alpha: 0.55);

    final bg = _mode == _MaskMode.schedule
        ? EntryColors.deepGlacier.withValues(alpha: 0.35)
        : EntryColors.winterDeepHorizon.withValues(alpha: 0.65);

    final padding = EdgeInsets.symmetric(
      horizontal: _mode == _MaskMode.schedule ? 12 : 12,
      vertical: _mode == _MaskMode.schedule ? 8 : 7,
    );

    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: inner,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: box,
      ),
    );
  }
}

enum _MaskMode { schedule, tag }
