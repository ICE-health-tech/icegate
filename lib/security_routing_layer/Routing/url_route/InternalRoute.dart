import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/ui_layer/notification_page/NotificationManagerPage.dart';
import 'package:ice_gate/ui_layer/notification_page/NotificationInboxPage.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:ice_gate/ui_layer/ReusableWidget/SettingWidget.dart';
import 'package:ice_gate/ui_layer/health_page/CaloriesPage.dart';
import 'package:ice_gate/ui_layer/health_page/ExercisePage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/FoodDashboardPage.dart';
import 'package:ice_gate/ui_layer/health_page/HabitDashboardPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/StepsPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/StepsDashboardPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/ExerciseAnalysisPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/HealthAnalysisPage.dart';
import 'package:ice_gate/ui_layer/projects_page/ProjectNotesPage.dart';
import 'package:ice_gate/ui_layer/projects_page/ProjectDetailsPage.dart';
import 'package:ice_gate/ui_layer/projects_page/ProjectAnalysisPage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/ui_layer/widget_page/WidgetPage.dart';
// import 'package:ice_gate/ui_layer/health_page/subpage/StepsPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/HeartRatePage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/SleepPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/FoodInputPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/WaterPage.dart';
import 'package:ice_gate/ui_layer/projects_page/TextEditorPage.dart';
import 'package:ice_gate/ui_layer/projects_page/FocusPage.dart';
import 'package:ice_gate/ui_layer/projects_page/BlockReminderPage.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/GPSTrackingPage.dart';
import 'package:ice_gate/orchestration_layer/Action/WebView/WebViewPage.dart';
import 'package:ice_gate/ui_layer/info_page/ScoringRulesPage.dart';
import 'package:ice_gate/ui_layer/animation_page/snowflake_assemble_screen.dart';
import 'package:ice_gate/initial_layer/CoreLogics/session_tracker.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart';
// // Import your pages
// import 'package:ice_gate/ui_layer/BigWidget/DragCanvasGrid.dart'; // Your Grid
// import 'package:ice_gate/ui_layer/HomePage.dart'; // Your Home
// Import the shell we created in Step 1
import 'package:ice_gate/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_gate/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:ice_gate/ui_layer/home_page/MainShell.dart';
import 'package:ice_gate/ui_layer/home_page/HomePage.dart';
import 'package:ice_gate/ui_layer/projects_page/FocusHistoryPage.dart';
import 'package:ice_gate/ui_layer/health_page/subpage/WeightPage.dart';
import 'package:ice_gate/ui_layer/user_page/AnalysisDashboardPage.dart';
import 'package:ice_gate/ui_layer/health_page/HealthPage.dart';
import 'package:ice_gate/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/ui_layer/finance_page/FinanceDashboardPage.dart';
import 'package:ice_gate/ui_layer/social_page/SocialPage.dart';
import 'package:ice_gate/ui_layer/social_page/SocialDashboardPage.dart';
import 'package:ice_gate/ui_layer/social_page/SocialNotesDashboard.dart';
import 'package:ice_gate/ui_layer/projects_page/ProjectsPage.dart';
import 'package:ice_gate/ui_layer/user_page/PersonalInformationPage.dart';
import 'package:ice_gate/ui_layer/user_page/LoginPage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/ui_layer/user_page/ChangePasswordPage.dart';
import 'package:ice_gate/ui_layer/user_page/ChangeUsernamePage.dart';
// import 'MainShell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final ValueNotifier<AuthStatus?> authStatusNotifier = ValueNotifier(
  AuthStatus.checkingSession,
);

final ValueNotifier<bool?> showIntroNotifier = ValueNotifier(null);

