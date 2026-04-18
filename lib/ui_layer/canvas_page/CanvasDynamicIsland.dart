import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

import 'package:ice_gate/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_gate/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:ice_gate/ui_layer/canvas_page/SSHConfigForm.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SSHService.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart';
import 'package:ice_gate/initial_layer/Notification/NotificationInit.dart';
import 'package:provider/provider.dart';

class CanvasDynamicIsland extends StatelessWidget {
  final int? socialIndex;
  final int? documentIndex;
  const CanvasDynamicIsland({super.key, this.socialIndex, this.documentIndex});

  String _getTitle(
    BuildContext context,
    String path,
    SocialBlock socialBlock,
    int? socialIndex,
    int? documentIndex,
  ) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return "ICE GATE";

    if (path == '/social/blocker') return "APP BLOCKER";
    if (path == '/') return "ICE GATE";
    if (path.startsWith('/canvas')) return "CANVAS";
    if (path.startsWith('/profile')) return "ANALYSIS";

    if (path.startsWith('/social')) {
      final index = socialIndex ?? socialBlock.activeTab.value;
      switch (index) {
        case 0:
          return "JOURNAL";
        case 1:
          return l10n.relationships.toUpperCase();
        case 2:
          return l10n.achievements.toUpperCase();
        case 3:
          return "ANALYSIS";
        default:
          return "MIND";
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
    if (path.startsWith('/projects/documents')) {
      final docBlock = context.read<DocumentationBlock>();
      final index = documentIndex ?? docBlock.activeDocumentTab.value;
      switch (index) {
        case 0:
          return "EXPLORER";
        case 1:
          return "EDITOR";
        case 2:
          return "SETTINGS";
        default:
          return "DOCUMENTS";
      }
    }
    if (path.startsWith('/projects')) return "PROJECTS";
    if (path.startsWith('/project_notes')) return "NOTES";
    if (path.startsWith('/settings')) return "SETTINGS";
    if (path.startsWith('/widgets/ssh')) return "REMOTE SSH";
    return "ICE GATE";
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
    if (currentRoute.startsWith('/projects/') &&
        currentRoute != '/projects' &&
        currentRoute != '/projects/documents') {
      return const SizedBox.shrink();
    }
    final isCanvas = currentRoute == '/canvas';
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive Scaling
    final bool isSmallDevice = screenWidth < 375;
    final double scalingFactor = isSmallDevice ? 0.85 : 1.0;

    final focusBlock = context.watch<FocusBlock>();
    final questBlock = context.watch<QuestBlock>();
    final docBlock = context.watch<DocumentationBlock>();
    final notificationService = context.watch<LocalNotificationService>();
    final sshService = SSHService();

    return Watch((context) {
      final currentRoute = GoRouterState.of(context).uri.path;
      final activeTab = DragCanvasGrid.activeCanvasTab.value;
      final isAnyTabOpen = isCanvas && activeTab != 'none';
      final numberOfQuests = questBlock.numberOfQuests.value;
      final numberOfEnabledNotifications =
          notificationService.numberOfEnabledNotifications.value;
      final totalNotifications = numberOfQuests + numberOfEnabledNotifications;
      final isFocusRunning = focusBlock.isRunning.value;
      final isSyncing = docBlock.isSyncing.value;
      final syncStatus = docBlock.syncStatus.value;
      final remainingSecs = focusBlock.remainingTime.value;
      final sessionType = focusBlock.currentSessionType.value;
      final useTmux = sshService.useTmuxSignal.value;

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
                ? 340
                : (isSyncing
                      ? 320
                      : (isFocusRunning ? 280 : (useTmux ? 260 : 240))));
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
                ? focusColor.withValues(alpha: 0.5)
                : (useTmux
                      ? Colors.greenAccent.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant.withValues(alpha: 0.5)),
            width: (isFocusRunning || useTmux) ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isFocusRunning
                          ? focusColor
                          : (useTmux ? Colors.greenAccent : colorScheme.shadow))
                      .withValues(alpha: 0.3),
              blurRadius: (isFocusRunning || useTmux) ? 20 : 16,
              offset: Offset(0, 6 * scalingFactor),
              spreadRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (isAnyTabOpen ? 12 : 8) * scalingFactor,
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
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
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
                child: Center(
                  child: currentRoute.startsWith('/widgets/ssh')
                      ? (sshService.isConfigMode.value
                            ? _buildSSHConfig(
                                context,
                                colorScheme,
                                scalingFactor,
                              )
                            : _buildSSHMetrics(
                                context,
                                colorScheme,
                                scalingFactor,
                              ))
                      : isFocusRunning
                      ? _buildFocusTimer(
                          context,
                          focusColor,
                          sessionType,
                          remainingSecs,
                          scalingFactor,
                          colorScheme,
                        )
                      : useTmux
                      ? _buildTmuxStatus(context, scalingFactor, colorScheme)
                      : isSyncing
                      ? _buildSyncStatus(
                          context,
                          syncStatus,
                          scalingFactor,
                          colorScheme,
                        )
                      : Watch((context) {
                          final socialBlock = context.read<SocialBlock>();
                          return _buildDefaultTitle(
                            context,
                            currentRoute,
                            socialBlock,
                            socialIndex,
                            documentIndex,
                            scalingFactor,
                            colorScheme,
                          );
                        }),
                ),
              )
            else
              const Spacer(),

            // Actions (extra leading gap so quest/notification badge never paints over title)
            if (!isAnyTabOpen)
              Padding(
                padding: EdgeInsets.only(left: 10 * scalingFactor),
                child: Row(
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
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 
                              0.8,
                            ),
                            size: 20 * scalingFactor,
                          ),
                        ),
                      ),

                      // SizedBox(width: 4 * scalingFactor),
                      // Settings shortcut
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('/settings');
                        },
                        child: Container(
                          padding: EdgeInsets.all(4 * scalingFactor),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 
                              0.8,
                            ),
                            size: 20 * scalingFactor,
                          ),
                        ),
                      ),
                      SizedBox(width: 4 * scalingFactor),
                      // Notifications (badge shows active quest count; cap display to avoid overlap)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push('/notifications');
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topRight,
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
                                size: 20 * scalingFactor,
                              ),
                            ),
                            if (totalNotifications > 0)
                              Positioned(
                                right: 0,
                                top: -2,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5 * scalingFactor,
                                    vertical: 2 * scalingFactor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.error,
                                    borderRadius: BorderRadius.circular(
                                      10 * scalingFactor,
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16 * scalingFactor,
                                    minHeight: 16 * scalingFactor,
                                    maxWidth: 34 * scalingFactor,
                                  ),
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      totalNotifications > 99
                                          ? '99+'
                                          : '$totalNotifications',
                                      style: TextStyle(
                                        color: colorScheme.onError,
                                        fontSize: 9 * scalingFactor,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        color: colorScheme.onSurface.withValues(alpha: 0.05),
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
                          size: 28 * scalingFactor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFocusTimer(
    BuildContext context,
    Color focusColor,
    String sessionType,
    int remainingSecs,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    String formatTime(int seconds) {
      int m = seconds ~/ 60;
      int s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/health/focus');
      },
      child: Row(
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
                  color: focusColor.withValues(alpha: 0.5),
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
      ),
    );
  }

  Widget _buildSyncStatus(
    BuildContext context,
    String? status,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        _RotatingSyncIcon(
          scalingFactor: scalingFactor,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: AutoSizeText(
            (status ?? "SYNCING...").toUpperCase(),
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 9 * scalingFactor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTmuxStatus(
    BuildContext context,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/widgets/ssh');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.layers_rounded,
            size: 14 * scalingFactor,
            color: Colors.greenAccent,
          ),
          const SizedBox(width: 8),
          Text(
            "TMUX ACTIVE",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10 * scalingFactor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTitle(
    BuildContext context,
    String currentRoute,
    SocialBlock socialBlock,
    int? socialIndex,
    int? documentIndex,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        if (currentRoute.startsWith('/social')) {
          HapticFeedback.mediumImpact();
          final currentIdx = socialBlock.activeTab.value;
          socialBlock.activeTab.value = (currentIdx + 1) % 3;
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
          documentIndex ??
              (currentRoute.startsWith('/projects/documents')
                  ? context.read<DocumentationBlock>().activeDocumentTab.value
                  : null),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 11 * scalingFactor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2 * scalingFactor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        minFontSize: 8,
      ),
    );
  }

  Widget _buildSSHMetrics(
    BuildContext context,
    ColorScheme colorScheme,
    double scalingFactor,
  ) {
    final sshService = SSHService();

    return Watch((context) {
      final aiMode = sshService.aiMode.value;
      final useTmux = sshService.useTmuxSignal.value;

      return StreamBuilder<Map<String, dynamic>>(
        stream: sshService.statsStream,
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {};
          final isConnected = sshService.isConnected;
          final latency = stats['latencyMs'] as double? ?? 0.0;
          final bytesIn = stats['bytesIn'] as int? ?? 0;

          String formatBytes(int bytes) {
            if (bytes >= 1024 * 1024) {
              return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
            }
            if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
            return '${bytes}B';
          }

          IconData getAiIcon() {
            switch (aiMode) {
              case 'gemini':
                return Icons.auto_awesome;
              case 'opencode':
                return Icons.code_rounded;
              case 'openclaw':
                return Icons.hub_rounded;
              default:
                return Icons.terminal_rounded;
            }
          }

          Color getAiColor() {
            switch (aiMode) {
              case 'gemini':
                return Colors.orangeAccent;
              case 'opencode':
                return Colors.blueAccent;
              case 'openclaw':
                return Colors.purpleAccent;
              default:
                return colorScheme.primary;
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Connection Status Dot
              Container(
                width: 6 * scalingFactor,
                height: 6 * scalingFactor,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isConnected ? Colors.greenAccent : Colors.redAccent)
                              .withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // AI Mode Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: getAiColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: getAiColor().withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  aiMode.toUpperCase(),
                  style: TextStyle(
                    color: getAiColor(),
                    fontSize: 7 * scalingFactor,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // IP Address or Status
              Flexible(
                child: Text(
                  isConnected
                      ? (sshService.currentHost ?? "CONNECTED")
                      : "NOT ACTIVE",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isConnected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontSize: 9 * scalingFactor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ),

              if (isConnected) ...[
                const SizedBox(width: 8),
                _metricItem(
                  Icons.download,
                  formatBytes(bytesIn),
                  colorScheme,
                  scalingFactor,
                ),
              ] else ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    TalkSSHPage.activeState?.showConnectDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "CONNECT",
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 8 * scalingFactor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 8),
              // Config Toggle
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  sshService.isConfigMode.value =
                      !sshService.isConfigMode.value;
                },
                child: Icon(
                  Icons.settings_outlined,
                  size: 14 * scalingFactor,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildSSHConfig(
    BuildContext context,
    ColorScheme colorScheme,
    double scalingFactor,
  ) {
    return SSHConfigForm(
      scalingFactor: scalingFactor,
      colorScheme: colorScheme,
    );
  }

  Widget _metricItem(
    IconData icon,
    String value,
    ColorScheme colorScheme,
    double scalingFactor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 10 * scalingFactor,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
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

class _RotatingSyncIcon extends StatefulWidget {
  final double scalingFactor;
  final ColorScheme colorScheme;

  const _RotatingSyncIcon({
    required this.scalingFactor,
    required this.colorScheme,
  });

  @override
  State<_RotatingSyncIcon> createState() => _RotatingSyncIconState();
}

class _RotatingSyncIconState extends State<_RotatingSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.sync_rounded,
        size: 16 * widget.scalingFactor,
        color: widget.colorScheme.primary,
      ),
    );
  }
}
