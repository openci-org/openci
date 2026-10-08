import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/asc/asc_api_key_secret.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _RecordingLogger implements Logger {
  final output = <String>[];
  final errors = <String>[];

  @override
  void stdout(String message) => output.add(message);

  @override
  void stderr(String message) => errors.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingClient extends MockClient {
  _TrackingClient(super.fn);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  const token = 'private-setup-token';
  const privateValue = 'private-key-value';
  const profile = AuthProfile(
    serverUrl: 'https://ci.example.com/proxy/',
    token: token,
    teamId: 'selected/team',
  );
  late Directory root;
  late CredentialStore store;
  late _RecordingLogger logger;
  late List<http.Request> requests;
  late List<_TrackingClient> clients;
  late MockClientHandler handler;
  late bool keyExists;

  http.Response response(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  http.Response success(http.Request request) {
    if (request.method == 'GET') {
      return response({
        'success': true,
        'secrets': [
          if (keyExists)
            {'name': iosCertificatePrivateKeySecretName, 'value': privateValue},
        ],
      });
    }
    keyExists = true;
    return response({'success': true});
  }

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('openci-setup-certificate-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    await store.set(
      const CredentialConfig(
        activeProfile: 'selected',
        profiles: {
          'selected': profile,
          'unused': AuthProfile(token: 'unused-token', teamId: 'unused-team'),
        },
      ),
    );
    logger = _RecordingLogger();
    requests = [];
    clients = [];
    keyExists = false;
    handler = (request) async => success(request);
  });

  tearDown(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    final messages = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [
      token,
      privateValue,
      'private-refresh-token',
      'refreshed-id-token',
      'rotated-refresh-token',
    ]) {
      expect(messages, isNot(contains(secret)));
    }
    expect(clients.every((client) => client.closed), isTrue);
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(
        SetupIosCertificateKeyCommand(logger: logger, credentialStore: store),
      );
    return http.runWithClient(
      () => runner.run(['ios-certificate-key', ...arguments]),
      () {
        final client = _TrackingClient((request) async {
          requests.add(request);
          return handler(request);
        });
        clients.add(client);
        return client;
      },
    );
  }

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test('prepares only the active team certificate key: $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      final credentials = await File(store.filePath).readAsBytes();

      expect(await run(), 0);

      expect(requests.map((r) => r.method), ['GET', 'POST', 'GET']);
      expect(requests.map((r) => r.url.toString()), [
        'https://ci.example.com/proxy/teams/selected%2Fteam/secrets',
        'https://ci.example.com/proxy/teams/selected%2Fteam/ios-signing/generate-key',
        'https://ci.example.com/proxy/teams/selected%2Fteam/secrets',
      ]);
      for (final request in requests) {
        expect(request.headers['authorization'], 'Bearer $token');
        expect(request.body, isEmpty);
      }
      expect(logger.output, [
        t.setup.iosCertificateKey.saveDestination(
          server: profile.serverUrl,
          team: profile.teamId,
          name: iosCertificatePrivateKeySecretName,
        ),
        t.setup.iosCertificateKey.ready,
      ]);
      expect(logger.errors, isEmpty);
      expect(await File(store.filePath).readAsBytes(), credentials);
      expect(root.listSync().map((entry) => p.basename(entry.path)), [
        'credentials.json',
      ]);
    });
  }

  test('keeps an existing key without requesting generation', () async {
    keyExists = true;

    expect(await run(), 0);
    expect(requests.single.method, 'GET');
    expect(logger.output.last, t.setup.iosCertificateKey.reused);
    expect(logger.errors, isEmpty);
  });

  test(
    'escapes displayed controls and preserves the team URL segment',
    () async {
      const team = 'team\x1b[2J/with space?#';
      await store.saveProfile('selected', profile.copyWith(teamId: team));

      expect(await run(), 0);
      for (final request in requests) {
        expect(request.url.pathSegments[2], team);
        expect(request.url.hasQuery, isFalse);
        expect(request.url.hasFragment, isFalse);
      }
      expect(logger.output.first, contains(r'team\x1b[2J/with space?#'));
      expect(logger.output.first, isNot(contains('\x1b')));
    },
  );

  test('rejects positional arguments before reading credentials', () async {
    await File(store.filePath).writeAsString(token);

    await expectLater(run(['unexpected']), throwsA(isA<UsageException>()));
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, isEmpty);
  });

  test('help does not read credentials or send requests', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(['--help']), isNull);
    expect(clients, isEmpty);
    expect(logger.errors, isEmpty);
  });

  test('requires login when no credentials have been saved', () async {
    await File(store.filePath).delete();

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.register.secret.loginRequired]);
  });

  for (final (label, invalidProfile) in <(String, AuthProfile?)>[
    ('missing active profile', null),
    ('empty token', profile.copyWith(token: ' ')),
    ('empty team', profile.copyWith(teamId: ' ')),
    ('relative URL', profile.copyWith(serverUrl: '/server')),
    (
      'URL credentials',
      profile.copyWith(serverUrl: 'https://user:password@example.com'),
    ),
  ]) {
    test('stops before HTTP for $label', () async {
      await store.set(
        CredentialConfig(
          activeProfile: 'selected',
          profiles: {'selected': ?invalidProfile},
        ),
      );

      expect(await run(), 1);
      expect(clients, isEmpty);
      expect(logger.output, isEmpty);
      expect(logger.errors, [t.register.secret.loginRequired]);
    });
  }

  test('does not expose malformed credentials', () async {
    await File(store.filePath).writeAsString(token);

    expect(await run(), 1);
    expect(clients, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.register.secret.loginRequired]);
  });

  Future<void> expireFirebaseToken() => store.saveProfile(
    'selected',
    profile.copyWith(
      authType: 'firebase',
      firebaseApiKey: 'test-api-key',
      refreshToken: 'private-refresh-token',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    ),
  );

  test('refreshes authentication before preparing the key', () async {
    await expireFirebaseToken();
    handler = (request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        return response({
          'id_token': 'refreshed-id-token',
          'refresh_token': 'rotated-refresh-token',
          'expires_in': '3600',
        });
      }
      expect(request.headers['authorization'], 'Bearer refreshed-id-token');
      return success(request);
    };

    expect(await run(), 0);
    expect(requests, hasLength(4));
    final updated = (await store.getActiveProfile())!;
    expect(updated.token, 'refreshed-id-token');
    expect(updated.refreshToken, 'rotated-refresh-token');
    expect(updated.teamId, profile.teamId);
    expect((await store.get()).profiles['unused']!.token, 'unused-token');
  });

  test('stops when authentication cannot be refreshed', () async {
    await expireFirebaseToken();
    handler = (_) async => response({'error': privateValue}, 400);

    expect(await run(), 1);
    expect(requests.single.url.host, 'securetoken.googleapis.com');
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.register.secret.loginRequired]);
  });

  for (final status in [401, 403, 500]) {
    test('reports generation failure HTTP $status without details', () async {
      handler = (request) async => request.method == 'POST'
          ? response({'error': privateValue}, status)
          : success(request);

      expect(await run(), 1);
      expect(requests.map((r) => r.method), ['GET', 'POST']);
      expect(logger.output, hasLength(1));
      expect(logger.errors, [
        status == 401 || status == 403
            ? t.register.secret.loginRequired
            : t.setup.iosCertificateKey.requestFailed(status: status),
      ]);
    });
  }

  test('requires the generated key to be present before success', () async {
    handler = (request) async => request.method == 'POST'
        ? response({'success': true})
        : success(request);

    expect(await run(), 1);
    expect(requests.map((r) => r.method), ['GET', 'POST', 'GET']);
    expect(logger.output, hasLength(1));
    expect(logger.errors, [t.setup.iosCertificateKey.setupFailed]);
  });

  test('reuses a generated key after losing the generation response', () async {
    handler = (request) async {
      final result = success(request);
      if (request.method == 'POST') throw http.ClientException(privateValue);
      return result;
    };

    expect(await run(), 1);
    expect(logger.errors, [t.setup.iosCertificateKey.setupFailed]);
    expect(await run(), 0);
    expect(requests.map((r) => r.method), ['GET', 'POST', 'GET']);
    expect(logger.output.last, t.setup.iosCertificateKey.reused);
  });
}
