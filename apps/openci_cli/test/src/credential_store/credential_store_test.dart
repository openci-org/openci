import 'dart:convert';
import 'dart:io';

import 'package:openci_cli/openci_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String customConfigPath;
  late CredentialStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('openci_cred_test_');
    customConfigPath = p.join(tempDir.path, 'credentials.json');
    store = CredentialStore(customFilePath: customConfigPath);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'get returns empty config when credentials file does not exist',
    () async {
      final config = await store.get();
      expect(config.activeProfile, equals('default'));
      expect(config.profiles, isEmpty);
      expect(await store.getActiveProfile(), isNull);
    },
  );

  test('set writes credentials file with 0600 permissions', () async {
    const config = CredentialConfig(
      activeProfile: 'prod',
      profiles: {
        'prod': AuthProfile(
          serverUrl: 'https://api.openci.org',
          token: 'secret-token',
        ),
      },
    );

    await store.set(config);

    final loaded = await store.get();
    expect(loaded, equals(config));

    if (!Platform.isWindows) {
      final stat = await File(customConfigPath).stat();
      // 0600 (octal) = 384 (decimal)
      expect(stat.mode & 0x1ff, equals(0x180));
    }
  });

  test(
    'saveProfile persists profile and sets it as active by default',
    () async {
      const localProfile = AuthProfile(
        serverUrl: 'http://localhost:8080',
        token: 'test-internal-key',
        teamId: 'dev-team',
        authType: 'api_key',
      );

      await store.saveProfile('local', localProfile);

      final loaded = await store.get();
      expect(loaded.activeProfile, equals('local'));
      expect(loaded.profiles['local'], equals(localProfile));

      final active = await store.getActiveProfile();
      expect(active, equals(localProfile));
    },
  );

  test('saveProfile supports multiple profiles and active switching', () async {
    const localProfile = AuthProfile(
      serverUrl: 'http://localhost:8080',
      token: 'local-key',
      teamId: 'local-team',
    );
    const prodProfile = AuthProfile(
      serverUrl: 'https://api.openci.org',
      token: 'prod-token',
      teamId: 'prod-team',
      authType: 'firebase_token',
    );

    await store.saveProfile('local', localProfile, setActive: true);
    await store.saveProfile('default', prodProfile, setActive: false);

    final active = await store.getActiveProfile();
    expect(active, equals(localProfile));

    final prod = await store.getProfile('default');
    expect(prod, equals(prodProfile));
  });

  test('persists the emulator host only on its matching profile', () async {
    const remote = AuthProfile(authType: 'firebase', token: 'remote-token');
    const local = AuthProfile(
      authType: 'firebase',
      token: 'local-token',
      refreshToken: 'local-refresh-token',
      firebaseApiKey: 'demo-key',
      firebaseAuthEmulatorHost: 'localhost:9099',
    );
    await store.saveProfile('remote', remote);
    await store.saveProfile('local', local);

    final reloaded = CredentialStore(customFilePath: store.filePath);
    expect(await reloaded.getProfile('local'), local);
    expect(await reloaded.getProfile('remote'), remote);
    final json = jsonDecode(await File(store.filePath).readAsString()) as Map;
    expect(
      json['profiles']['local']['firebase_auth_emulator_host'],
      'localhost:9099',
    );
    expect(
      json['profiles']['remote'],
      isNot(contains('firebase_auth_emulator_host')),
    );
  });

  test('loads existing profiles without emulator settings', () async {
    await File(store.filePath).writeAsString(
      jsonEncode({
        'active_profile': 'remote',
        'profiles': {
          'local': {'token': 'api-key'},
          'remote': {
            'auth_type': 'firebase',
            'token': 'id-token',
            'refresh_token': 'refresh-token',
            'firebase_api_key': 'firebase-key',
          },
        },
      }),
    );

    final saved = await store.get();
    expect(saved.activeProfile, 'remote');
    expect(saved.profiles['local'], const AuthProfile(token: 'api-key'));
    expect(saved.profiles['remote']!.firebaseAuthEmulatorHost, isNull);
    expect(saved.profiles['remote']!.refreshToken, 'refresh-token');
  });

  test(
    'deleteProfile removes profile and updates active profile if needed',
    () async {
      const localProfile = AuthProfile(
        serverUrl: 'http://localhost:8080',
        token: 'key',
        teamId: 'team',
      );

      await store.saveProfile('local', localProfile);
      expect(await store.getProfile('local'), isNotNull);

      final deleted = await store.deleteProfile('local');
      expect(deleted, isTrue);
      expect(await store.getProfile('local'), isNull);
      expect(await store.getActiveProfile(), isNull);

      final deleteNonExistent = await store.deleteProfile('non-existent');
      expect(deleteNonExistent, isFalse);
    },
  );

  test('toString masks token in AuthProfile and CredentialConfig', () {
    const profile = AuthProfile(
      serverUrl: 'http://localhost:8080',
      token: 'super-secret-api-key-12345',
      teamId: 'team-alpha',
      authType: 'api_key',
      refreshToken: 'private-refresh-token',
    );

    final profileStr = profile.toString();
    expect(profileStr, contains('http://localhost:8080'));
    expect(profileStr, contains('team-alpha'));
    expect(profileStr, contains('api_key'));
    expect(profileStr, contains('token: ***'));
    expect(profileStr, isNot(contains('super-secret-api-key-12345')));
    expect(profileStr, isNot(contains('private-refresh-token')));

    const config = CredentialConfig(
      activeProfile: 'local',
      profiles: {'local': profile},
    );

    final configStr = config.toString();
    expect(configStr, contains('activeProfile: local'));
    expect(configStr, contains('token: ***'));
    expect(configStr, isNot(contains('super-secret-api-key-12345')));
    expect(configStr, isNot(contains('private-refresh-token')));
  });

  test(
    'deleting an inactive profile preserves the active profile after reload',
    () async {
      const active = AuthProfile(
        serverUrl: 'https://ci.example.test',
        token: 'active-token',
      );
      const inactive = AuthProfile(
        serverUrl: 'http://localhost:8080',
        token: 'local-token',
      );
      await store.saveProfile('prod', active);
      await store.saveProfile('local', inactive, setActive: false);

      expect(await store.deleteProfile('local'), isTrue);
      final reloaded = CredentialStore(customFilePath: store.filePath);
      expect(await reloaded.getActiveProfile(), active);
      expect((await reloaded.get()).activeProfile, 'prod');
      expect(await reloaded.getProfile('local'), isNull);
    },
  );

  test('deleting the active profile selects a remaining profile', () async {
    const prod = AuthProfile(
      serverUrl: 'https://ci.example.test',
      token: 'prod-token',
    );
    const local = AuthProfile(
      serverUrl: 'http://localhost:8080',
      token: 'local-token',
    );
    await store.saveProfile('prod', prod);
    await store.saveProfile('local', local);

    expect(await store.deleteProfile('local'), isTrue);
    final reloaded = CredentialStore(customFilePath: store.filePath);
    expect(await reloaded.getActiveProfile(), prod);
    expect((await reloaded.get()).activeProfile, 'prod');
    expect(await reloaded.getProfile('local'), isNull);
  });
}
