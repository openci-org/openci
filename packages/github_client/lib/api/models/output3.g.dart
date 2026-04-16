// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Output3 _$Output3FromJson(Map<String, dynamic> json) => _Output3(
  title: json['title'] as String?,
  summary: json['summary'] as String?,
  text: json['text'] as String?,
  annotationsCount: (json['annotations_count'] as num).toInt(),
  annotationsUrl: json['annotations_url'] as String,
);

Map<String, dynamic> _$Output3ToJson(_Output3 instance) => <String, dynamic>{
  'title': instance.title,
  'summary': instance.summary,
  'text': instance.text,
  'annotations_count': instance.annotationsCount,
  'annotations_url': instance.annotationsUrl,
};
