// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_installations_installation_id_access_tokens_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppInstallationsInstallationIdAccessTokensRequestBody
_$AppInstallationsInstallationIdAccessTokensRequestBodyFromJson(
  Map<String, dynamic> json,
) => _AppInstallationsInstallationIdAccessTokensRequestBody(
  repositories: (json['repositories'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  repositoryIds: (json['repository_ids'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  permissions: json['permissions'] == null
      ? null
      : AppPermissions.fromJson(json['permissions'] as Map<String, dynamic>),
);

Map<String, dynamic>
_$AppInstallationsInstallationIdAccessTokensRequestBodyToJson(
  _AppInstallationsInstallationIdAccessTokensRequestBody instance,
) => <String, dynamic>{
  'repositories': instance.repositories,
  'repository_ids': instance.repositoryIds,
  'permissions': instance.permissions,
};
