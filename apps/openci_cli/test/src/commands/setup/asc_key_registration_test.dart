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

  http.Response response(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

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
    handler = (request) async => response(
      request.method == 'GET'
          ? {'success': true, 'secrets': <Object>[]}
          : {'success': true},
    );
  });

  tearDown(() async {
    final messages = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [
      token,
      'BEGIN PRIVATE KEY',
      'dGVzdA==',
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
    test(
      'preflights and saves all credentials in one request: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);
        final target = (await prepare())!;
        expect(target.profileName, 'remote');
        expect(target.profile, profile);
        expect(logger.output, [
          t.setup.ascKeys.saveDestination(
            server: profile.serverUrl,
            team: profile.teamId,
            name: ascApiKeySecretName,
          ),
        ]);
        expect(await save(target), 0);
        expect(requests.map((r) => r.method), ['GET', 'POST']);
        final post = requests.last;
        expect(
          post.url.toString(),
          'https://ci.example.com/proxy/teams/selected-team/secrets',
        );
        expect(post.headers['authorization'], 'Bearer $token');
        final body = jsonDecode(utf8.decode(post.bodyBytes)) as Map;
        expect(body['name'], ascApiKeySecretName);
        expect(jsonDecode(body['value'] as String), {
          'key_id': 'KEY123',
          'issuer_id': 'issuer',
          'key': pem,
        });
        expect(logger.errors, isEmpty);
        expect(await key.privateKeyFile.readAsString(), pem);
      },
    );
  }

  test(
    'displays replacement before confirmation if the secret exists',
    () async {
      handler = (_) async => response({
        'success': true,
        'secrets': [
          {'name': ascApiKeySecretName},
        ],
      });
      expect(await prepare(), isNotNull);
      expect(
        logger.output.last,
        t.setup.ascKeys.secretWillReplace(name: ascApiKeySecretName),
      );
      expect(requests.single.method, 'GET');
    },
  );

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
        (r) =>
            r.url.toString() ==
            'http://localhost:8080/teams/team%2Fwith%20space%3F%23/secrets',
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
      return response({'success': true});
    };
    expect(
      await save(AscKeySaveTarget(profileName: 'remote', profile: expired)),
      0,
    );
    expect(requests, hasLength(2));
    expect((await store.getActiveProfile())!.token, 'refreshed-id-token');
  });

  for (final status in [401, 403, 500]) {
    test(
      'retains local files and never retries a failed save ($status)',
      () async {
        final target = (await prepare())!;
        handler = (_) async =>
            response({'error': 'private diagnostic'}, status);
        expect(await save(target), 1);
        expect(requests.where((r) => r.method == 'POST'), hasLength(1));
        expect(await key.privateKeyFile.readAsString(), pem);
        expect(logger.errors, [
          status == 401 || status == 403
              ? t.register.secret.loginRequired
              : t.register.secret.requestFailed(status: status),
        ]);
      },
    );
  }

  test(
    'handles a lost save response without retrying or logging the key',
    () async {
      final target = (await prepare())!;
      handler = (_) async => throw const SocketException('private diagnostic');
      expect(await save(target), 1);
      expect(requests.where((r) => r.method == 'POST'), hasLength(1));
      expect(logger.errors, [t.register.secret.saveFailed]);
    },
  );

  test('does not post an invalid private key', () async {
    final target = (await prepare())!;
    await key.privateKeyFile.writeAsString('private diagnostic');
    expect(await save(target), 1);
    expect(requests, hasLength(1));
    expect(logger.errors, [t.setup.ascKeys.savedKeyInvalid]);
  });
}
