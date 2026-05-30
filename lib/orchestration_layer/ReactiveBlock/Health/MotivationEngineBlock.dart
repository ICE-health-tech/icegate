import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/MotivationEngine.dart';
import 'package:signals/signals.dart';

/// Reactive facade over [MotivationEngine] — keeps daily motivation in sync with [HealthBlock].
class MotivationEngineBlock {
  final dailyResult = signal<DailyMotivationResult?>(null);

  EffectCleanup? _healthBinding;

  void bindHealth(HealthBlock health) {
    _healthBinding?.call();
    _healthBinding = effect(() {
      dailyResult.value = MotivationEngine.fromHealthSignals(
        steps: health.todaySteps.value,
        stepGoal: health.dailyStepGoal.value,
        waterMl: health.todayWater.value,
        waterGoal: health.dailyWaterGoal.value,
        sleepHours: health.todaySleep.value,
        sleepGoal: health.dailySleepGoal.value,
        exerciseMinutes: health.todayExerciseMinutes.value,
        exerciseGoal: health.dailyExerciseGoal.value,
      );
    });
  }

  void dispose() {
    _healthBinding?.call();
    _healthBinding = null;
  }
}
