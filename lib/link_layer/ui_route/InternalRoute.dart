import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/sensor_layer/ui_layer/notification_page/NotificationManagerPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/notification_page/NotificationInboxPage.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SettingWidget.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/CaloriesPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/StepsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/StepsDashboardPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/HealthAnalysisPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/TextEditorPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/entry/PrismEntryPage.dart';
import 'package:ice_gate/orchestration_layer/Services/SessionTracker.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/DevQuickTabsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/GoalConfigurationWidget.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainShell.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/HomePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/FocusHistoryPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthIntegrationPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/AnalysisDashboardPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/LoginPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/RegisterPage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/ChangePasswordPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/ChangeUsernamePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/DocumentationPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/ExercisePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/FoodDashboardPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/ExerciseAnalysisPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectNotesPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectDetailsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/sdlc/ProjectSdlcBoardPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/sdlc/ProjectsSdlcHubPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectAnalysisPage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/HeartRatePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/SleepPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/FoodInputPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/FoodConsumePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/WaterPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/WeightPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/WeightInputPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/OxygenSaturationPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/TemperaturePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/subpage/DataIntegrationPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/FocusPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/BlockReminderPage.dart';
import 'package:ice_gate/orchestration_layer/Action/WebView/WebViewPage.dart';
// import 'package:ice_gate/sensor_layer/ui_layer/info_page/ScoringRulesPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/TalkSSH/SSHManagerPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceDashboardPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/pages/FinanceDailyReportPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SocialPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindAnalysisPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SkillCertificatePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SocialNotesDashboard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/blocker/SocialBlockerPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/HubLoader.dart';
import 'package:ice_gate/orchestration_layer/HubRegistry.dart';
import 'package:ice_gate/sensor_layer/ui_layer/integrations_page/IntegrationHubPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/integrations_page/CursorHubPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectsCalendarPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectDiagramsGalleryPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectsPlanPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectsWhiteboardPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/ProjectsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/PersonalInformationPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/NoteManagerPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/FolderDetailsPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/SyncEnginePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/system_page/SystemMonitorPage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/stock_page/StockPage.dart';
import 'package:ice_gate/utils/app_log.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final ValueNotifier<AuthStatus?> authStatusNotifier = ValueNotifier(
  AuthStatus.checkingSession,
);

final ValueNotifier<bool?> showIntroNotifier = ValueNotifier(null);

final ValueNotifier<String?> intendedPathNotifier = ValueNotifier(null);

/// True while the user must complete [ChangePasswordPage] after email recovery deep link.
final ValueNotifier<bool> pendingPasswordRecoveryNotifier = ValueNotifier(false);

