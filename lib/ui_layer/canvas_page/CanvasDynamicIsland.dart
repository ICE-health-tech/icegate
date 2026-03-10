import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';

import 'package:ice_gate/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_gate/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:ice_gate/ui_layer/social_page/SocialPage.dart';
import 'package:provider/provider.dart';

class CanvasDynamicIsland extends StatelessWidget {
  const CanvasDynamicIsland({super.key});

  String _getTitle(String path) {
    if (path == '/') return "ICE GATE";
    if (path.startsWith('/canvas')) return "CANVAS";
    if (path.startsWith('/profile')) return "ANALYSIS";
    if (path.startsWith('/health')) return "HEALTH";
    if (path.startsWith('/finance')) return "FINANCE";
    if (path.startsWith('/social')) {
      final index = SocialPage.activeTab.value;
      switch (index) {
        case 0:
          return "RANKING";
        case 1:
          return "PEOPLE";
        case 2:
          return "FEATS";
        default:
          return "SOCIAL";
      }
    }
    if (path.startsWith('/health')) {
      if (path.contains('food')) return "FOOD";
      if (path.contains('exercise')) return "TRAINING";
      if (path.contains('water')) return "HYDRATION";
      if (path.contains('focus')) return "FOCUS";
      return "HEALTH";
    }
    if (path.startsWith('/finance')) return "FINANCE";
    if (path.startsWith('/projects')) return "PROJECTS";
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
    if (currentRoute.startsWith('/projects/') && currentRoute != '/projects') {
      return const SizedBox.shrink();
    }
    final isCanvas = currentRoute == '/canvas';
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive Scaling
    final bool isSmallDevice = screenWidth < 375;
    final double scalingFactor = isSmallDevice ? 0.85 : 1.0;

    final focusBlock = context.watch<FocusBlock>();
    final questBlock = context.watch<QuestBlock>();

    return Watch((context) {
      final activeTab = DragCanvasGrid.activeCanvasTab.value;
      final isAnyTabOpen = isCanvas && activeTab != 'none';
      final numberOfQuests = questBlock.numberOfQuests.value;
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
      final bool hasTacticalIcons =
          currentRoute.startsWith('/social') ||
          currentRoute.startsWith('/health') ||
          currentRoute.startsWith('/finance');

      final double targetWidth = isAnyTabOpen
          ? 320
          : (isFocusRunning ? 260 : (hasTacticalIcons ? 280 : 200));
      final double width = (targetWidth * scalingFactor).clamp(
        0.0,
        screenWidth - 40, // More breathing room
      );

      final Color focusColor = sessionType == 'Focus'
          ? Colors.blueAccent
          : Colors.greenAccent;
      final String location = GoRouterState.of(context).uri.toString();
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
                print("Current location: " + location);
                if (location.startsWith('/projects/editor')) {
                  context.go("/projects");
                }

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

            // Tactical Icons Area (if applicable)
            if (currentRoute.startsWith('/social') ||
                currentRoute.startsWith('/health') ||
                currentRoute.startsWith('/finance'))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildTacticalIcons(
                  context,
                  currentRoute,
                  scalingFactor,
                  colorScheme,
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
                              const SizedBox(width: 8),
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
                      if (numberOfQuests > 0)
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
                              '$numberOfQuests',
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

  List<Widget> _buildTacticalIcons(
    BuildContext context,
    String path,
    double scale,
    ColorScheme colorScheme,
  ) {
    if (path.startsWith('/social')) {
      final activeTab = SocialPage.activeTab.value;
      return [
        _tacticalIcon(
          icon: Icons.emoji_events_rounded,
          isSelected: activeTab == 0,
          onTap: () {
            HapticFeedback.lightImpact();
            SocialPage.activeTab.value = 0;
          },
          scale: scale,
          colorScheme: colorScheme,
        ),
        _tacticalIcon(
          icon: Icons.people_alt_rounded,
          isSelected: activeTab == 1,
          onTap: () {
            HapticFeedback.lightImpact();
            SocialPage.activeTab.value = 1;
          },
          scale: scale,
          colorScheme: colorScheme,
        ),
        _tacticalIcon(
          icon: Icons.military_tech_rounded,
          isSelected: activeTab == 2,
          onTap: () {
            HapticFeedback.lightImpact();
            SocialPage.activeTab.value = 2;
          },
          scale: scale,
          colorScheme: colorScheme,
        ),
      ];
    }

    if (path.startsWith('/health')) {
      return [
        _tacticalIcon(
          icon: Icons.restaurant_rounded,
          isSelected: path == '/health/food/dashboard',
          onTap: () => context.go('/health/food/dashboard'),
          scale: scale,
          colorScheme: colorScheme,
        ),
        _tacticalIcon(
          icon: Icons.fitness_center_rounded,
          isSelected: path == '/health/exercise',
          onTap: () => context.go('/health/exercise'),
          scale: scale,
          colorScheme: colorScheme,
        ),
        _tacticalIcon(
          icon: Icons.timer_rounded,
          isSelected: path == '/health/focus',
          onTap: () => context.go('/health/focus'),
          scale: scale,
          colorScheme: colorScheme,
        ),
        _tacticalIcon(
          icon: Icons.water_drop_rounded,
          isSelected: path == '/health/water',
          onTap: () => context.go('/health/water'),
          scale: scale,
          colorScheme: colorScheme,
        ),
      ];
    }

    if (path.startsWith('/finance')) {
      return [
        _tacticalIcon(
          icon: Icons.savings_rounded,
          isSelected: false, // Could be linked to scroll or sub-tab
          onTap: () => HapticFeedback.selectionClick(),
          scale: scale,
          colorScheme: colorScheme,
        ),
        _tacticalIcon(
          icon: Icons.shopping_cart_rounded,
          isSelected: false,
          onTap: () => HapticFeedback.selectionClick(),
          scale: scale,
          colorScheme: colorScheme,
        ),
        _tacticalIcon(
          icon: Icons.trending_up_rounded,
          isSelected: false,
          onTap: () => HapticFeedback.selectionClick(),
          scale: scale,
          colorScheme: colorScheme,
        ),
      ];
    }

    return [];
  }

  Widget _tacticalIcon({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required double scale,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4 * scale),
        padding: EdgeInsets.all(4 * scale),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8 * scale),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant.withOpacity(0.7),
          size: 18 * scale,
        ),
      ),
    );
  }
}
