import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FoodAnalysisBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/SSHConfigForm.dart';
import 'package:ice_gate/orchestration_layer/Services/SSHService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:provider/provider.dart';

class CanvasDynamicIsland extends StatelessWidget {
  final int? socialIndex;
  final int? documentIndex;
  final PersonBlock personBlock;
  const CanvasDynamicIsland({
    super.key,
    this.socialIndex,
    this.documentIndex,
    required this.personBlock,
  });

  String _getTitle(
    BuildContext context,
    String path,
    SocialBlock socialBlock,
    FinanceBlock financeBlock,
    int? socialIndex,
    int? documentIndex,
  ) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return "ICE GATE";

    if (path == '/social/blocker') return "APP BLOCKER";
    if (path == '/intro') return "INITIALIZING...";
    if (path == '/notifications') return "NOTIFICATIONS";
    if (path == '/notification-inbox') return "INBOX";
    if (path == '/documentation') return "DOCUMENTATION";
    
    if (path.startsWith('/canvas')) return "CANVAS";
    if (path.startsWith('/profile')) return "ANALYSIS";
    
    if (path == '/') {
      return "${personBlock.information.value.profiles.firstName} ${personBlock.information.value.profiles.lastName}";
    }

    if (path.startsWith('/social')) {
      if (path.contains('blocker')) return "APP BLOCKER";
      if (path.contains('journal')) return "JOURNAL";
      final index = socialIndex ?? socialBlock.activeTab.value;
      switch (index) {
        case 0: return "JOURNAL";
        case 1: return "ACHIEVEMENTS";
        case 2: return "ANALYSIS";
        default: return "MIND";
      }
    }

    if (path.startsWith('/health')) {
      if (path.contains('integrations')) return "DATA";
      if (path.contains('food')) return "NUTRITION";
      if (path.contains('exercise')) return "ACTIVITY";
      if (path.contains('water')) return "HYDRATION";
      if (path.contains('focus')) return "FOCUS";
      if (path.contains('steps')) return "STEPS";
      if (path.contains('heart_rate') || path.contains('vitals')) return "VITALS";
      if (path.contains('sleep')) return "SLEEP";
      if (path.contains('calories')) return "CALORIES";
      if (path.contains('oxygen_saturation')) return "SPO2";
      if (path.contains('weight')) return "BIOMETRICS";
      return "HEALTH";
    }

    if (path.startsWith('/finance')) {
      final index = financeBlock.activeTab.value;
      switch (index) {
        case 0: return "OVERVIEW";
        case 1: return "HISTORY";
        case 2: return "BILLING";
        case 3: return "SAVING";
        default: return "FINANCE";
      }
    }

    if (path.startsWith('/projects/documents') || path.startsWith('/projects/notes')) {
      return "DOCUMENTS";
    }

    if (path.startsWith('/projects/editor')) return "EDITOR";
    if (path.startsWith('/projects')) return "PROJECTS";
    
    if (path.startsWith('/personal-info')) return "IDENTITY";
    if (path == '/change-password') return "SECURITY";
    if (path == '/change-username') return "ID UPDATE";
    if (path == '/manual') return "PROTOCOLS";
    if (path == '/sync-engine') return "SYNC CORE";
    if (path.startsWith('/settings')) return "SETTINGS";
    if (path.startsWith('/widgets/ssh')) return "REMOTE SSH";
    
