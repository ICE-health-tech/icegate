part of 'ScoreBlock.dart';

mixin ScoreBlockState {
  Timer? _scoreUpdateTimer;
  Timer? _todaySocialUpdateTimer;
  final _score = signal<ScoreData>(ScoreData.empty());
  final isReady = signal<bool>(false);

  // DAOs stored locally for access in update methods
  late ScoreDAO _dao;
  late FinanceDAO _financeDAO;
  late MetricsDAO _metricsDAO;

  late String _personID;

  final _latestNotes = signal<List<ProjectNoteData>>([]);
  final _latestAccounts = signal<List<FinancialAccountData>>([]);
  final _latestAssets = signal<List<AssetData>>([]);
  final _latestTransactions = signal<List<TransactionData>>([]);
  final _latestMeals = signal<List<DayWithMeal>>([]);

  // Track subscriptions and effect cleanups to cancel them on dispose
  final List<dynamic> _subscriptions = [];

  final usageHistory = signal<List<AppUsageHistoryData>>(
    [],
    debugLabel: 'usageHistory',
  );

  String? _initializedPersonID;

}
