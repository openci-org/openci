// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nullable_license_simple.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NullableLicenseSimple _$NullableLicenseSimpleFromJson(
  Map<String, dynamic> json,
) => _NullableLicenseSimple(
  key: json['Key'] as String,
  name: json['name'] as String,
  url: json['url'] as String?,
  spdxId: json['spdx_id'] as String?,
  nodeId: json['node_id'] as String,
  htmlUrl: json['html_url'] as String?,
);

Map<String, dynamic> _$NullableLicenseSimpleToJson(
  _NullableLicenseSimple instance,
) => <String, dynamic>{
  'Key': instance.key,
  'name': instance.name,
  'url': instance.url,
  'spdx_id': instance.spdxId,
  'node_id': instance.nodeId,
  'html_url': instance.htmlUrl,
};
