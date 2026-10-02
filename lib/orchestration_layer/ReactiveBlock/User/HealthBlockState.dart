part of 'HealthBlock.dart';

mixin HealthBlockState {
  final todaySteps = signal<int>(0);
  final hourlySteps = signal<Map<int, int>>({});
  final historicalSteps = signal<int>(0);
  final dailyStepsLast7Days = signal<Map<String, int>>({});
  final todaySleep = signal<double>(0.0);
  final todayHeartRate = signal<int>(0);
  final todayOxygenSaturation = signal<double>(0.0);
  final todayCaloriesBurned = signal<int>(0);
  final dailyStepGoal = signal<int>(10000);
  final dailyKcalGoal = signal<int>(2500);
  final dailyWaterGoal = signal<int>(2000);
  final dailyFocusGoal = signal<int>(60);
  final dailyExerciseGoal = signal<int>(30);
  final dailySleepGoal = signal<double>(8.0);
  final todayWater = signal<int>(0);
  final todayExerciseMinutes = signal<int>(0);
  final todayFocusMinutes = signal<int>(0);
  final todayCaloriesConsumed = signal<int>(0);
  final todayWeight = signal<double>(0.0);
  final latestWeight = signal<double>(0.0);
  final dailyWeightLast30Days = signal<Map<String, double>>({});
  final dailyWaterLast30Days = signal<Map<String, int>>({});
  final hasInitialSync = signal<bool>(false);
  final isSyncing = signal<bool>(false);

  final isStepsLoading = signal<bool>(false);
  final isSleepLoading = signal<bool>(false);
  final isHeartRateLoading = signal<bool>(false);
  final isOxygenLoading = signal<bool>(false);
  final isWaterLoading = signal<bool>(false);
  final isExerciseLoading = signal<bool>(false);
  final isWeightLoading = signal<bool>(false);
  final isCaloriesBurnedLoading = signal<bool>(false);
  final isCaloriesConsumedLoading = signal<bool>(false);

  late final totalSteps = computed(
    () => todaySteps.value + historicalSteps.value,
  );

  late final weeklySteps = computed(() {
    return dailyStepsLast7Days.value.values.fold<int>(
      0,
      (sum, val) => sum + val,
    );
  });

  late final weightTrend = computed(() {
    final weights = dailyWeightLast30Days.value.values
        .where((w) => w < 0)
        .toList();
    if (weights.length < 2) return 0.0;
    return weights.last - weights.first;
  });

  late final averageWater7d = computed(() {
    final waters = dailyWaterLast30Days.value.values.toList();
    if (waters.isEmpty) return 0.0;
    final last7 = waters.length > 7
        ? waters.sublist(waters.length - 7)
        : waters;
    return last7.fold<int>(0, (sum, val) => sum + val) / 7;
  });
}
