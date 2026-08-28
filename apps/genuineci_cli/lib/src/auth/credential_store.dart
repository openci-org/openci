import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'credential_store.freezed.dart';
part 'credential_store.g.dart';

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

class CredentialStore {
  final String _filePath;

  CredentialStore({String? customFilePath})
    : _filePath = customFilePath ?? _defaultCredentialsPath();

  static String _defaultCredentialsPath() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.join(home, '.genuineci', 'credentials.json');
  }

  String get filePath => _filePath;

  Future<CredentialConfig> load() async {
    final file = File(_filePath);
    if (!await file.exists()) {
      return const CredentialConfig();
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      throw FormatException('Credential file at $_filePath is empty.');
    }
    final json = jsonDecode(content);
    if (json is! Map<String, dynamic>) {
      throw FormatException(
        'Invalid JSON format in credential file at $_filePath.',
      );
    }
    return CredentialConfig.fromJson(json);
  }

  Future<void> save(CredentialConfig config) async {
    final file = File(_filePath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    const encoder = JsonEncoder.withIndent('  ');
    final content = '${encoder.convert(config.toJson())}\n';

    final tempFile = File(
      '${file.path}.tmp.${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await tempFile.writeAsString(content, flush: true);
      await tempFile.rename(file.path);
    } catch (_) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> saveProfile(
    String name,
    AuthProfile profile, {
    bool setActive = true,
  }) async {
    final current = await load();
    final updatedProfiles = Map<String, AuthProfile>.from(current.profiles);
    updatedProfiles[name] = profile;

    final updated = current.copyWith(
      activeProfile: setActive ? name : current.activeProfile,
      profiles: updatedProfiles,
    );
    await save(updated);
  }

  Future<AuthProfile?> getActiveProfile() async {
    final current = await load();
    return current.profiles[current.activeProfile];
  }

  Future<AuthProfile?> getProfile(String name) async {
    final current = await load();
    return current.profiles[name];
  }

  Future<bool> deleteProfile(String name) async {
    final current = await load();
    if (!current.profiles.containsKey(name)) {
      return false;
    }
    final updatedProfiles = Map<String, AuthProfile>.from(current.profiles)
      ..remove(name);
    final nextActive = current.activeProfile == name
        ? (updatedProfiles.keys.firstOrNull ?? 'default')
        : current.activeProfile;

    await save(
      current.copyWith(activeProfile: nextActive, profiles: updatedProfiles),
    );
    return true;
  }
}
