// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthProfile _$AuthProfileFromJson(Map<String, dynamic> json) => _AuthProfile(
  serverUrl: json['server_url'] as String? ?? 'http://localhost:8080',
  token: json['token'] as String? ?? '',
  teamId: json['team_id'] as String? ?? '',
  authType: json['auth_type'] as String? ?? 'api_key',
);

Map<String, dynamic> _$AuthProfileToJson(_AuthProfile instance) =>
    <String, dynamic>{
      'server_url': instance.serverUrl,
      'token': instance.token,
      'team_id': instance.teamId,
      'auth_type': instance.authType,
    };

_CredentialConfig _$CredentialConfigFromJson(Map<String, dynamic> json) =>
    _CredentialConfig(
      activeProfile: json['active_profile'] as String? ?? 'default',
      profiles:
          (json['profiles'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, AuthProfile.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$CredentialConfigToJson(_CredentialConfig instance) =>
    <String, dynamic>{
      'active_profile': instance.activeProfile,
      'profiles': instance.profiles,
    };