    return "ICE GATE";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentRoute = GoRouterState.of(context).uri.path;
    // Hide on canvas sub-pages too
    if (currentRoute.startsWith('/canvas/') && currentRoute != '/canvas') {
      return const SizedBox.shrink();
    }
    if (currentRoute.startsWith('/projects/') &&
        currentRoute != '/projects' &&
        currentRoute != '/projects/documents') {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive Scaling
    final bool isSmallDevice = screenWidth < 375;
    final double scalingFactor = isSmallDevice ? 0.85 : 1.0;

    final focusBlock = context.read<FocusBlock>();
    final docBlock = context.read<DocumentationBlock>();
    final notificationService = context.read<LocalNotificationService>();
    final healthBlock = context.read<HealthBlock>();
    final financeBlock = context.read<FinanceBlock>();
    final socialBlock = context.read<SocialBlock>();
    final foodAnalysisBlock = context.read<FoodAnalysisBlock>();
    final sshService = SSHService();

    return Watch((context) {
      final currentRoute = GoRouterState.of(context).uri.path;
      final isFocusRunning = focusBlock.isRunning.value;
      final isSyncing = docBlock.isSyncing.value;
      final syncStatus = docBlock.syncStatus.value;
      final sessionType = focusBlock.currentSessionType.value;
      final useTmux = sshService.useTmuxSignal.value;
      final isFoodAnalyzing = foodAnalysisBlock.isAnalyzing.value;
      final foodAnalysisStatus = foodAnalysisBlock.analysisStatus.value;

      // Time formatting helper
      String formatTime(int seconds) {
        int m = seconds ~/ 60;
        int s = seconds % 60;
        return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      // Calculate width based on screen size
      // isFoodAnalyzing needs extra width for the status text
      final double targetWidth = currentRoute.startsWith('/widgets/ssh')
                ? 340
                : (currentRoute.startsWith('/finance') || currentRoute.startsWith('/social')
                    ? screenWidth * 0.92
                    : (isFoodAnalyzing
                          ? 300
                          : ((isSyncing || syncStatus != null)
                                ? 320
                                : (isFocusRunning ? 280 : (useTmux ? 260 : 240)))));
                          
      final double width = (targetWidth * scalingFactor).clamp(
        0.0,
        (currentRoute.startsWith('/finance') || currentRoute.startsWith('/social')) ? screenWidth : screenWidth - 40,
      );

      final Color focusColor = sessionType == 'Focus'
          ? Colors.blueAccent
          : Colors.greenAccent;
      final String location = GoRouterState.of(context).uri.toString();
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuart,
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
          horizontal: 8 * scalingFactor,
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
                      : currentRoute.startsWith('/finance')
                      ? _buildFinanceTabs(
                          context,
                          financeBlock,
                          scalingFactor,
                          colorScheme,
                        )
                      : currentRoute.startsWith('/social')
                      ? _buildSocialTabs(
                          context,
                          socialBlock,
                          scalingFactor,
                          colorScheme,
                        )
                      : isFoodAnalyzing
                      ? _buildFoodAnalysisStatus(
                          context,
                          foodAnalysisStatus,
                          scalingFactor,
                          colorScheme,
                        )
                      : isFocusRunning
                      ? _buildFocusTimer(
                          context,
                          focusBlock,
                          focusColor,
                          sessionType,
                          scalingFactor,
                          colorScheme,
                        )
                      : useTmux
                      ? _buildTmuxStatus(context, scalingFactor, colorScheme)
                      : (isSyncing || syncStatus != null)
                      ? _buildSyncStatus(
                          context,
                          syncStatus,
                          isSyncing,
                          scalingFactor,
                          colorScheme,
                        )
                      : _buildDefaultTitle(
                            context,
                            currentRoute,
                            socialBlock,
                            financeBlock,
                            socialIndex,
                            documentIndex,
                            scalingFactor,
                            colorScheme,
                          ),
                ),
              ),

            // Actions (extra leading gap so quest/notification badge never paints over title)
            Padding(
                padding: EdgeInsets.only(left: 10 * scalingFactor),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentRoute != '/widgets/ssh' &&
                        !currentRoute.startsWith('/finance') &&
                        !currentRoute.startsWith('/social')) ...[
                      // AI Meal Analysis shortcut — only on health routes
                      if (currentRoute.startsWith('/health'))
                        _buildAIMealButton(
                          context,
                          foodAnalysisBlock,
                          scalingFactor,
                          colorScheme,
                        ),
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
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
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
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                            size: 20 * scalingFactor,
                          ),
                        ),
                      ),
                      SizedBox(width: 4 * scalingFactor),
                      // Notifications (badge shows active notifications; cap display to avoid overlap)
                      Watch((context) {
                        final totalNotifications =
                            notificationService.numberOfEnabledNotifications.value;

                        return GestureDetector(
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
                        );
                      }),
                      
