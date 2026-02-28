// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PersonProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonProtocolImpl _$$PersonProtocolImplFromJson(Map<String, dynamic> json) =>
    _$PersonProtocolImpl(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$PersonProtocolImplToJson(
  _$PersonProtocolImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
  'gender': instance.gender,
  'phoneNumber': instance.phoneNumber,
  'profileImageUrl': instance.profileImageUrl,
  'isActive': instance.isActive,
};
