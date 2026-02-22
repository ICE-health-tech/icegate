// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'HumanEvaluation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HumanBodyMetricsImpl _$$HumanBodyMetricsImplFromJson(
  Map<String, dynamic> json,
) => _$HumanBodyMetricsImpl(
  weight: (json['weight'] as num).toDouble(),
  height: (json['height'] as num).toDouble(),
  age: (json['age'] as num).toInt(),
  gender: json['gender'] as String,
  activityLevel: json['activityLevel'] as String,
  goal: json['goal'] as String?,
);

Map<String, dynamic> _$$HumanBodyMetricsImplToJson(
  _$HumanBodyMetricsImpl instance,
) => <String, dynamic>{
  'weight': instance.weight,
  'height': instance.height,
  'age': instance.age,
  'gender': instance.gender,
  'activityLevel': instance.activityLevel,
  'goal': instance.goal,
};

_$BloodTestMetricsImpl _$$BloodTestMetricsImplFromJson(
  Map<String, dynamic> json,
) => _$BloodTestMetricsImpl(
  glucose: (json['glucose'] as num?)?.toDouble(),
  cholesterol: (json['cholesterol'] as num?)?.toDouble(),
  hdl: (json['hdl'] as num?)?.toDouble(),
  ldl: (json['ldl'] as num?)?.toDouble(),
  triglycerides: (json['triglycerides'] as num?)?.toDouble(),
  hemoglobin: (json['hemoglobin'] as num?)?.toDouble(),
  whiteBloodCells: (json['whiteBloodCells'] as num?)?.toDouble(),
  platelets: (json['platelets'] as num?)?.toDouble(),
  bloodType: json['bloodType'] as String?,
);

Map<String, dynamic> _$$BloodTestMetricsImplToJson(
  _$BloodTestMetricsImpl instance,
) => <String, dynamic>{
  'glucose': instance.glucose,
  'cholesterol': instance.cholesterol,
  'hdl': instance.hdl,
  'ldl': instance.ldl,
  'triglycerides': instance.triglycerides,
  'hemoglobin': instance.hemoglobin,
  'whiteBloodCells': instance.whiteBloodCells,
  'platelets': instance.platelets,
  'bloodType': instance.bloodType,
};

_$HumanInputValuesImpl _$$HumanInputValuesImplFromJson(
  Map<String, dynamic> json,
) => _$HumanInputValuesImpl(
  humanBodyMetrics: HumanBodyMetrics.fromJson(
    json['humanBodyMetrics'] as Map<String, dynamic>,
  ),
  bloodTestMetrics: BloodTestMetrics.fromJson(
    json['bloodTestMetrics'] as Map<String, dynamic>,
  ),
  caloriesProtocol: TargetCaloriesProtocol.fromJson(
    json['caloriesProtocol'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$HumanInputValuesImplToJson(
  _$HumanInputValuesImpl instance,
) => <String, dynamic>{
  'humanBodyMetrics': instance.humanBodyMetrics,
  'bloodTestMetrics': instance.bloodTestMetrics,
  'caloriesProtocol': instance.caloriesProtocol,
};

_$HumanTargetValuesImpl _$$HumanTargetValuesImplFromJson(
  Map<String, dynamic> json,
) => _$HumanTargetValuesImpl(
  humanBodyMetrics: HumanBodyMetrics.fromJson(
    json['humanBodyMetrics'] as Map<String, dynamic>,
  ),
  bloodTestMetrics: BloodTestMetrics.fromJson(
    json['bloodTestMetrics'] as Map<String, dynamic>,
  ),
  caloriesProtocol: TargetCaloriesProtocol.fromJson(
    json['caloriesProtocol'] as Map<String, dynamic>,
  ),
  bmi: (json['bmi'] as num?)?.toDouble(),
  bmr: (json['bmr'] as num?)?.toDouble(),
  tdee: (json['tdee'] as num?)?.toDouble(),
  healthStatus: json['healthStatus'] as String?,
  recommendations: (json['recommendations'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$$HumanTargetValuesImplToJson(
  _$HumanTargetValuesImpl instance,
) => <String, dynamic>{
  'humanBodyMetrics': instance.humanBodyMetrics,
  'bloodTestMetrics': instance.bloodTestMetrics,
  'caloriesProtocol': instance.caloriesProtocol,
  'bmi': instance.bmi,
  'bmr': instance.bmr,
  'tdee': instance.tdee,
  'healthStatus': instance.healthStatus,
  'recommendations': instance.recommendations,
};
