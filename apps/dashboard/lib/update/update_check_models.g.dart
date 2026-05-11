// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_check_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LatestBuildInfo _$LatestBuildInfoFromJson(Map<String, dynamic> json) =>
    _LatestBuildInfo(
      version: json['version'] as String? ?? '',
      sha: json['sha'] as String? ?? '',
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LatestBuildInfoToJson(_LatestBuildInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'sha': instance.sha,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
