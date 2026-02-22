// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CVAddressProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CVAddressProtocolImpl _$$CVAddressProtocolImplFromJson(
  Map<String, dynamic> json,
) => _$CVAddressProtocolImpl(
  cvAddressID: (json['cvAddressID'] as num).toInt(),
  personID: (json['personID'] as num).toInt(),
  githubUrl: json['githubUrl'] as String?,
  websiteUrl: json['websiteUrl'] as String?,
  company: json['company'] as String?,
  university: json['university'] as String?,
  location: json['location'] as String?,
  country: json['country'] as String?,
  bio: json['bio'] as String?,
  occupation: json['occupation'] as String?,
  educationLevel: json['educationLevel'] as String?,
  linkedinUrl: json['linkedinUrl'] as String?,
);

Map<String, dynamic> _$$CVAddressProtocolImplToJson(
  _$CVAddressProtocolImpl instance,
) => <String, dynamic>{
  'cvAddressID': instance.cvAddressID,
  'personID': instance.personID,
  'githubUrl': instance.githubUrl,
  'websiteUrl': instance.websiteUrl,
  'company': instance.company,
  'university': instance.university,
  'location': instance.location,
  'country': instance.country,
  'bio': instance.bio,
  'occupation': instance.occupation,
  'educationLevel': instance.educationLevel,
  'linkedinUrl': instance.linkedinUrl,
};
