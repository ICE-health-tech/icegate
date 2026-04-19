import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/FoodConsumePage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/FoodDashboardPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/FoodInputPage.dart';
import 'package:ice_gate/ui_layer/home_page/HomePage.dart';
import 'package:ice_gate/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_gate/ui_layer/projects_page/ProjectAnalysisPage.dart';
import 'package:ice_gate/ui_layer/user_page/PersonalInformationPage.dart';
import 'package:ice_gate/ui_layer/health_page/HealthPage.dart';
import 'package:ice_gate/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/ui_layer/social_page/SocialPage.dart';
import 'package:ice_gate/ui_layer/projects_page/projects_page.dart';
import 'package:ice_gate/ui_layer/canvas_page/CanvasDynamicIsland.dart';
import 'package:ice_gate/ui_layer/user_page/AnalysisDashboardPage.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/WeightPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/WeightInputPage.dart';
import 'package:provider/provider.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  /// Laptop / desktop window: smaller FAB and dock to the right (not centered).
  static bool _wideChromeLayout(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return width >= 560;
    }
    return width >= 720;
  }

  Widget _getMainButtonForRoute(
    BuildContext context,
    String route,
    double responsiveSize,
  ) {
    // print("Current route: $route");
    // Determine which page's icon to show based on the route
    Widget pageIcon;
    switch (route) {
      case '/':
        pageIcon = HomePage.icon(context, size: responsiveSize);
        break;
      case '/canvas':
        pageIcon = DragCanvasGrid.icon(context, size: responsiveSize);
        break;
      case '/profile':
        pageIcon = AnalysisDashboardPage.icon(context, size: responsiveSize);
        break;
      case '/health':
        pageIcon = HealthPage.icon(context, size: responsiveSize);
        break;
      case '/health/food/consume':
        pageIcon = FoodConsumePage.icon(context, size: responsiveSize);
        break;
      case '/health/food':
        pageIcon = FoodInputPage.icon(context, size: responsiveSize);
        break;
      case '/health/exercise':
        pageIcon = HealthPage.icon(context, size: responsiveSize);
        break;
      case '/health/steps':
        pageIcon = HealthPage.icon(context, size: responsiveSize);
        break;
      case '/health/heart_rate':
        pageIcon = HealthPage.icon(context, size: responsiveSize);
        break;
      case '/health/sleep':
        pageIcon = HealthPage.icon(context, size: responsiveSize);
        break;
      case '/health/water':
        pageIcon = HealthPage.icon(context, size: responsiveSize);
        break;
      case '/health/weight':
        pageIcon = WeightPage.icon(context, size: responsiveSize);
        break;
      case '/health/weight/log':
        pageIcon = WeightInputPage.icon(context, size: responsiveSize);
        break;
      case '/health/food/dashboard':
        pageIcon = FoodDashboardPage.icon(context, size: responsiveSize);
        break;
      case '/ssh':
        pageIcon = TalkSSHPage.icon(context, size: responsiveSize);
        break;
      case '/finance':
        pageIcon = FinancePage.icon(context, size: responsiveSize);
        break;

      case '/social':
        pageIcon = SocialPage.icon(context, size: responsiveSize);
        break;
      case '/projects':
        pageIcon = ProjectsPage.icon(context, size: responsiveSize);
        break;
      case '/projects/dashboard':
        pageIcon = ProjectAnalysisPage.icon(context, size: responsiveSize);
        break;

      case '/projects/editor':
        pageIcon = SizedBox.shrink();
        break;
      case '/personal-info':
        pageIcon = PersonalInformationPage.icon(context, size: responsiveSize);
        break;
      case '/project_notes':
        pageIcon = ProjectsPage.icon(context, size: responsiveSize);
        break;
      case '/health/focus':
        return const SizedBox.shrink();
      case '/notifications':
        return const SizedBox.shrink();
      default:
        // Default to home icon
        pageIcon = HomePage.returnHomeIcon(context, size: responsiveSize);
    }

    // Wrap with custom size
    return SizedBox(
      width: responsiveSize,
      height: responsiveSize,
      child: pageIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    final bool shouldHideAppBar =
        currentRoute == '/health/focus' ||
        currentRoute == '/notifications' ||
        currentRoute == '/personal-info' ||
        currentRoute == '/profile' ||
        currentRoute == '/settings' ||
        currentRoute == '/manual' ||
        currentRoute == '/projects/editor' ||
        currentRoute.contains('/dashboard') ||
        currentRoute.contains('/analysis') ||
        currentRoute.startsWith('/webview');

    final bool wideLayout = _wideChromeLayout(context);
    final width = MediaQuery.sizeOf(context).width;
    final double responsiveSize = wideLayout
        ? (width * 0.035).clamp(40.0, 50.0)
        : (width * 0.5).clamp(40.0, 68.0);
    final mainButton = _getMainButtonForRoute(
      context,
      currentRoute,
      responsiveSize,
    );

    return Scaffold(
      // --- DYNAMIC BODY (Changes based on route) ---
      // Wide desktop: bottomNavigationBar can get unbounded height — without a
      // tight height, Align(centerRight) vertically centers the FAB mid-window.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: wideLayout ? 16.0 : 20.0,
          top: 5,
          left: wideLayout ? 16.0 : 0,
          right: wideLayout ? 16.0 : 0,
        ),
        child: wideLayout
            ? SizedBox(
                height: responsiveSize,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: mainButton,
                ),
              )
            : SizedBox(
                height: responsiveSize,
                child: Center(child: mainButton),
              ),
      ),

      body: Stack(
        children: [
          child,
          if (!shouldHideAppBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: SizedBox(
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CanvasDynamicIsland(
                        personBlock: context.watch<PersonBlock>(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
