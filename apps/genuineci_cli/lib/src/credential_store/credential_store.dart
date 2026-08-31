import 'package:genuineci_cli/src/credential_store/credential_config.dart';

import '../json_file_store/json_file_store.dart';

class CredentialStore {
  final JsonFileStore<CredentialConfig> _store;

  CredentialStore({String? customFilePath})
    : _store = JsonFileStore<CredentialConfig>(
        filePath:
            customFilePath ?? JsonFileStore.defaultPath('credentials.json'),
        fromJson: CredentialConfig.fromJson,
        toJson: (config) => config.toJson(),
      );

  String get filePath => _store.filePath;

  Future<CredentialConfig> get() async {
    return (await _store.get()) ?? const CredentialConfig();
  }

  Future<void> set(CredentialConfig config) async {
    await _store.set(config, chmod600: true);
  }

  Future<void> saveProfile(
    String name,
    AuthProfile profile, {
    bool setActive = true,
  }) async {
    final current = await get();
    final updatedProfiles = Map<String, AuthProfile>.from(current.profiles);
    updatedProfiles[name] = profile;

    final updated = current.copyWith(
      activeProfile: setActive ? name : current.activeProfile,
      profiles: updatedProfiles,
    );
    await set(updated);
  }

  Future<AuthProfile?> getActiveProfile() async {
    final current = await get();
    return current.profiles[current.activeProfile];
  }

  Future<AuthProfile?> getProfile(String name) async {
    final current = await get();
    return current.profiles[name];
  }

  Future<bool> deleteProfile(String name) async {
    final current = await get();
    if (!current.profiles.containsKey(name)) {
      return false;
    }
    final updatedProfiles = Map<String, AuthProfile>.from(current.profiles)
      ..remove(name);
    final nextActive = current.activeProfile == name
        ? (updatedProfiles.keys.firstOrNull ?? 'default')
        : current.activeProfile;

    await set(
      current.copyWith(activeProfile: nextActive, profiles: updatedProfiles),
    );
    return true;
  }
}
