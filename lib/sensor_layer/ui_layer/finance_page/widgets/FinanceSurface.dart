import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

/// Finance module chrome — frosted panels with ice depth (top highlight + cool shadow).
abstract final class FinanceSurface {
  /// Outer gap so card shadows are not clipped by siblings.
  static const cardMargin = EdgeInsets.only(bottom: 10);

  /// Comfortable inner padding for list / hero cards.
  static const cardPadding = EdgeInsets.all(20);
  static const cardPaddingCompact = EdgeInsets.all(16);

  static Color border({required bool isDark}) => isDark
      ? EntryColors.neonSilver.withValues(alpha: 0.72)
      : EntryColors.deepGlacier.withValues(alpha: 0.78);

  static Color ink({required bool isDark}) =>
      isDark ? EntryColors.frostedWhite : EntryColors.deepGlacier;

  static Color mutedInk({required bool isDark}) => isDark
      ? EntryColors.darkSilver
      : EntryColors.polishedSteel;

  static Color silverAccent() => EntryColors.financeSilverAccent;

  static Color currencyPillBackground({
    required bool isDark,
    required bool active,
  }) =>
      active ? ink(isDark: isDark) : Colors.transparent;

  static Color currencyPillForeground({
    required bool isDark,
    required bool active,
  }) =>
      active
          ? (isDark ? EntryColors.obsidianBase : EntryColors.frostedWhite)
          : mutedInk(isDark: isDark);

  static List<BoxShadow> shadows({
    required bool isDark,
    bool elevated = false,
  }) {
    final depth = elevated ? 1.0 : 0.85;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: (isDark ? 0.55 : 0.2) * depth),
        blurRadius: elevated ? 28 : 18,
        offset: Offset(0, elevated ? 16 : 10),
        spreadRadius: isDark ? 0 : 1,
      ),
      BoxShadow(
        color: EntryColors.financeSilverAccent.withValues(
          alpha: (isDark ? 0.16 : 0.1) * depth,
        ),
        blurRadius: elevated ? 36 : 24,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
      if (elevated)
        BoxShadow(
          color: EntryColors.neonSilver.withValues(
            alpha: isDark ? 0.12 : 0.08,
          ),
          blurRadius: 48,
          offset: const Offset(0, 20),
          spreadRadius: -12,
        ),
    ];
  }

  static LinearGradient panelGradient({required bool isDark}) {
    final fillTop = isDark
        ? Color.alphaBlend(
            EntryColors.financeSilverAccent.withValues(alpha: 0.14),
            EntryColors.obsidianBase.withValues(alpha: 0.82),
          )
        : EntryColors.frostedWhite.withValues(alpha: 0.98);
    final fillBottom = isDark
        ? const Color(0xFF020408).withValues(alpha: 0.95)
        : EntryColors.polishedSteel.withValues(alpha: 0.24);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [fillTop, fillBottom],
      stops: const [0.0, 1.0],
    );
  }

  static Color _topEdgeHighlight({required bool isDark}) =>
      EntryColors.frostedWhite.withValues(alpha: isDark ? 0.42 : 0.65);

  static LinearGradient _bottomDepthShade({required bool isDark}) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
        ],
      );

  /// Fill + border only — safe inside [ClipRRect].
  static BoxDecoration panelFill(
    ColorScheme cs, {
    required bool isDark,
    double radius = 18,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: panelGradient(isDark: isDark),
      border: Border.all(
        color: border(isDark: isDark),
        width: isDark ? 1.15 : 1.2,
      ),
    );
  }

  static BoxDecoration panel(
    ColorScheme cs, {
    required bool isDark,
    double radius = 18,
    bool elevated = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: panelGradient(isDark: isDark),
      border: Border.all(
        color: border(isDark: isDark),
        width: isDark ? 1.15 : 1.2,
      ),
      boxShadow: shadows(isDark: isDark, elevated: elevated),
    );
  }

  /// Frosted card — shadow outside clip so depth is visible.
  static Widget card({
    required Widget child,
    required ColorScheme cs,
    required bool isDark,
    double radius = 18,
    EdgeInsetsGeometry padding = cardPadding,
    EdgeInsetsGeometry margin = cardMargin,
    bool elevated = false,
    VoidCallback? onTap,
  }) {
    final borderRadius = BorderRadius.circular(radius);
    Widget shell = Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadows(isDark: isDark, elevated: elevated),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: elevated ? 22 : 16,
              sigmaY: elevated ? 22 : 16,
            ),
            child: DecoratedBox(
              decoration: panelFill(cs, isDark: isDark, radius: radius),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _bottomDepthShade(isDark: isDark),
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: padding, child: child),
                  Positioned(
                    top: 0,
                    left: radius * 0.3,
                    right: radius * 0.3,
                    child: IgnorePointer(
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _topEdgeHighlight(isDark: isDark),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      shell = GestureDetector(onTap: onTap, child: shell);
    }
    return shell;
  }
}
