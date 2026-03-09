import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// 1. Data Model for Sub-Buttons
// ---------------------------------------------------------------------------
class SubButton {
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final String? tooltip;
  final String? label;
  final VoidCallback? onPressed;

  const SubButton({
    this.onPressed,
    this.icon = Icons.circle,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.tooltip,
    this.label,
  });
}

// ---------------------------------------------------------------------------
// 2. The Generic MainButton Widget
// ---------------------------------------------------------------------------
class MainButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Widget? iconWidget;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final String type;
  final String destination;
  final List<SubButton>? subButtons;
  final VoidCallback mainFunction;
  final VoidCallback? doubleClickFunction;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onLongPress;

  const MainButton({
    super.key,
    required this.type,
    this.destination = "",
    this.onPressed,
    this.icon = Icons.add,
    this.iconWidget,
    required this.mainFunction,
    this.subButtons,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.doubleClickFunction,
    this.onSwipeUp,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onLongPress,
  });

  @override
  State<MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<MainButton>
    with SingleTickerProviderStateMixin {
  bool isDialActive = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(curve: Curves.easeInOut, parent: _controller));
  }

  @override
  void didUpdateWidget(MainButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destination != oldWidget.destination) {
      _removeOverlayImmediate();
    }
  }

  @override
  void dispose() {
    _removeOverlayImmediate();
    _controller.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
    setState(() => isDialActive = true);
    HapticFeedback.heavyImpact();
  }

  void _hideOverlay() {
    if (_overlayEntry == null) return;

    _controller.reverse().then((_) {
      _removeOverlayImmediate();
    });
  }

  void _removeOverlayImmediate() {
    if (_overlayEntry != null) {
      final entry = _overlayEntry;
      _overlayEntry = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        entry?.remove();
        if (mounted) setState(() => isDialActive = false);
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final mainSize = widget.size ?? 56.0;
        final subSize = mainSize * 0.9; // Larger hit area
        final double radius = mainSize * 1.5; // More spread
        final List<SubButton> buttonsToRender = widget.subButtons ?? [];

        return Stack(
          children: [
            // 1. BACKDROP
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideOverlay,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

            // 2. COMPOSITED ELEMENTS
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.center,

              targetAnchor: Alignment.center,
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: radius * 4,
                  height: radius * 4,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // SUB-BUTTONS
                      ...buttonsToRender.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final SubButton data = entry.value;

                        final double startAngle = -math.pi * 0.95;
                        final double totalArc = math.pi * 0.9;
                        final double angleStep = buttonsToRender.length > 1
                            ? totalArc / (buttonsToRender.length - 1)
                            : 0;
                        final double angle = startAngle + (angleStep * index);

                        final Offset targetOffset = Offset(
                          math.cos(angle) * radius,
                          math.sin(angle) * radius,
                        );

                        final Animation<double> buttonCurve = CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutBack,
                        );

                        return AnimatedBuilder(
                          animation: buttonCurve,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: targetOffset * buttonCurve.value,
                              child: Transform.scale(
                                scale: buttonCurve.value,
                                child: child,
                              ),
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              final action = data.onPressed;
                              _removeOverlayImmediate();
                              if (action != null) {
                                Future.microtask(action);
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: data.size ?? subSize,
                              height: data.size ?? subSize,
                              // padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    data.backgroundColor ?? Colors.blueAccent,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                data.icon,
                                color: data.iconColor ?? Colors.white,
                                size: (data.size ?? subSize) * 0.5,
                              ),
                            ),
                          ),
                        );
                      }),

                      // PROXY MAIN BUTTON
                      GestureDetector(
                        onTap: _hideOverlay,
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: widget.doubleClickFunction,
                        child: Container(
                          width: mainSize,
                          height: mainSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                widget.backgroundColor ??
                                Theme.of(context).primaryColor,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: RotationTransition(
                            turns: _rotateAnimation,
                            child: Icon(
                              widget.icon,
                              color: widget.iconColor ?? Colors.white,
                              size: mainSize * 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSwipeRight() {
    HapticFeedback.mediumImpact();
    if (widget.onSwipeRight != null) {
      widget.onSwipeRight!();
    } else if (widget.doubleClickFunction != null) {
      widget.doubleClickFunction!();
    } else {
      widget.mainFunction();
    }
  }

  void _handleSwipeLeft() {
    HapticFeedback.mediumImpact();
    if (widget.onSwipeLeft != null) {
      widget.onSwipeLeft!();
    } else if (widget.onSwipeRight != null) {
      widget.onSwipeRight!();
    } else {
      widget.mainFunction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainSize = widget.size ?? 56.0;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Opacity(
        opacity: isDialActive ? 0.0 : 1.0,
        child: GestureDetector(
          onTap: widget.mainFunction,
          onLongPress: widget.onLongPress ?? _showOverlay,
          onDoubleTap: widget.doubleClickFunction,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 300) {
                _handleSwipeRight();
              } else if (details.primaryVelocity! < -300) {
                _handleSwipeLeft();
              }
            }
          },

          onVerticalDragEnd: (details) {
            // Detect swipe up
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -500) {
              HapticFeedback.mediumImpact();
              if (widget.onSwipeUp != null) {
                widget.onSwipeUp!();
              } else {
                widget.mainFunction();
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: mainSize,
            height: mainSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.backgroundColor ?? Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.iconWidget != null
                ? ClipOval(
                    child: SizedBox(
                      width: mainSize * 0.7,
                      height: mainSize * 0.7,
                      child: widget.iconWidget!,
                    ),
                  )
                : Icon(
                    widget.icon,
                    color: widget.iconColor ?? Colors.white,
                    size: mainSize * 0.5,
                  ),
          ),
        ),
      ),
    );
  }
}