                      Watch((context) {
                        if (!healthBlock.isSyncing.value) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(left: 4 * scalingFactor),
                          child: _PulseHeartIcon(scalingFactor: scalingFactor, colorScheme: colorScheme),
                        );
                      }),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFocusTimer(
    BuildContext context,
    FocusBlock focusBlock,
    Color focusColor,
    String sessionType,
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
          Watch((context) {
            final remainingSecs = focusBlock.remainingTime.value;
            return Text(
              formatTime(remainingSecs),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14 * scalingFactor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Monospace',
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(
    BuildContext context,
    String? status,
    bool isSyncing,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/projects/notes');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          if (isSyncing)
            _RotatingSyncIcon(
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            )
          else
            Icon(
              Icons.check_circle_rounded,
              size: 16 * scalingFactor,
              color: colorScheme.primary,
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
      ),
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
    FinanceBlock financeBlock,
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
        } else if (currentRoute == '/') {
          HapticFeedback.mediumImpact();
          context.go("/personal-info");
        }
      },
      child: AutoSizeText(
        _getTitle(
          context,
          currentRoute,
          socialBlock,
          financeBlock,
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
          fontSize: 12 * scalingFactor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1 * scalingFactor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        minFontSize: 8,
      ),
    );
  }

  /// Builds the center content when AI food analysis is in progress.
  /// Shows a pulsing food icon + status text (e.g., "Analyzing pizza...")
  Widget _buildFoodAnalysisStatus(
    BuildContext context,
    String status,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to the food dashboard to see the analysis result
        HapticFeedback.mediumImpact();
        context.push('/health/food/dashboard');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          // Pulsing food analysis indicator
          _PulseFoodIcon(
            scalingFactor: scalingFactor,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: AutoSizeText(
              (status.isNotEmpty ? status : "ANALYZING MEAL...").toUpperCase(),
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 9 * scalingFactor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the AI meal scan shortcut button for health routes.
  /// Shows a camera icon that navigates to /health/food for meal input.
  /// When analysis is running, the icon pulses orange.
  Widget _buildAIMealButton(
    BuildContext context,
    FoodAnalysisBlock foodBlock,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return Watch((context) {
      final isAnalyzing = foodBlock.isAnalyzing.value;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          // Navigate to the food input page for AI meal analysis
          context.push('/health/food');
        },
        child: Container(
          padding: EdgeInsets.all(4 * scalingFactor),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            // Show different icon when analyzing vs idle
            isAnalyzing
                ? Icons.restaurant_rounded
                : Icons.photo_camera_rounded,
            color: isAnalyzing
                ? Colors.orangeAccent
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            size: 20 * scalingFactor,
          ),
        ),
      );
    });
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

  Widget _buildFinanceTabs(
    BuildContext context,
    FinanceBlock financeBlock,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return Watch((context) {
      final activeIndex = financeBlock.activeTab.value;
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdaptiveTabIcon(
              context,
              index: 0,
              icon: Icons.dashboard_rounded,
              label: "OVERVIEW",
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            ),
            SizedBox(width: 16 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 1,
              icon: Icons.history_rounded,
              label: "HISTORY",
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            ),
            SizedBox(width: 16 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 2,
              icon: Icons.receipt_long_rounded,
              label: "BILLING",
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            ),
            SizedBox(width: 16 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 3,
              icon: Icons.savings_rounded,
              label: "SAVING",
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSocialTabs(
    BuildContext context,
    SocialBlock socialBlock,
    double scalingFactor,
    ColorScheme colorScheme,
  ) {
    return Watch((context) {
      final activeIndex = socialBlock.activeTab.value;
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdaptiveTabIcon(
              context,
              index: 0,
              icon: Icons.sentiment_satisfied_rounded,
              label: "JOURNAL",
              activeIndex: activeIndex,
              onTap: (idx) => socialBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            ),
            SizedBox(width: 32 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 1,
              icon: Icons.sentiment_satisfied_rounded,
              label: "ACHIEVEMENTS",
              activeIndex: activeIndex,
              onTap: (idx) => socialBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            ),
            SizedBox(width: 32 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 2,
              icon: Icons.bar_chart_rounded,
              label: "ANALYSIS",
              activeIndex: activeIndex,
              onTap: (idx) => socialBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAdaptiveTabIcon(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required int activeIndex,
    required Function(int) onTap,
    required double scalingFactor,
    required ColorScheme colorScheme,
  }) {
    final bool isActive = index == activeIndex;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: (isActive ? 16 : 12) * scalingFactor,
          vertical: 6 * scalingFactor,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20 * scalingFactor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18 * scalingFactor,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            if (isActive) ...[
              SizedBox(width: 8 * scalingFactor),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 10 * scalingFactor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
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

class _PulseHeartIcon extends StatefulWidget {
  final double scalingFactor;
  final ColorScheme colorScheme;

  const _PulseHeartIcon({
    required this.scalingFactor,
    required this.colorScheme,
  });

  @override
  State<_PulseHeartIcon> createState() => _PulseHeartIconState();
}

class _PulseHeartIconState extends State<_PulseHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.favorite_rounded,
        size: 16 * widget.scalingFactor,
        color: Colors.redAccent,
      ),
    );
  }
}

/// Pulsing food icon — shown in the Dynamic Island center when AI meal analysis is running.
/// Uses the same scale-pulse animation as _PulseHeartIcon but with a restaurant icon + orange color.
class _PulseFoodIcon extends StatefulWidget {
  final double scalingFactor;
  final ColorScheme colorScheme;

  const _PulseFoodIcon({
    required this.scalingFactor,
    required this.colorScheme,
  });

  @override
  State<_PulseFoodIcon> createState() => _PulseFoodIconState();
}

class _PulseFoodIconState extends State<_PulseFoodIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Slightly faster pulse than heart — conveys "processing" urgency
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.restaurant_rounded,
        size: 14 * widget.scalingFactor,
        color: Colors.orangeAccent,
      ),
    );
  }
}
