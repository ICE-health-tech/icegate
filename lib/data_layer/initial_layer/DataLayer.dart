import 'dart:async';
import 'package:drift/drift.dart' hide Column;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleDriveService.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Integrations/IntegrationHubBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/IntegrationSyncCoordinator.dart';
import 'package:ice_gate/orchestration_layer/Services/google_auth_utils.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailyMailSummaryAutoSend.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DatabaseAgent.dart'
    as DatabaseAgent;
import 'package:ice_gate/orchestration_layer/Services/CustomAuthService.dart';
import 'package:ice_gate/orchestration_layer/Services/PasskeyAuthService.dart';
import 'package:ice_gate/orchestration_layer/Services/BiometricAuthService.dart';
import 'package:ice_gate/orchestration_layer/Services/SecureStorageService.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ContentBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/WidgetSettingsBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlockerBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/QuoteBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MusicBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Health/MotivationEngineBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/NotificationEngine.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FoodAnalysisBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/StorageBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';

import 'package:ice_gate/link_layer/cloud_database/PowersyncConnector.dart';
import 'package:ice_gate/orchestration_layer/Services/FocusAudioHandler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:path/path.dart' as p;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_gate/link_layer/ui_route/InternalRoute.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/AppleHealthServices.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/LocaleBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ChallengeBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/RemoteControllerBlock.dart';
import 'package:ice_gate/data_layer/Services/cloud/SupabaseService.dart';
import 'package:ice_gate/link_layer/environmental_block/EnvironmentalBlock.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ice_gate/utils/app_log.dart';

class DataLayer extends StatefulWidget {
  final Widget childWidget;

  const DataLayer({super.key, required this.childWidget});

  @override
  State<DataLayer> createState() => _DataLayerState();
}

class _DataLayerState extends State<DataLayer> with WidgetsBindingObserver {
  AppDatabase? _databaseInstance;
  AppDatabase get database => _databaseInstance!;

  late LocalNotificationService notificationService;
  late GoogleCalendarService googleCalendarService;
  late GoogleDriveService googleDriveService;
  late DeviceCalendarService deviceCalendarService;
  IntegrationHubBlock? integrationHubBlock;
  bool _pendingGoogleEcosystemConnect = false;
  late FocusAudioHandler audioHandler;

  late PersonBlock personBlock;
  late AuthBlock authBlock;
  late ObjectDatabaseBlock objectDatabaseBlock;
  late ScoreBlock scoreBlock;
  late WidgetManagerBlock widgetManagerBlock;
  late GrowthBlock growthBlock;
  late FocusBlock focusBlock;
  late MusicBlock musicBlock;
  late HealthBlock healthBlock;
  late MotivationEngineBlock motivationEngineBlock;
  late NotificationEngine notificationEngine;
  late ProjectBlock projectBlock;
  late FinanceBlock financeBlock;
  late ContentBlock contentBlock;
  late WidgetSettingsBlock widgetSettingsBlock;
  late InternalWidgetBlock internalWidgetBlock;
  late ExternalWidgetBlock externalWidgetBlock;
  late QuoteBlock quoteBlock;
  late QuestBlock questBlock;
  late SocialBlockerBlock socialBlockerBlock;
  late SocialBlock socialBlock;
  late MindBlock mindBlock;
  late ChallengeBlock challengeBlock;
  late LocaleBlock localeBlock;
  late ConfigBlock configBlock;
  late DocumentationBlock documentationBlock;
  late RemoteControllerBlock remoteControllerBlock;
  late FoodAnalysisBlock foodAnalysisBlock;
  late EnvironmentalBlock environmentalBlock;
  late StorageBlock storageBlock;

  DateTime? _lastPausedTime;
  String? _lastInitializedPersonId; // Guard for redundant re-inits

