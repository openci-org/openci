// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Output2 _$Output2FromJson(Map<String, dynamic> json) => _Output2(
  summary: json['summary'] as String,
  title: json['title'] as String?,
  text: json['text'] as String?,
  annotations: (json['annotations'] as List<dynamic>?)
      ?.map((e) => Annotations2.fromJson(e as Map<String, dynamic>))
      .toList(),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => Images2.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Output2ToJson(_Output2 instance) => <String, dynamic>{
  'summary': instance.summary,
  'title': instance.title,
  'text': instance.text,
  'annotations': instance.annotations,
  'images': instance.images,
};