/// Fade + slight slide for overlay-style routes (notifications hub, inbox, …).
CustomTransitionPage<void> _smoothOverlayPage({
  required GoRouterState state,
  required Widget child,
  Offset slideBegin = const Offset(0, 0.04),
  Duration duration = const Duration(milliseconds: 380),
  Duration reverseDuration = const Duration(milliseconds: 300),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: slideBegin, end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
    child: child,
  );
}

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: Listenable.merge([
    authStatusNotifier,
    showIntroNotifier,
    pendingPasswordRecoveryNotifier,
  ]),
  redirect: (context, state) {
    final status = authStatusNotifier.value;
    final isLoggingIn = state.uri.path == '/login';
    final isRegister = state.uri.path == '/register';

    debugPrint("🛣️ [GoRouter] Path: ${state.uri.path}, Status: $status");

    if (pendingPasswordRecoveryNotifier.value &&
        state.uri.path != '/change-password') {
      debugPrint(
        '🛣️ [GoRouter] Password recovery pending → /change-password',
      );
      return '/change-password';
    }

    if (showIntroNotifier.value == null) {
      SessionTracker.shouldShowIntro().then((shouldShow) {
        showIntroNotifier.value = shouldShow;
      });
      return null;
    }

    if (showIntroNotifier.value == true &&
        state.uri.path != '/intro' &&
        !pendingPasswordRecoveryNotifier.value) {
      // Never navigate away from login/register for intro — avoids tearing down the
      // route while a dialog (e.g. forgot password) is open → black screen / orphan overlay.
      if (state.uri.path == '/login' || state.uri.path == '/register') {
        showIntroNotifier.value = false;
        return null;
      }
      showIntroNotifier.value = false;
      return '/intro';
    }
    appLog("Current Location: ${state.matchedLocation}");

    if (status == null ||
        status == AuthStatus.checkingSession ||
        status == AuthStatus.init) {
      if (state.uri.path != '/' &&
          state.uri.path != '/login' &&
          state.uri.path != '/register' &&
          state.uri.path != '/intro') {
        debugPrint(
          "📌 [GoRouter] Capturing intended path: ${state.uri.toString()}",
        );
        intendedPathNotifier.value = state.uri.toString();
      }
      return null;
    }

    if (status == AuthStatus.authenticated) {
      if (state.uri.path == '/register') {
        return '/';
      }
      if (isLoggingIn) {
        debugPrint(
          "🛣️ [GoRouter] Authenticated from login, redirecting to /intro first",
        );
        return '/intro';
      }
      if (state.uri.path == '/intro') {
        return null;
      }
    } else {
      if (!isLoggingIn &&
          !isRegister &&
          state.uri.path != '/intro') {
        debugPrint("🛣️ [GoRouter] Unauthenticated, redirecting to /login");
        intendedPathNotifier.value = state.uri.toString();
        return '/login';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/intro',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PrismEntryPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),

    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _smoothOverlayPage(
        state: state,
        child: const NotificationManagerPage(),
      ),
    ),
    GoRoute(
      path: '/notification-inbox',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _smoothOverlayPage(
        state: state,
        child: const NotificationInboxPage(),
        slideBegin: const Offset(0.06, 0),
      ),
    ),
    GoRoute(
      path: '/documentation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DocumentationPage(),
    ),
    GoRoute(
      path: '/projects/editor',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        Widget page;
        if (state.extra is ProjectNoteData) {
          page = TextEditorPage(note: state.extra as ProjectNoteData);
        } else if (state.extra is File) {
          page = TextEditorPage(initialFile: state.extra as File);
        } else if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          page = TextEditorPage(
            note: data['note'] as ProjectNoteData?,
            initialCategory: data['category'] as String?,
            initialFile: data['file'] as File?,
            initialImage: data['initialImage'] as String?,
            initialDirectory: data['initialDirectory'] as Directory?,
            initialExtension: data['extension'] as String?,
          );
        } else {
          page = const TextEditorPage();
        }
        return HubLoader(hub: HubId.projects, child: page);
      },
    ),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            final fromEntry = state.extra == 'from_entry';
            if (fromEntry) {
              return CustomTransitionPage(
                key: state.pageKey,
                transitionDuration: const Duration(milliseconds: 800),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                child: const HomePage(),
              );
            }
            // Default Material/Cupertino slide for other entries
            return MaterialPage(key: state.pageKey, child: const HomePage());
          },
        ),
        GoRoute(
          path: '/canvas',
          builder: (context, state) => const DragCanvasGrid(),
          routes: [
            GoRoute(
              path: 'goals',
              builder: (context, state) => const GoalConfigurationWidget(),
            ),
            GoRoute(
              path: 'dev-tools',
              builder: (context, state) => const DevQuickTabsPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/integrations',
          builder: (context, state) {
            final focus = state.uri.queryParameters['focus'];
            return IntegrationHubPage(initialFocus: focus);
          },
          routes: [
            GoRoute(
              path: 'sensors',
              builder: (context, state) => const HealthIntegrationPage(),
            ),
            GoRoute(
              path: 'cursor',
              builder: (context, state) => const CursorHubPage(),
            ),
          ],
        ),
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
        GoRoute(
          path: '/health',
          builder: (context, state) => const HealthPage(),
          routes: [
            GoRoute(
              path: 'integrations',
              redirect: (context, state) => '/integrations?focus=health',
            ),
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
              path: 'oxygen_saturation',
              builder: (context, state) => const OxygenSaturationPage(),
            ),
            GoRoute(
              path: 'temperature',
              builder: (context, state) => const TemperaturePage(),
            ),
            GoRoute(
              path: 'weight',
              builder: (context, state) => const WeightPage(),
              routes: [
                GoRoute(
                  path: 'log',
                  builder: (context, state) => const WeightInputPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'food',
              builder: (context, state) => const FoodConsumePage(),
              routes: [
                GoRoute(
                  path: 'input',
                  builder: (context, state) => const FoodInputPage(),
                ),
                GoRoute(
                  path: 'consume',
                  redirect: (context, state) => '/health/food',
                ),
                GoRoute(
                  path: 'entry/:id',
                  builder: (context, state) {
                    final mealId = state.pathParameters['id'];
                    return FoodInputPage(mealId: mealId);
                  },
                ),
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
              path: 'analysis',
              builder: (context, state) => const HealthAnalysisPage(),
            ),
            GoRoute(
              path: 'goals',
              builder: (context, state) => const GoalConfigurationWidget(),
            ),
            GoRoute(
              path: 'integrations',
              builder: (context, state) => const DataIntegrationPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinancePage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const FinanceDashboardPage(),
            ),
            GoRoute(
              path: 'reports/daily',
              builder: (context, state) => const FinanceDailyReportPage(),
            ),
            GoRoute(
              path: 'stock/:symbol',
              builder: (context, state) {
                final symbol = state.pathParameters['symbol']!;
                return StockPage(symbol: symbol);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/social',
          builder: (context, state) => const SocialPage(),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const MindAnalysisPage(),
            ),
            GoRoute(
              path: 'skills',
              builder: (context, state) {
                final q = state.uri.queryParameters;
                final startSkillsRaw = q['startSkills'];
                // go_router already percent-decodes query parameter values.
                final startSkills = startSkillsRaw == null ||
                        startSkillsRaw.isEmpty
                    ? null
                    : startSkillsRaw
                        .split('|')
                        .where((s) => s.trim().isNotEmpty)
                        .toList();
                return MindSkillsPage(
                  projectId: q['projectId'],
                  altProjectId: q['altProjectId'],
                  projectTitle: q['title'],
                  startSkill: q['startSkill'],
                  startSkills: startSkills,
                  autoStartSession: q['autoStart'] == '1' ||
                      q['autoStart'] == 'true',
                );
              },
              routes: [
                GoRoute(
                  path: 'certificate',
                  builder: (context, state) {
                    final q = state.uri.queryParameters;
                    final skill = q['skill'] ?? '';
                    return SkillCertificatePage(
                      skillName: skill,
                      accentIndex: int.tryParse(q['accent'] ?? '') ?? 0,
                      initiallySelected:
                          q['selected'] == '1' || q['selected'] == 'true',
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'journal',
              builder: (context, state) => const SocialNotesDashboard(),
            ),
            GoRoute(
              path: 'contacts',
              builder: (context, state) => const SocialPage(),
            ),
            GoRoute(
              path: 'blocker',
              builder: (context, state) => const SocialBlockerPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsPage(),
          routes: [
            GoRoute(
              path: 'plan',
              builder: (context, state) => ProjectsPlanPage(
                projectId: state.uri.queryParameters['projectId'],
              ),
            ),
            GoRoute(
              path: 'board',
              builder: (context, state) => const ProjectsWhiteboardPage(),
            ),
            GoRoute(
              path: 'diagrams',
              builder: (context, state) => const ProjectDiagramsGalleryPage(),
            ),
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const ProjectAnalysisPage(),
            ),
            GoRoute(
              path: 'notes',
              builder: (context, state) => const NoteManagerPage(),
              routes: [
                GoRoute(
                  path: 'folder',
                  builder: (context, state) =>
                      FolderDetailsPage(directory: state.extra as Directory),
                ),
              ],
            ),
            GoRoute(
              path: 'documents',
              builder: (context, state) => const NoteManagerPage(),
              routes: [
                // FolderDetailsPage.dart and NoteManagerPage.dart both push
                // '/projects/documents/folder' — this sub-route was missing, causing
                // GoRouter to throw "no routes for location".
                GoRoute(
                  path: 'folder',
                  builder: (context, state) =>
                      FolderDetailsPage(directory: state.extra as Directory),
                ),
              ],
            ),
            GoRoute(
              path: 'calendar',
              builder: (context, state) => const ProjectsCalendarPage(),
            ),
            GoRoute(
              path: 'sdlc',
              builder: (context, state) => const ProjectsSdlcHubPage(),
            ),
            GoRoute(
              path: ':projectId',
              builder: (context, state) {
                final projectId = state.pathParameters['projectId'];

                return Watch((context) {
                  final projects = context.read<ProjectBlock>().projects.value;

                  if (projects.isEmpty) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final project = projects.cast<ProjectProtocol?>().firstWhere(
                    (p) => p?.id.toString() == projectId,
                    orElse: () => null,
                  );

                  if (project != null) {
                    return ProjectDetailsPage(project: project);
                  } else {
                    return const ProjectsPage();
                  }
                });
              },
              routes: [
                GoRoute(
                  path: 'sdlc',
                  builder: (context, state) {
                    final projectId = state.pathParameters['projectId'];

                    return Watch((context) {
                      final projects =
                          context.read<ProjectBlock>().projects.value;

                      if (projects.isEmpty) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final project =
                          projects.cast<ProjectProtocol?>().firstWhere(
                        (p) => p?.id.toString() == projectId,
                        orElse: () => null,
                      );

                      if (project != null) {
                        return ProjectSdlcBoardPage(project: project);
                      }
                      return const ProjectsPage();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/widgets/ssh',
          builder: (context, state) {
            final aiMode = state.uri.queryParameters['aiMode'];

            if (state.extra is Map<String, dynamic>) {
              final data = state.extra as Map<String, dynamic>;
              return TalkSSHPage(
                initialPrompt: data['prompt'] as String?,
                hostId: data['hostId'] as String?,
                remotePath: data['remotePath'] as String?,
                initialContent: data['content'] as String?,
                aiMode: aiMode ?? data['aiMode'] as String?,
                autoStartCommand: data['autoStartCommand'] as String?,
              );
            }
            return TalkSSHPage(
              initialPrompt: state.extra as String?,
              aiMode: aiMode,
            );
          },
        ),
        GoRoute(
          path: '/widget/ssh_manager',
          builder: (context, state) {
            if (state.extra is Map<String, dynamic>) {
              final data = state.extra as Map<String, dynamic>;
              return SSHManagerPage(
                initialPrompt:
                    data['prompt'] as String? ??
                    data['initialPrompt'] as String?,
                hostId: data['hostId'] as String?,
                remotePath: data['remotePath'] as String?,
                initialContent:
                    data['content'] as String? ??
                    data['initialContent'] as String?,
              );
            }
            return const SSHManagerPage();
          },
        ),

        GoRoute(
          path: '/webview',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'] ?? 'about:blank';
            final title =
                state.uri.queryParameters['title'] ?? 'External Widget';
            return WebViewPage(url: url, title: title);
          },
        ),
        // Route 10: Personal Information
        GoRoute(
          path: '/personal-info',
          builder: (context, state) => const PersonalInformationPage(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: '/change-username',
          builder: (context, state) => const ChangeUsernamePage(),
        ),
        GoRoute(
          path: "/project_notes",
          builder: (context, state) => const ProjectNotesPage(),
        ),

        GoRoute(
          path: '/sync-engine',
          builder: (context, state) => const SyncEnginePage(),
        ),
        GoRoute(
          path: '/system/monitor',
          builder: (context, state) => const SystemMonitorPage(),
        ),
      ],
    ),
  ],
);
