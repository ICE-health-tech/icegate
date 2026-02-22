// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'InternalWidgetDragProtocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemImpl _$$ItemImplFromJson(Map<String, dynamic> json) => _$ItemImpl(
  url: json['url'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
  alias: json['alias'] as String,
  dateAdded: json['dateAdded'] as String,
  widgetID: (json['widgetID'] as num).toInt(),
  isStay: json['isStay'] as bool? ?? false,
  isTarget: json['isTarget'] as bool? ?? false,
  score: (json['score'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$ItemImplToJson(_$ItemImpl instance) =>
    <String, dynamic>{
      'url': instance.url,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'alias': instance.alias,
      'dateAdded': instance.dateAdded,
      'widgetID': instance.widgetID,
      'isStay': instance.isStay,
      'isTarget': instance.isTarget,
      'score': instance.score,
    };
