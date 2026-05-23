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
    final border = cs.outline.withValues(alpha: 0.22);

    Widget squareNav({
      required IconData icon,
      required String tooltip,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 22, color: cs.primary),
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
        Material(
          color: EntryLandscapePalette.midnightNavy.withValues(alpha: 0.35),
          child: InkWell(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 40,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: border)),
              ),
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
                      color: EntryLandscapePalette.icyWhiteBlue.withValues(
                        alpha: 0.85,
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
            color: cs.surface.withValues(alpha: 0.45),
            border: Border(right: BorderSide(color: border)),
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
                        onTap: () => context.go('/health'),
                      ),
                      squareNav(
                        icon: Icons.account_balance_wallet_rounded,
                        tooltip: 'Finance',
                        onTap: () => context.go('/finance'),
                      ),
                      squareNav(
                        icon: Icons.psychology_rounded,
                        tooltip: 'Social',
                        onTap: () => context.go('/social'),
                      ),
                      squareNav(
                        icon: Icons.rocket_launch_rounded,
                        tooltip: 'Projects',
                        onTap: () => context.go('/projects'),
                      ),
                      squareNav(
                        icon: Icons.grid_view_rounded,
                        tooltip: 'Canvas',
                        onTap: () => context.go('/canvas'),
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
                        color: cs.onSurface.withValues(alpha: 0.55),
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
