// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ProfileProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileProtocolImpl _$$ProfileProtocolImplFromJson(
  Map<String, dynamic> json,
) => _$ProfileProtocolImpl(
  profileID: json['profileID'] as String,
  personID: json['personID'] as String,
  bio: json['bio'] as String?,
  occupation: json['occupation'] as String?,
  educationLevel: json['educationLevel'] as String?,
  location: json['location'] as String?,
  websiteUrl: json['websiteUrl'] as String?,
  linkedinUrl: json['linkedinUrl'] as String?,
  githubUrl: json['githubUrl'] as String?,
);

Map<String, dynamic> _$$ProfileProtocolImplToJson(
  _$ProfileProtocolImpl instance,
) => <String, dynamic>{
  'profileID': instance.profileID,
  'personID': instance.personID,
  'bio': instance.bio,
  'occupation': instance.occupation,
  'educationLevel': instance.educationLevel,
  'location': instance.location,
  'websiteUrl': instance.websiteUrl,
  'linkedinUrl': instance.linkedinUrl,
  'githubUrl': instance.githubUrl,
};
