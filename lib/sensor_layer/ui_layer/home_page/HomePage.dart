import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../UIConstants.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart'
    show InternalWidgetBlock;
// import 'package:ice_gate/orchestration_layer/Services/FireAPI/UrlNavigate.dart' as WidgetNavigatorAction;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'
    hide ThemeData;
import 'package:go_router/go_router.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/AddPluginForm.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/QuoteBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/RadialPremiumBackground.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/AvailablePlugins.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/WebPlugin/GoogleCalendar.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MorningBriefingSheet.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/EnvironmentalPluginCards.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/HomePageSettings.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/WorkspaceSidebarLayout.dart';
import 'package:ice_gate/utils/app_log.dart';

/// Avoids re-running heavy bootstrap when returning to Home (same session / same user).
String? _homePageBootstrapUserId;

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
        appLog("double click");
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
      subButtons: [
        SubButton(
          label: "Docs",
          icon: Icons.description_rounded,
          onPressed: () => context.push('/projects/documents'),
        ),
      ],
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
        appLog("double click");
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
  late ScoreBlock scoreBlock;
  late FinanceBlock financeBlock;
  late ExternalWidgetBlock externalWidgetBlock;
  late GrowthBlock growthBlock;
  late HealthBlock healthBlock;
  late ProjectBlock projectBlock;
  late QuoteBlock quoteBlock;
  late MindBlock mindBlock;
  late ConfigBlock configBlock;
  EffectCleanup? _levelEffect;
  // final _levelUpToShow = signal<int?>(null);
  int? _lastSeenLevel;

  @override
  void initState() {
    super.initState();

    database = context.read<AppDatabase>();
    internalWidgetBlock = context.read<InternalWidgetBlock>();

    externalWidgetBlock = context.read<ExternalWidgetBlock>();
    authBlock = context.read<AuthBlock>();
    scoreBlock = context.read<ScoreBlock>();
    personBlock = context.read<PersonBlock>();
    growthBlock = context.read<GrowthBlock>();
    financeBlock = context.read<FinanceBlock>();
    healthBlock = context.read<HealthBlock>();
    projectBlock = context.read<ProjectBlock>();
    quoteBlock = context.read<QuoteBlock>();
    mindBlock = context.read<MindBlock>();
    configBlock = context.read<ConfigBlock>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleMorningHooks();
    });

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      _homePageBootstrapUserId = null;
    } else if (_homePageBootstrapUserId != userId) {
      _homePageBootstrapUserId = userId;
      authBlock.fetchUser();
      _fetchInitialData();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final personId = personBlock.currentPersonID.value;
      if (personId != null && personId.isNotEmpty) {
        context.read<SocialBlock>().restoreActiveFocus(personId);
      }
    });

    // Level Up effect
    // Future.microtask(() {
    //   _initLevelTracking();
    // });
  }

  Future<void> _scheduleMorningHooks() async {
    if (!mounted) return;
    try {
      await context.read<LocalNotificationService>().scheduleMorningLoopFromPrefs();
    } catch (e) {
      appLog('Morning notification schedule skipped: $e');
    }
    // Let home pillars paint first, then optional morning sheet.
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    await MorningBriefingSheet.maybeShow(context);
  }

  void _fetchInitialData() {
    final jwtValue = authBlock.jwt.value;
    if (jwtValue != null) {
      personBlock.fetchFromDatabase(jwtValue);
    }

    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
    if (personId.isEmpty) return;

    // DataLayer already warms finance/health/widgets on personId — only fill gaps.
    Future.microtask(() async {
      if (internalWidgetBlock.listInternalWidgetHomePage.value.isEmpty) {
        internalWidgetBlock.refreshBlock(
          database.internalWidgetsDAO,
          personId,
          'home',
        );
      }
      if (externalWidgetBlock.listExternalWidgets.value.isEmpty) {
        externalWidgetBlock.refreshBlock(
          database.externalWidgetsDAO,
          personId,
        );
      }
      if (financeBlock.accounts.value.isEmpty &&
          financeBlock.transactions.value.isEmpty) {
        await financeBlock.refreshFromLocalDatabase();
      }
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
    final textTheme = Theme.of(context).textTheme;
    final double sizeOfDepartment = UIConstants.getSizeOfDepartment(context);
    final double sizeOfWidget = UIConstants.getSizeOfWidget(context);
    final colorScheme = Theme.of(context).colorScheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // statusBarColor: Colors.transparent,
        // statusBarIconBrightness: Brightness.light,
        // systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: RadialPremiumBackground(
        child: SwipeablePage(
          onSwipe: () => Navigator.maybePop(context), // Use maybePop for safety
          direction: SwipeablePageDirection.leftToRight,
          child: Scaffold(
            // backgroundColor: Colors.transparent,
            appBar: AppBar(
              toolbarHeight: 70,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leadingWidth: 0,
              leading: const SizedBox.shrink(),
              actions: [const SizedBox(width: 8)],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            // Use Builder instead of Watch here — this scope doesn't read
            // any signals directly. Inner Watch widgets handle their own
            // reactive tracking. Using Watch here caused nested-scope
            // SignalEffectException crashes.
            body: Builder(builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final scrollBody = SingleChildScrollView(
                  key: const PageStorageKey<String>('home_feed_scroll'),
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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [],
                      ),
                      const SizedBox(height: 10),
                      // // --- SECTION: GAMIFIED HEADER ---
                      // _buildGamifiedHeader(context),
                      // const SizedBox(height: 16),
                      _buildEnvironmentalSummary(context),
                      _buildQuotesSection(context),

                      // const SizedBox(height: 20),
                      const SizedBox(height: 8),

                      // --- SECTION: 4 life elements ---
                      _buildSectionHeader(
                        context,
                        AppLocalizations.of(
                          context,
                        )!.homepage_four_life_elements,
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
                              final kcal =
                                  healthBlock.todayCaloriesConsumed.value;
                              final sleep = healthBlock.todaySleep.value;
                              final hr = healthBlock.todayHeartRate.value;
                              final water = healthBlock.todayWater.value;
                              final weight = healthBlock.latestWeight.value;

                              final allMetrics = [
                                {
                                  'label': l10n.steps,
                                  'value': '$steps',
                                  'visible': configBlock.showIndexSteps.value,
                                },
                                {
                                  'label': l10n.kcal_consume,
                                  'value': '$kcal',
                                  'visible':
                                      configBlock.showIndexCalories.value,
                                },
                                {
                                  'label': l10n.sleep,
                                  'value': '${sleep.toStringAsFixed(1)}h',
                                  'visible': true,
                                }, // Always show some core metrics
                                {
                                  'label': l10n.hr,
                                  'value': hr > 0 ? '$hr bpm' : '--',
                                  'visible': true,
                                },
                                {
                                  'label': l10n.home_index_water,
                                  'value': '$water ml',
                                  'visible': configBlock.showIndexWater.value,
                                },
                                {
                                  'label': l10n.home_index_weight,
                                  'value': weight > 0 ? '$weight kg' : '--',
                                  'visible': configBlock.showIndexWeight.value,
                                },
                              ];

                              final visibleMetrics = allMetrics
                                  .where((m) => m['visible'] == true)
                                  .map(
                                    (m) => {
                                      'label': m['label'] as String,
                                      'value': m['value'],
                                    },
                                  )
                                  .toList();

                              return _buildQuickAccessCard(
                                context,
                                l10n.health,
                                Icons.favorite_rounded,
                                HealthMetricColors.homePillarAccent('health'),
                                metrics: visibleMetrics,
                                route: '/health',
                                scoreData: scoreBlock.score.healthGlobalScore,
                              );
                            }),
                            Watch((context) {
                              financeBlock.accounts.value;
                              financeBlock.assets.value;
                              financeBlock.transactions.value;
                              financeBlock.subscriptions.value;
                              final balance = financeBlock.totalBalance.value;
                              final spending =
                                  financeBlock.monthlySpending.value;
                              final income = financeBlock.monthlyIncome.value;
                              final savings = financeBlock.totalSavings.value;
                              final delta = financeBlock.dailyDelta.value;
                              final usage =
                                  financeBlock.budgetUsagePercent.value;

                              final allMetrics = [
                                {
                                  'label': l10n.balance,
                                  'value': financeBlock.formatCurrency(
                                    balance,
                                    compact: true,
                                  ),
                                  'visible': configBlock.showIndexBalance.value,
                                },
                                {
                                  'label': l10n.spent,
                                  'value': financeBlock.formatCurrency(
                                    spending,
                                    compact: true,
                                  ),
                                  'visible':
                                      configBlock.showIndexSpending.value,
                                },
                                {
                                  'label': l10n.income,
                                  'value': financeBlock.formatCurrency(
                                    income,
                                    compact: true,
                                  ),
                                  'visible': true,
                                },
                                {
                                  'label': l10n.savings,
                                  'value': financeBlock.formatCurrency(
                                    savings,
                                    compact: true,
                                  ),
                                  'visible': true,
                                },
                                {
                                  'label': l10n.home_index_daily,
                                  'value': financeBlock.formatCurrency(
                                    delta,
                                    compact: true,
                                  ),
                                  'visible':
                                      configBlock.showIndexFinanceDaily.value,
                                },
                                {
                                  'label': l10n.home_index_usage,
                                  'value': '${usage.toStringAsFixed(0)}%',
                                  'visible':
                                      configBlock.showIndexFinanceUsage.value,
                                },
                              ];

                              final visibleMetrics = allMetrics
                                  .where((m) => m['visible'] == true)
                                  .map(
                                    (m) => {
                                      'label': m['label'] as String,
                                      'value': m['value'],
                                    },
                                  )
                                  .toList();

                              return _buildQuickAccessCard(
                                context,
                                l10n.finance,
                                Icons.account_balance_wallet_rounded,
                                HealthMetricColors.homePillarAccent('finance'),
                                metrics: visibleMetrics,
                                route: '/finance',
                                scoreData:
                                    scoreBlock.score.financialGlobalScore,
                              );
                            }),
                            Watch((context) {
                              final moodLog = mindBlock.latestMoodLog.value;
                              final socialScore =
                                  scoreBlock.score.socialGlobalScore;
                              final focusMinutes =
                                  healthBlock.todayFocusMinutes.value;
                              final activeMindFocus = context
                                  .read<SocialBlock>()
                                  .activeFocusTrend
                                  .value;
                              dynamic moodDisplay = l10n.mood_no_data;
                              if (moodLog != null) {
                                moodDisplay = Row(
                                  children: [
                                    _buildMoodIcon(context, moodLog.moodScore),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: AutoSizeText(
                                        moodLog.moodScore == 1
                                            ? l10n.mood_awful
                                            : moodLog.moodScore == 2
                                            ? l10n.mood_bad
                                            : moodLog.moodScore == 3
                                            ? l10n.mood_meh
                                            : moodLog.moodScore == 4
                                            ? l10n.mood_good
                                            : l10n.mood_rad,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        minFontSize: 8,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final allMetrics = [
                                {
                                  'label': l10n.mind_current_mood,
                                  'value': moodDisplay,
                                  'visible': configBlock.showIndexMood.value,
                                },
                                {
                                  'label': l10n.mind_day_average,
                                  'value': socialScore.toStringAsFixed(1),
                                  'visible': true,
                                },
                                {
                                  'label': l10n.mind_latest_log,
                                  'value': moodLog != null
                                      ? _formatRelativeTime(moodLog.createdAt)
                                      : l10n.mind_never,
                                  'visible': true,
                                },
                                {
                                  'label': l10n.mind_focus_current,
                                  'value': activeMindFocus != null
                                      ? Row(
                                          children: [
                                            Icon(
                                              MindFocusTrend.resolveIcon(
                                                activeMindFocus.iconCodePoint,
                                              ),
                                              size: 14,
                                              color: activeMindFocus.color,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: AutoSizeText(
                                                activeMindFocus.name,
                                                style: TextStyle(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                maxLines: 2,
                                                minFontSize: 8,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      : l10n.mind_focus_none,
                                  'visible': true,
                                },
                                {
                                  'label': l10n.home_index_focus,
                                  'value': '${focusMinutes}m',
                                  'visible': configBlock.showIndexFocus.value,
                                },
                                {
                                  'label': l10n.mind_latest_note,
                                  'value': moodLog?.note ?? l10n.mood_no_data,
                                  'visible':
                                      configBlock.showIndexMoodNote.value,
                                },
                              ];

                              final visibleMetrics = allMetrics
                                  .where((m) => m['visible'] == true)
                                  .map(
                                    (m) => {
                                      'label': m['label'] as String,
                                      'value': m['value'],
                                    },
                                  )
                                  .toList();

                              return _buildQuickAccessCard(
                                context,
                                l10n.social,
                                Icons.psychology_rounded,
                                HealthMetricColors.homePillarAccent('mind'),
                                metrics: visibleMetrics,
                                route: '/social',
                                scoreData: socialScore,
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
                                final allMetrics = [
                                  {
                                    'label': l10n.home_projects_done,
                                    'value': '$projectsDone',
                                    'visible': true,
                                  },
                                  {
                                    'label': l10n.home_projects_active,
                                    'value': '$projectsRemaining',
                                    'visible': true,
                                  },
                                  {
                                    'label': l10n.home_tasks_done,
                                    'value': '$tasksDone',
                                    'visible':
                                        configBlock.showIndexProjects.value,
                                  },
                                  {
                                    'label': l10n.home_tasks_active,
                                    'value': '$tasksRemaining',
                                    'visible':
                                        configBlock.showIndexProjects.value,
                                  },
                                  {
                                    'label': l10n.home_index_total,
                                    'value': '${allProjects.length}',
                                    'visible': true,
                                  },
                                ];

                              final visibleMetrics = allMetrics
                                  .where((m) => m['visible'] == true)
                                  .map(
                                    (m) => {
                                      'label': m['label'] as String,
                                      'value': m['value'],
                                    },
                                  )
                                  .toList();

                              return _buildQuickAccessCard(
                                context,
                                l10n.projects,
                                Icons.rocket_launch_rounded,
                                HealthMetricColors.homePillarAccent('projects'),
                                metrics: visibleMetrics,
                                route: '/projects',
                                scoreData: scoreBlock.score.careerGlobalScore,
                              );
                            }),
                          ],
                        ),
                      ),

                      // const SizedBox(height: 20),
                      // const DailyFinanceReportReminderCard(),
                      const SizedBox(height: 12),

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
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  final configBlock = context
                                      .read<ConfigBlock>();
                                  HomePageSettings.show(context, configBlock);
                                },
                                icon: Icon(
                                  Icons.settings_suggest_rounded,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                  size: 20,
                                ),
                                tooltip: "Settings",
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
                        ],
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: sizeOfWidget,
                        child: Watch((context) {
                          final configBlock = context.read<ConfigBlock>();
                          final envBlock = context.read<EnvironmentalBlock>();
                          final externalWidgets = externalWidgetBlock
                              .listExternalWidgets
                              .value;
                          final showAqi = configBlock.showAqi.value;
                          final showWeather = configBlock.showWeather.value;

                          // Build the temporary list of plugin widgets
                          final List<Widget> pluginItems = [];

                          // 1. Environmental Data if enabled
                          if (showAqi) {
                            pluginItems.add(
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: AQIPluginCard(envBlock: envBlock),
                              ),
                            );
                          }
                          if (showWeather) {
                            pluginItems.add(
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: WeatherPluginCard(envBlock: envBlock),
                              ),
                            );
                          }

                          pluginItems.add(
                            const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: IntegrationHubPluginCard(),
                            ),
                          );

                          // 2. Internal plugins — phones only; macOS/web sidebar covers these.
                          if (!WorkspaceSidebarLayout.useHomeWorkspace(context)) {
                            for (final pluginDef in AvailablePlugins.internal) {
                              pluginItems.add(
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: SizedBox(
                                    width: sizeOfWidget,
                                    height: sizeOfWidget,
                                    child: _buildInternalWidget(
                                      context,
                                      pluginDef.createInstance(),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }

                          // 3. External Widgets
                          for (final ext in externalWidgets) {
                            pluginItems.add(
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: sizeOfWidget,
                                  child: _buildExternalWidget(context, ext),
                                ),
                              ),
                            );
                          }

                          final totalItemCount = pluginItems.length + 1;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(right: 20),
                            itemCount: totalItemCount,
                            itemBuilder: (context, index) {
                              // Show Add Button at the END
                              if (index == totalItemCount - 1) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: SizedBox(
                                    width: sizeOfWidget,
                                    height: sizeOfWidget,
                                    child: _buildAddButton(context),
                                  ),
                                );
                              }
                              return pluginItems[index];
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      // --- SECTION: QUOTES ---
                      const SizedBox(height: 40),
                    ],
                  ),
                );

              final bodyChild = WorkspaceSidebarLayout.useHomeWorkspace(context)
                  ? WorkspaceSidebarLayout(
                      onPluginTap: () => _showAddPluginDialog(context),
                      child: scrollBody,
                    )
                  : scrollBody;

              return SwipeablePage(
                direction: SwipeablePageDirection.leftToRight,
                onSwipe: () => context.pop(),
                child: bodyChild,
              );
            }),
          ),
        ),
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
          label: Text(
            AppLocalizations.of(context)!.analysis,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// L1 glass + --ice-health wash (duylongart_glass_ui.md). Health pillar only.
  static const Color _iceHealth = HealthMetricColors.pillarGreen;

  BoxDecoration _healthL1IceDecoration() {
    const glassBg = Color.fromRGBO(255, 255, 255, 0.03);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _iceHealth.withValues(alpha: 0.2),
          glassBg,
          glassBg,
        ],
        stops: const [0.0, 0.35, 1.0],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF000f1e).withValues(alpha: 0.37),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: _iceHealth.withValues(alpha: 0.12),
          blurRadius: 48,
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    required List<Map<String, dynamic>> metrics,
    required String route,
    required double scoreData,
    bool useL1IceGlass = false,
  }) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final isLaptop = defaultTargetPlatform == TargetPlatform.macOS;
    // Icon badge: size set directly on the Container (not padding-driven).
    final double iconContainerSize = isPhone
        ? 50.0
        : (isLaptop ? 40.0 : 52.0);
    final double headerIconSize = isPhone
        ? 26.0
        : (isLaptop ? 22.0 : 25.0);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iceEtchedPrimary = Colors.white.withValues(alpha: 0.95);
    final iceEtchedSecondary =
        const Color.fromRGBO(173, 216, 230, 0.5);
    final titleColor =
        useL1IceGlass ? iceEtchedPrimary : colorScheme.onSurface;
    final labelColor = useL1IceGlass
        ? iceEtchedSecondary
        : colorScheme.onSurface.withValues(alpha: isDark ? 0.5 : 0.72);
    final valueColor = useL1IceGlass
        ? iceEtchedPrimary
        : colorScheme.onSurface.withValues(alpha: isDark ? 0.9 : 0.95);
    final pillarGradientTop = isDark ? 0.18 : 0.36;
    final pillarGradientMid = isDark ? 0.08 : 0.20;
    final pillarGradientBottom = isDark ? 0.02 : 0.08;
    final iconBadgeAlpha = isDark ? 0.1 : 0.22;
    final glowAlpha = isDark ? 0.1 : 0.18;

    final cardBody = InkWell(
          onTap: () => context.push(route),
          child: Stack(
            children: [
              if (useL1IceGlass)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
              if (!useL1IceGlass) ...[
                // Glassmorphism Background (non–ice pillars)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: pillarGradientTop),
                          color.withValues(alpha: pillarGradientMid),
                          color.withValues(alpha: pillarGradientBottom),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -25,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: glowAlpha),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
              Padding(
                padding: EdgeInsets.all(isPhone ? 12.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: iconContainerSize,
                          height: iconContainerSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: iconBadgeAlpha),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: headerIconSize,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          child: Column(
                            key: ValueKey(title),
                            children: [
                              AutoSizeText(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: isPhone ? 18 : 22,
                                  color: titleColor,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                              ),
                              // const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 2-column metrics — width from layout so tiles never bleed together.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final spacing = isPhone ? 8.0 : 12.0;
                        final maxW = constraints.maxWidth;
                        final tileW = maxW.isFinite
                            ? ((maxW - spacing) / 2).clamp(72.0, 160.0)
                            : (isPhone ? 88.0 : 100.0);
                        return Wrap(
                          spacing: spacing,
                          runSpacing: isPhone ? 6 : 8,
                          children: metrics.map((m) {
                            final valueChild =
                                m['value'] is Widget
                                    ? m['value'] as Widget
                                    : AutoSizeText(
                                      m['value']?.toString() ?? '',
                                      style: TextStyle(
                                        color: valueColor,
                                        fontSize: isPhone ? 11 : 13,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      minFontSize: 8,
                                      overflow: TextOverflow.ellipsis,
                                    );
                            return SizedBox(
                              width: tileW,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: tileW,
                                    child: valueChild,
                                  ),
                                  AutoSizeText(
                                    m['label']?.toString() ?? '',
                                    style: TextStyle(
                                      color: labelColor,
                                      fontSize: isPhone ? 9 : 10,
                                      fontWeight: FontWeight.w600,
                                      height: 1.1,
                                    ),
                                    maxLines: 2,
                                    minFontSize: 7,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    final width = isPhone ? 210.0 : (isLaptop ? 240.0 : 280.0);
    const margin = EdgeInsets.only(right: 12);

    if (useL1IceGlass) {
      return Container(
        width: width,
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: _healthL1IceDecoration(),
              child: cardBody,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      margin: margin,
      child: Card(
        elevation: isDark ? 0 : 1,
        color: isDark ? colorScheme.onPrimary : colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: color.withValues(alpha: isDark ? 0.12 : 0.32),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: cardBody,
      ),
    );
  }

  Widget _buildInternalWidget(
    BuildContext context,
    InternalWidgetProtocol? widgetData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizeOfWidget = UIConstants.getSizeOfWidget(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.8)
        : colorScheme.onSurface.withValues(alpha: 0.85);
    final labelColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.7)
        : colorScheme.onSurface.withValues(alpha: 0.72);

    if (widgetData == null) {
      return InkWell(
        onTap: () => _showAddPluginDialog(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: sizeOfWidget,
          height: sizeOfWidget,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.add_rounded,
            color: colorScheme.primary.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
      );
    }

    final item = Container(
      width: sizeOfWidget,
      height: sizeOfWidget,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.outline.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle gradient for depth
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.05),
                      colorScheme.primary.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widgetData.icon,
                    color: iconColor,
                    size: sizeOfWidget * 0.3,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: AutoSizeText(
                      widgetData.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: labelColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? colorScheme.secondary.withValues(alpha: 0.8)
        : colorScheme.onSurface.withValues(alpha: 0.85);
    final labelColor = isDark
        ? colorScheme.secondary.withValues(alpha: 0.7)
        : colorScheme.onSurface.withValues(alpha: 0.72);
    final String fullUrl = GoogleCalendarPlugin.resolveLaunchUrl(
      protocol: data.protocol ?? 'https',
      host: data.host ?? '',
      path: data.url ?? '',
    );

    final sizeOfWidget = UIConstants.getSizeOfWidget(context);
    final item = Container(
      width: sizeOfWidget,
      height: sizeOfWidget,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? colorScheme.secondary.withValues(alpha: 0.1)
              : colorScheme.outline.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.secondary.withValues(alpha: 0.05),
                      colorScheme.secondary.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: iconColor,
                    size: sizeOfWidget * 0.3,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: AutoSizeText(
                      (data.name ?? 'Untitled').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: labelColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  WidgetNavigatorAction.navigateExternalUrl(
                    context,
                    fullUrl,
                    title: data.name ?? 'Web',
                  );
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
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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

  /// Outdoor temperature & AQI from [EnvironmentalBlock]; opens `/health/temperature`.
  Widget _buildEnvironmentalSummary(BuildContext context) {
    final configBlock = context.read<ConfigBlock>();
    final envBlock = context.read<EnvironmentalBlock>();

    return Watch((context) {
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final tempTint = colorScheme.primary.withValues(alpha: isDark ? 0.95 : 0.85);
      final aqiTint = colorScheme.tertiary.withValues(alpha: isDark ? 0.95 : 0.85);
      final containerColor = Colors.transparent;
      final separatorColor = colorScheme.onSurface.withValues(alpha: 0.18);
      final conditionColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.9);

      final showAqi = configBlock.showAqi.value;
      final showWeather = configBlock.showWeather.value;

      if (!showAqi && !showWeather) return const SizedBox.shrink();

      final envData = envBlock.currentData.watch(context);
      final loading = envBlock.isLoading.watch(context);
      final l10n = AppLocalizations.of(context)!;

      final tempLabel = loading
          ? '…'
          : (envData != null
              ? '${envData.temperature.toStringAsFixed(0)}°C'
              : '--°C');
      final aqiLabel = loading
          ? '…'
          : (envData != null
              ? '${l10n.health_aqi_unit} ${envData.aqi}'
              : '${l10n.health_aqi_unit} --');

      final bool showCondition =
          showWeather &&
          envData != null &&
          !loading &&
          envData.weatherDescription.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => context.push('/health/temperature'),
              splashColor: EntryLandscapePalette.steelBlue.withValues(
                alpha: 0.2,
              ),
              highlightColor: EntryLandscapePalette.midnightNavy.withValues(
                alpha: 0.15,
              ),
              child: Ink(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      // Make the header truly transparent: no blur, no frosted fill,
                      // no outline, and no drop shadow.
                      color: containerColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                            if (showWeather) ...[
                              Icon(
                                Icons.thermostat_rounded,
                                color: tempTint,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tempLabel,
                                style: TextStyle(
                                  color: tempTint,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                            if (showAqi && showWeather)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  width: 1,
                                  height: 22,
                                  color: separatorColor,
                                ),
                              ),
                            if (showAqi) ...[
                              Icon(
                                Icons.waves_rounded,
                                size: 20,
                                color: envData != null
                                    ? _getAQIColor(envData.aqi)
                                    : aqiTint,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                aqiLabel,
                                style: TextStyle(
                                  color: envData != null
                                      ? _getAQIColor(envData.aqi)
                                      : aqiTint,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.15,
                                ),
                              ),
                            ],
                            if (showCondition) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Container(
                                  width: 1,
                                  height: 22,
                                  color: separatorColor.withValues(alpha: 0.78),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    envData.weatherDescription,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: conditionColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Color _getAQIColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow[700]!;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  Widget _buildMoodIcon(BuildContext context, int score) {
    final Color color;
    final IconData icon;

    switch (score) {
      case 1:
        color = const Color(0xFF8000FF);
        icon = Icons.sentiment_very_dissatisfied_rounded;
        break;
      case 2:
        color = const Color(0xFF2C3E50);
        icon = Icons.sentiment_dissatisfied_rounded;
        break;
      case 3:
        color = const Color(0xFFE0E0E0);
        icon = Icons.sentiment_neutral_rounded;
        break;
      case 4:
        color = const Color(0xFF00FF88);
        icon = Icons.sentiment_satisfied_alt_rounded;
        break;
      case 5:
        color = const Color(0xFF00FFFF);
        icon = Icons.sentiment_very_satisfied_rounded;
        break;
      default:
        color = const Color(0xFFE0E0E0);
        icon = Icons.sentiment_neutral_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: color),
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
                color: colorScheme.primary.withValues(alpha: 0.5),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
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
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.format_quote_rounded,
                color: colorScheme.primary.withValues(alpha: 0.5),
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
    final sizeOfWidget = UIConstants.getSizeOfWidget(context);

    return InkWell(
      onTap: () => _showAddPluginDialog(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: sizeOfWidget,
        height: sizeOfWidget,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                color: colorScheme.primary.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.add.toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
