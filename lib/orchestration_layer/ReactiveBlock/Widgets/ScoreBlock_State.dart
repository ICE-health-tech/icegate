part of 'ScoreBlock.dart';

mixin ScoreBlockState {
  Timer? _scoreUpdateTimer;
  Timer? _todaySocialUpdateTimer;
  final _score = signal<ScoreData>(ScoreData.empty());
  final isReady = signal<bool>(false);

  // DAOs stored locally for access in update methods
  late ScoreDAO _dao;
  late FinanceDAO _financeDAO;
  late HealthBlock _healthBlock;
  late MetricsDAO _metricsDAO;

  late String _personID;
  String? _tenantID;

  final _latestNotes = signal<List<ProjectNoteData>>([]);
  final _latestAccounts = signal<List<FinancialAccountData>>([]);
  final _latestAssets = signal<List<AssetData>>([]);
  final _latestTransactions = signal<List<TransactionData>>([]);
  final _latestMeals = signal<List<DayWithMeal>>([]);

  // Track subscriptions and effect cleanups to cancel them on dispose
  final List<dynamic> _subscriptions = [];

  // Reactive Streams (Database totals)
  final _totalHealthQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalHealthQuestPoints',
  );
  final _totalSocialQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalSocialQuestPoints',
  );
  final _totalFinanceQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalFinanceQuestPoints',
  );
  final _totalProjectQuestPoints = signal<double>(
    0.0,
    debugLabel: 'totalProjectQuestPoints',
  );
  final _historicalHealthMetricPoints = signal<double>(
    0.0,
    debugLabel: 'historicalHealthMetricPoints',
  );

  // Today's Points Signals
  final todayHealthPoints = signal<double>(
    0.0,
    debugLabel: 'todayHealthPoints',
  );
  final todaySocialPoints = signal<double>(
    0.0,
    debugLabel: 'todaySocialPoints',
  );
  final todayFinancePoints = signal<double>(
    0.0,
    debugLabel: 'todayFinancePoints',
  );
  final todayProjectPoints = signal<double>(
    0.0,
    debugLabel: 'todayProjectPoints',
  );

  // Breakdown Signals (Synced from DB categorical metrics)
  final projectsBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'projectsBreakdown',
  );
  final healthBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'healthBreakdown',
  );
  final socialBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'socialBreakdown',
  );
  final financeBreakdown = signal<Map<String, double>>(
    {},
    debugLabel: 'financeBreakdown',
  );

  final averageScore = signal<double>(0);
  final totalXP = signal<double>(0);
  final globalLevel = signal<int>(1);
  final levelProgress = signal<double>(0);
  final rankTitle = signal<String>("Novice");
  final usageHistory = signal<List<AppUsageHistoryData>>(
    [],
    debugLabel: 'usageHistory',
  );

  String? _initializedPersonID;

  // RxDart Subjects for debounced side-effects (Database writes)
  final _healthUpdateSubject = PublishSubject<void>();
  final _careerUpdateSubject = PublishSubject<void>();
  final _financeUpdateSubject = PublishSubject<void>();
  final _mindUpdateSubject = PublishSubject<void>();
}