  Timer? _healthSyncTimer;
  Timer? _dailyMailSummaryTimer;

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
    // NOTE: _startHealthSync() is called AFTER _initializeData() completes
    // to ensure healthBlock is initialized before being accessed.
    _initializeData();
  }

  void _startHealthSync() {
    // Exercise data source of truth is exercise_logs (Supabase/PowerSync),
    // not HealthKit. Re-aggregate exercise_logs → health_metrics on ALL
    // platforms (including macOS) since it reads from local DB.
    healthBlock.syncExerciseHistory();

    // Desktop platforms (macOS, Linux, Windows, Web) have no health sensors.
    // They receive real sensor data passively via PowerSync from the phone.
    // Skip HealthKit polling to prevent writing steps=0 and corrupting
    // the source-of-truth data from iPhone.
    final isDesktop =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
    if (isDesktop) {
      debugPrint(
        "DataLayer: ⏭️ Skipping HealthKit sync on desktop — no health sensors.",
      );
      return;
    }

    _syncHealthData(days: 30);
    _healthSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncHealthData(days: 3);
    });
  }

  /// Poll so auto-send still runs if the app stays open past the scheduled time.
  void _startDailyMailSummaryPolling() {
    if (kIsWeb) return;
    _dailyMailSummaryTimer?.cancel();
    _dailyMailSummaryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_trySendDailyMailSummaryIfDue());
    });
  }

  Future<void> _syncHealthData({int days = 3}) async {
    // Guard: healthBlock is a `late` field — check _isInitialized first to
    // avoid LateInitializationError before _initializeData() assigns it.
    if (!_isInitialized || _hasError) {
      debugPrint(
        "DataLayer: Skipping health sync (not ready: initialized=$_isInitialized)",
      );
      return;
    }
    if (healthBlock.personId.isEmpty) {
      debugPrint("DataLayer: Skipping health sync — personId not set yet.");
      return;
    }
    try {
      debugPrint("DataLayer: Starting $days-day health sync...");
      final now = DateTime.now();
      for (int i = 0; i < days; i++) {
        final targetDate = now.subtract(Duration(days: i));
        await _syncHealthDataForDay(targetDate);
      }
      debugPrint("DataLayer: $days-day health sync completed.");
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

    final isDesktop =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;

    if (isDesktop && steps == 0 && calories == 0) {
      return;
    }

    final personId = healthBlock.personId;
    if (personId.isEmpty || personId == DataSeeder.guestPersonId) {
      debugPrint("DataLayer: ⚠️ Skipping health sync for Guest ID ($personId)");
      return;
    }

    // NOTE: exercise_minutes is NOT synced from HealthKit here.
    // Its source of truth is exercise_logs (Supabase) → summed by
    // HealthBlock._exerciseSubscription → saved to health_metrics.

    if (isToday) {
      final sleepHours = await HealthService.fetchSleepData();
      final heartRate = await HealthService.fetchLatestHeartRate();
      final hourlySteps = await HealthService.fetchHourlyStepsForDay(date);

      if (mounted && _isInitialized) {
        healthBlock.updateSteps(steps);
        healthBlock.updateHourlySteps(hourlySteps);
        healthBlock.updateSleep(sleepHours);
        healthBlock.updateHeartRate(heartRate);
        healthBlock.updateCalories(calories.toInt());

        await database.healthMetricsDAO.insertOrUpdateMetrics(
          HealthMetricsTableCompanion.insert(
            id: IDGen.generateDeterministicUuid(
              healthBlock.personId,
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}:General",
            ),
            personID: Value(healthBlock.personId),
            date: date,
            steps: Value(steps),
            caloriesBurned: Value(calories.toInt()),
            sleepHours: Value(sleepHours),
            heartRate: Value(heartRate),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    } else {
      final normalizedDate = DateTime(date.year, date.month, date.day, 12);
      await database.healthMetricsDAO.insertOrUpdateMetrics(
        HealthMetricsTableCompanion.insert(
          id: IDGen.generateDeterministicUuid(
            healthBlock.personId,
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}:General",
          ),
          personID: Value(healthBlock.personId),
          date: normalizedDate,
          steps: Value(steps),
          caloriesBurned: Value(calories.toInt()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _initializeData() async {
    if (_isInitialized && !_hasError) return;

    try {
      if (_hasError) {
        setState(() {
          _hasError = false;
          _errorMessage = null;
        });
      }
      debugPrint("🚀 [Boot] Step 0: Initialize Locale...");
      // Khởi tạo LocaleBlock trước để ngôn ngữ sẵn sàng khi UI render
      localeBlock = LocaleBlock();
      await localeBlock.init();

      debugPrint("🚀 [Boot] Step 1: Initialize Supabase...");
      final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
      final supabaseAnon = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
      if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
        throw StateError(
          'SUPABASE_URL missing in .env (got "$supabaseUrl"). '
          'OAuth would open invalid URLs like /auth/v1/authorize.',
        );
      }
      if (supabaseAnon.isEmpty) {
        throw StateError('SUPABASE_ANON_KEY missing in .env');
      }
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnon,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      debugPrint("🚀 [Boot] Step 2: Initialize PowerSync...");
      String dbPath;
      if (kIsWeb) {
        debugPrint(
          "🌐 [Boot] Web platform detected. Initializing PowerSync with IndexedDB.",
        );
        // Bumped to powersync48.db to finalize transactions and activity logs.
        dbPath = 'powersync48.db';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        dbPath = p.join(dir.path, 'powersync50.db');
      }
      // final powersync = PowerSyncDatabase(
      //   schema: ps_schema.schema,
      //   path: dbPath,
      // );
      // // await powersync.initialize();

      // _databaseInstance ??= AppDatabase.powersync(powersync);

      _databaseInstance ??= AppDatabase();
      
      // Initialize FoodAnalysisBlock early to avoid LateInitializationError
      foodAnalysisBlock = FoodAnalysisBlock(database);

      debugPrint("🚀 [Boot] Step 3: Initialize Notifications...");
      notificationService = LocalNotificationService();
      notificationService.onDailyMailSummaryTriggered = _trySendDailyMailSummaryIfDue;
      await notificationService.init(database);
      googleCalendarService = GoogleCalendarService();
      googleDriveService = GoogleDriveService();
      deviceCalendarService = DeviceCalendarService();
      unawaited(deviceCalendarService.restoreAccess());

      debugPrint("🚀 [Boot] Step 4: Initialize Audio...");
      try {
        if (kIsWeb) {
          debugPrint(
            "🌐 [Boot] Web platform detected. Initializing raw FocusAudioHandler.",
          );
          audioHandler = FocusAudioHandler();
        } else if (!_isAudioInitialized) {
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
        baseUrl: dotenv.env['BACKEND_URL'] ?? "",
      );
      final passkeyService = PasskeyAuthService();
      final biometricService = BiometricAuthService();
      final secureStorage = SecureStorageService();

      // NEW: Initialize SupabaseService
      final supabaseService = SupabaseService(
        database: database,
        client: Supabase.instance.client,
      );
      database.supabaseSync = supabaseService;

      personBlock = PersonBlock(
        authService: authService,
        personDao: database.personManagementDAO,
      );
      integrationHubBlock = IntegrationHubBlock(
        personId: personBlock.information.value.profiles.id ?? '',
        dao: database.integrationAccountDAO,
        coordinator: IntegrationSyncCoordinator(
          accountDao: database.integrationAccountDAO,
          calendarService: googleCalendarService,
          driveService: googleDriveService,
          deviceCalendarService: deviceCalendarService,
        ),
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
        hourlyLogDao: database.hourlyActivityLogDAO,
      );
      motivationEngineBlock = MotivationEngineBlock();
      motivationEngineBlock.bindHealth(healthBlock);
      notificationEngine = NotificationEngine(notificationService);
      growthBlock = GrowthBlock();
      scoreBlock = ScoreBlock();
      projectBlock = ProjectBlock();
      internalWidgetBlock = InternalWidgetBlock();
      externalWidgetBlock = ExternalWidgetBlock();
      financeBlock = FinanceBlock();
      quoteBlock = QuoteBlock();
      quoteBlock.init(database.quoteDAO);
      questBlock = QuestBlock();
      socialBlock = SocialBlock();
      mindBlock = MindBlock(database.mindLogsDAO);
      contentBlock = ContentBlock();
      widgetSettingsBlock = WidgetSettingsBlock();
      objectDatabaseBlock = ObjectDatabaseBlock();
      configBlock = ConfigBlock();
      documentationBlock = DocumentationBlock();
      challengeBlock = ChallengeBlock();

      musicBlock = MusicBlock(audioHandler: audioHandler);
      socialBlockerBlock = SocialBlockerBlock();
      focusBlock = FocusBlock(
        focusSessionDao: database.focusSessionsDAO,
        healthLogsDao: database.healthLogsDAO,
        healthMetricsDao: database.healthMetricsDAO,
        personId: "",
        musicBlock: musicBlock,
        notificationService: notificationService,
      );

      remoteControllerBlock = RemoteControllerBlock(
        supabase: Supabase.instance.client,
        authBlock: authBlock,
        focusBlock: focusBlock,
        musicBlock: musicBlock,
      );


      environmentalBlock = EnvironmentalBlock();
      storageBlock = StorageBlock(mediaIndexDao: database.localMediaIndexDAO);
      Future.microtask(() => storageBlock.init());


      _effectCleanups.add(
        effect(() {
          try {
            final profile = personBlock.information.value.profiles;
            final personId = profile.id;

            if (personId != null && personId.isNotEmpty) {
              if (personId == _lastInitializedPersonId) {
                return;
              }
              _lastInitializedPersonId = personId;

              untracked(() {
                appLog(
                  "👤 [DataLayer] PersonID resolved to $personId. Re-initializing dependent blocks...",
                );
                storageBlock.startAutoScan(personId: personId);
                Future.microtask(() async {
                  try {
                    final achievements = await database.achievementsDAO
                        .getAchievementsByPerson(personId);
                    await storageBlock.syncAchievementStories(
                      personId: personId,
                      achievements: achievements,
                      achievementsDao: database.achievementsDAO,
                    );
                  } catch (e) {
                    appLog('Story sync backfill skipped: $e');
                  }
                });
                healthBlock.personId = personId;
                Future.microtask(() => healthBlock.init());
                Future.microtask(() => mindBlock.init(personId));
                _syncHealthData();

                projectBlock.init(database.projectsDAO, personId);
                growthBlock.init(database.growthDAO, personId);
                financeBlock.init(
                  database.financeDAO,
                  database.portfolioSnapshotsDAO,
                  personId,
                  configBlock: configBlock,
                );
                Future.microtask(() => financeBlock.refreshFromLocalDatabase());
                configBlock.init(database.configsDAO, personId);
                widgetSettingsBlock.init(database.widgetDAO, personId);
                questBlock.init(database, personId);
                notificationService.startWatchingEnabledNotifications(personId);

                scoreBlock.init(
                  database.scoreDAO,
                  database.financeDAO,
                  database.healthMealDAO,
                  database.metricsDAO,
                  database.projectNoteDAO,
                  personId,
                );

                focusBlock.personId = personId;
                focusBlock.fetchDailyStats();
                notificationService.syncAllNotifications(personId);
                _resyncHealthNudges(force: true);

                // Sync Social Blocker rules + shield evaluation
                Future.microtask(() async {
                  await socialBlockerBlock.initWithSync(focusBlock, personId);
                });

                // NEW: Trigger Cloud Sync
                database.supabaseSync?.syncFullDown(personId).then((_) async {
                  debugPrint("📡 [CloudSync] Initial full sync completed.");
                  await growthBlock.sync();
                  // Reschedule notifications once cloud data is local
                  notificationService.syncAllNotifications(personId);
                _resyncHealthNudges(force: true);
                  financeBlock.refreshFromLocalDatabase();
                });

                // Initialize Remote Controller
                remoteControllerBlock.init();

                internalWidgetBlock.refreshBlock(
                  database.internalWidgetsDAO,
                  personId,
                  'home',
                );
                internalWidgetBlock.refreshBlock(
                  database.internalWidgetsDAO,
                  personId,
                  'projects',
                );
                externalWidgetBlock.refreshBlock(
                  database.externalWidgetsDAO,
                  personId,
                );

                integrationHubBlock?.updatePersonId(personId);
                if (_pendingGoogleEcosystemConnect) {
                  _pendingGoogleEcosystemConnect = false;
                  unawaited(
                    integrationHubBlock
                        ?.connectGoogleEcosystem(interactive: true)
                        .then((_) => _syncDocumentationDriveState()),
                  );
                } else {
                  unawaited(
                    integrationHubBlock?.restoreGoogleEcosystem().then(
                      (_) => _syncDocumentationDriveState(),
                    ),
                  );
                }
              });
            }
          } catch (e) {
            debugPrint("DataLayer: Error in personId effect: $e");
          }
        }),
      );

      focusBlock
        .growthBlock = growthBlock;

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
        // Start the periodic health sync NOW that all blocks are initialized.
        _startHealthSync();
        _startDailyMailSummaryPolling();
        Future.microtask(_trySendDailyMailSummaryIfDue);
      }
      debugPrint("🚀 [Boot] ✅ initializationData sequence COMPLETED.");

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        final ps = database.powerSync;

        appLog(
          "🔑 [DataLayer] Supabase Auth Change: Event=$event, HasSession=${session != null}",
        );

        if (event == AuthChangeEvent.passwordRecovery && session != null) {
          pendingPasswordRecoveryNotifier.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            router.go('/change-password');
          });
        }

        if (session != null) {
          if (event == AuthChangeEvent.signedIn &&
              sessionUsedGoogleProvider(session)) {
            _pendingGoogleEcosystemConnect = true;
          }

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
              authBlock.cancelAuthInteractionTimeout();
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
                powerSyncUrl: dotenv.env['POWERSYNC_URL'] ?? "",
                baseUrl: dotenv.env['BACKEND_URL'] ?? "",
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

      _effectCleanups.add(
        effect(() {
          final motivation = motivationEngineBlock.dailyResult.value;
          if (motivation == null) return;
          untracked(() {
            notificationEngine.syncHealthNudges(motivation: motivation);
          });
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
      // Workaround for occasional desktop key-state desync on resume:
      // clear pressed keys so duplicate KeyDown doesn't trip assertions.
      try {
        // These are marked testing-only in Flutter, so we call via `dynamic`
        // to avoid analyzer access restrictions in app code.
        (HardwareKeyboard.instance as dynamic).clearState();
      } catch (_) {
        try {
          (RawKeyboard.instance as dynamic).clearKeysPressed();
        } catch (_) {}
      }
      if (_isInitialized) {
        authBlock.checkAuthInteractionDeadline();
      }
      if (_lastPausedTime != null) {
        final diff = DateTime.now().difference(_lastPausedTime!);
        debugPrint("DataLayer: App was paused for ${diff.inSeconds} seconds");
        if (diff.inHours >= 2) {
          authBlock.showWelcomeBack.value = true;
        }
        _syncHealthData();
        Future.microtask(_trySendDailyMailSummaryIfDue);
      }
    }
  }

  Future<void> _syncDocumentationDriveState() async {
    try {
      await documentationBlock.driveService.signIn(interactive: false);
      documentationBlock.isGoogleDriveConnected.value =
          documentationBlock.driveService.driveApi != null;
    } catch (e) {
      debugPrint('DataLayer: Documentation Drive sync failed: $e');
    }
  }

  Future<void> _trySendDailyMailSummaryIfDue() async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await DailyMailSummaryAutoSend.trySendIfDue(
        finance: financeBlock,
        health: healthBlock,
        mind: mindBlock,
        growth: growthBlock,
        project: projectBlock,
        config: configBlock,
        person: personBlock,
        localeCode: localeBlock.currentLocale.value.languageCode,
      );
    } catch (e) {
      debugPrint('DataLayer: daily mail summary auto-send failed: $e');
    }
  }

  Future<void> _resyncHealthNudges({bool force = false}) async {
    final motivation = motivationEngineBlock.dailyResult.value;
    if (motivation == null) return;
    try {
      await notificationEngine.syncHealthNudges(
        motivation: motivation,
        force: force,
      );
    } catch (e) {
      debugPrint('DataLayer: health nudge sync failed: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthSyncTimer?.cancel();
    _dailyMailSummaryTimer?.cancel();
    for (final cleanup in _effectCleanups) {
      cleanup();
    }
    _effectCleanups.clear();

    // Dispose all blocks to stop background activities
    if (_isInitialized) {
      documentationBlock.dispose();
      focusBlock.dispose();
      musicBlock.dispose();
      remoteControllerBlock.dispose();
      socialBlockerBlock.dispose();
      foodAnalysisBlock.dispose();
      environmentalBlock.dispose();
      storageBlock.dispose();
      growthBlock.dispose();
      motivationEngineBlock.dispose();
    }


    
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    "Critical Initialization Error",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? "Unknown Error",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _initializeData(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<LocalNotificationService>.value(value: notificationService),
        Provider<GoogleCalendarService>.value(value: googleCalendarService),
        Provider<DeviceCalendarService>.value(value: deviceCalendarService),
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
        Provider<PortfolioSnapshotsDAO>.value(
          value: database.portfolioSnapshotsDAO,
        ),
        Provider<FocusSessionsDAO>.value(value: database.focusSessionsDAO),
        Provider<ScoreDAO>.value(value: database.scoreDAO),
        Provider<CustomNotificationDAO>.value(
          value: database.customNotificationDAO,
        ),
        Provider<PersonDAO>.value(value: database.personDAO),
        Provider<QuoteDAO>.value(value: database.quoteDAO),
        Provider<HealthLogsDAO>.value(value: database.healthLogsDAO),
        Provider<QuestDAO>.value(value: database.questDAO),
        Provider<HealthMealDAO>.value(value: database.healthMealDAO),
        Provider<AchievementsDAO>.value(value: database.achievementsDAO),
        Provider<HourlyActivityLogDAO>.value(
          value: database.hourlyActivityLogDAO,
        ),
        Provider<MindLogsDAO>.value(value: database.mindLogsDAO),
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
        Provider<SocialBlockerBlock>.value(value: socialBlockerBlock),
        Provider<SocialBlock>.value(value: socialBlock),
        Provider<WidgetManagerBlock>.value(value: widgetManagerBlock),
        Provider<MusicBlock>.value(value: musicBlock),
        Provider<FocusBlock>.value(value: focusBlock),
        Provider<HealthBlock>.value(value: healthBlock),
        Provider<MotivationEngineBlock>.value(value: motivationEngineBlock),
        Provider<NotificationEngine>.value(value: notificationEngine),
        Provider<LocaleBlock>.value(value: localeBlock),
        Provider<ConfigBlock>.value(value: configBlock),
        Provider<DocumentationBlock>.value(value: documentationBlock),
        Provider<ChallengeBlock>.value(value: challengeBlock),
        Provider<MindBlock>.value(value: mindBlock),
        Provider<RemoteControllerBlock>.value(value: remoteControllerBlock),
        Provider<FoodAnalysisBlock>.value(value: foodAnalysisBlock),
        Provider<EnvironmentalBlock>.value(value: environmentalBlock),
        Provider<StorageBlock>.value(value: storageBlock),
        if (integrationHubBlock != null)
          Provider<IntegrationHubBlock>.value(value: integrationHubBlock!),

      ],
      child: widget.childWidget,
    );
  }
}
