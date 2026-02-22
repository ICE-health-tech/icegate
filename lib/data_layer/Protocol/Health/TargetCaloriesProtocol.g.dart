// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TargetCaloriesProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TargetCaloriesProtocolImpl _$$TargetCaloriesProtocolImplFromJson(
  Map<String, dynamic> json,
) => _$TargetCaloriesProtocolImpl(
  calories: (json['calories'] as num).toInt(),
  protein: (json['protein'] as num).toInt(),
  carbs: (json['carbs'] as num).toInt(),
  fat: (json['fat'] as num).toInt(),
);

Map<String, dynamic> _$$TargetCaloriesProtocolImplToJson(
  _$TargetCaloriesProtocolImpl instance,
) => <String, dynamic>{
  'calories': instance.calories,
  'protein': instance.protein,
  'carbs': instance.carbs,
  'fat': instance.fat,
};
