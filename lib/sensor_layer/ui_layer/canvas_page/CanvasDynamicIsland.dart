import 'dart:ui';

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
import 'package:ice_gate/utils/app_log.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MorningBriefingSheet.dart';
import 'package:ice_gate/orchestration_layer/Services/CursorApiService.dart';

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

    if (path == '/social/blocker') return l10n.island_app_blocker;
    if (path == '/intro') return l10n.island_initializing;
    if (path == '/notifications') return l10n.island_notifications;
    if (path == '/notification-inbox') return l10n.island_inbox;
    if (path == '/documentation') return l10n.island_documentation;

    if (path.startsWith('/canvas')) return l10n.island_canvas;
    if (path.startsWith('/profile')) return l10n.analysis.toUpperCase();
    
    if (path == '/') {
      return "${personBlock.information.value.profiles.firstName} ${personBlock.information.value.profiles.lastName}";
    }

    if (path.startsWith('/social')) {
      if (path.contains('blocker')) return l10n.island_app_blocker;
      if (path.contains('journal')) return l10n.journal.toUpperCase();
      final focus = socialBlock.activeFocusTrend.value;
      if (focus != null) return focus.name.toUpperCase();
      final index = socialIndex ?? socialBlock.activeTab.value;
      switch (index) {
        case 0:
          return l10n.journal.toUpperCase();
        case 1:
          return l10n.mind_focus_title.toUpperCase();
        case 2:
          return l10n.achievements;
        case 3:
          return l10n.analysis.toUpperCase();
        default:
          return l10n.island_mind;
      }
    }

    if (path == '/health') {
      final burned = context.read<HealthBlock>().todayCaloriesBurned.value;
      return '$burned ${l10n.health_kcal}';
    }

    if (path.startsWith('/health')) {
      if (path.contains('integrations')) return l10n.island_health_data;
      if (path.contains('food')) return l10n.island_nutrition;
      if (path.contains('exercise')) return l10n.island_activity;
      if (path.contains('water')) return l10n.island_hydration;
      if (path.contains('focus')) return l10n.island_focus;
      if (path.contains('steps')) return l10n.island_steps;
      if (path.contains('heart_rate') || path.contains('vitals')) {
        return l10n.island_vitals;
      }
      if (path.contains('sleep')) return l10n.island_sleep;
      if (path.contains('calories')) return l10n.island_calories;
      if (path.contains('oxygen_saturation')) return l10n.island_spo2;
      if (path.contains('weight')) return l10n.island_biometrics;
      return l10n.health.toUpperCase();
    }

    if (path.startsWith('/finance')) {
      if (path.contains('/reports/daily')) return l10n.reports_hub_title;
      final index = financeBlock.activeTab.value;
      switch (index) {
        case 0:
          return l10n.finance_tab_overview;
        case 1:
          return l10n.finance_tab_daily;
        case 2:
          return l10n.finance_tab_billing;
        case 3:
          return l10n.finance_tab_saving;
        case 4:
          return l10n.finance_tab_achievements;
        default:
          return l10n.finance.toUpperCase();
      }
    }

    if (path.startsWith('/projects/documents') ||
        path.startsWith('/projects/notes')) {
      return l10n.island_documents;
    }

    if (path.startsWith('/projects/editor')) return l10n.island_editor;
    if (path.startsWith('/projects')) return l10n.projects.toUpperCase();

    if (path.startsWith('/personal-info')) return l10n.island_identity;
    if (path == '/change-password') return l10n.security_title.toUpperCase();
    if (path == '/change-username') return l10n.island_id_update;
    if (path == '/manual') return l10n.island_protocols;
    if (path == '/sync-engine') return l10n.island_sync_core;
    if (path.startsWith('/settings')) return l10n.island_settings;
    if (path.startsWith('/widgets/ssh')) return l10n.island_remote_ssh;

    return l10n.island_app_name;
  }

  /// Sub-route title for the gap between back and finance tabs (null on `/finance`).
  String? _financeSubRouteTitle(BuildContext context, String path) {
    if (path == '/finance') return null;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return null;
    if (path.contains('/reports/daily')) return l10n.reports_hub_title;
    return null;
  }

  Color? _pillarAccentForRoute(String path, {Color? socialAccent}) {
    if (path == '/canvas') return HealthMetricColors.pillarBlue;
    if (path.startsWith('/finance')) return EntryColors.financeSilverAccent;
    if (path.startsWith('/social')) return socialAccent ?? EntryColors.socialPurple;
    if (path.startsWith('/health')) return EntryColors.healthGreen;
    if (path.startsWith('/projects')) return EntryColors.projectBlue;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      final socialMindFocus = socialBlock.activeFocusTrend.value;

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
      final pillarAccent = _pillarAccentForRoute(
        currentRoute,
        socialAccent: socialMindFocus?.color,
      );
      final financeSubTitle = currentRoute.startsWith('/finance')
          ? _financeSubRouteTitle(context, currentRoute)
          : null;
      final onFinance = currentRoute.startsWith('/finance');
      final borderColor = isFocusRunning
          ? focusColor.withValues(alpha: 0.5)
          : (onFinance
                ? EntryColors.financeSilverAccent.withValues(
                    alpha: isDark ? 0.42 : 0.34,
                  )
                : (currentRoute.startsWith('/social') && socialMindFocus != null
                      ? socialMindFocus.color.withValues(
                          alpha: isDark ? 0.55 : 0.42,
                        )
                      : (useTmux
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.55,
                                  )))));
      final islandHeight = 46 * scalingFactor;
      final islandRadius = islandHeight / 2;
      final outerBorderColor =
          borderColor.withValues(alpha: isDark ? 0.9 : 0.6);
      final outerBorderWidth = 1.0 * scalingFactor;
      final islandFill = isDark
          ? const Color(0xFF141A22)
          : colorScheme.surfaceContainerHigh.withValues(alpha: 0.98);
      final islandGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.09),
                  islandFill,
                ),
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.03),
                  islandFill,
                ),
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.05),
                  islandFill,
                ),
              ]
            : [
                Color.alphaBlend(
                  colorScheme.onSurface.withValues(alpha: 0.05),
                  islandFill,
                ),
                Color.alphaBlend(
                  colorScheme.onSurface.withValues(alpha: 0.02),
                  islandFill,
                ),
                Color.alphaBlend(
                  colorScheme.onSurface.withValues(alpha: 0.04),
                  islandFill,
                ),
              ],
        stops: const [0.0, 0.55, 1.0],
      );

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuart,
        width: width,
        height: islandHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(islandRadius),
          gradient: islandGradient,
          border: Border.all(
            color: outerBorderColor,
            width: outerBorderWidth,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8 * scalingFactor),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 12 * scalingFactor,
              right: 12 * scalingFactor,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isDark ? Colors.white : colorScheme.onSurface)
                          .withValues(alpha: isDark ? 0.18 : 0.08),
                      (isDark ? Colors.white : colorScheme.onSurface)
                          .withValues(alpha: isDark ? 0.04 : 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                    _PressableIslandIconButton(
                      scalingFactor: scalingFactor,
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        appLog("Current location: $location");
                        if (location.startsWith('/projects/editor')) {
                          context.go("/projects");
                        }

                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/');
                        }
                      },
                    ),

                    Expanded(
                      child: currentRoute.startsWith('/widgets/ssh')
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: sshService.isConfigMode.value
                                  ? _buildSSHConfig(
                                      context,
                                      colorScheme,
                                      scalingFactor,
                                    )
                                  : _buildSSHMetrics(
                                      context,
                                      colorScheme,
                                      scalingFactor,
                                    ),
                            )
                          : currentRoute.startsWith('/finance')
                          ? Row(
                              children: [
                                if (financeSubTitle != null) ...[
                                  _buildRouteTitleChip(
                                    financeSubTitle,
                                    pillarAccent ?? colorScheme.primary,
                                    scalingFactor,
                                  ),
                                  SizedBox(width: 8 * scalingFactor),
                                ],
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildFinanceTabs(
                                      context,
                                      financeBlock,
                                      scalingFactor,
                                      colorScheme,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: currentRoute.startsWith('/social')
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
                                  ? _buildTmuxStatus(
                                      context,
                                      scalingFactor,
                                      colorScheme,
                                    )
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
                      // Home: morning loop · elsewhere: focus timer (hidden on canvas hub)
                      if (currentRoute != '/canvas') ...[
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (currentRoute == '/') {
                              MorningBriefingSheet.showSummary(context);
                            } else {
                              context.push('/health/focus');
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(4 * scalingFactor),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              currentRoute == '/'
                                  ? Icons.wb_sunny_outlined
                                  : Icons.timer_outlined,
                              color: currentRoute == '/'
                                  ? HealthMetricColors.pillarYellow.withValues(
                                      alpha: 0.95,
                                    )
                                  : colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                              size: 20 * scalingFactor,
                            ),
                          ),
                        ),
                      ],

                      // SizedBox(width: 4 * scalingFactor),
                      // Settings shortcut
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (currentRoute == '/projects') {
                            context.push('/projects/dashboard');
                          } else {
                            context.push('/settings');
                          }
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
              ],
            ),
      );
    });
  }

  Widget _buildRouteTitleChip(
    String title,
    Color accent,
    double scalingFactor,
  ) {
    return Flexible(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scalingFactor,
              vertical: 4 * scalingFactor,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xF2FFFFFF),
                fontSize: 10 * scalingFactor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
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
            AppLocalizations.of(context)!.island_tmux_active,
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
          socialBlock.activeTab.value = (currentIdx + 1) % 4;
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
      final cursorApi = CursorApiService.instance;
      final cursorHasKey = cursorApi.hasKeySignal.value;
      final l10n = AppLocalizations.of(context)!;

      String offlineStatusLabel() {
        if (aiMode != 'cursor') return l10n.island_not_active;
        if (!cursorHasKey) return l10n.island_cursor_no_api_key;
        return l10n.island_cursor_ssh_standby;
      }

      Color statusDotColor(bool connected) {
        if (connected) return Colors.greenAccent;
        if (aiMode == 'cursor' && cursorHasKey) {
          return Colors.amberAccent;
        }
        return Colors.redAccent;
      }

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
              case 'cursor':
                return Icons.smart_toy_outlined;
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
              case 'cursor':
                return Colors.tealAccent;
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
                  color: statusDotColor(isConnected),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusDotColor(isConnected).withValues(alpha: 0.5),
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
                      ? (sshService.currentHost ?? l10n.island_connected)
                      : offlineStatusLabel(),
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
                      AppLocalizations.of(context)!.island_connect,
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
    const financeAccent = EntryColors.financeSilverAccent;
    return Watch((context) {
      final l10n = AppLocalizations.of(context)!;
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
              label: l10n.finance_tab_overview,
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: financeAccent,
            ),
            SizedBox(width: 16 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 1,
              icon: Icons.today_rounded,
              label: l10n.finance_tab_daily,
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: financeAccent,
            ),
            SizedBox(width: 12 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 2,
              icon: Icons.receipt_long_rounded,
              label: l10n.finance_tab_billing,
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: financeAccent,
            ),
            SizedBox(width: 12 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 3,
              icon: Icons.savings_rounded,
              label: l10n.finance_tab_saving,
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: financeAccent,
            ),
            SizedBox(width: 12 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 4,
              icon: Icons.emoji_events_rounded,
              label: l10n.finance_tab_achievements,
              activeIndex: activeIndex,
              onTap: (idx) => financeBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: financeAccent,
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
      final l10n = AppLocalizations.of(context)!;
      final activeIndex = socialBlock.activeTab.value;
      final focus = socialBlock.activeFocusTrend.value;
      final accent = focus?.color ?? colorScheme.primary;
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdaptiveTabIcon(
              context,
              index: 0,
              icon: Icons.sentiment_satisfied_rounded,
              label: l10n.journal.toUpperCase(),
              activeIndex: activeIndex,
              onTap: (idx) => socialBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: accent,
            ),
            SizedBox(width: 32 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 1,
              icon: Icons.center_focus_strong_rounded,
              label: l10n.mind_focus_title.toUpperCase(),
              activeIndex: activeIndex,
              onTap: (idx) => socialBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: accent,
            ),
            SizedBox(width: 32 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 2,
              icon: Icons.emoji_events_outlined,
              label: l10n.achievements,
              activeIndex: activeIndex,
              onTap: (idx) => socialBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: accent,
            ),
            SizedBox(width: 32 * scalingFactor),
            _buildAdaptiveTabIcon(
              context,
              index: 3,
              icon: Icons.bar_chart_rounded,
              label: l10n.analysis.toUpperCase(),
              activeIndex: activeIndex,
              onTap: (idx) => socialBlock.activeTab.value = idx,
              scalingFactor: scalingFactor,
              colorScheme: colorScheme,
              accentColor: accent,
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
    Color? accentColor,
  }) {
    final bool isActive = index == activeIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? colorScheme.primary;
    // Light theme: dark ink on pale island. Dark theme: pillar accent / silver.
    final activeInk = isDark ? accent : colorScheme.onSurface;
    final inactiveInk = colorScheme.onSurfaceVariant.withValues(
      alpha: isDark ? 0.55 : 0.72,
    );
    final activeFill = isDark
        ? accent.withValues(alpha: 0.15)
        : colorScheme.primary.withValues(alpha: 0.1);
    final activeBorder = isDark
        ? accent.withValues(alpha: 0.35)
        : colorScheme.primary.withValues(alpha: 0.32);
    final idleFill = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final idleBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : colorScheme.outlineVariant.withValues(alpha: 0.35);

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
          color: isActive ? activeFill : idleFill,
          borderRadius: BorderRadius.circular(20 * scalingFactor),
          border: Border.all(
            color: isActive ? activeBorder : idleBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18 * scalingFactor,
              color: isActive ? activeInk : inactiveInk,
            ),
            if (isActive) ...[
              SizedBox(width: 8 * scalingFactor),
              Text(
                label,
                style: TextStyle(
                  color: activeInk,
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

class _PressableIslandIconButton extends StatefulWidget {
  const _PressableIslandIconButton({
    required this.scalingFactor,
    required this.icon,
    required this.onPressed,
  });

  final double scalingFactor;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_PressableIslandIconButton> createState() =>
      _PressableIslandIconButtonState();
}

class _PressableIslandIconButtonState extends State<_PressableIslandIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final s = widget.scalingFactor;

    final baseFill = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : cs.surfaceContainerHighest.withValues(alpha: 0.35);
    final pressedFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final border = isDark
        ? Colors.white.withValues(alpha: _pressed ? 0.22 : 0.14)
        : cs.outlineVariant.withValues(alpha: _pressed ? 0.9 : 0.7);
    final iconColor = isDark
        ? const Color(0xF2FFFFFF)
        : cs.onSurface.withValues(alpha: 0.85);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          splashColor: (isDark ? Colors.white : cs.primary).withValues(alpha: 0.14),
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: _pressed ? pressedFill : baseFill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 1.2 * s),
            ),
            child: Padding(
              padding: EdgeInsets.all(6 * s),
              child: Icon(
                widget.icon,
                color: iconColor,
                size: 18 * s,
              ),
            ),
          ),
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
