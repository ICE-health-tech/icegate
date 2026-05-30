import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-width hub row — same visual language as Canvas (BẢNG GHÉP) entry cards.
class HubEntryCard extends StatelessWidget {
  const HubEntryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = compact ? 18.0 : 22.0;
    final iconSize = compact ? 44.0 : 52.0;
    final iconGlyph = compact ? 22.0 : 26.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(radius),
        splashColor: accent.withValues(alpha: 0.18),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          child: Container(
            decoration: BoxDecoration(
              // Transparent face, premium border.
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: compact ? 1 : 1.1,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                // subtle inner highlight line
                color: Colors.white.withValues(alpha: 0.16),
                width: 0.8,
              ),
            ),
            child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.28),
                        accent.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(icon, color: accent, size: iconGlyph),
                ),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                          fontSize: compact ? 11 : 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: 0.75),
                  size: compact ? 22 : 26,
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Grid cell — same pillar gradient/border as [HubEntryCard], vertical layout.
class HubGridTile extends StatelessWidget {
  const HubGridTile({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.onLongPress,
    this.isAddSlot = false,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isAddSlot;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(dense ? 14 : 18);
    final outerBorderColor = isAddSlot
        ? cs.outline.withValues(alpha: 0.28)
        : accent.withValues(alpha: dense ? 0.32 : 0.28);
    final borderWidth = dense ? 1.0 : 1.0;
    final innerBorderColor = Colors.white.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(dense ? 14 : 18),
        splashColor: accent.withValues(alpha: 0.18),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: dense ? 0.55 : 0.42),
              borderRadius: radius,
              border: Border.all(
                color: outerBorderColor,
                width: borderWidth,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: innerBorderColor,
                width: 0.8,
              ),
            ),
            child: Padding(
            padding: EdgeInsets.fromLTRB(
              dense ? 6 : 10,
              dense ? 6 : 12,
              dense ? 6 : 8,
              dense ? 6 : 10,
            ),
            child: dense
                ? Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: Colors.transparent,
                          border: Border.all(
                            color: isAddSlot
                                ? cs.outline.withValues(alpha: 0.18)
                                : accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isAddSlot
                              ? cs.onSurface.withValues(alpha: 0.65)
                              : accent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            height: 1.15,
                            letterSpacing: -0.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.transparent,
                          border: Border.all(
                            color: isAddSlot
                                ? cs.outline.withValues(alpha: 0.18)
                                : accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isAddSlot
                              ? cs.onSurface.withValues(alpha: 0.65)
                              : accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
          ),
        ),
      ),
    );
  }
}
