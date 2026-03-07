import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ice_gate/data_layer/Protocol/Health/TargetCaloriesProtocol.dart';

part 'HumanEvaluation.freezed.dart';
part 'HumanEvaluation.g.dart';

/// Human body metrics for health evaluation
@freezed
abstract class HumanBodyMetrics with _$HumanBodyMetrics {
  const factory HumanBodyMetrics({
    required double weight, // in kg
    required double height, // in cm
    required int age,
    required String gender, // 'male' or 'female'
    required String
    activityLevel, // 'sedentary', 'light', 'moderate', 'active', 'very_active'
    String? goal, // 'lose_weight', 'maintain', 'gain_weight', 'gain_muscle'
  }) = _HumanBodyMetrics;

  factory HumanBodyMetrics.fromJson(Map<String, dynamic> json) =>
      _$HumanBodyMetricsFromJson(json);

  factory HumanBodyMetrics.empty() {
    return const HumanBodyMetrics(
      weight: 0,
      height: 0,
      age: 0,
      gender: 'male',
      activityLevel: 'moderate',
      goal: 'maintain',
    );
  }
}

/// Blood test metrics for health evaluation
@freezed
abstract class BloodTestMetrics with _$BloodTestMetrics {
  const factory BloodTestMetrics({
    double? glucose, // mg/dL
    double? cholesterol, // mg/dL
    double? hdl, // mg/dL (good cholesterol)
    double? ldl, // mg/dL (bad cholesterol)
    double? triglycerides, // mg/dL
    double? hemoglobin, // g/dL
    double? whiteBloodCells, // cells/mcL
    double? platelets, // cells/mcL
    String? bloodType, // 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  }) = _BloodTestMetrics;

  factory BloodTestMetrics.fromJson(Map<String, dynamic> json) =>
      _$BloodTestMetricsFromJson(json);

  factory BloodTestMetrics.empty() {
    return const BloodTestMetrics();
  }
}

/// Input values for human health evaluation
@freezed
abstract class HumanInputValues with _$HumanInputValues {
  const factory HumanInputValues({
    required HumanBodyMetrics humanBodyMetrics,
    required BloodTestMetrics bloodTestMetrics,
    required TargetCaloriesProtocol caloriesProtocol,
  }) = _HumanInputValues;

  factory HumanInputValues.fromJson(Map<String, dynamic> json) =>
      _$HumanInputValuesFromJson(json);

  factory HumanInputValues.empty() {
    return HumanInputValues(
      humanBodyMetrics: HumanBodyMetrics.empty(),
      bloodTestMetrics: BloodTestMetrics.empty(),
      caloriesProtocol: TargetCaloriesProtocol.empty(),
    );
  }
}

/// Target values calculated from human health evaluation
@freezed
abstract class HumanTargetValues with _$HumanTargetValues {
  const factory HumanTargetValues({
    required HumanBodyMetrics humanBodyMetrics,
    required BloodTestMetrics bloodTestMetrics,
    required TargetCaloriesProtocol caloriesProtocol,
    double? bmi, // Body Mass Index
    double? bmr, // Basal Metabolic Rate
    double? tdee, // Total Daily Energy Expenditure
    String? healthStatus, // 'excellent', 'good', 'fair', 'poor'
    List<String>? recommendations,
  }) = _HumanTargetValues;

  factory HumanTargetValues.fromJson(Map<String, dynamic> json) =>
      _$HumanTargetValuesFromJson(json);

  factory HumanTargetValues.empty() {
    return HumanTargetValues(
      humanBodyMetrics: HumanBodyMetrics.empty(),
      bloodTestMetrics: BloodTestMetrics.empty(),
      caloriesProtocol: TargetCaloriesProtocol.empty(),
    );
  }

  /// Calculate BMI from body metrics
  factory HumanTargetValues.fromEvaluation({
    required HumanBodyMetrics bodyMetrics,
    required BloodTestMetrics bloodMetrics,
    required TargetCaloriesProtocol calories,
  }) {
    // Calculate BMI
    final heightInMeters = bodyMetrics.height / 100;
    final bmi = bodyMetrics.weight / (heightInMeters * heightInMeters);

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (bodyMetrics.gender.toLowerCase() == 'male') {
      bmr =
          (10 * bodyMetrics.weight) +
          (6.25 * bodyMetrics.height) -
          (5 * bodyMetrics.age) +
          5;
    } else {
      bmr =
          (10 * bodyMetrics.weight) +
          (6.25 * bodyMetrics.height) -
          (5 * bodyMetrics.age) -
          161;
    }

    // Calculate TDEE based on activity level
    double activityMultiplier;
    switch (bodyMetrics.activityLevel.toLowerCase()) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'very_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }
    final tdee = bmr * activityMultiplier;

    // Determine health status based on BMI and blood metrics
    String healthStatus;
    if (bmi < 18.5) {
      healthStatus = 'underweight';
    } else if (bmi < 25) {
      healthStatus = 'healthy';
    } else if (bmi < 30) {
      healthStatus = 'overweight';
    } else {
      healthStatus = 'obese';
    }

    // Generate recommendations
    final recommendations = <String>[];
    if (bmi < 18.5) {
      recommendations.add('Consider increasing calorie intake');
    } else if (bmi >= 25) {
      recommendations.add(
        'Consider reducing calorie intake and increasing exercise',
      );
    }

    if (bloodMetrics.cholesterol != null && bloodMetrics.cholesterol! > 200) {
      recommendations.add('High cholesterol detected - consult a doctor');
    }

    if (bloodMetrics.glucose != null && bloodMetrics.glucose! > 100) {
      recommendations.add('Elevated glucose levels - monitor blood sugar');
    }

    return HumanTargetValues(
      humanBodyMetrics: bodyMetrics,
      bloodTestMetrics: bloodMetrics,
      caloriesProtocol: calories,
      bmi: bmi,
      bmr: bmr,
      tdee: tdee,
      healthStatus: healthStatus,
      recommendations: recommendations.isEmpty ? null : recommendations,
    );
  }
}

/// Extension methods for HumanBodyMetrics
extension HumanBodyMetricsExtension on HumanBodyMetrics {
  /// Calculate BMI (Body Mass Index)
  double get bmi {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal weight';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  /// Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
  double get bmr {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  double get tdee {
    double multiplier;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.55;
    }
    return bmr * multiplier;
  }
}
