// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Output _$OutputFromJson(Map<String, dynamic> json) => _Output(
  title: json['title'] as String,
  summary: json['summary'] as String,
  text: json['text'] as String?,
  annotations: (json['annotations'] as List<dynamic>?)
      ?.map((e) => Annotations.fromJson(e as Map<String, dynamic>))
      .toList(),
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => Images.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OutputToJson(_Output instance) => <String, dynamic>{
  'title': instance.title,
  'summary': instance.summary,
  'text': instance.text,
  'annotations': instance.annotations,
  'images': instance.images,
};
