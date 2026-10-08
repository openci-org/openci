import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/asc/asc_api_key.dart';
import 'package:genuineci_cli/src/asc/asc_api_key_secret.dart';
import 'package:genuineci_cli/src/commands/setup/asc_key_registration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Logger implements Logger {
  final output = <String>[];
  final errors = <String>[];
  @override
  void stdout(String message) => output.add(message);
  @override
  void stderr(String message) => errors.add(message);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client extends MockClient {
  _Client(super.fn);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  const token = 'private-test-token';
  const pem =
      '-----BEGIN PRIVATE KEY-----\ndGVzdA==\n-----END PRIVATE KEY-----\n';
  const profile = AuthProfile(
    serverUrl: 'https://ci.example.com/proxy/',
    token: token,
    teamId: 'selected-team',
  );
  late Directory directory;
  late CredentialStore store;
  late _Logger logger;
  late AscApiKey key;
  late AscKeyRegistration registration;
  late MockClientHandler handler;
  late List<http.Request> requests;
  late List<_Client> clients;
  late AppLocale originalLocale;
  late bool certificateKeyExists;

  http.Response response(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  http.Response successResponse(http.Request request) {
    if (request.url.path.endsWith('/ios-signing/generate-key')) {
      certificateKeyExists = true;
    }
    return response(
      request.method == 'GET'
          ? {
              'success': true,
              'secrets': [
                if (certificateKeyExists)
                  {'name': iosCertificatePrivateKeySecretName},
              ],
            }
          : {'success': true},
    );
  }

  setUp(() async {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    directory = await Directory.systemTemp.createTemp('asc registration test ');
    store = CredentialStore(
      customFilePath: p.join(directory.path, 'credentials.json'),
    );
    await store.saveProfile('remote', profile);
    key = AscApiKey(
      keyId: 'KEY123',
      issuerId: 'issuer',
      privateKeyFile: await File(
        p.join(directory.path, 'AuthKey_KEY123.p8'),
      ).writeAsString(pem),
    );
    logger = _Logger();
    registration = AscKeyRegistration(logger: logger, credentialStore: store);
    requests = [];
    clients = [];
    certificateKeyExists = false;
    handler = (request) async => successResponse(request);
  });

  tearDown(() async {
    final messages = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [
      token,
      'BEGIN PRIVATE KEY',
      'dGVzdA==',
      base64Encode(utf8.encode(pem)),
      'private diagnostic',
      'private-refresh-token',
      'refreshed-id-token',
    ]) {
      expect(messages, isNot(contains(secret)));
    }
    expect(clients.every((client) => client.closed), isTrue);
    expect(await key.privateKeyFile.exists(), isTrue);
    expect(
      await File(store.filePath).readAsString(),
      isNot(contains('BEGIN PRIVATE KEY')),
    );
    await directory.delete(recursive: true);
    LocaleSettings.setLocaleSync(originalLocale);
  });

  Future<T> request<T>(Future<T> Function() callback) =>
      http.runWithClient(callback, () {
        final client = _Client((request) async {
          requests.add(request);
          return handler(request);
        });
        clients.add(client);
        return client;
      });

  Future<AscKeySaveTarget?> prepare() => request(registration.prepare);
  Future<int> save(AscKeySaveTarget target) =>
      request(() => registration.save(target, key));

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test('saves ASC secrets and prepares the certificate key: $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      final target = (await prepare())!;
      expect(target.profileName, 'remote');
      expect(target.profile, profile);
      expect(logger.output, [
        t.setup.ascKeys.saveDestination(
          server: profile.serverUrl,
          team: profile.teamId,
          names: [
            ...ascApiKeySecretNames,
            iosCertificatePrivateKeySecretName,
          ].join('\n    '),
        ),
        t.setup.ascKeys.certificateKeyWillCreate,
      ]);
      expect(await save(target), 0);
      expect(requests.map((r) => r.method), [
        'GET',
        'POST',
        'POST',
        'POST',
        'GET',
        'POST',
        'GET',
      ]);
      final saved = <String, String>{};
      for (final post in requests.skip(1).take(3)) {
        expect(
          post.url.toString(),
          'https://ci.example.com/proxy/teams/selected-team/secrets',
        );
        expect(post.headers['authorization'], 'Bearer $token');
        final body = jsonDecode(utf8.decode(post.bodyBytes)) as Map;
        expect(body.keys, unorderedEquals(['name', 'value']));
        saved[body['name'] as String] = body['value'] as String;
      }
      expect(saved, {
        'OPENCI_GENERATED_ASC_KEY_ID': 'KEY123',
        'OPENCI_GENERATED_ASC_ISSUER_ID': 'issuer',
        'OPENCI_GENERATED_P8_BASE64': base64Encode(utf8.encode(pem)),
      });
      expect(
        base64Decode(saved[ascP8SecretName]!),
        await key.privateKeyFile.readAsBytes(),
      );
      expect(logger.errors, isEmpty);
      final generate = requests[5];
      expect(
        generate.url.toString(),
        'https://ci.example.com/proxy/teams/selected-team/ios-signing/generate-key',
      );
      expect(generate.headers['authorization'], 'Bearer $token');
      expect(generate.body, isEmpty);
      expect(logger.output.last, t.setup.iosCertificateKey.ready);
      expect(await key.privateKeyFile.readAsString(), pem);
    });
  }

  for (final existing in [
    for (final name in ascApiKeySecretNames) [name],
    ascApiKeySecretNames,
    [iosCertificatePrivateKeySecretName],
    [...ascApiKeySecretNames, iosCertificatePrivateKeySecretName],
    ['UNRELATED_SECRET'],
  ]) {
    test('displays replacement only for existing secrets: $existing', () async {
      handler = (_) async => response({
        'success': true,
        'secrets': [
          for (final name in existing) {'name': name},
        ],
      });
      expect(await prepare(), isNotNull);
      expect(logger.output.skip(1), [
        for (final name in ascApiKeySecretNames)
          if (existing.contains(name))
            t.setup.ascKeys.secretWillReplace(name: name),
        existing.contains(iosCertificatePrivateKeySecretName)
            ? t.setup.ascKeys.certificateKeyWillReuse
            : t.setup.ascKeys.certificateKeyWillCreate,
      ]);
      expect(requests.single.method, 'GET');
    });
  }

  test('encodes team path segments and supports the local profile', () async {
    await store.saveProfile(
      'local',
      profile.copyWith(
        serverUrl: 'http://localhost:8080',
        teamId: 'team/with space?#',
      ),
    );
    final target = (await prepare())!;
    expect(await save(target), 0);
    expect(
      requests.every(
        (r) => [
          'http://localhost:8080/teams/team%2Fwith%20space%3F%23/secrets',
          'http://localhost:8080/teams/team%2Fwith%20space%3F%23/ios-signing/generate-key',
        ].contains(r.url.toString()),
      ),
      isTrue,
    );
  });

  for (final invalid in [
    const AuthProfile(),
    profile.copyWith(serverUrl: 'not a URL'),
    profile.copyWith(teamId: ''),
    profile.copyWith(token: ''),
  ]) {
    test('stops before HTTP with invalid credentials: $invalid', () async {
      await store.saveProfile('remote', invalid);
      expect(await prepare(), isNull);
      expect(requests, isEmpty);
      expect(logger.errors, [t.register.secret.loginRequired]);
    });
  }

  for (final status in [401, 403, 500]) {
    test('stops setup when preflight returns $status', () async {
      handler = (_) async => response({'error': 'private diagnostic'}, status);
      expect(await prepare(), isNull);
      expect(logger.errors, [
        status == 401 || status == 403
            ? t.register.secret.loginRequired
            : t.setup.ascKeys.savePreflightFailed,
      ]);
      expect(requests.single.method, 'GET');
    });
  }

  for (final body in [
    {'success': false, 'secrets': []},
    {'success': true},
    {
      'success': true,
      'secrets': [123],
    },
  ]) {
    test('rejects malformed preflight response: $body', () async {
      handler = (_) async => response(body);
      expect(await prepare(), isNull);
      expect(logger.errors, [t.setup.ascKeys.savePreflightFailed]);
    });
  }

  test('handles preflight network errors without raw diagnostics', () async {
    handler = (_) async => throw const SocketException('private diagnostic');
    expect(await prepare(), isNull);
    expect(logger.errors, [t.setup.ascKeys.savePreflightFailed]);
  });

  for (final change in ['active', 'team', 'server', 'account']) {
    test('refuses a changed $change after confirmation', () async {
      final target = (await prepare())!;
      await store.saveProfile(
        change == 'active' ? 'other' : 'remote',
        switch (change) {
          'team' => profile.copyWith(teamId: 'other-team'),
          'server' => profile.copyWith(serverUrl: 'https://other.example.com'),
          'account' => profile.copyWith(token: 'different-user-token'),
          _ => profile,
        },
      );
      expect(await save(target), 1);
      expect(requests, hasLength(1));
      expect(logger.errors, [t.setup.ascKeys.saveProfileChanged]);
    });
  }

  test('refreshes expired Firebase credentials before the save', () async {
    final expired = profile.copyWith(
      authType: 'firebase',
      firebaseApiKey: 'public-firebase-key',
      refreshToken: 'private-refresh-token',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );
    await store.saveProfile('remote', expired);
    handler = (request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        expect(request.bodyFields['refresh_token'], 'private-refresh-token');
        return response({
          'id_token': 'refreshed-id-token',
          'refresh_token': 'rotated-refresh-token',
          'expires_in': '3600',
        });
      }
      expect(request.headers['authorization'], 'Bearer refreshed-id-token');
      return successResponse(request);
    };
    expect(
      await save(AscKeySaveTarget(profileName: 'remote', profile: expired)),
      0,
    );
    expect(requests, hasLength(7));
    expect((await store.getActiveProfile())!.token, 'refreshed-id-token');
  });

  for (final status in [401, 403, 500]) {
    for (final failureAt in [1, 2, 3]) {
      test('stops after save $failureAt fails with $status', () async {
        final target = (await prepare())!;
        var posts = 0;
        handler = (_) async => ++posts == failureAt
            ? response({'error': 'private diagnostic'}, status)
            : response({'success': true});
        expect(await save(target), 1);
        expect(requests.where((r) => r.method == 'POST'), hasLength(failureAt));
        expect(await key.privateKeyFile.readAsString(), pem);
        expect(logger.errors, [
          status == 401 || status == 403
              ? t.register.secret.loginRequired
              : t.register.secret.requestFailed(status: status),
        ]);
      });
    }
  }

  for (final failureAt in [1, 2, 3]) {
    for (final responseLost in [false, true]) {
      test(
        'retry restores all three after save $failureAt fails (response lost: $responseLost)',
        () async {
          final target = (await prepare())!;
          final saved = {
            for (final name in ascApiKeySecretNames) name: 'old-$name',
          };
          var posts = 0;
          var shouldFail = true;
          handler = (request) async {
            if (request.method == 'GET' ||
                request.url.path.endsWith('/ios-signing/generate-key')) {
              return successResponse(request);
            }
            final body = jsonDecode(utf8.decode(request.bodyBytes)) as Map;
            final fails = ++posts == failureAt && shouldFail;
            if (fails && !responseLost) {
              return response({'error': 'private diagnostic'}, 500);
            }
            saved[body['name'] as String] = body['value'] as String;
            if (fails) throw const SocketException('private diagnostic');
            return response({'success': true});
          };
          expect(await save(target), 1);
          expect(posts, failureAt);
          expect(logger.errors, [
            responseLost
                ? t.register.secret.saveFailed
                : t.register.secret.requestFailed(status: 500),
          ]);
          expect(await key.privateKeyFile.readAsString(), pem);
          shouldFail = false;
          requests.clear();
          expect(await save(target), 0);
          expect(requests, hasLength(6));
          expect(saved, {
            'OPENCI_GENERATED_ASC_KEY_ID': 'KEY123',
            'OPENCI_GENERATED_ASC_ISSUER_ID': 'issuer',
            'OPENCI_GENERATED_P8_BASE64': base64Encode(utf8.encode(pem)),
          });
        },
      );
    }
  }

  test('does not post an invalid private key', () async {
    final target = (await prepare())!;
    await key.privateKeyFile.writeAsString('private diagnostic');
    expect(await save(target), 1);
    expect(requests, hasLength(1));
    expect(logger.errors, [t.setup.ascKeys.savedKeyInvalid]);
  });

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    for (final existingAtPreflight in [false, true]) {
      test(
        'rechecks and keeps an existing certificate key: $locale, $existingAtPreflight',
        () async {
          LocaleSettings.setLocaleSync(locale);
          certificateKeyExists = existingAtPreflight;
          final target = (await prepare())!;
          certificateKeyExists = true;

          expect(await save(target), 0);
          expect(requests.map((r) => r.method), [
            'GET',
            'POST',
            'POST',
            'POST',
            'GET',
          ]);
          expect(
            requests.every((r) => r.url.path.endsWith('/secrets')),
            isTrue,
          );
          expect(logger.output.last, t.setup.iosCertificateKey.reused);
          expect(logger.errors, isEmpty);
        },
      );
    }

    test('prepares a key removed after preflight: $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      certificateKeyExists = true;
      final target = (await prepare())!;
      certificateKeyExists = false;

      expect(await save(target), 0);
      expect(certificateKeyExists, isTrue);
      expect(logger.output.last, t.setup.iosCertificateKey.ready);
      expect(logger.errors, isEmpty);
    });
  }

  for (final phase in ['lookup', 'generate', 'verify']) {
    for (final status in [401, 403, 500]) {
      test('fails certificate $phase on HTTP $status', () async {
        final target = (await prepare())!;
        var gets = 0;
        handler = (request) async {
          if (request.method == 'GET') gets++;
          final fails = switch (phase) {
            'lookup' => request.method == 'GET' && gets == 1,
            'generate' => request.url.path.endsWith(
              '/ios-signing/generate-key',
            ),
            _ => request.method == 'GET' && gets == 2,
          };
          return fails
              ? response({'error': 'private diagnostic'}, status)
              : successResponse(request);
        };

        expect(await save(target), 1);
        expect(logger.errors, [
          status == 401 || status == 403
              ? t.register.secret.loginRequired
              : t.setup.iosCertificateKey.requestFailed(status: status),
        ]);
        expect(logger.output, isNot(contains(t.setup.iosCertificateKey.ready)));
      });
    }
  }

  for (final failure in ['http', 'response-lost']) {
    test(
      'retries certificate setup after $failure without replacing a saved key',
      () async {
        final target = (await prepare())!;
        var generations = 0;
        var shouldFail = true;
        handler = (request) async {
          if (request.url.path.endsWith('/ios-signing/generate-key')) {
            generations++;
            if (shouldFail) {
              if (failure == 'http') {
                return response({'error': 'private diagnostic'}, 500);
              }
              certificateKeyExists = true;
              throw const SocketException('private diagnostic');
            }
          }
          return successResponse(request);
        };

        expect(await save(target), 1);
        expect(generations, 1);
        expect(logger.errors, [
          failure == 'http'
              ? t.setup.iosCertificateKey.requestFailed(status: 500)
              : t.setup.iosCertificateKey.setupFailed,
        ]);
        shouldFail = false;
        expect(await save(target), 0);
        expect(generations, failure == 'http' ? 2 : 1);
        expect(certificateKeyExists, isTrue);
      },
    );
  }

  for (final body in [
    {'success': true, 'secrets': <Object>[]},
    {'success': false, 'secrets': <Object>[]},
    {
      'success': true,
      'secrets': ['private diagnostic'],
    },
  ]) {
    test(
      'does not report success when the certificate key cannot be verified: $body',
      () async {
        final target = (await prepare())!;
        handler = (request) async => request.method == 'GET'
            ? response(body)
            : response({'success': true});

        expect(await save(target), 1);
        expect(logger.errors, [t.setup.iosCertificateKey.setupFailed]);
        expect(logger.output, isNot(contains(t.setup.iosCertificateKey.ready)));
      },
    );
  }
}
