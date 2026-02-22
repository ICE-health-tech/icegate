// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GpsLocation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GpsLocationImpl _$$GpsLocationImplFromJson(Map<String, dynamic> json) =>
    _$GpsLocationImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      speedAccuracy: (json['speedAccuracy'] as num?)?.toDouble() ?? 0.0,
      headingAccuracy: (json['headingAccuracy'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$GpsLocationImplToJson(_$GpsLocationImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'altitude': instance.altitude,
      'speed': instance.speed,
      'heading': instance.heading,
      'accuracy': instance.accuracy,
      'speedAccuracy': instance.speedAccuracy,
      'headingAccuracy': instance.headingAccuracy,
    };
