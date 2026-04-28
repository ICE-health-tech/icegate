import 'package:freezed_annotation/freezed_annotation.dart';

// Standard Dart naming convention uses snake_case for file names
part 'CaloriesProtocol.freezed.dart';

@freezed
abstract class CaloriesProtocol with _$CaloriesProtocol {
  const factory CaloriesProtocol({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String? imageUrl,
  }) = _CaloriesProtocol;

  // factory CaloriesProtocol.fromJson(Map<String, dynamic> json) =>
  //     _$CaloriesProtocolFromJson(json);

  // You can keep this as a factory or a static method
  factory CaloriesProtocol.empty() {
    return const CaloriesProtocol(calories: 0, protein: 0, carbs: 0, fat: 0);
  }
  factory CaloriesProtocol.fromJson(Map<String, dynamic> json) {
    final fat = (json['fat'] as num? ?? 0).toInt();
    final carbs = (json['carbs'] as num? ?? 0).toInt();
    final protein = (json['protein'] as num? ?? 0).toInt();
    final calories = (json['calories'] as num? ?? 0).toInt();
    final imageUrl = (json['imageUrl'] ?? json['image_url']) as String?;
    return CaloriesProtocol(
      fat: fat,
      carbs: carbs,
      protein: protein,
      calories: calories,
      imageUrl: imageUrl,
    );
  }
}
