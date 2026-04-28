import 'package:freezed_annotation/freezed_annotation.dart';

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
}
