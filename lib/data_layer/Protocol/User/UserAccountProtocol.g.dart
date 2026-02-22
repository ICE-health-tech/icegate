// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserAccountProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserAccountProtocolImpl _$$UserAccountProtocolImplFromJson(
  Map<String, dynamic> json,
) => _$UserAccountProtocolImpl(
  accountID: (json['accountID'] as num).toInt(),
  personID: (json['personID'] as num).toInt(),
  username: json['username'] as String,
  primaryEmail: json['primaryEmail'] as String?,
  role: json['role'] as String? ?? 'user',
  isLocked: json['isLocked'] as bool? ?? false,
  lastLoginAt: json['lastLoginAt'] == null
      ? null
      : DateTime.parse(json['lastLoginAt'] as String),
);

Map<String, dynamic> _$$UserAccountProtocolImplToJson(
  _$UserAccountProtocolImpl instance,
) => <String, dynamic>{
  'accountID': instance.accountID,
  'personID': instance.personID,
  'username': instance.username,
  'primaryEmail': instance.primaryEmail,
  'role': instance.role,
  'isLocked': instance.isLocked,
  'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
};
