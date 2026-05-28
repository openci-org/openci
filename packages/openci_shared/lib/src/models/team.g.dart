// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Team _$TeamFromJson(Map<String, dynamic> json) => _Team(
  id: json['id'] as String,
  name: json['name'] as String,
  members: (json['members'] as List<dynamic>).map((e) => e as String).toList(),
  installationIds:
      (json['installationIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  runNumber: (json['runNumber'] as num?)?.toInt() ?? 1,
  aiEnabled: json['aiEnabled'] as bool? ?? true,
  githubBaseUrl: json['githubBaseUrl'] as String?,
  githubApiBaseUrl: json['githubApiBaseUrl'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt'] as Object),
);

Map<String, dynamic> _$TeamToJson(_Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'members': instance.members,
  'installationIds': instance.installationIds,
  'runNumber': instance.runNumber,
  'aiEnabled': instance.aiEnabled,
  'githubBaseUrl': instance.githubBaseUrl,
  'githubApiBaseUrl': instance.githubApiBaseUrl,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
};
