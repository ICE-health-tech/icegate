import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/ui_layer/notification_page/NotificationManagerPage.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:ice_shield/ui_layer/ReusableWidget/SettingWidget.dart';
import 'package:ice_shield/ui_layer/health_page/CaloriesPage.dart';
import 'package:ice_shield/ui_layer/health_page/ExercisePage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/FoodDashboardPage.dart';
import 'package:ice_shield/ui_layer/health_page/HabitDashboardPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/StepsPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/StepsDashboardPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/ExerciseAnalysisPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/HealthAnalysisPage.dart';
import 'package:ice_shield/ui_layer/projects_page/ProjectNotesPage.dart';
import 'package:ice_shield/ui_layer/projects_page/ProjectDetailsPage.dart';
import 'package:ice_shield/ui_layer/projects_page/ProjectAnalysisPage.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:provider/provider.dart';
import 'package:ice_shield/ui_layer/widget_page/WidgetPage.dart';
// import 'package:ice_shield/ui_layer/health_page/subpage/StepsPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/HeartRatePage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/SleepPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/FoodInputPage.dart';
import 'package:ice_shield/ui_layer/health_page/subpage/WaterPage.dart';
import 'package:ice_shield/ui_layer/projects_page/TextEditorPage.dart';
import 'package:ice_shield/ui_layer/projects_page/FocusPage.dart';
import 'package:ice_shield/ui_layer/widget_page/PluginList/IOTTracker/GPSTrackingPage.dart';
import 'package:ice_shield/orchestration_layer/Action/WebView/WebViewPage.dart';
import 'package:ice_shield/ui_layer/info_page/ScoringRulesPage.dart';
import 'package:ice_shield/ui_layer/animation_page/snowflake_assemble_screen.dart';
import 'package:ice_shield/initial_layer/CoreLogics/session_tracker.dart';
// // Import your pages
// import 'package:ice_shield/ui_layer/BigWidget/DragCanvasGrid.dart'; // Your Grid
// import 'package:ice_shield/ui_layer/HomePage.dart'; // Your Home
// Import the shell we created in Step 1
import 'package:ice_shield/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_shield/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:ice_shield/ui_layer/home_page/MainShell.dart';
import 'package:ice_shield/ui_layer/home_page/HomePage.dart';
import 'package:ice_shield/ui_layer/user_page/AnalysisDashboardPage.dart';
import 'package:ice_shield/ui_layer/health_page/HealthPage.dart';
import 'package:ice_shield/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_shield/ui_layer/social_page/SocialPage.dart';
import 'package:ice_shield/ui_layer/projects_page/ProjectsPage.dart';
import 'package:ice_shield/ui_layer/user_page/PersonalInformationPage.dart';
import 'package:ice_shield/ui_layer/user_page/LoginPage.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_shield/ui_layer/user_page/ChangePasswordPage.dart';
// import 'MainShell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final ValueNotifier<AuthStatus?> authStatusNotifier = ValueNotifier(
  AuthStatus.checkingSession,
);

