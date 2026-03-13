import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

import 'package:ice_gate/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_gate/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SSHService.dart';
import 'package:provider/provider.dart';

class CanvasDynamicIsland extends StatelessWidget {
  final int? socialIndex;
  const CanvasDynamicIsland({super.key, this.socialIndex});

  String _getTitle(
    BuildContext context,
    String path,
    SocialBlock socialBlock,
    int? socialIndex,
  ) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return "ICE GATE";

    if (path == '/') return "ICE GATE";
    if (path.startsWith('/canvas')) return "CANVAS";
    if (path.startsWith('/profile')) return "ANALYSIS";

    if (path.startsWith('/social')) {
      final index = socialIndex ?? 0;
      print("Index of current social page: $index");
      switch (index) {
        case 0:
          return l10n.ranking.toUpperCase();
        case 1:
          return l10n.relationships.toUpperCase();
        case 2:
          return l10n.achievements.toUpperCase();
        default:
          return "SOCIAL";
      }
    }

    if (path.startsWith('/health')) {
      if (path.contains('food')) return l10n.health_log_food.toUpperCase();
      if (path.contains('exercise')) return l10n.health_exercise.toUpperCase();
      if (path.contains('water')) return l10n.health_log_water.toUpperCase();
      if (path.contains('focus')) return l10n.health_focus.toUpperCase();
      if (path.contains('heart_rate') || path.contains('vitals')) {
        return "VITALS";
      }
      return "HEALTH";
    }

    if (path.startsWith('/finance')) return "FINANCE";
    if (path.startsWith('/projects')) return "PROJECTS";
    if (path.startsWith('/project_notes')) return "NOTES";
    if (path.startsWith('/settings')) return "SETTINGS";
    if (path.startsWith('/widgets/ssh')) return "SSH TERMINAL";
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
    final socialBlock = context.watch<SocialBlock>();

    return Watch((context) {
      final currentRoute = GoRouterState.of(context).uri.path;
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
      final double targetWidth = isAnyTabOpen
          ? 320
          : (currentRoute.startsWith('/widgets/ssh')
              ? 300
              : (isFocusRunning ? 260 : 200));
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
                print("Current location: $location");
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
                    child: currentRoute.startsWith('/widgets/ssh')
                        ? _buildSSHMetrics(context, colorScheme, scalingFactor)
                        : isFocusRunning
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
                            : GestureDetector(
                                onTap: () {
                                  if (currentRoute.startsWith('/social')) {
                                    HapticFeedback.mediumImpact();
                                    final currentIdx = socialBlock.activeTab.value;
                                    socialBlock.activeTab.value =
                                        (currentIdx + 1) % 3;
                                  }
                                },
                                child: AutoSizeText(
                                  _getTitle(
                                    context,
                                    currentRoute,
                                    socialBlock,
                                    socialIndex ??
                                        (currentRoute.startsWith('/social')
                                            ? socialBlock.activeTab.value
                                            : null),
                                  ),
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
                ),
              )
            else
              const Spacer(),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentRoute != '/widgets/ssh') ...[
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
                ],

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

  Widget _buildSSHMetrics(BuildContext context, ColorScheme colorScheme, double scalingFactor) {
    final sshService = SSHService();
    
    return StreamBuilder<Map<String, dynamic>>(
      stream: sshService.statsStream,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final isConnected = sshService.isConnected;
        final latency = stats['latencyMs'] as double? ?? 0.0;
        final bytesIn = stats['bytesIn'] as int? ?? 0;
        final bytesOut = stats['bytesOut'] as int? ?? 0;
        
        String formatBytes(int bytes) {
          if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
          if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
          return '${bytes}B';
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isConnected ? colorScheme.primary : Colors.grey,
                shape: BoxShape.circle,
                boxShadow: isConnected ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? (sshService.currentHost?.toUpperCase() ?? "SSH") : "OFFLINE",
              style: TextStyle(
                color: isConnected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontSize: 10 * scalingFactor,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
              ),
            ),
            if (isConnected) ...[
              const SizedBox(width: 12),
              _metricItem(Icons.sensors, '${latency.toInt()}ms', colorScheme, scalingFactor),
              const SizedBox(width: 8),
              _metricItem(Icons.download, formatBytes(bytesIn), colorScheme, scalingFactor),
              const SizedBox(width: 8),
              _metricItem(Icons.upload, formatBytes(bytesOut), colorScheme, scalingFactor),
            ],
          ],
        );
      }
    );
  }

  Widget _metricItem(IconData icon, String value, ColorScheme colorScheme, double scalingFactor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10 * scalingFactor, color: colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 9 * scalingFactor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}
