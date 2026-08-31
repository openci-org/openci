import 'package:freezed_annotation/freezed_annotation.dart';

part 'credential_config.freezed.dart';
part 'credential_config.g.dart';

@freezed
abstract class AuthProfile with _$AuthProfile {
  const AuthProfile._();

  const factory AuthProfile({
    @JsonKey(name: 'server_url')
    @Default('http://localhost:8080')
    String serverUrl,
    @Default('') String token,
    @JsonKey(name: 'team_id') @Default('') String teamId,
    @JsonKey(name: 'auth_type') @Default('api_key') String authType,
  }) = _AuthProfile;

  factory AuthProfile.fromJson(Map<String, dynamic> json) =>
      _$AuthProfileFromJson(json);

  @override
  String toString() {
    final maskedToken = token.isEmpty ? '' : '***';
    return 'AuthProfile(serverUrl: $serverUrl, token: $maskedToken, teamId: $teamId, authType: $authType)';
  }
}

@freezed
abstract class CredentialConfig with _$CredentialConfig {
  const factory CredentialConfig({
    @JsonKey(name: 'active_profile') @Default('default') String activeProfile,
    @Default({}) Map<String, AuthProfile> profiles,
  }) = _CredentialConfig;

  factory CredentialConfig.fromJson(Map<String, dynamic> json) =>
      _$CredentialConfigFromJson(json);
}