final ValueNotifier<bool?> showIntroNotifier = ValueNotifier(null);

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: Listenable.merge([authStatusNotifier, showIntroNotifier]),
  redirect: (context, state) {
    final status = authStatusNotifier.value;
    final isLoggingIn = state.uri.path == '/login';

    debugPrint("🛣️ [GoRouter] Path: ${state.uri.path}, Status: $status");

    // Check intro logic first on startup
    if (showIntroNotifier.value == null) {
      SessionTracker.shouldShowIntro().then((shouldShow) {
        showIntroNotifier.value = shouldShow;
      });
      return null;
    }

    if (showIntroNotifier.value == true && state.uri.path != '/intro') {
      showIntroNotifier.value = false; // Reset so they don't get stuck
      return '/intro';
    }

    if (status == null ||
        status == AuthStatus.checkingSession ||
        status == AuthStatus.init) {
      return null;
    }

    if (status == AuthStatus.authenticated) {
      if (isLoggingIn) {
        debugPrint(
          "🛣️ [GoRouter] Authenticated, redirecting from /login to /",
        );
        return '/';
      }
    } else {
      if (!isLoggingIn) {
        debugPrint("🛣️ [GoRouter] Unauthenticated, redirecting to /login");
        return '/login';
      }
    }

    return null;
  },
  routes: [
    // --- NON-SHELL ROUTES ---
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/intro',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SnowflakeAssembleScreen(),
    ),

    // --- SHELL ROUTE (Wraps pages with the App Bar) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // 'child' is the widget returned by the specific GoRoute below
        return MainShell(child: child);
      },
      routes: [
        // Route 1: Home
        GoRoute(
          path: '/',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const HomePage(title: 'DuyLong'),
        ),
        // Route 2: The Grid Canvas
        GoRoute(
          path: '/canvas',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => DragCanvasGrid(),
          routes: [
            GoRoute(
              path: 'goals',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const GoalConfigurationWidget(),
            ),
          ],
        ),
        // Route 3: Settings placeholder
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const SettingsWidget(),
          routes: [
            GoRoute(
              path: 'change-password',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const ChangePasswordPage(),
            ),
          ],
        ),
        // Route 4: Profile Dashboard
        GoRoute(
          path: '/profile',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const AnalysisDashboardPage(),
        ),
        // Route 5: Health
        GoRoute(
          path: '/health',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const HealthPage(),
          routes: [
            GoRoute(
              path: 'steps',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const StepsPage(),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  parentNavigatorKey: _shellNavigatorKey,
                  builder: (context, state) => const StepsDashboardPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'heart_rate',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const HeartRatePage(),
            ),
            GoRoute(
              path: 'sleep',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const SleepPage(),
            ),
            GoRoute(
              path: 'calories',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const CaloriesPage(),
            ),
            GoRoute(
              path: 'food',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const FoodInputPage(),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  parentNavigatorKey: _shellNavigatorKey,
                  builder: (context, state) => const FoodDashboardPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'exercise',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const ExercisePage(),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  parentNavigatorKey: _shellNavigatorKey,
                  builder: (context, state) => const ExerciseAnalysisPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'focus',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const FocusPage(),
            ),
            GoRoute(
              path: 'water',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const WaterPage(),
            ),
            GoRoute(
              path: 'habits',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const HabitDashboardPage(),
            ),
            GoRoute(
              path: 'analysis',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const HealthAnalysisPage(),
            ),
          ],
        ),
        // Route 6: Finance
        GoRoute(
          path: '/finance',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const FinancePage(),
        ),
        // Route 7: Social
        GoRoute(
          path: '/social',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const SocialPage(),
        ),
        // Route 8: Projects
        GoRoute(
          path: '/projects',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const ProjectsPage(),
          routes: [
            GoRoute(
              path: 'editor',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const TextEditorPage(),
            ),

            GoRoute(
              path: ':projectId',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) {
                final projectIdStr = state.pathParameters['projectId'];
                if (projectIdStr == null) return const ProjectsPage();
                final projectId = int.tryParse(projectIdStr);
                if (projectId == null) return const ProjectsPage();

                return Watch((context) {
                  final projects = context.read<ProjectBlock>().projects.value;
                  try {
                    final project = projects.firstWhere(
                      (p) => p.projectID == projectId,
                    );
                    return ProjectDetailsPage(project: project);
                  } catch (e) {
                    return projects.isEmpty
                        ? const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          )
                        : const ProjectsPage();
                  }
                });
              },
            ),
          ],
        ),
        GoRoute(
          path: '/project-analysis',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const ProjectAnalysisPage(),
        ),
        GoRoute(
          path: '/project/:projectId',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) {
            final projectIdStr = state.pathParameters['projectId'];
            if (projectIdStr == null) return const ProjectsPage();
            final projectId = int.tryParse(projectIdStr);
            if (projectId == null) return const ProjectsPage();

            return Watch((context) {
              final projects = context.read<ProjectBlock>().projects.value;
              try {
                final project = projects.firstWhere(
                  (p) => p.projectID == projectId,
                );
                return ProjectDetailsPage(project: project);
              } catch (e) {
                return projects.isEmpty
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      )
                    : const ProjectsPage();
              }
            });
          },
        ),
        // Route 9: Widgets
        GoRoute(
          path: '/widgets',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const WidgetPage(),
          routes: [
            GoRoute(
              path: 'gps',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const GPSTrackingPage(),
            ),
            GoRoute(
              path: 'webview',
              parentNavigatorKey: _shellNavigatorKey,
              builder: (context, state) => const WebViewPage(
                url: 'https://google.com',
                title: 'External Widget',
              ),
            ),
          ],
        ),
        // Route 10: Personal Information
        GoRoute(
          path: '/personal-info',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const PersonalInformationPage(),
        ),
        GoRoute(
          path: "/project_notes",
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const ProjectNotesPage(),
        ),
        GoRoute(
          path: '/notifications',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const NotificationManagerPage(),
        ),
        GoRoute(
          path: '/manual',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const ScoringRulesPage(),
        ),
      ],
    ),
  ],
);
