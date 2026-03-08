import 'dart:async';
import 'package:drift/drift.dart' show Value;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DatabaseAgent.dart'
    as DatabaseAgent;
import 'package:ice_gate/initial_layer/CoreLogics/CustomAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PasskeyAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/BiometricAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SecureStorageService.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ContentBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/WidgetSettingsBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/QuoteBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/data_layer/DataSources/cloud_database/PowerSyncConnector.dart';
import 'package:ice_gate/initial_layer/FocusAudioHandler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:powersync/powersync.dart' hide Column;
import 'package:ice_gate/data_layer/DataSources/cloud_database/powersync_schema.dart'
    as ps_schema;
import 'package:path_provider/path_provider.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:path/path.dart' as p;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_gate/security_routing_layer/Routing/url_route/InternalRoute.dart';
import 'package:ice_gate/ui_layer/health_page/services/HealthService.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class DataLayer extends StatefulWidget {
  final Widget childWidget;

  const DataLayer({super.key, required this.childWidget});

  @override
  State<DataLayer> createState() => _DataLayerState();
}

class _DataLayerState extends State<DataLayer> with WidgetsBindingObserver {
  late AppDatabase database;
  late LocalNotificationService notificationService;
  late FocusAudioHandler audioHandler;

  late PersonBlock personBlock;
  late AuthBlock authBlock;
  late ObjectDatabaseBlock objectDatabaseBlock;
  late ScoreBlock scoreBlock;
  late WidgetManagerBlock widgetManagerBlock;
  late GrowthBlock growthBlock;
  late FocusBlock focusBlock;
  late HealthBlock healthBlock;
  late ProjectBlock projectBlock;
  late FinanceBlock financeBlock;
  late ContentBlock contentBlock;
  late WidgetSettingsBlock widgetSettingsBlock;
  late InternalWidgetBlock internalWidgetBlock;
  late ExternalWidgetBlock externalWidgetBlock;
  late QuoteBlock quoteBlock;
  late QuestBlock questBlock;
  DateTime? _lastPausedTime;

  Timer? _healthSyncTimer;

