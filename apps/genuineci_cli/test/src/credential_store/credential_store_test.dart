import 'dart:io';

import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/credential_store/credential_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String customConfigPath;
  late CredentialStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('genuineci_cred_test_');
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
    );

    final profileStr = profile.toString();
    expect(profileStr, contains('http://localhost:8080'));
    expect(profileStr, contains('team-alpha'));
    expect(profileStr, contains('api_key'));
    expect(profileStr, contains('token: ***'));
    expect(profileStr, isNot(contains('super-secret-api-key-12345')));

    const config = CredentialConfig(
      activeProfile: 'local',
      profiles: {'local': profile},
    );

    final configStr = config.toString();
    expect(configStr, contains('activeProfile: local'));
    expect(configStr, contains('token: ***'));
    expect(configStr, isNot(contains('super-secret-api-key-12345')));
  });
}
