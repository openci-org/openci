// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installation_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstallationToken _$InstallationTokenFromJson(Map<String, dynamic> json) =>
    _InstallationToken(
      token: json['token'] as String,
      expiresAt: json['expires_at'] as String,
      permissions: json['permissions'] == null
          ? null
          : AppPermissions.fromJson(
              json['permissions'] as Map<String, dynamic>,
            ),
      repositorySelection: json['repository_selection'] == null
          ? null
          : InstallationTokenRepositorySelection.fromJson(
              json['repository_selection'] as String,
            ),
      repositories: (json['repositories'] as List<dynamic>?)
          ?.map((e) => Repository.fromJson(e as Map<String, dynamic>))
          .toList(),
      singleFile: json['single_file'] as String?,
      hasMultipleSingleFiles: json['has_multiple_single_files'] as bool?,
      singleFilePaths: (json['single_file_paths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$InstallationTokenToJson(_InstallationToken instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expires_at': instance.expiresAt,
      'permissions': instance.permissions,
      'repository_selection':
          _$InstallationTokenRepositorySelectionEnumMap[instance
              .repositorySelection],
      'repositories': instance.repositories,
      'single_file': instance.singleFile,
      'has_multiple_single_files': instance.hasMultipleSingleFiles,
      'single_file_paths': instance.singleFilePaths,
    };

const _$InstallationTokenRepositorySelectionEnumMap = {
  InstallationTokenRepositorySelection.all: 'all',
  InstallationTokenRepositorySelection.selected: 'selected',
  InstallationTokenRepositorySelection.$unknown: r'$unknown',
};
