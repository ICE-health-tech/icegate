// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AuthenticationProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthenticationProtocolImpl _$$AuthenticationProtocolImplFromJson(
  Map<String, dynamic> json,
) => _$AuthenticationProtocolImpl(
  username: json['username'] as String,
  password: json['password'] as String,
  jwt: json['jwt'] as String,
);

Map<String, dynamic> _$$AuthenticationProtocolImplToJson(
  _$AuthenticationProtocolImpl instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'jwt': instance.jwt,
};
