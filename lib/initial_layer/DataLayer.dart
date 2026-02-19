import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/DatabaseAgent.dart'
    as DatabaseAgent;
import 'package:ice_shield/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
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
import 'package:ice_shield/initial_layer/FocusAudioHandler.dart';
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

// 1. Convert to StatefulWidget to manage the database lifecycle internally.
class DataLayer extends StatefulWidget {
  final Widget childWidget;
  final AppDatabase database;
  // Blocks should be in State if they are initialized there.
  // late PersonBlock personBlock; // Removed
  // late AuthBlock authBlock; // Removed
  // late ObjectDatabaseBlock objectDatabaseBlock; // Removed

  // The database is no longer passed in the constructor.
  const DataLayer({
    super.key,
    required this.database,
    required this.childWidget,
  });

  @override
  State<DataLayer> createState() => _DataLayerState();
}

class _DataLayerState extends State<DataLayer> {
  // 2. Declare the database instance using 'late final'.
  // 'late' guarantees it will be initialized before its first use.
  // late final AppDatabase database;

  late PersonBlock personBlock;
  late AuthBlock authBlock;
  late ObjectDatabaseBlock objectDatabaseBlock;
  late ScoreBlock scoreBlock;
  late WidgetManagerBlock widgetManagerBlock;
  late GrowthBlock growthBlock;
  late FocusBlock focusBlock;
  late HealthBlock healthBlock;

  Timer? _healthSyncTimer;

  late HealthMetricsDAO healthMetricsDAO;
  // late StreamSubscription<StepCount> _stepSubscription; // Removed
  int currentSteps = 0;
  bool _isInitialized = false;
  final List<EffectCleanup> _effectCleanups = [];

