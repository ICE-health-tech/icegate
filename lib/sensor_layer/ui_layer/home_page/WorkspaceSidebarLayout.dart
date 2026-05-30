import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

/// Wireframe layout: narrow “Analysis” rail → icon plugin rail → main content.
/// Shown on wider screens; phones keep full-width scroll only.
class WorkspaceSidebarLayout extends StatelessWidget {
  const WorkspaceSidebarLayout({
    super.key,
    required this.child,
    this.onPluginTap,
  });

  final Widget child;
  final VoidCallback? onPluginTap;

  static bool useWorkspace(double width) => width >= 680;

  /// Home page only: show the side rails on **macOS / Windows / Linux / web** with
  /// a laptop-sized window — not on iPhone/iPad/Android builds.
  static bool useHomeWorkspace(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (kIsWeb) {
      return w >= 720;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return w >= 560;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return w >= 720;
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : cs.outline.withValues(alpha: 0.22);
    final borderSide = BorderSide(color: glassBorderColor);
    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : cs.onSurface.withValues(alpha: 0.65);
    final analysisLabelColor = isDark
        ? EntryLandscapePalette.icyWhiteBlue.withValues(alpha: 0.85)
        : cs.onSurface.withValues(alpha: 0.78);
    final pluginLabelColor = isDark
        ? cs.onSurface.withValues(alpha: 0.55)
        : cs.onSurface.withValues(alpha: 0.78);

    // Get the current path to highlight active state
    String currentPath = '/';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    Widget squareNav({
      required IconData icon,
      required String tooltip,
      required String route,
      required VoidCallback onTap,
      Color? activeColor,
    }) {
      final bool isActive = currentPath.startsWith(route) || (route == '/' && currentPath == '/');
      final activeAcc = activeColor ?? cs.primary;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Tooltip(
          message: tooltip,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : cs.surfaceContainerHighest)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? activeAcc.withValues(alpha: 0.4)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : cs.outline.withValues(alpha: 0.2)),
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeAcc.withValues(alpha: 0.12),
                            blurRadius: 12,
                          )
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        icon,
                        size: 22,
                        color: isActive ? activeAcc : inactiveIconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column 1: vertical “Analysis”
        Container(
          width: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : cs.surfaceContainerHigh,
            border: Border(right: borderSide),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/profile'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      AppLocalizations.of(context)!.analysis.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        color: analysisLabelColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Column 2: five tool squares + vertical “Plugin”
        Container(
          width: 56,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.01)
                : cs.surfaceContainerHigh,
            border: Border(right: borderSide),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      squareNav(
                        icon: Icons.favorite_rounded,
                        tooltip: 'Health',
                        route: '/health',
                        activeColor: const Color(0xFFa7f3d0), // --ice-health
                        onTap: () => context.go('/health'),
                      ),
                      squareNav(
                        icon: Icons.account_balance_wallet_rounded,
                        tooltip: 'Finance',
                        route: '/finance',
                        activeColor: const Color(0xFFbae6fd), // --ice-finance
                        onTap: () => context.go('/finance'),
                      ),
                      squareNav(
                        icon: Icons.psychology_rounded,
                        tooltip: 'Social',
                        route: '/social',
                        activeColor: const Color(0xFFe9d5ff), // --ice-mind
                        onTap: () => context.go('/social'),
                      ),
                      squareNav(
                        icon: Icons.rocket_launch_rounded,
                        tooltip: 'Projects',
                        route: '/projects',
                        activeColor: const Color(0xFFfef08a), // --ice-projects
                        onTap: () => context.go('/projects'),
                      ),
                      squareNav(
                        icon: Icons.grid_view_rounded,
                        tooltip: 'Canvas',
                        route: '/canvas',
                        activeColor: const Color(0xFFbae6fd), // --ice-accent-blue
                        onTap: () => context.go('/canvas'),
                      ),
                      squareNav(
                        icon: Icons.hub_rounded,
                        tooltip: l10n.integration_hub_title,
                        route: '/integrations',
                        activeColor: const Color(0xFF64D2FF),
                        onTap: () => context.push('/integrations'),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onPluginTap,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'PLUGIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: pluginLabelColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
