import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:ice_shield/ui_layer/widget_page/AddPluginForm.dart';
import 'package:provider/provider.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'dart:ui';
import 'StoreWidget.dart'; // The Bottom Bar

// --- MAIN SCREEN WRAPPER ---

void buildAddCell(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: AddPluginForm(
        data: FormData(
          title: "Add Custom Widget",
          description: "Enter the name and URL of the website you want to add.",
        ),
      ),
    ),
  );
}

class DragCanvasGrid extends StatefulWidget {
  const DragCanvasGrid({super.key});

  // Global signal for tab state
  static final activeCanvasTab = signal<String>('none');

  static void toggleStore() {
    print("Toggle store");
    if (activeCanvasTab.value == 'store') {
      activeCanvasTab.value = 'none';
    } else {
      activeCanvasTab.value = 'store';
    }
  }

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      destination: "/canvas",
      size: size,
      // Note: Some MainButton implementations use 'icon' as a fallback.
      // If it looks weird, try setting icon to Icons.circle (invisible) or null.
      // icon: Icons.grid_view,
      iconWidget: Center(
        child: Transform.rotate(
          angle: 45 * math.pi / 180,
          child: Icon(
            Icons.grid_view,
            color: Colors.white,
            size: size! * 0.6, // Ensure the icon respects the passed size
          ),
        ),
      ),
      mainFunction: () {
        toggleStore();
        HapticFeedback.heavyImpact();
      },
      onLongPress: () {
        context.go("/");
        HapticFeedback.heavyImpact();
      },
    );
  }

  @override
  State<DragCanvasGrid> createState() => _DragCanvasGridState();
}

class _DragCanvasGridState extends State<DragCanvasGrid> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: baseColor,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: DragCanvas(baseColor: baseColor, isDark: isDark),
      ),
    );
  }
}

class DragCanvas extends StatefulWidget {
  final Color baseColor;
  final bool isDark;

  const DragCanvas({super.key, required this.baseColor, required this.isDark});

  @override
  State<DragCanvas> createState() => _DragCanvasState();
}

class _DragCanvasState extends State<DragCanvas> {
  bool isClick = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WidgetManagerBlock>().loadFromDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 70), // Match 70px Header Area

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: widget.baseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(color: Colors.transparent),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DotGridPainter(
                        color: widget.isDark ? Colors.white : Colors.black,
                        opacity: 0.1,
                        spacing: 25,
                      ),
                    ),
                  ),
                  Watch((context) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildEntryCard(
                          context: context,
                          title: "Notification Center",
                          subtitle: "Manage your alerts and focus history",
                          icon: Icons.notifications_active_rounded,
                          color: Colors.blueAccent,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/notifications');
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildEntryCard(
                          context: context,
                          title: "Goal Center",
                          subtitle: "Track your daily health evolution",
                          icon: Icons.track_changes_rounded,
                          color: Colors.orangeAccent,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            context.push('/canvas/goals');
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Watch((context) {
          final activeTab = DragCanvasGrid.activeCanvasTab.value;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: child,
              );
            },
            child: activeTab == 'store'
                ? const StoreWidget()
                : const SizedBox.shrink(),
          );
        }),
      ],
    );
  }

  Widget _buildEntryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding:  EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:  TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double opacity;

  DotGridPainter({required this.color, this.spacing = 20, this.opacity = 0.1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 2;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