  late HealthMetricsDAO healthMetricsDAO;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isAudioInitialized = false;
  String? _errorMessage;
  final List<EffectCleanup> _effectCleanups = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startHealthSync();
    _initializeData();
  }

  void _startHealthSync() {
    _syncHealthData();
    _healthSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncHealthData();
    });
  }

  Future<void> _syncHealthData() async {
    if (!_isInitialized || _hasError) {
      debugPrint(
        "DataLayer: Skipping health sync (not initialized or has error)",
      );
      return;
    }
    try {
      debugPrint("DataLayer: Starting multi-day health sync...");
      final now = DateTime.now();
      for (int i = 0; i < 3; i++) {
        final targetDate = now.subtract(Duration(days: i));
        await _syncHealthDataForDay(targetDate);
      }
      debugPrint("DataLayer: Multi-day health sync completed.");
    } catch (e) {
      debugPrint("DataLayer: Error in _syncHealthData: $e");
    }
  }

  Future<void> _syncHealthDataForDay(DateTime date) async {
    if (!_isInitialized || _hasError) return;
    final isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    final steps = await HealthService.fetchStepsForDay(date);
    final calories = await HealthService.fetchCaloriesForDay(date);

    if (steps == 0 && calories == 0) {
      final isDesktop =
          kIsWeb ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows;

      if (isDesktop) return;
    }

    if (isToday) {
      final sleepHours = await HealthService.fetchSleepData();
      final heartRate = await HealthService.fetchLatestHeartRate();

      if (mounted && _isInitialized) {
        healthBlock.updateSteps(steps);
        healthBlock.updateSleep(sleepHours);
        healthBlock.updateHeartRate(heartRate);
        healthBlock.updateCalories(calories.toInt());
      }
    } else {
      await database.healthMetricsDAO.insertOrUpdateMetrics(
        HealthMetricsTableCompanion.insert(
          id: IDGen.generateDeterministicUuid(
            healthBlock.personId,
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
          ),
          personID: Value(healthBlock.personId),
          date: DateTime(date.year, date.month, date.day, 12),
          steps: Value(steps),
          caloriesBurned: Value(calories.toInt()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _initializeData() async {
    try {
      debugPrint("🚀 [Boot] Step 1: Initialize Supabase...");
      await Supabase.initialize(
        url: 'https://wthislkepfufkbgiqegs.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0aGlzbGtlcGZ1ZmtiZ2lxZWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0ODk2MjEsImV4cCI6MjA4NzA2NTYyMX0.EaYqJVIni8cSh0BCDZH1hQxqy-pdPj8o2aSG6dF7z-8',
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      debugPrint("🚀 [Boot] Step 2: Initialize PowerSync...");
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'powersync30.db');
      final powersync = PowerSyncDatabase(
        schema: ps_schema.schema,
        path: dbPath,
      );
      await powersync.initialize();
      database = AppDatabase.powersync(powersync);

      debugPrint("🚀 [Boot] Step 3: Initialize Notifications...");
      notificationService = LocalNotificationService();
      await notificationService.init(database);

      debugPrint("🚀 [Boot] Step 4: Initialize Audio...");
      try {
        if (!_isAudioInitialized) {
          audioHandler = await AudioService.init(
            builder: () => FocusAudioHandler(),
            config: const AudioServiceConfig(
              androidNotificationChannelId:
                  'duylong.art.ice_gate.channel.audio',
              androidNotificationChannelName: 'Focus Audio Playback',
              androidNotificationOngoing: true,
            ),
          );
          _isAudioInitialized = true;
        }
      } catch (e) {
        debugPrint("DataLayer: AudioService already running or failed: $e");
      }

      debugPrint("🚀 [Boot] Step 5: Initializing Core Blocks...");
      final authService = CustomAuthService(
        baseUrl: "https://backend.duylong.art",
      );
      final passkeyService = PasskeyAuthService();
      final biometricService = BiometricAuthService();
      final secureStorage = SecureStorageService();

      personBlock = PersonBlock(
        authService: authService,
        personDao: database.personManagementDAO,
      );
      authBlock = AuthBlock(
        authService: authService,
        sessionDao: database.sessionDAO,
        passkeyService: passkeyService,
        biometricService: biometricService,
        secureStorage: secureStorage,
        personDao: database.personManagementDAO,
      );
      healthMetricsDAO = database.healthMetricsDAO;

      healthBlock = HealthBlock(
        personId: "",
        healthDao: database.healthMetricsDAO,
        healthLogsDao: database.healthLogsDAO,
        healthMealDao: database.healthMealDAO,
      );
      growthBlock = GrowthBlock();
      scoreBlock = ScoreBlock();
      projectBlock = ProjectBlock();
      internalWidgetBlock = InternalWidgetBlock();
      externalWidgetBlock = ExternalWidgetBlock();
      financeBlock = FinanceBlock();
      quoteBlock = QuoteBlock();
      questBlock = QuestBlock();
      contentBlock = ContentBlock();
      widgetSettingsBlock = WidgetSettingsBlock();
      objectDatabaseBlock = ObjectDatabaseBlock();

      focusBlock = FocusBlock(
        focusSessionDao: database.focusSessionsDAO,
        healthLogsDao: database.healthLogsDAO,
        healthMetricsDao: database.healthMetricsDAO,
        personId: "",
        audioHandler: audioHandler,
        notificationService: notificationService,
      );

      _effectCleanups.add(
        effect(() {
          try {
            final profile = personBlock.information.value.profiles;
            final personId = profile.id;

            if (personId != null && personId.isNotEmpty) {
              untracked(() {
                print(
                  "👤 [DataLayer] PersonID resolved to $personId. Re-initializing dependent blocks...",
                );
                healthBlock.personId = personId;
                Future.microtask(() => healthBlock.init());
                _syncHealthData();

                growthBlock.init(database.growthDAO, personId);
                projectBlock.init(database.projectsDAO, personId);
                financeBlock.init(database.financeDAO, personId);
                questBlock.init(database.questDAO, personId);
                contentBlock.init(database.aiAnalysisDAO, personId);
                widgetSettingsBlock.init(database.widgetDAO, personId);

                scoreBlock.init(
                  database.scoreDAO,
                  database.personManagementDAO,
                  database.financeDAO,
                  healthBlock,
                  database.healthMealDAO,
                  database.metricsDAO,
                  personId,
                  tenantID: personBlock.information.value.profiles.tenantId,
                );

                focusBlock.personId = personId;
                focusBlock.fetchDailyStats();
                notificationService.syncAllNotifications(personId);

                internalWidgetBlock.refreshBlock(
                  database.internalWidgetsDAO,
                  personId,
                  'home',
                );
                externalWidgetBlock.refreshBlock(
                  database.externalWidgetsDAO,
                  personId,
                );
              });
            }
          } catch (e) {
            debugPrint("DataLayer: Error in personId effect: $e");
          }
        }),
      );

      focusBlock
        ..growthBlock = growthBlock
        ..scoreBlock = scoreBlock;
      await focusBlock.init();

      widgetManagerBlock = WidgetManagerBlock(
        widgetDao: database.widgetDAO,
        personIdSignal: computed(
          () => personBlock.information.value.profiles.id,
        ),
      );

      debugPrint("🚀 [Boot] Step 6: Checking Auth Session...");
      if (mounted) {
        authBlock.checkSession(context);
      }

      debugPrint("🚀 [Boot] Step 7: Starting Monitoring...");
      await DatabaseAgent.monitoring(database);

      debugPrint("🚀 [Boot] Step 8: Finalizing Initialization...");
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _syncHealthData();
      }
      debugPrint("🚀 [Boot] ✅ initializationData sequence COMPLETED.");

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        final ps = database.powerSync;

        print(
          "🔑 [DataLayer] Supabase Auth Change: Event=$event, HasSession=${session != null}",
        );

        if (session != null) {
          Future.microtask(() {
            batch(() {
              authBlock.jwt.value = session.accessToken;
              authBlock.username.value = session.user.email ?? "Google User";
              authBlock.persistSession(
                session.accessToken,
                session.user.email ?? "Google User",
              );

              if (authBlock.status.value != AuthStatus.authenticated) {
                authBlock.status.value = AuthStatus.authenticated;
              }
            });
          });

          if (ps != null) {
            authBlock.syncUserWithSupabase(session.user);
            authBlock.fetchUser();
          }
        }
      });

      _effectCleanups.add(
        effect(() {
          final token = authBlock.jwt.value;
          final status = authBlock.status.value;

          if (token != null &&
              token.isNotEmpty &&
              status == AuthStatus.authenticated) {
            final ps = database.powerSync;

            if (ps != null) {
              final connector = MyPowerSyncConnector(
                authBlock: authBlock,
                powerSyncUrl:
                    "https://69967e7cd17eab7f63d96041.powersync.journeyapps.com",
                baseUrl: "https://backend.duylong.art",
              );
              ps.connect(connector: connector);
            }

            personBlock.fetchInitialData(token).then((_) {
              objectDatabaseBlock.updateUrlOfUser(personBlock);
            });
          }
        }),
      );

      _effectCleanups.add(
        effect(() {
          try {
            authStatusNotifier.value = authBlock.status.value;
          } catch (e) {
            debugPrint("DataLayer: Error in authStatus effect: $e");
          }
        }),
      );
    } catch (e, stack) {
      debugPrint("DataLayer: Initialization CRITICAL error: $e");
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
      debugPrint("DataLayer: App paused at $_lastPausedTime");
    } else if (state == AppLifecycleState.resumed) {
      debugPrint("DataLayer: App resumed");
      if (_lastPausedTime != null) {
        final diff = DateTime.now().difference(_lastPausedTime!);
        debugPrint("DataLayer: App was paused for ${diff.inSeconds} seconds");
        if (diff.inHours >= 2) {
          authBlock.showWelcomeBack.value = true;
        }
        _syncHealthData();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthSyncTimer?.cancel();
    for (final cleanup in _effectCleanups) {
      cleanup();
    }
    _effectCleanups.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  "Critical Initialization Error",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_errorMessage ?? "Unknown Error"),
                ),
                ElevatedButton(
                  onPressed: () => _initializeData(),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<LocalNotificationService>.value(value: notificationService),
        Provider<FocusAudioHandler>.value(value: audioHandler),
        Provider<AppDatabase>.value(value: database),
        Provider<ExternalWidgetsDAO>.value(value: database.externalWidgetsDAO),
        Provider<ProjectNoteDAO>.value(value: database.projectNoteDAO),
        Provider<InternalWidgetsDAO>.value(value: database.internalWidgetsDAO),
        StreamProvider<List<ExternalWidgetData>>(
          create: (_) => database.externalWidgetsDAO.watchAllWidgets(
            personBlock.information.value.profiles.id ?? "",
          ),
          initialData: const [],
          catchError: (_, __) => const [],
        ),
        StreamProvider<List<InternalWidgetData>>(
          create: (_) => database.internalWidgetsDAO.watchAllWidgets(
            personBlock.information.value.profiles.id ?? "",
          ),
          initialData: const [],
          catchError: (_, __) => const [],
        ),
        Provider<PersonManagementDAO>.value(
          value: database.personManagementDAO,
        ),
        Provider<FinanceDAO>.value(value: database.financeDAO),
        Provider<GrowthDAO>.value(value: database.growthDAO),
        Provider<AiAnalysisDAO>.value(value: database.aiAnalysisDAO),
        Provider<WidgetDAO>.value(value: database.widgetDAO),
        Provider<HealthMetricsDAO>.value(value: database.healthMetricsDAO),
        Provider<ProjectsDAO>.value(value: database.projectsDAO),
        Provider<ScoreDAO>.value(value: database.scoreDAO),
        Provider<CustomNotificationDAO>.value(
          value: database.customNotificationDAO,
        ),
        Provider<PersonDAO>.value(value: database.personDAO),
        Provider<QuoteDAO>.value(value: database.quoteDAO),
        Provider<HealthLogsDAO>.value(value: database.healthLogsDAO),
        Provider<QuestDAO>.value(value: database.questDAO),
        Provider<HealthMealDAO>.value(value: database.healthMealDAO),
        Provider<PersonBlock>.value(value: personBlock),
        Provider<AuthBlock>.value(value: authBlock),
        Provider<ObjectDatabaseBlock>.value(value: objectDatabaseBlock),
        Provider<FinanceBlock>.value(value: financeBlock),
        Provider<GrowthBlock>.value(value: growthBlock),
        Provider<ContentBlock>.value(value: contentBlock),
        Provider<WidgetSettingsBlock>.value(value: widgetSettingsBlock),
        Provider<ScoreBlock>.value(value: scoreBlock),
        Provider<ProjectBlock>.value(value: projectBlock),
        Provider<InternalWidgetBlock>.value(value: internalWidgetBlock),
        Provider<ExternalWidgetBlock>.value(value: externalWidgetBlock),
        Provider<QuoteBlock>.value(value: quoteBlock),
        Provider<QuestBlock>.value(value: questBlock),
        Provider<WidgetManagerBlock>.value(value: widgetManagerBlock),
        Provider<FocusBlock>.value(value: focusBlock),
        Provider<HealthBlock>.value(value: healthBlock),
      ],
      child: widget.childWidget,
    );
  }
}
