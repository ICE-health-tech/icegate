import 'dart:async';

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
import 'package:path/path.dart' as p;
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_shield/security_routing_layer/Routing/url_route/InternalRoute.dart';
import 'package:ice_shield/ui_layer/health_page/services/HealthService.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastPausedTime;

  Timer? _healthSyncTimer;

  late HealthMetricsDAO healthMetricsDAO;
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
      debugPrint("DataLayer: Periodic health sync started...");

      // Sync Steps
      final steps = await HealthService.fetchStepCount();
      debugPrint("DataLayer: HealthService returned $steps steps");

      // Sync Sleep
      final sleepHours = await HealthService.fetchSleepData();
      debugPrint("DataLayer: HealthService returned $sleepHours sleep hours");

      // Sync Heart Rate
      final heartRate = await HealthService.fetchLatestHeartRate();
      debugPrint("DataLayer: HealthService returned $heartRate bpm");

      if (mounted) {
        setState(() {
          currentSteps = steps;
        });

        if (_isInitialized) {
          debugPrint("DataLayer: Forwarding $steps steps to healthBlock");
          healthBlock.updateSteps(steps);

          debugPrint(
            "DataLayer: Forwarding $sleepHours sleep hours to healthBlock",
          );
          healthBlock.updateSleep(sleepHours);

          debugPrint("DataLayer: Forwarding $heartRate bpm to healthBlock");
          healthBlock.updateHeartRate(heartRate);
        } else {
          debugPrint(
            "DataLayer: healthBlock not initialized yet, skipping health update",
          );
        }
      }
    } catch (e) {
      debugPrint("DataLayer: Error in _syncHealthData: $e");
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
      final dbPath = p.join(dir.path, 'powersync.db');
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

      personBlock = PersonBlock(authService: authService);
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

      contentBlock = ContentBlock();
      contentBlock.init(database.contentDAO, "");

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
        database.healthMetricsDAO,
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
              healthBlock.init();

              growthBlock.init(database.growthDAO, personId);
              projectBlock.init(database.projectsDAO, personId);
              financeBlock.init(database.financeDAO, personId);
              contentBlock.init(database.contentDAO, personId);
              widgetSettingsBlock.init(database.widgetDAO, personId);

              scoreBlock.init(
                database.scoreDAO,
                database.personManagementDAO,
                database.financeDAO,
                database.healthMetricsDAO,
                database.healthMealDAO,
                personId,
              );

              focusBlock.personId = personId;
              focusBlock.fetchDailyStats();
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

      String jsonString = await rootBundle.loadString(
        "assets/LightThemePurple.json",
      );
      print("DUYLONG>>");
      await database.themesTableDAO.insertNewTheme(
        name: "Light theme",
        jsonContent: jsonString,
        author: "Duy Long",
      );
      print("DUYLONG>>");
      //Error

      // Disabling DataSeeder to avoid local data conflicts with Supabase
      // await DataSeeder.seed(database);
      // print("DUYLONG>>>>");
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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final ps = database.powerSync;

      print(
        "🔑 [DataLayer] Supabase Auth Change: Event=$event, HasSession=${session != null}",
      );

      if (session != null) {
        print(
          "🔑 [DataLayer] Session Token: ${session.accessToken.substring(0, 10)}...",
        );
        // Sync state to AuthBlock so downstream effects (PowerSync, fetchUser) trigger
        authBlock.jwt.value = session.accessToken;
        authBlock.username.value = session.user.email ?? "Google User";

        // --- NEW: Persist to local DB for auto-login on next start ---
        authBlock.persistSession(
          session.accessToken,
          authBlock.username.value!,
        );

        // --- NEW: Synchronize user data with public schema ---
        authBlock.syncUserWithSupabase(session.user);

        if (authBlock.status.value != AuthStatus.authenticated) {
          print(
            "🔑 [DataLayer] Transitioning AuthBlock to 'authenticated' state",
          );
          authBlock.status.value = AuthStatus.authenticated;

          // Only fetch user if we transitioned to authenticated
          authBlock.fetchUser();
        }
      }

      if (ps == null) {
        print(
          "⚠️ [DataLayer] PowerSync instance is null. Skipping sync connect.",
        );
        return;
      }

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.initialSession) {
        if (session != null) {
          print(
            "☁️ [DataLayer] Supabase Auth Event: $event. Connecting PowerSync...",
          );
          final connector = MyPowerSyncConnector(
            authBlock: authBlock,
            powerSyncUrl:
                "https://69967e7cd17eab7f63d96041.powersync.journeyapps.com",
            baseUrl: "https://backend.duylong.art",
          );
          ps.connect(connector: connector);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        print(
          "☁️ [DataLayer] Supabase Signed Out. Disconnecting PowerSync and clearing local session...",
        );
        ps.disconnect();
        authBlock.logout(); // Trigger local state clear
      }
    });

    // --- NEW: Global Data Initializer ---
    // Listen to AuthBlock token changes to trigger initial data fetch and PowerSync Cloud connect
    _effectCleanups.add(
      effect(() {
        final token = authBlock.jwt.value;
        if (token != null && token.isNotEmpty) {
          // Trigger PowerSync Cloud Connect
          final ps = database.powerSync;
          if (ps != null) {
            // --- MONITOR STATUS ---
            ps.statusStream.listen((status) {
              print(
                "🌐 [PowerSync] Status: ${status.connected ? 'Connected' : 'Disconnected'} (Last synced: ${status.lastSyncedAt})",
              );
              if (status.anyError != null) {
                print("❌ [PowerSync] Error: ${status.anyError}");
              }
            });
          }

          personBlock.fetchInitialData(token).then((_) {
            // Update object database urls after initial fetch
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
          create: (_) => database.externalWidgetsDAO.watchAllWidgets(),
          initialData: const [],
          catchError: (_, error) {
            debugPrint('Error watching widgets: $error');
            return const [];
          },
        ),

        StreamProvider<List<InternalWidgetData>>(
          create: (_) => database.internalWidgetsDAO.watchAllWidgets(),
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
        Provider<ContentDAO>.value(value: database.contentDAO),
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
