import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ice_shield/ui_layer/health_page/subpage/FoodDashboardPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/FoodInputPage.dart';
import 'package:ice_shield/ui_layer/home_page/HomePage.dart';
import 'package:ice_shield/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_shield/ui_layer/projects_page/ProjectAnalysisPage.dart';
import 'package:ice_shield/ui_layer/user_page/PersonalInformationPage.dart';
// import 'package:ice_shield/ui_layer/user_page/AnalysisDashboardPage.dart';
import 'package:ice_shield/ui_layer/health_page/HealthPage.dart';
import 'package:ice_shield/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_shield/ui_layer/social_page/SocialPage.dart';
import 'package:ice_shield/ui_layer/projects_page/ProjectsPage.dart';

import 'package:ice_shield/ui_layer/canvas_page/CanvasDynamicIsland.dart';
import 'package:ice_shield/ui_layer/user_page/AnalysisDashboardPage.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});
  Widget _getMainButtonForRoute(BuildContext context, String route) {
    final width = MediaQuery.of(context).size.width;
    // final height = MediaQuery.of(context).size.height;
    // final cross = sqrt(width * width + height * height);

    final double responsiveSize = (width * 0.19).clamp(56.0, 90.0);

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
      case '/health/food/dashboard':
        pageIcon = FoodDashboardPage.icon(context, size: responsiveSize);
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
      case '/project-analysis':
        pageIcon = ProjectAnalysisPage.icon(context, size: responsiveSize);
        break;

      case '/projects/editor':
        return const SizedBox.shrink();
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
        currentRoute.startsWith('/widgets/webview');

    return Scaffold(
      // --- DYNAMIC BODY (Changes based on route) ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, top: 5),
        child: _getMainButtonForRoute(context, currentRoute),
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
                  height: 80, // Match AppBar toolbarHeight after user change
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const CanvasDynamicIsland(),
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
