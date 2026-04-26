import 'package:flutter/material.dart';

/// Quick action button data model
class QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Speed dial floating action button for quick health actions
class QuickActionButton extends StatefulWidget {
  final List<QuickAction> actions;

  const QuickActionButton({super.key, required this.actions});

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons
        ...List.generate(widget.actions.length, (index) {
          final action = widget.actions[index];
          return ScaleTransition(
            scale: _animation,
            child: FadeTransition(
              opacity: _animation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          action.label,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action button
                    FloatingActionButton(
                      heroTag: 'quick_action_$index',
                      mini: true,
                      backgroundColor: action.color,
                      onPressed: () {
                        action.onTap();
                        _toggle();
                      },
                      child: Icon(action.icon, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        // Main FAB
        FloatingActionButton(
          heroTag: 'main_fab',
          backgroundColor: colorScheme.secondary,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              color: colorScheme.onSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
