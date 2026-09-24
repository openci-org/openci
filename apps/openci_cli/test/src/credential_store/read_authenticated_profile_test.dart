import 'dart:convert';
import 'dart:io';

import 'package:openci_cli/src/auth/firebase_auth_client.dart';
import 'package:openci_cli/src/credential_store/credential_config.dart';
import 'package:openci_cli/src/credential_store/credential_store.dart';
import 'package:openci_cli/src/credential_store/read_authenticated_profile.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late CredentialStore store;
  late AuthProfile profile;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('openci-refresh-test-');
    store = CredentialStore(customFilePath: '${temp.path}/credentials.json');
    profile = AuthProfile(
      serverUrl: 'https://ci.example.com',
      teamId: 'team-1',
      authType: 'firebase',
      token: 'old-id-token',
      refreshToken: 'old-refresh-token',
      firebaseApiKey: 'firebase-api-key',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );
    await store.saveProfile('local', const AuthProfile(token: 'local-api-key'));
    await store.saveProfile('remote', profile);
  });

  tearDown(() => temp.delete(recursive: true));

  Future<AuthProfile?> readWith(MockClientHandler handler) =>
      http.runWithClient(
        () => readAuthenticatedProfile(store),
        () => MockClient(handler),
      );

  for (final host in [null, '127.0.0.1:9099']) {
    test('refreshes and persists rotated credentials: emulator=$host', () async {
      profile = profile.copyWith(firebaseAuthEmulatorHost: host);
      await store.saveProfile('remote', profile);
      final updated = await readWith((request) async {
        expect(
          request.url,
          Uri.parse(
            host == null
                ? 'https://securetoken.googleapis.com/v1/token?key=firebase-api-key'
                : 'http://127.0.0.1:9099/securetoken.googleapis.com/v1/token?key=firebase-api-key',
          ),
        );
        expect(request.bodyFields['refresh_token'], 'old-refresh-token');
        return http.Response(
          jsonEncode({
            'id_token': 'new-id-token',
            'refresh_token': 'new-refresh-token',
            'expires_in': '3600',
          }),
          200,
        );
      });

      expect(updated!.token, 'new-id-token');
      expect(updated.refreshToken, 'new-refresh-token');
      expect(updated.serverUrl, profile.serverUrl);
      expect(updated.teamId, 'team-1');
      expect(updated.firebaseApiKey, 'firebase-api-key');
      expect(updated.firebaseAuthEmulatorHost, host);
      expect(updated.expiresAt!.isAfter(DateTime.now().toUtc()), isTrue);
      final saved = await store.get();
      expect(saved.activeProfile, 'remote');
      expect(saved.profiles['remote'], updated);
      expect(saved.profiles['local']!.token, 'local-api-key');
    });
  }

  test(
    'keeps an unexpired Firebase session without a network request',
    () async {
      profile = profile.copyWith(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      );
      await store.saveProfile('remote', profile);
      final before = await File(store.filePath).readAsBytes();

      expect(
        await readWith((_) async => throw StateError('Unexpected request')),
        profile,
      );
      expect(await File(store.filePath).readAsBytes(), before);
    },
  );

  test('keeps local API key profiles without a network request', () async {
    const local = AuthProfile(token: 'local-api-key');
    await store.saveProfile('local', local);

    expect(
      await readWith((_) async => throw StateError('Unexpected request')),
      local,
    );
  });

  test(
    'preserves credentials when Firebase rejects the refresh token',
    () async {
      final before = await File(store.filePath).readAsBytes();

      await expectLater(
        readWith(
          (_) async => http.Response('{"error":"INVALID_REFRESH_TOKEN"}', 400),
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(await File(store.filePath).readAsBytes(), before);
    },
  );

  test(
    'emulator failure preserves the session without remote fallback',
    () async {
      await store.saveProfile(
        'local',
        profile.copyWith(firebaseAuthEmulatorHost: 'localhost:9099'),
      );
      final before = await File(store.filePath).readAsBytes();
      final requests = <Uri>[];

      await expectLater(
        readWith((request) async {
          requests.add(request.url);
          throw http.ClientException('Connection refused');
        }),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(requests, [
        Uri.parse(
          'http://localhost:9099/securetoken.googleapis.com/v1/token?key=firebase-api-key',
        ),
      ]);
      expect(await File(store.filePath).readAsBytes(), before);
    },
  );

  test(
    'rejects an invalid saved emulator host without changing credentials',
    () async {
      await store.saveProfile(
        'local',
        profile.copyWith(firebaseAuthEmulatorHost: ''),
      );
      final before = await File(store.filePath).readAsBytes();
      var requests = 0;

      await expectLater(
        readWith((_) async {
          requests++;
          throw StateError('Unexpected request');
        }),
        throwsA(isA<FormatException>()),
      );
      expect(requests, 0);
      expect(await File(store.filePath).readAsBytes(), before);
    },
  );

  test('rejects expired profiles without a refresh token', () async {
    await store.saveProfile('remote', profile.copyWith(refreshToken: ''));

    await expectLater(
      readWith((_) async => throw StateError('Unexpected request')),
      throwsA(isA<FirebaseAuthException>()),
    );
  });

  test('returns null when no active credentials exist', () async {
    await File(store.filePath).delete();
    expect(
      await readWith((_) async => throw StateError('Unexpected request')),
      isNull,
    );
  });
}
