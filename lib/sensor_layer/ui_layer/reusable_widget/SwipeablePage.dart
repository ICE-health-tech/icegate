import 'package:flutter/material.dart';

enum SwipeablePageDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

class SwipeablePage extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;
  final SwipeablePageDirection direction;
  final double sensitivity;

  const SwipeablePage({
    super.key,
    required this.child,
    required this.onSwipe,
    this.direction = SwipeablePageDirection.leftToRight,
    this.sensitivity = 20.0, // Minimum drag distance to trigger swipe
  });

  @override
  State<SwipeablePage> createState() => _SwipeablePageState();
}

class _SwipeablePageState extends State<SwipeablePage> {
  double _dragExtent = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        if (widget.direction == SwipeablePageDirection.leftToRight ||
            widget.direction == SwipeablePageDirection.rightToLeft) {
          setState(() {
            _dragExtent += details.primaryDelta!;
          });
        }
      },
      onHorizontalDragEnd: (details) {
        _handleDragEnd();
      },
      onVerticalDragUpdate: (details) {
        if (widget.direction == SwipeablePageDirection.topToBottom ||
            widget.direction == SwipeablePageDirection.bottomToTop) {
          setState(() {
            _dragExtent += details.primaryDelta!;
          });
        }
      },
      onVerticalDragEnd: (details) {
        _handleDragEnd();
      },
      child: widget.child,
    );
  }

  void _handleDragEnd() {
    bool swiped = false;

    switch (widget.direction) {
      case SwipeablePageDirection.leftToRight:
        if (_dragExtent > widget.sensitivity) swiped = true;
        break;
      case SwipeablePageDirection.rightToLeft:
        if (_dragExtent < -widget.sensitivity) swiped = true;
        break;
      case SwipeablePageDirection.topToBottom:
        if (_dragExtent > widget.sensitivity) swiped = true;
        break;
      case SwipeablePageDirection.bottomToTop:
        if (_dragExtent < -widget.sensitivity) swiped = true;
        break;
    }

    if (swiped) {
      widget.onSwipe();
    }

    // Reset drag extent
    setState(() {
      _dragExtent = 0.0;
    });
  }
}