  @override
  void initState() {
    super.initState();

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
      final steps = await HealthService.fetchStepCount();
      debugPrint("DataLayer: HealthService returned $steps steps");
      if (mounted) {
        setState(() {
          currentSteps = steps;
        });

        if (_isInitialized) {
          debugPrint("DataLayer: Forwarding $steps steps to healthBlock");
          healthBlock.updateSteps(steps);
        } else {
          debugPrint(
            "DataLayer: healthBlock not initialized yet, skipping step update",
          );
        }
      }
    } catch (e) {
      debugPrint("DataLayer: Error in _syncHealthData: $e");
    }
  }

  Future<void> _initializeData() async {
    print("DataLayerState(${identityHashCode(this)}): _initializeData called");
    // Use a try-catch block for robust error handling during async setup.
    try {
      // 3. Initialize the database instance internally.
      // database = AppDatabase();

      // --- Database and Asset Loading ---
      var baseUrl = "https://backend.duylong.art";
      var authService = CustomAuthService(baseUrl: baseUrl);
      var passkeyService = PasskeyAuthService();

      // Initialize Blocks
      personBlock = PersonBlock(authService: authService);
      authBlock = AuthBlock(
        authService: authService,
        sessionDao: widget.database.sessionDAO,
        passkeyService: passkeyService,
        personDao: widget.database.personManagementDAO,
      );
      healthMetricsDAO = widget.database.healthMetricsDAO;

      // int steps = 0;

      // int steps = 0;
      //   HealthMetricsTableCompanion(
      //     personID: const Value(1),
      //     steps: Value(currentSteps),
      //     date: Value(now),
      //   ),
      // );

      // 1. Pre-instantiate all blocks to avoid LateInitializationError in UI
      // even if specific init steps fail.
      debugPrint("DataLayer: Pre-instantiating blocks for personID: 1");
      healthBlock = HealthBlock(
        personId: 1,
        healthDao: widget.database.healthMetricsDAO,
        healthLogsDao: widget.database.healthLogsDAO,
      );
      growthBlock = GrowthBlock();
      scoreBlock = ScoreBlock();
      focusBlock = FocusBlock(
        focusSessionDao: widget.database.focusSessionsDAO,
        personId: 1,
        audioHandler: context.read<FocusAudioHandler>(),
        notificationService: context.read<LocalNotificationService>(),
      );
      objectDatabaseBlock = ObjectDatabaseBlock();
      // widgetManagerBlock is initialized later

      // Initialize HealthBlock
      debugPrint("DataLayer: Initializing HealthBlock");
      healthBlock.init();

      // Initialize GrowthBlock
      print("DataLayer: Initializing GrowthBlock");
      try {
        growthBlock.init(widget.database.growthDAO, 1);
      } catch (e) {
        print("DataLayer: GrowthBlock init failed: $e");
      }

      // Initialize ScoreBlock
      print("DataLayer: Initializing ScoreBlock");
      try {
        scoreBlock.init(
          widget.database.scoreDAO,
          widget.database.personManagementDAO,
          widget.database.financeDAO,
          widget.database.healthMetricsDAO,
          widget.database.healthMealDAO,
          1,
        );
      } catch (e) {
        print("DataLayer: ScoreBlock init failed: $e");
      }

      // Initialize FocusBlock
      print("DataLayer: Initializing FocusBlock");
      try {
        focusBlock
          ..growthBlock = growthBlock
          ..scoreBlock = scoreBlock;

        await focusBlock.init();
      } catch (e, stack) {
        print("DataLayer: FocusBlock init failed: $e");
        print(stack);
      }

      // widget.database.scoreDAO.insertOrUpdateScore(ScoreLocalData(personID: 1, healthGlobalScore: 0, socialGlobalScore: 0, financialGlobalScore: 0, careerGlobalScore: 0, createdAt: DateTime.now(), updatedAt: DateTime.now(), scoreID: 1));

      print("DataLayer: FocusBlock initialized");

      // Initialize ObjectDatabaseBlock
      print("DataLayer: Initializing ObjectDatabaseBlock");
      objectDatabaseBlock = ObjectDatabaseBlock();

      print("DataLayer: Initializing WidgetManagerBlock");
      widgetManagerBlock = WidgetManagerBlock(
        widgetDao: widget.database.widgetDAO,
        personIdSignal: computed(
          () => personBlock.information.value.profiles.id,
        ),
      );

      // Check session immediately on startup
      if (mounted) {
        authBlock.checkSession(context);
      }

      // Await asset loading
      print("DataLayer: Loading theme asset");
      String jsonString = await rootBundle.loadString(
        "assets/LightThemePurple.json",
      );

      ExternalWidgetProtocol externalWidgetProtocol = ExternalWidgetProtocol(
        name: '',
        protocol: '',
        host: '',
        url: '',
      );

      // Await database operations
      print("DataLayer: Ensuring default data");
      await widget.database.externalWidgetsDAO.insertNewWidget(
        externalWidgetProtocol: externalWidgetProtocol,
      );

      await widget.database.themesTableDAO.insertNewTheme(
        name: "Light theme",
        jsonContent: jsonString,
        author: "Duy Long",
      );

      // --- NEW: Seed Data ---
      print("DataLayer: Seeding data");
      await DataSeeder.seed(widget.database);
      print("DataLayer: Initialization success");
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      print("DataLayer: Initialization CRITICAL error: $e");
      print(stack);
      // We set _isInitialized = true even on error to "fail forward"
      // and let the app handle missing data gracefully rather than hanging forever.
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }

    // --- NEW: Monitoring --- Agent
    await DatabaseAgent.monitoring(widget.database);

    // --- NEW: Global Data Initializer ---
    // Listen to AuthBlock token changes to trigger initial data fetch
    _effectCleanups.add(
      effect(() {
        final token = authBlock.jwt.value;
        if (token != null && token.isNotEmpty) {
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
  void dispose() {
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

    // Only build MultiProvider if blocks are initialized to avoid LateInitializationError
    // But since we are providing them, and they are late, we need to be careful.
    // effectively they are initialized in initState -> _initializeData (sync part starts).
    // But _initializeData has async parts. personBlock, authBlock are sync initialized before async await.
    // So usually safe.

    return MultiProvider(
      providers: [
        // 1. Provider for the main database instance.
        // The type provided is AppDatabase (your database class).
        Provider<AppDatabase>(
          create: (_) =>
              widget.database, // Use the internally initialized field
        ),

        // 2. Provider for the DAO instance.
        // The type provided is ExternalWidgetDao (your DAO class).
        Provider<ExternalWidgetsDAO>(
          // Access the DAO getter from the database instance.
          create: (context) => widget.database.externalWidgetsDAO,
        ),

        // 3. Provider for ProjectNoteDAO
        Provider<ProjectNoteDAO>(
          create: (context) => widget.database.projectNoteDAO,
        ),
        Provider<InternalWidgetsDAO>(
          create: (context) => widget.database.internalWidgetsDAO,
        ),

        // 3. StreamProvider to watch the live list of data. (For READ operations)
        StreamProvider<List<ExternalWidgetData>>(
          create: (context) =>
              widget.database.externalWidgetsDAO.watchAllWidgets(),
          initialData: const [],
          catchError: (_, error) {
            debugPrint('Error watching widgets: $error');
            return const [];
          },
        ),

        // --- NEW: DAOs ---
        Provider<PersonManagementDAO>(
          create: (_) => widget.database.personManagementDAO,
        ),
        Provider<FinanceDAO>(create: (_) => widget.database.financeDAO),
        Provider<GrowthDAO>(create: (_) => widget.database.growthDAO),
        Provider<ContentDAO>(create: (_) => widget.database.contentDAO),
        Provider<WidgetDAO>(create: (_) => widget.database.widgetDAO),
        Provider<HealthMetricsDAO>(
          create: (_) => widget.database.healthMetricsDAO,
        ),
        Provider<ProjectsDAO>(create: (_) => widget.database.projectsDAO),
        Provider<ScoreDAO>(create: (_) => widget.database.scoreDAO),
        Provider<CustomNotificationDAO>(
          create: (_) => widget.database.customNotificationDAO,
        ),
        Provider<PersonDAO>(create: (_) => widget.database.personDAO),
        Provider<QuoteDAO>(create: (_) => widget.database.quoteDAO),
        Provider<HealthLogsDAO>(create: (_) => widget.database.healthLogsDAO),

        // --- NEW: Reactive Blocks ---
        // PersonBlock (Load user ID 1 by default)
        Provider<PersonBlock>(create: (_) => personBlock),

        // AuthBlock
        Provider<AuthBlock>(create: (_) => authBlock),

        // ObjectDatabaseBlock
        Provider<ObjectDatabaseBlock>(create: (_) => objectDatabaseBlock),

        // FinanceBlock
        Provider<FinanceBlock>(
          create: (_) => FinanceBlock()..init(widget.database.financeDAO, 1),
          dispose: (_, block) => block.dispose(),
        ),

        // GrowthBlock
        Provider<GrowthBlock>.value(value: growthBlock),

        // ContentBlock
        Provider<ContentBlock>(
          create: (_) => ContentBlock()..init(widget.database.contentDAO, 1),
          dispose: (_, block) => block.dispose(),
        ),
        Provider<HealthMealDAO>(create: (_) => widget.database.healthMealDAO),

        // WidgetSettingsBlock
        Provider<WidgetSettingsBlock>(
          create: (_) =>
              WidgetSettingsBlock()..init(widget.database.widgetDAO, 1),
          dispose: (_, block) => block.dispose(),
        ),

        Provider<ScoreBlock>.value(value: scoreBlock),
        Provider<ProjectBlock>(
          create: (_) => ProjectBlock()..init(widget.database.projectsDAO, 1),
          dispose: (_, block) => block.dispose(),
        ),
        Provider<InternalWidgetBlock>(create: (_) => InternalWidgetBlock()),
        Provider<ExternalWidgetBlock>(create: (_) => ExternalWidgetBlock()),
        Provider<WidgetManagerBlock>(create: (_) => widgetManagerBlock),

        // --- Focus ---
        Provider<FocusSessionsDAO>(
          create: (_) => widget.database.focusSessionsDAO,
        ),
        Provider<FocusBlock>.value(value: focusBlock),
        Provider<HealthBlock>.value(value: healthBlock),
      ],
      // Use MaterialApp as the child and WidgetConsumer as the home screen.
      child: widget.childWidget,
    );
  }
}
