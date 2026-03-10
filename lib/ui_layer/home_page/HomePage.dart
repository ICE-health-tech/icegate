import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../UIConstants.dart';
import 'package:ice_gate/data_layer/Protocol/Health/HealthMetricsData.dart';
import 'package:ice_gate/initial_layer/CoreLogics/GamificationService.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart'
    show InternalWidgetBlock;
// import 'package:ice_gate/initial_layer/FireAPI/UrlNavigate.dart' as WidgetNavigatorAction;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/ui_layer/health_page/models/HealthMetric.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'
    hide ThemeData;
import 'package:go_router/go_router.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ice_gate/ui_layer/widget_page/AddPluginForm.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/ScoreAnimations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/QuoteBlock.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  // final String title;
  const HomePage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "home",
      destination: "/",
      size: size,
      mainFunction: () => context.go("/"),
      icon: Icons.ac_unit,
      doubleClickFunction: () {
        print("double click");
        context.pop();
      },
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () => WidgetNavigatorAction.smartPop(context),
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      onLongPress: () {
        context.go("/canvas");
      },
      subButtons: [],
    );
  }

  static Widget returnHomeIcon(BuildContext context, {double? size}) {
    return MainButton(
      type: "home",
      destination: "/",
      size: size,
      mainFunction: () => context.go("/"),
      icon: Icons.home,
      // iconWidget: Watch((context) {
      //   final steps = Provider.of<HealthBlock>(
      //     context,
      //     listen: false,
      //   ).todaySteps.value;
      //   return Center(
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         Text(
      //           steps >= 1000
      //               ? '${(steps / 1000).toStringAsFixed(1)}k'
      //               : '$steps',
      //           style: const TextStyle(
      //             color: Colors.white,
      //             fontSize: 12,
      //             fontWeight: FontWeight.bold,
      //           ),
      //         ),
      //         const Icon(
      //           Icons.directions_walk,
      //           size: 10,
      //           color: Colors.white70,
      //         ),
      //       ],
      //     ),
      //   );
      // }),
      doubleClickFunction: () {
        print("double click");
        context.pop();
      },
      onSwipeRight: () => WidgetNavigatorAction.smartPop(context),
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
    );
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isEditMode = false;
  late AppDatabase database;
  late InternalWidgetBlock internalWidgetBlock;
  late AuthBlock authBlock;
  late PersonBlock personBlock;
  late HealthMetricsDAO healthMetricsDAO;
  late Map<String, HealthMetric> healthMetricsData = {};
  late Map<String, HealthMetric> financeMetricsData = {};
  late Map<String, HealthMetric> socialMetricsData = {};
  late ScoreBlock scoreBlock;
  late FinanceBlock financeBlock;
  late ExternalWidgetBlock externalWidgetBlock;
  late GrowthBlock growthBlock;
  late HealthBlock healthBlock;
  late ProjectBlock projectBlock;
  late QuoteBlock quoteBlock;
  EffectCleanup? _levelEffect;
  final _levelUpToShow = signal<int?>(null);
  int? _lastSeenLevel;

  @override
  void initState() {
    super.initState();

    database = context.read<AppDatabase>();
    internalWidgetBlock = context.read<InternalWidgetBlock>();

    externalWidgetBlock = context.read<ExternalWidgetBlock>();
    authBlock = context.read<AuthBlock>();
    scoreBlock = context.read<ScoreBlock>();
    authBlock.fetchUser();
    personBlock = context.read<PersonBlock>();
    growthBlock = context.read<GrowthBlock>();
    healthMetricsDAO = context.read<HealthMetricsDAO>();
    financeBlock = context.read<FinanceBlock>();
    healthBlock = context.read<HealthBlock>();
    projectBlock = context.read<ProjectBlock>();
    quoteBlock = context.read<QuoteBlock>();

    _fetchInitialData();

    // Level Up effect
    _initLevelTracking();
  }

  Future<void> _initLevelTracking() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSeenLevel = prefs.getInt('last_seen_level');

    _levelEffect = effect(() {
      final currentLevel = scoreBlock.globalLevel.value;

      // If we haven't seen a level before, initialize it to the current level
      // instead of showing a level up from 0/1.
      if (_lastSeenLevel == null) {
        _lastSeenLevel = currentLevel;
        prefs.setInt('last_seen_level', currentLevel);
        return;
      }

      if (currentLevel > _lastSeenLevel!) {
        _levelUpToShow.value = currentLevel;
        _lastSeenLevel = currentLevel;
        prefs.setInt('last_seen_level', currentLevel);
      }
    });
  }

  void _fetchInitialData() {
    final jwtValue = authBlock.jwt.value;
    if (jwtValue != null) {
      personBlock.fetchFromDatabase(jwtValue);
    }

    Future.microtask(() {
      print("DUYLONG>>");
      final String personIdToUse =
          Supabase.instance.client.auth.currentUser?.id ?? "";
      internalWidgetBlock.refreshBlock(
        database.internalWidgetsDAO,
        personIdToUse,
        'home',
      );
      externalWidgetBlock.refreshBlock(
        database.externalWidgetsDAO,
        personIdToUse,
      );

      // print("DUYLONG<>:internal widget block: "+internalWidgetBlock.listInternalWidgetHomePage.value.toString()
      // );
      final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
      HealthMetricsData.getMetricsByDay(personId, DateTime.now(), context).then(
        (newData) {
          if (mounted) {
            setState(() {
              healthMetricsData = newData;
            });
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _levelEffect?.call();
    super.dispose();
  }

  // 1. Handles the actual step count data
  void _navigateInternalUrl(String name) {
    if (name == '/projects') {
      context.push(name);
      return;
    }

    if (name.startsWith('/project')) {
      final parts = name.split('/');
      if (parts.length > 2) {
        final id = (parts.last);

        context.push('/projects/$id');
        return;
      }
      context.push('/projects');
      return;
    }
    context.push(name);
  }

  void _showAddPluginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: AddPluginForm(
          data: FormData(
            title: AppLocalizations.of(context)!.add_app_plugin,
            description: AppLocalizations.of(context)!.plugin_desc,
          ),
          scope: 'home',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final personBlock = context.read<PersonBlock>();
    final double sizeOfDepartment = UIConstants.getSizeOfDepartment(context);
    final double sizeOfWidget = UIConstants.getSizeOfWidget(context);
    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context), // Use maybePop for safety
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.home_rounded, size: 30),
            //   onPressed: () => context.go('/'),
            // ),
            IconButton(
              icon: const Icon(Icons.grid_view, size: 30),
              onPressed: () => context.go('/canvas'),
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 30),
              onPressed: () => context.go('/settings'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: Watch((context) {
          final level = _levelUpToShow.value;
          if (level == null) return const SizedBox.shrink();
          return LevelUpCelebration(
            level: level,
            onFinished: () => _levelUpToShow.value = null,
          );
        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: Watch((context) {
          final internalWidgets =
              internalWidgetBlock.listInternalWidgetHomePage.value;
          final externalWidgets = externalWidgetBlock.listExternalWidgets.value;

          return SwipeablePage(
            direction: SwipeablePageDirection.leftToRight,
            onSwipe: () => context.pop(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                // vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION: USER HEADER (Row 2) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text(
                          "${personBlock.information.value.profiles.firstName} ${personBlock.information.value.profiles.lastName}",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,

                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        onPressed: () {
                          context.go("/personal-info");
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // --- SECTION: GAMIFIED HEADER ---
                  _buildGamifiedHeader(context),
                  const SizedBox(height: 16),
                  _buildQuotesSection(context),
                  const SizedBox(height: 16),
                  // --- SECTION: 4 life elements ---
                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.homepage_four_life_elements,
                    '/profile',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: sizeOfDepartment,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Watch((context) {
                          final steps = healthBlock.todaySteps.value;
                          final kcal = healthBlock.todayCaloriesConsumed.value;
                          final sleep = healthBlock.todaySleep.value;
                          final hr = healthBlock.todayHeartRate.value;
                          return _buildQuickAccessCard(
                            context,
                            AppLocalizations.of(context)!.health,
                            Icons.favorite_rounded,
                            Colors.green,
                            metrics: [
                              {
                                'label': AppLocalizations.of(context)!.steps,
                                'value': '$steps',
                              },
                              {
                                'label': AppLocalizations.of(
                                  context,
                                )!.kcal_consume,
                                'value': '$kcal',
                              },
                              {
                                'label': AppLocalizations.of(context)!.sleep,
                                'value': '${sleep.toStringAsFixed(1)}h',
                              },
                              {
                                'label': AppLocalizations.of(context)!.hr,
                                'value': hr > 0 ? '$hr bpm' : '--',
                              },
                            ],
                            route: '/health',
                            scoreData: scoreBlock.score.healthGlobalScore,
                          );
                        }),
                        Watch((context) {
                          final balance = financeBlock.totalBalance.value;
                          final spending = financeBlock.monthlySpending.value;
                          final income = financeBlock.monthlyIncome.value;
                          final savings = financeBlock.totalSavings.value;
                          return _buildQuickAccessCard(
                            context,
                            AppLocalizations.of(context)!.finance,
                            Icons.account_balance_wallet_rounded,
                            Colors.blue,
                            metrics: [
                              {
                                'label': AppLocalizations.of(context)!.balance,
                                'value': '\$${balance.toStringAsFixed(0)}',
                              },
                              {
                                'label': AppLocalizations.of(context)!.spent,
                                'value': '\$${spending.toStringAsFixed(0)}',
                              },
                              {
                                'label': AppLocalizations.of(context)!.income,
                                'value': '\$${income.toStringAsFixed(0)}',
                              },
                              {
                                'label': AppLocalizations.of(context)!.savings,
                                'value': '\$${savings.toStringAsFixed(0)}',
                              },
                            ],
                            route: '/finance',
                            scoreData: scoreBlock.score.financialGlobalScore,
                          );
                        }),
                        Watch((context) {
                          final info = personBlock.information.value;
                          return StreamBuilder<List<PersonData>>(
                            stream: database.personDAO.getAllPersons(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
                              return _buildQuickAccessCard(
                                context,
                                AppLocalizations.of(context)!.social,
                                Icons.people_alt_rounded,
                                Colors.purple,
                                metrics: [
                                  {
                                    'label': AppLocalizations.of(
                                      context,
                                    )!.total_users,
                                    'value': '$count',
                                  },
                                  {
                                    'label': AppLocalizations.of(
                                      context,
                                    )!.friends,
                                    'value': '${info.profiles.friends}',
                                  },
                                  {
                                    'label': AppLocalizations.of(
                                      context,
                                    )!.mutual,
                                    'value': '${info.profiles.mutual}',
                                  },
                                  {
                                    'label': AppLocalizations.of(
                                      context,
                                    )!.username,
                                    'value':
                                        authBlock.username.value ??
                                        info.profiles.username,
                                  },
                                ],
                                route: '/social',
                                scoreData: scoreBlock.score.socialGlobalScore,
                              );
                            },
                          );
                        }),
                        Watch((context) {
                          final projectGoals = growthBlock.goals.value
                              .where((g) => g.category == 'project')
                              .toList();
                          final tasksRemaining = projectGoals
                              .where((g) => g.status != 'done')
                              .length;
                          final tasksDone = projectGoals
                              .where((g) => g.status == 'done')
                              .length;

                          final allProjects = projectBlock.projects.value;
                          final projectsDone = allProjects
                              .where((p) => p.status == 1)
                              .length;
                          final projectsRemaining = allProjects
                              .where((p) => p.status == 0)
                              .length;

                          return _buildQuickAccessCard(
                            context,
                            AppLocalizations.of(context)!.projects,
                            Icons.rocket_launch_rounded,
                            Colors.orange,
                            metrics: [
                              {
                                'label': AppLocalizations.of(context)!.done,
                                'value':
                                    '$projectsDone ${AppLocalizations.of(context)!.projs}',
                              },
                              {
                                'label': AppLocalizations.of(context)!.active,
                                'value':
                                    '$projectsRemaining ${AppLocalizations.of(context)!.projs}',
                              },
                              {
                                'label': AppLocalizations.of(context)!.done,
                                'value':
                                    '$tasksDone ${AppLocalizations.of(context)!.tasks}',
                              },
                              {
                                'label': AppLocalizations.of(context)!.active,
                                'value':
                                    '$tasksRemaining ${AppLocalizations.of(context)!.tasks}',
                              },
                            ],
                            route: '/projects',
                            scoreData: scoreBlock.score.careerGlobalScore,
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- SECTION: QUICK ACCESS GRID ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoSizeText(
                        AppLocalizations.of(context)!.homepage_plugin,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditMode = !_isEditMode;
                          });
                        },
                        child: Text(
                          _isEditMode
                              ? AppLocalizations.of(context)!.done
                              : AppLocalizations.of(context)!.edit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: sizeOfWidget,
                    child: Watch((context) {
                      final sortedInternal = List<InternalWidgetProtocol>.from(
                        internalWidgets,
                      );
                      sortedInternal.sort(
                        (a, b) => b.dateAdded.compareTo(a.dateAdded),
                      );

                      final itemCount =
                          sortedInternal.length + externalWidgets.length + 1;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(right: 20),
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          // Show Add Button at the END
                          if (index == itemCount - 1) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: SizedBox(
                                width: sizeOfWidget,
                                height: sizeOfWidget,
                                child: _buildAddButton(context),
                              ),
                            );
                          }

                          if (index < sortedInternal.length) {
                            final widget = sortedInternal[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: sizeOfWidget,
                                height: sizeOfWidget,
                                child: _buildInternalWidget(context, widget),
                              ),
                            );
                          }

                          final extIndex = index - sortedInternal.length;
                          if (extIndex < externalWidgets.length) {
                            final ext = externalWidgets[extIndex];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: sizeOfWidget,
                                child: _buildExternalWidget(context, ext),
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // --- SECTION: QUOTES ---
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }),
        // Duplicate FAB removed from here
      ),
    );
  }

  Widget _buildGamifiedHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final level = scoreBlock.globalLevel.value;
    final progress = scoreBlock.levelProgress.value;
    final rank = scoreBlock.rankTitle.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
            colorScheme.primary.withOpacity(0.6),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.onPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank.toUpperCase(),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.9),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.level(level),
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: colorScheme.onPrimary,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.progress_to_level(level + 1),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.85),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AutoSizeText(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
        ),
        TextButton.icon(
          onPressed: () => context.go(route),
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          label: Text(AppLocalizations.of(context)!.analysis),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    required List<Map<String, String>> metrics,
    required String route,
    required double scoreData,
  }) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final safeScore = scoreData.isFinite ? scoreData.toInt() : 0;
    final level = GamificationService.getLevel(safeScore);
    final progress = GamificationService.getProgressToNextLevel(safeScore);

    return Container(
      width: isPhone ? 210 : 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: color.withOpacity(0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(route),
          child: Stack(
            children: [
              // Glassmorphism Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.18),
                        color.withOpacity(0.08),
                        color.withOpacity(0.02),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Subtle Glow
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isPhone ? 12.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutQuart,
                          builder: (context, value, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: isPhone ? 64 : 76,
                                  height: isPhone ? 64 : 76,
                                  child: CircularProgressIndicator(
                                    value: value.clamp(0.0, 1.0),
                                    strokeWidth: isPhone ? 4 : 5,
                                    backgroundColor: color.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(isPhone ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: isPhone ? 26 : 30,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          child: ScorePulseWrapper(
                            value: scoreData,
                            child: Column(
                              key: ValueKey(title),
                              children: [
                                AutoSizeText(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: isPhone ? 18 : 22,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                RollingScoreText(
                                  value: level,
                                  prefix: "LV ",
                                  style: TextStyle(
                                    color: color,
                                    fontSize: isPhone ? 14 : 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RollingScoreText(
                                  value: scoreData,
                                  prefix: "P: ",
                                  decimalPlaces: 1,
                                  style: TextStyle(
                                    color: color.withOpacity(0.9),
                                    fontSize: isPhone ? 16 : 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 2x2 Grid of metrics
                    Wrap(
                      spacing: isPhone ? 8 : 12,
                      runSpacing: isPhone ? 4 : 4,
                      children: metrics.map((m) {
                        return SizedBox(
                          width: isPhone ? 80 : 90,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                m['value'] ?? '',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.9),
                                  fontSize: isPhone ? 11 : 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AutoSizeText(
                                m['label'] ?? '',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: isPhone ? 9 : 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternalWidget(
    BuildContext context,
    InternalWidgetProtocol? widgetData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final sizeOfWidget = UIConstants.getSizeOfWidget(context);

    if (widgetData == null) {
      return InkWell(
        onTap: () => _showAddPluginDialog(context),
        borderRadius: BorderRadius.circular(28),
        customBorder: Border.all(
          color: colorScheme.outline.withAlpha(90),
          width: 3,
        ),
        child: Container(
          width: sizeOfWidget,
          height: sizeOfWidget,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),

            border: Border.all(
              color: colorScheme.outline.withAlpha(90),
              width: 3,
              style: BorderStyle
                  .none, // Can change to solid for dashed effect if custom painter
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 3,
                    style: BorderStyle
                        .none, // Can change to solid for dashed effect if custom painter
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: colorScheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    final item = Container(
      width: sizeOfWidget,
      height: sizeOfWidget,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 3.0, // Thinner, cleaner border
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(widgetData.icon, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AutoSizeText(
              widgetData.name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        InkWell(
          onTap: _isEditMode
              ? () {
                  _showRenameInternalDialog(context, widgetData);
                }
              : () => _navigateInternalUrl(widgetData.url),
          borderRadius: BorderRadius.circular(20),
          child: item,
        ),
        if (_isEditMode) ...[
          Positioned(
            top: 5,
            right: 5,
            child: InkWell(
              onTap: () {
                // Logic to delete internal widget
                HapticFeedback.heavyImpact();
                internalWidgetBlock.deleteWidget(
                  database.internalWidgetsDAO,
                  widgetData.name,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),

                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                    width: 5,
                  ),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 20,
            child: Text(
              AppLocalizations.of(context)!.edit,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: UIConstants.getResponsiveFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExternalWidget(BuildContext context, ExternalWidgetData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final String fullUrl =
        "${data.protocol ?? 'https'}://${data.host ?? ''}${data.url ?? ''}";

    final sizeOfWidget = UIConstants.getSizeOfWidget(context);
    final item = Container(
      width: sizeOfWidget,
      height: sizeOfWidget,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 3.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Colors.blueAccent,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AutoSizeText(
              data.name ?? 'Untitled',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: colorScheme.primary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        InkWell(
          onTap: _isEditMode
              ? () {
                  _showRenameExternalDialog(context, data);
                }
              : () {
                  WidgetNavigatorAction.navigateExternalUrl(context, fullUrl);
                },
          borderRadius: BorderRadius.circular(28),
          child: item,
        ),
        if (_isEditMode) ...[
          Positioned(
            top: 5,
            right: 5,
            child: InkWell(
              onTap: () {
                // Logic to delete external widget
                HapticFeedback.heavyImpact();
                externalWidgetBlock.deleteWidget(
                  database.externalWidgetsDAO,
                  data.id,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                    width: 5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 20,
            child: Text(
              "Rename",
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: UIConstants.getResponsiveFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showRenameInternalDialog(
    BuildContext context,
    InternalWidgetProtocol widgetData,
  ) {
    final controller = TextEditingController(text: widgetData.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppLocalizations.of(context)!.edit} Internal Widget'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Widget Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                internalWidgetBlock.renameWidget(
                  database.internalWidgetsDAO,
                  widgetData.name,
                  controller.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.edit),
          ),
        ],
      ),
    );
  }

  void _showRenameExternalDialog(
    BuildContext context,
    ExternalWidgetData data,
  ) {
    final controller = TextEditingController(text: data.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppLocalizations.of(context)!.edit} External Widget'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Widget Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                externalWidgetBlock.renameWidget(
                  database.externalWidgetsDAO,
                  data.id,
                  controller.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Watch((context) {
      final quote = quoteBlock.currentQuote.value;
      final author = quoteBlock.currentAuthor.value;

      return InkWell(
        onTap: () {
          quoteBlock.shuffle();
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: colorScheme.primary.withOpacity(0.5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AutoSizeText(
                  quote,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (author != null && author.isNotEmpty) ...[
                Text(
                  "- $author",
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.format_quote_rounded,
                color: colorScheme.primary.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAddButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showAddPluginDialog(context),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.2),
            width: 3,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: colorScheme.primary, size: 32),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.done,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
