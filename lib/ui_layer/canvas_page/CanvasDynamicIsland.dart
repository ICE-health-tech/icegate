import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';

import 'package:ice_shield/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_shield/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:provider/provider.dart';

class CanvasDynamicIsland extends StatelessWidget {
  const CanvasDynamicIsland({super.key});

  String _getTitle(String path) {
    if (path == '/') return "ICE GATE";
    if (path.startsWith('/canvas')) return "CANVAS";
    if (path.startsWith('/profile')) return "ANALYSIS";
    if (path.startsWith('/health')) return "HEALTH";
    if (path.startsWith('/finance')) return "FINANCE";
    if (path.startsWith('/social')) return "SOCIAL";
    if (path.startsWith('/projects')) return "PROJECTS";
    if (path.startsWith('/widgets')) return "WIDGETS";
    // if (path.startsWith('/personal-info')) return "USER INFO";
    if (path.startsWith('/project_notes')) return "NOTES";
    if (path.startsWith('/settings')) return "SETTINGS";
    return "ICE SHIELD";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentRoute = GoRouterState.of(context).uri.path;
    // Hide on health sub-pages (e.g., /health/steps, /health/sleep)
    if (currentRoute.startsWith('/health/') && currentRoute != '/health') {
      return const SizedBox.shrink();
    }
    // Hide on canvas sub-pages too
    if (currentRoute.startsWith('/canvas/') && currentRoute != '/canvas') {
      return const SizedBox.shrink();
    }
    final isCanvas = currentRoute == '/canvas';
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive Scaling
    final bool isSmallDevice = screenWidth < 375;
    final double scalingFactor = isSmallDevice ? 0.85 : 1.0;

    final focusBlock = context.watch<FocusBlock>();

    return Watch((context) {
      final activeTab = DragCanvasGrid.activeCanvasTab.value;
      final isAnyTabOpen = isCanvas && activeTab != 'none';
      final sessionsCount = focusBlock.sessionsCompletedToday.value;
      final isFocusRunning = focusBlock.isRunning.value;
      final remainingSecs = focusBlock.remainingTime.value;
      final sessionType = focusBlock.currentSessionType.value;

      // Time formatting helper
      String formatTime(int seconds) {
        int m = seconds ~/ 60;
        int s = seconds % 60;
        return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      // Calculate width based on screen size
      // Focus mode needs more room than standard title but less than full tab
      final double targetWidth = isAnyTabOpen
          ? 300
          : (isFocusRunning ? 240 : 200);
      final double width = (targetWidth * scalingFactor).clamp(
        0.0,
        screenWidth - 100,
      );

      final Color focusColor = sessionType == 'Focus'
          ? Colors.blueAccent
          : Colors.greenAccent;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        width: width,
        height: 48 * scalingFactor,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(27 * scalingFactor),
          border: Border.all(
            color: isFocusRunning
                ? focusColor.withOpacity(0.5)
                : colorScheme.outlineVariant.withOpacity(0.5),
            width: isFocusRunning ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isFocusRunning ? focusColor : colorScheme.shadow)
                  .withOpacity(0.3),
              blurRadius: isFocusRunning ? 20 : 16,
              offset: Offset(0, 6 * scalingFactor),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: (isFocusRunning ? focusColor : colorScheme.primary)
                  .withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (isAnyTabOpen ? 16 : 8) * scalingFactor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/');
                }
              },
              child: Container(
                padding: EdgeInsets.all(4 * scalingFactor),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.onSurface,
                  size: 20 * scalingFactor,
                ),
              ),
            ),

            // Center Content (Title or Focus Timer)
            if (!isAnyTabOpen)
              Expanded(
                child: GestureDetector(
                  onTap: isFocusRunning
                      ? () {
                          HapticFeedback.mediumImpact();
                          context.push('/health/focus');
                        }
                      : null,
                  child: Center(
                    child: isFocusRunning
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: focusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: focusColor.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${sessionType.toUpperCase()} ",
                                style: TextStyle(
                                  color: focusColor,
                                  fontSize: 10 * scalingFactor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                formatTime(remainingSecs),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14 * scalingFactor,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Monospace',
                                ),
                              ),
                            ],
                          )
                        : AutoSizeText(
                            _getTitle(currentRoute),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 11 * scalingFactor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2 * scalingFactor,
                            ),
                            maxLines: 1,
                          ),
                  ),
                ),
              )
            else
              const Spacer(),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Focus Shortcut
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/health/focus');
                  },
                  child: Container(
                    padding: EdgeInsets.all(4 * scalingFactor),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      size: 22 * scalingFactor,
                    ),
                  ),
                ),
                SizedBox(width: 4 * scalingFactor),
                // Notifications
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/notifications');
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4 * scalingFactor),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 22 * scalingFactor, // Increased from 20
                        ),
                      ),
                      if (sessionsCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: EdgeInsets.all(3 * scalingFactor),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 14 * scalingFactor,
                              minHeight: 14 * scalingFactor,
                            ),
                            child: Text(
                              '$sessionsCount',
                              style: TextStyle(
                                color: colorScheme.onError,
                                fontSize: 8 * scalingFactor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (isAnyTabOpen) ...[
                  SizedBox(width: 8 * scalingFactor),

                  // Step Goal Customizer
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GoalConfigurationWidget(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(6 * scalingFactor),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings_suggest_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 26 * scalingFactor,
                      ),
                    ),
                  ),

                  if (isCanvas) ...[
                    SizedBox(width: 8 * scalingFactor),

                    // vertical divider
                    Container(
                      width: 1,
                      height: 16 * scalingFactor,
                      color: colorScheme.outlineVariant,
                    ),

                    SizedBox(width: 8 * scalingFactor),

                    // Store Toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        DragCanvasGrid.toggleStore();
                      },
                      child: AnimatedRotation(
                        turns: activeTab == 'store' ? 0.125 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.add_circle_rounded,
                          color: activeTab == 'store'
                              ? colorScheme.error
                              : colorScheme.primary,
                          size: 28 * scalingFactor, // Reduced from 32
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}
