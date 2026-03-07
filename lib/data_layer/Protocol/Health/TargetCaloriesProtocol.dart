import 'package:freezed_annotation/freezed_annotation.dart';
// import 'package:ice_gate/initial_layer/DuyLongServices/GeminiAPI.dart';
import 'package:ice_gate/initial_layer/CoreLogics/HumanEvaluation.dart';
// import 'package:ice_gate/initial_layer/Services/PersonHealthEvaluation.dart';

// Standard Dart naming convention uses snake_case for file names
part 'TargetCaloriesProtocol.freezed.dart';
part 'TargetCaloriesProtocol.g.dart';

@freezed
abstract class TargetCaloriesProtocol with _$TargetCaloriesProtocol {
  const factory TargetCaloriesProtocol({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) = _TargetCaloriesProtocol;

  factory TargetCaloriesProtocol.fromJson(Map<String, dynamic> json) =>
      _$TargetCaloriesProtocolFromJson(json);

  // You can keep this as a factory or a static method
  factory TargetCaloriesProtocol.empty() {
    return const TargetCaloriesProtocol(
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
  }
  factory TargetCaloriesProtocol.fromEvaluation(HumanInputValues inputValues) {
    HumanTargetValues humanTargetValues = HumanTargetValues.fromEvaluation(
      bodyMetrics: inputValues.humanBodyMetrics,
      bloodMetrics: inputValues.bloodTestMetrics,
      calories: inputValues.caloriesProtocol,
    );

    return TargetCaloriesProtocol(
      calories: humanTargetValues.caloriesProtocol.calories,
      protein: humanTargetValues.caloriesProtocol.protein,
      carbs: humanTargetValues.caloriesProtocol.carbs,
      fat: humanTargetValues.caloriesProtocol.fat,
    );
  }
}