// Store the intended path to redirect after login
final ValueNotifier<String?> intendedPathNotifier = ValueNotifier(null);

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
    print("Current Location: ${state.matchedLocation}");

    if (status == null ||
        status == AuthStatus.checkingSession ||
        status == AuthStatus.init) {
      // Capture the initial deep link if not logged in yet
      if (state.uri.path != '/' && state.uri.path != '/login' && state.uri.path != '/intro') {
         debugPrint("📌 [GoRouter] Capturing intended path: ${state.uri.toString()}");
         intendedPathNotifier.value = state.uri.toString();
      }
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
        // Capture intended path before redirecting to login
        intendedPathNotifier.value = state.uri.toString();
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
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationManagerPage(),
    ),
    GoRoute(
      path: '/notification-inbox',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationInboxPage(),
    ),
    GoRoute(
      path: '/projects/editor',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        if (state.extra is ProjectNoteData) {
          return TextEditorPage(note: state.extra as ProjectNoteData);
        } else if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return TextEditorPage(
            note: data['note'] as ProjectNoteData?,
            initialCategory: data['category'] as String?,
          );
        }
        return const TextEditorPage();
      },
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
          builder: (context, state) => const HomePage(),
        ),
        // Route 2: The Grid Canvas
        GoRoute(
          path: '/canvas',
          builder: (context, state) => DragCanvasGrid(),
          routes: [
            GoRoute(
              path: 'goals',
              builder: (context, state) => const GoalConfigurationWidget(),
            ),
          ],
        ),
        // Route 3: Settings placeholder
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsWidget(),
          routes: [
            GoRoute(
              path: 'change-password',
              builder: (context, state) => const ChangePasswordPage(),
            ),
            GoRoute(
              path: 'change-username',
              builder: (context, state) => const ChangeUsernamePage(),
            ),
          ],
        ),
        // Route 4: Profile Dashboard
        GoRoute(
          path: '/profile',
          builder: (context, state) => const AnalysisDashboardPage(),
          routes: [
            GoRoute(
              path: ':personId',
              builder: (context, state) {
                final personId = state.pathParameters['personId'];
                return AnalysisDashboardPage(personId: personId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/focus-history',
          builder: (context, state) => const FocusHistoryPage(),
        ),
        // Route 5: Health
        GoRoute(
          path: '/health',
          builder: (context, state) => const HealthPage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const HealthAnalysisPage(),
            ),
            GoRoute(
              path: 'steps',
              builder: (context, state) => const StepsPage(),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const StepsDashboardPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'heart_rate',
              builder: (context, state) => const HeartRatePage(),
            ),
            GoRoute(
              path: 'sleep',
              builder: (context, state) => const SleepPage(),
            ),
            GoRoute(
              path: 'calories',
              builder: (context, state) => const CaloriesPage(),
            ),
            GoRoute(
              path: 'weight',
              builder: (context, state) => const WeightPage(),
            ),
            GoRoute(
              path: 'food',
              builder: (context, state) => const FoodInputPage(),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const FoodDashboardPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'exercise',
              builder: (context, state) => const ExercisePage(),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const ExerciseAnalysisPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'focus',
              builder: (context, state) => const FocusPage(),
            ),
            GoRoute(
              path: 'block-reminder',
              builder: (context, state) => const BlockReminderPage(),
            ),
            GoRoute(
              path: 'water',
              builder: (context, state) => const WaterPage(),
            ),
            GoRoute(
              path: 'habits',
              builder: (context, state) => const HabitDashboardPage(),
            ),
            GoRoute(
              path: 'analysis',
              builder: (context, state) => const HealthAnalysisPage(),
            ),
          ],
        ),
        // Route 6: Finance
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinancePage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const FinanceDashboardPage(),
            ),
          ],
        ),
        // Route 7: Social
        GoRoute(
          path: '/social',
          builder: (context, state) => const SocialPage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const SocialDashboardPage(),
            ),
            GoRoute(
              path: 'journal',
              builder: (context, state) => const SocialNotesDashboard(),
            ),
            GoRoute(
              path: 'contacts',
              builder: (context, state) => const SocialPage(),
            ),
          ],
        ),
        // Route 8: Projects
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsPage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const ProjectAnalysisPage(),
            ),
            GoRoute(
              path:
                  ':projectId', // Đường dẫn con của /projects nên URL sẽ là /projects/123
              builder: (context, state) {
                final projectId = state.pathParameters['projectId'];

                return Watch((context) {
                  final projects = context.read<ProjectBlock>().projects.value;

                  // TRƯỜNG HỢP 1: Đang tải dữ liệu
                  if (projects.isEmpty) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // TRƯỜNG HỢP 2: Tìm kiếm đúng project theo ID từ URL
                  // Dùng firstWhereOrNull để an toàn (cần import package:collection)
                  final project = projects.cast<ProjectProtocol?>().firstWhere(
                    (p) => p?.id.toString() == projectId,
                    orElse: () => null,
                  );

                  // TRƯỜNG HỢP 3: Hiển thị kết quả
                  if (project != null) {
                    return ProjectDetailsPage(project: project);
                  } else {
                    // Nếu không tìm thấy ID, quay về trang danh sách
                    return const ProjectsPage();
                  }
                });
              },
            ),
          ],
        ),
        // Route 9: Widgets
        GoRoute(
          path: '/widgets',
          builder: (context, state) => const WidgetPage(),
          routes: [
            GoRoute(
              path: 'gps',
              builder: (context, state) => const GPSTrackingPage(),
            ),
            GoRoute(
              path: 'webview',
              builder: (context, state) => const WebViewPage(
                url: 'https://google.com',
                title: 'External Widget',
              ),
            ),
            GoRoute(
              path: 'ssh',
              builder: (context, state) => TalkSSHPage(
                initialPrompt: state.extra as String?,
              ),
            ),
          ],
        ),
        // Route 10: Personal Information
        GoRoute(
          path: '/personal-info',
          builder: (context, state) => const PersonalInformationPage(),
        ),
        GoRoute(
          path: "/project_notes",
          builder: (context, state) => const ProjectNotesPage(),
        ),
        GoRoute(
          path: '/manual',
          builder: (context, state) => const ScoringRulesPage(),
        ),
      ],
    ),
  ],
);
