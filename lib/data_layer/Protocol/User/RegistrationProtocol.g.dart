// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RegistrationProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegistrationPayloadImpl _$$RegistrationPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$RegistrationPayloadImpl(
  userName: json['userName'] as String,
  password: json['password'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  role: json['role'] as String? ?? 'USER',
);

Map<String, dynamic> _$$RegistrationPayloadImplToJson(
  _$RegistrationPayloadImpl instance,
) => <String, dynamic>{
  'userName': instance.userName,
  'password': instance.password,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'role': instance.role,
};
