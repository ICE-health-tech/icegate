// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EmailAddressProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EmailAddressProtocolImpl _$$EmailAddressProtocolImplFromJson(
  Map<String, dynamic> json,
) => _$EmailAddressProtocolImpl(
  emailAddressID: json['emailAddressID'] as String,
  personID: json['personID'] as String,
  emailAddress: json['emailAddress'] as String,
  emailType: json['emailType'] as String? ?? 'personal',
  isPrimary: json['isPrimary'] as bool? ?? true,
  status:
      $enumDecodeNullable(_$EmailStatusEnumMap, json['status']) ??
      EmailStatus.pending,
  verifiedAt: json['verifiedAt'] == null
      ? null
      : DateTime.parse(json['verifiedAt'] as String),
);

Map<String, dynamic> _$$EmailAddressProtocolImplToJson(
  _$EmailAddressProtocolImpl instance,
) => <String, dynamic>{
  'emailAddressID': instance.emailAddressID,
  'personID': instance.personID,
  'emailAddress': instance.emailAddress,
  'emailType': instance.emailType,
  'isPrimary': instance.isPrimary,
  'status': _$EmailStatusEnumMap[instance.status]!,
  'verifiedAt': instance.verifiedAt?.toIso8601String(),
};

const _$EmailStatusEnumMap = {
  EmailStatus.pending: 'pending',
  EmailStatus.verified: 'verified',
  EmailStatus.bounced: 'bounced',
  EmailStatus.disabled: 'disabled',
};
