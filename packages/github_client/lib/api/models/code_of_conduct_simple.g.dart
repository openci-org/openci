// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_of_conduct_simple.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CodeOfConductSimple _$CodeOfConductSimpleFromJson(Map<String, dynamic> json) =>
    _CodeOfConductSimple(
      url: json['url'] as String,
      key: json['Key'] as String,
      name: json['name'] as String,
      htmlUrl: json['html_url'] as String?,
    );

Map<String, dynamic> _$CodeOfConductSimpleToJson(
  _CodeOfConductSimple instance,
) => <String, dynamic>{
  'url': instance.url,
  'Key': instance.key,
  'name': instance.name,
  'html_url': instance.htmlUrl,
};
