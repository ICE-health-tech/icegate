import 'dart:async';
import 'package:drift/drift.dart' show Value;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/DatabaseAgent.dart'
    as DatabaseAgent;
import 'package:ice_shield/initial_layer/CoreLogics/CustomAuthService.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PasskeyAuthService.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/ContentBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/WidgetSettingsBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Home/QuoteBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_shield/data_layer/DataSources/cloud_database/PowerSyncConnector.dart'; // Add this back
import 'package:ice_shield/initial_layer/FocusAudioHandler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:powersync/powersync.dart' hide Column;
import 'package:ice_shield/data_layer/DataSources/cloud_database/powersync_schema.dart'
    as ps_schema;
import 'package:path_provider/path_provider.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:path/path.dart' as p;
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_shield/security_routing_layer/Routing/url_route/InternalRoute.dart';
import 'package:ice_shield/ui_layer/health_page/services/HealthService.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

// Note: We are assuming AppDatabase and ExternalWidgetsDAO are defined in this file.
// We'll use dynamic type hints until we know the exact import path for those types.

// To make this runnable, I will use AppDatabase as the type, but if you need
// AppDatabase, you must ensure the import matches the actual file path.

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
  late HealthMealDAO healthMealDao;
  int currentSteps = 0;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isAudioInitialized = false;
  String? _errorMessage;
  final List<EffectCleanup> _effectCleanups = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Keep initState() synchronous.
    // Start periodic HealthKit sync
    _startHealthSync();

    _initializeData();
  }

  void _startHealthSync() {
    // Initial fetch
    _syncHealthData();

    // Periodic sync every 1 minute
    _healthSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncHealthData();
    });
  }

  Future<void> _syncHealthData() async {
    try {
      debugPrint("DataLayer: Starting multi-day health sync...");
      final now = DateTime.now();

      // Sync last 3 days to catch any missed boundary data
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
    final isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    // Sync Steps
    final steps = await HealthService.fetchStepsForDay(date);
    debugPrint("DataLayer: HealthService returned $steps steps for $date");

    // Sync Calories
    final calories = await HealthService.fetchCaloriesForDay(date);
    debugPrint("DataLayer: HealthService returned $calories kcal for $date");

    // Guard: On macOS/Web/Linux/Windows, HealthService returns 0 because it can't fetch.
    // We should NOT overwrite existing data with 0 if it's likely just a platform limitation.
    if (steps == 0 && calories == 0) {
      final isDesktop =
          kIsWeb ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows;

      if (isDesktop) {
        debugPrint(
          "DataLayer: Skipping sync for $date on ${defaultTargetPlatform.name} (0 values detected)",
        );
        return;
      }
    }

    // For historical days, we save directly to DAO to avoid HealthBlock logic overhead
    // For today, we use HealthBlock to ensure reactive signals stay in sync
    if (isToday) {
      debugPrint("DataLayer: [iPhone Sync] Updating HealthBlock for TODAY...");
      // Sync Sleep (usually only relevant for today/yesterday context)
      final sleepHours = await HealthService.fetchSleepData();
      // Sync Heart Rate (latest only)
      final heartRate = await HealthService.fetchLatestHeartRate();

      if (mounted && _isInitialized) {
        // Use direct signal access to avoid lint issues if analyzer is slow
        healthBlock.updateSteps(steps);
        healthBlock.updateSleep(sleepHours);
        healthBlock.updateHeartRate(heartRate);
        healthBlock.updateCalories(calories.toInt());
      }
    } else {
      debugPrint(
        "DataLayer: [iPhone Sync] Saving HISTORICAL data for $date to DB...",
      );
      // Save historical data directly to DB using insertOrUpdateMetrics which handles IDs properly
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
      // 1. Initialize Supabase
      await Supabase.initialize(
        url: 'https://wthislkepfufkbgiqegs.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0aGlzbGtlcGZ1ZmtiZ2lxZWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0ODk2MjEsImV4cCI6MjA4NzA2NTYyMX0.EaYqJVIni8cSh0BCDZH1hQxqy-pdPj8o2aSG6dF7z-8',
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      // 2. Initialize PowerSync and Database
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, 'powersync29.db');
      final powersync = PowerSyncDatabase(
        schema: ps_schema.schema,
        path: dbPath,
      );
      await powersync.initialize();
      database = AppDatabase.powersync(powersync);

      // 3. Initialize Notifications
      notificationService = LocalNotificationService();
      await notificationService.init(database);

      // 4. Initialize Audio
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

      // 5. Initialize Services and Blocks
      var authService = CustomAuthService(baseUrl: "http://localhost"); // Dummy
      var passkeyService = PasskeyAuthService();

      personBlock = PersonBlock(
        authService: authService,
        personDao: database.personManagementDAO,
      );
      authBlock = AuthBlock(
        authService: authService,
        sessionDao: database.sessionDAO,
        passkeyService: passkeyService,
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
      growthBlock.init(database.growthDAO, "");
      scoreBlock = ScoreBlock();
      projectBlock = ProjectBlock();
      projectBlock.init(database.projectsDAO, "");

      internalWidgetBlock = InternalWidgetBlock();
      externalWidgetBlock = ExternalWidgetBlock();

      financeBlock = FinanceBlock();
      financeBlock.init(database.financeDAO, "");

      quoteBlock = QuoteBlock();
      quoteBlock.init(database.quoteDAO);

      questBlock = QuestBlock();
      questBlock.init(database.questDAO, "");

      contentBlock = ContentBlock();
      contentBlock.init(database.aiAnalysisDAO, "");

      widgetSettingsBlock = WidgetSettingsBlock();
      widgetSettingsBlock.init(database.widgetDAO, "");

      focusBlock = FocusBlock(
        focusSessionDao: database.focusSessionsDAO,
        healthLogsDao: database.healthLogsDAO,
        healthMetricsDao: database.healthMetricsDAO,
        personId: "",
        audioHandler: audioHandler,
        notificationService: notificationService,
      );
      objectDatabaseBlock = ObjectDatabaseBlock();

      // 5. Initialize Services and Blocks
      healthBlock.init();
      // growthBlock.init - Moved to dynamic effect below

      scoreBlock.init(
        database.scoreDAO,
        database.personManagementDAO,
        database.financeDAO,
        healthBlock,
        database.healthMealDAO,
        "", // Initial fallback
      );
      print("DUYLONG: personBlock: $personBlock");
      // --- NEW: Dynamic Person ID Re-initialization ---
      _effectCleanups.add(
        effect(() {
          // Track the profile and personId
          final profile = personBlock.information.value.profiles;
          final personId = profile.id;

          if (personId != null && personId.isNotEmpty) {
            untracked(() {
              print(
                "👤 [DataLayer] PersonID resolved to $personId. Re-initializing dependent blocks...",
              );

              // Re-initialize blocks with the correct identity
              healthBlock.personId = personId;
              Future.microtask(() => healthBlock.init());

              // Trigger immediate health sync for the new person
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
                personId,
              );

              focusBlock.personId = personId;
              focusBlock.fetchDailyStats();

              notificationService.syncAllNotifications(personId);
            });
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

      if (mounted) {
        authBlock.checkSession(context);
      }

      // String jsonString = await rootBundle.loadString(
      //   "assets/LightThemePurple.json",
      // );
      // print("DUYLONG>>");
      // await database.themesTableDAO.insertNewTheme(
      //   name: "Light theme",
      //   jsonContent: jsonString,
      //   author: "Duy Long",
      // );
      // print("DUYLONG>>");
      //Error

      // Re-enabling DataSeeder to provide initial mission/widget data
      // await DataSeeder.seed(database);
      print("DUYLONG>>>> Seeded database");
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Immediately sync health data now that blocks are initialized
        _syncHealthData();
      }
    } catch (e, stack) {
      debugPrint("DataLayer: Initialization CRITICAL error: $e");
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isInitialized = true; // Still allow building the error UI
        });
      }
    }

    // --- NEW: Monitoring --- Agent
    await DatabaseAgent.monitoring(database);

    // --- NEW: Supabase Auth Listener for PowerSync ---
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final ps = database.powerSync;

      print(
        "🔑 [DataLayer] Supabase Auth Change: Event=$event, HasSession=${session != null}",
      );

      if (session != null) {
        // Use microtask to decouple signal updates from the auth listener execution
        // which prevents SignalEffectException during batch processing.
        Future.microtask(() {
          batch(() {
            print(
              "🔑 [DataLayer] Session Token: ${session.accessToken.substring(0, 10)}...",
            );
            // Sync state to AuthBlock so downstream effects (PowerSync, fetchUser) trigger
            authBlock.jwt.value = session.accessToken;
            authBlock.username.value = session.user.email ?? "Google User";

            // --- NEW: Persist to local DB for auto-login on next start ---

            print("PERSON ID : ${session.user.id}");
            personBlock.information.value = personBlock.information.value
                .copyWith(
                  profiles: personBlock.information.value.profiles.copyWith(
                    id: session.user.id,
                    firstName:
                        session.user.userMetadata?['full_name'] ?? 'User',
                  ),
                );

            authBlock.persistSession(
              session.accessToken,
              session.user.email ?? "Google User",
            );

            if (authBlock.status.value != AuthStatus.authenticated) {
              print(
                "🔑 [DataLayer] Transitioning AuthBlock to 'authenticated' state",
              );
              authBlock.status.value = AuthStatus.authenticated;
            }
          });
        });

        if (ps != null) {
          // --- NEW: Synchronize user data with public schema ---
          authBlock.syncUserWithSupabase(session.user);
          // Only fetch user if we transitioned to authenticated
          authBlock.fetchUser();
        } else {
          print(
            "⚠️ [DataLayer] PowerSync instance is null. Skipping sync connect.",
          );
        }
      }
    });

    // --- NEW: Global Data Initializer ---
    // Listen to AuthBlock token changes to trigger initial data fetch and PowerSync Cloud connect
    // --- NEW: Global Data Initializer ---
    _effectCleanups.add(
      effect(() {
        final token = authBlock.jwt.value;
        final status = authBlock.status.value; // Lắng nghe trạng thái Auth

        // CHỈ kết nối PowerSync khi có Token và trạng thái đã Authenticated
        if (token != null &&
            token.isNotEmpty &&
            status == AuthStatus.authenticated) {
          final ps = database.powerSync;

          if (ps != null) {
            print(
              "🚀 [DataLayer] Auth Signal là Authenticated. Đang khởi động PowerSync...",
            );

            // 1. Lắng nghe trạng thái
            ps.statusStream.listen((status) {
              print(
                "🌐 [PowerSync] Trạng thái: ${status.connected ? 'Connected' : 'Disconnected'}",
              );
              if (status.anyError != null) {
                print("❌ [PowerSync] Lỗi: ${status.anyError}");
              }
            });

            // 2. Khởi tạo Connector
            final connector = MyPowerSyncConnector(
              authBlock: authBlock,
              powerSyncUrl:
                  "https://69967e7cd17eab7f63d96041.powersync.journeyapps.com",
              baseUrl: "https://backend.duylong.art",
            );

            // 3. Ép ngắt kết nối cũ và tạo kết nối mới
            ps.disconnect().then((_) {
              print(
                "☁️ [PowerSync] Gọi lệnh connect(). fetchCredentials SẼ chạy ngay sau dòng này!",
              );
              ps.connect(connector: connector);
            });
          }

          // Khởi tạo các dữ liệu phụ thuộc
          personBlock.fetchInitialData(token).then((_) {
            objectDatabaseBlock.updateUrlOfUser(personBlock);
          });
        }
      }),
    );

    // Bridge AuthBlock status to GoRouter refresh notifier
    _effectCleanups.add(
      effect(() {
        authStatusNotifier.value = authBlock.status.value;
      }),
    );
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

        // Trigger welcome back animation if > 2 hours (7200 seconds)
        // For testing purposes, I might want to use a smaller value like 5 seconds,
        // but the requirement is 2 hours.
        if (diff.inHours >= 2) {
          debugPrint(
            "DataLayer: Long absence detected, triggering welcome back signal",
          );
          authBlock.showWelcomeBack.value = true;
        }

        // Trigger immediate health sync on resume
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
    // OPTIONAL: It's good practice to close the database when the root widget dies.
    // database.close();
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

    // Only build MultiProvider if blocks are initialized to avoid LateInitializationError
    // But since we are providing them, and they are late, we need to be careful.
    // effectively they are initialized in initState -> _initializeData (sync part starts).
    // But _initializeData has async parts. personBlock, authBlock are sync initialized before async await.
    // So usually safe.

    return MultiProvider(
      providers: [
        // Services
        Provider<LocalNotificationService>.value(value: notificationService),
        Provider<FocusAudioHandler>.value(value: audioHandler),

        // 1. Provider for the main database instance.
        Provider<AppDatabase>.value(value: database),

        // 2. Provider for the DAO instance.
        Provider<ExternalWidgetsDAO>.value(value: database.externalWidgetsDAO),
        Provider<ProjectNoteDAO>.value(value: database.projectNoteDAO),
        Provider<InternalWidgetsDAO>.value(value: database.internalWidgetsDAO),

        StreamProvider<List<ExternalWidgetData>>(
          create: (_) => database.externalWidgetsDAO.watchAllWidgets(
            personBlock.information.value.profiles.id ?? "",
          ),
          initialData: const [],
          catchError: (_, error) {
            debugPrint('Error watching widgets: $error');
            return const [];
          },
        ),

        StreamProvider<List<InternalWidgetData>>(
          create: (_) => database.internalWidgetsDAO.watchAllWidgets(
            personBlock.information.value.profiles.id ?? "",
          ),
          initialData: const [],
          catchError: (_, error) {
            debugPrint('DUYLONG watching widgets: $error');
            return const [];
          },
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

        // --- NEW: Reactive Blocks ---
        // PersonBlock (Load user ID 1 by default)
        Provider<PersonBlock>.value(value: personBlock),

        // AuthBlock
        Provider<AuthBlock>.value(value: authBlock),

        // ObjectDatabaseBlock
        Provider<ObjectDatabaseBlock>.value(value: objectDatabaseBlock),

        // FinanceBlock
        Provider<FinanceBlock>.value(value: financeBlock),

        // GrowthBlock
        Provider<GrowthBlock>.value(value: growthBlock),

        // ContentBlock
        Provider<ContentBlock>.value(value: contentBlock),
        Provider<HealthMealDAO>.value(value: database.healthMealDAO),

        // WidgetSettingsBlock
        Provider<WidgetSettingsBlock>.value(value: widgetSettingsBlock),

        Provider<ScoreBlock>.value(value: scoreBlock),
        Provider<ProjectBlock>.value(value: projectBlock),
        // --- Home Logic ---
        Provider<InternalWidgetBlock>.value(value: internalWidgetBlock),
        Provider<ExternalWidgetBlock>.value(value: externalWidgetBlock),
        Provider<QuoteBlock>.value(value: quoteBlock),
        Provider<QuestBlock>.value(value: questBlock),
        Provider<WidgetManagerBlock>.value(value: widgetManagerBlock),

        // --- Focus ---
        Provider<FocusSessionsDAO>.value(value: database.focusSessionsDAO),
        Provider<FocusBlock>.value(value: focusBlock),
        Provider<HealthBlock>.value(value: healthBlock),
      ],
      // Use MaterialApp as the child and WidgetConsumer as the home screen.
      child: widget.childWidget,
    );
  }
}
