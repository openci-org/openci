import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/openci_cli.dart';
import 'package:openci_cli/src/commands/register/read_secret_input.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _RecordingLogger implements Logger {
  final stdoutMessages = <String>[];
  final stderrMessages = <String>[];

  @override
  void stdout(String message) => stdoutMessages.add(message);

  @override
  void stderr(String message) => stderrMessages.add(message);

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
  const token = 'private-test-api-key';
  const secretValue = 'private-secret-value 日本語 🚀';
  const profile = AuthProfile(
    serverUrl: 'https://ci.example.com/proxy/',
    token: token,
    teamId: 'selected-team',
  );
  late Directory temp;
  late CredentialStore store;
  late _RecordingLogger logger;
  late MockClientHandler handler;
  late List<http.Request> requests;
  late List<_TrackingClient> clients;
  late Future<SecretInput?> Function() readInput;
  late int reads;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('openci-register-test-');
    store = CredentialStore(customFilePath: '${temp.path}/credentials.json');
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
    reads = 0;
    readInput = () async => (name: 'API_TOKEN', value: secretValue);
    handler = (_) async => http.Response(
      '{"success":true}',
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  tearDown(() async {
    final messages = [
      ...logger.stdoutMessages,
      ...logger.stderrMessages,
    ].join('\n');
    for (final secret in [
      token,
      'private-secret-value',
      'private-refresh-token',
      'refreshed-id-token',
    ]) {
      expect(messages, isNot(contains(secret)));
    }
    expect(clients.every((client) => client.closed), isTrue);
    expect(
      await File(store.filePath).readAsString(),
      isNot(contains('private-secret-value')),
    );
    await temp.delete(recursive: true);
  });

  Future<int?> runRegister([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('openci register', 'test')
      ..addCommand(
        RegisterSecretCommand(
          logger: logger,
          credentialStore: store,
          readInput: () async {
            reads++;
            return readInput();
          },
        ),
      );
    return http.runWithClient(() => runner.run(['secret', ...arguments]), () {
      final client = _TrackingClient((request) async {
        requests.add(request);
        return handler(request);
      });
      clients.add(client);
      return client;
    });
  }

  test('posts the value to the active team through the shared API', () async {
    final before = await File(store.filePath).readAsString();

    expect(await runRegister(), 0);

    expect(reads, 1);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(
      request.url.toString(),
      'https://ci.example.com/proxy/teams/selected-team/secrets',
    );
    expect(request.headers['authorization'], 'Bearer $token');
    expect(request.headers['content-type'], contains('application/json'));
    expect(jsonDecode(utf8.decode(request.bodyBytes)), {
      'name': 'API_TOKEN',
      'value': secretValue,
    });
    expect(logger.stderrMessages, isEmpty);
    expect(logger.stdoutMessages, [
      t.register.secret.saved(name: 'API_TOKEN', teamId: 'selected-team'),
    ]);
    expect(await File(store.filePath).readAsString(), before);
  });

  test('supports a local profile and encodes the team path segment', () async {
    await store.saveProfile(
      'local',
      const AuthProfile(token: token, teamId: 'team/with space?#'),
    );

    expect(await runRegister(), 0);
    expect(
      requests.single.url.toString(),
      'http://localhost:8080/teams/team%2Fwith%20space%3F%23/secrets',
    );
  });

  test('refreshes an expired Firebase session before registering', () async {
    await store.saveProfile(
      'remote',
      profile.copyWith(
        authType: 'firebase',
        firebaseApiKey: 'firebase-api-key',
        refreshToken: 'private-refresh-token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
    );
    final saveHandler = handler;
    handler = (request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        expect(request.bodyFields['refresh_token'], 'private-refresh-token');
        return http.Response(
          jsonEncode({
            'id_token': 'refreshed-id-token',
            'refresh_token': 'private-refresh-token',
            'expires_in': '3600',
          }),
          200,
        );
      }
      expect(request.headers['authorization'], 'Bearer refreshed-id-token');
      return saveHandler(request);
    };

    expect(await runRegister(), 0);
    expect(requests, hasLength(2));
    expect(requests.first.url.host, 'securetoken.googleapis.com');
    expect((await store.getActiveProfile())!.token, 'refreshed-id-token');
  });

  test('help does not read a value or contact the server', () async {
    final output = <String>[];
    await runZoned(
      () => runRegister(['--help']),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) => output.add(message),
      ),
    );

    expect(output.join('\n'), contains('openci register secret'));
    expect(output.join('\n'), isNot(contains('<name>')));
    expect(reads, 0);
    expect(requests, isEmpty);
  });

  for (final arguments in <List<String>>[
    ['API_TOKEN'],
    ['API_TOKEN', 'private-secret-value'],
  ]) {
    test(
      'rejects invalid arguments before reading a value: $arguments',
      () async {
        await expectLater(
          runRegister(arguments),
          throwsA(
            isA<UsageException>().having(
              (error) => error.toString(),
              'message',
              isNot(contains('private-secret-value')),
            ),
          ),
        );
        expect(reads, 0);
        expect(requests, isEmpty);
      },
    );
  }

  for (final name in ['', '1TOKEN', 'API-TOKEN', 'API_TOKEN\n']) {
    test('rejects an invalid name entered at the prompt: $name', () async {
      readInput = () async => (name: name, value: secretValue);

      expect(await runRegister(), 1);
      expect(requests, isEmpty);
      expect(logger.stdoutMessages, isEmpty);
      expect(logger.stderrMessages, [t.register.secret.invalidName]);
    });
  }

  for (final invalid in [
    const AuthProfile(),
    profile.copyWith(teamId: ''),
    profile.copyWith(serverUrl: 'invalid-server'),
    profile.copyWith(serverUrl: 'https://ci.example.com?query'),
  ]) {
    test('requires valid login before reading a value: $invalid', () async {
      await store.saveProfile('invalid', invalid);
      expect(await runRegister(), 1);
      expect(reads, 0);
      expect(requests, isEmpty);
      expect(logger.stderrMessages, [t.register.secret.loginRequired]);
    });
  }

  test(
    'reports malformed credentials without printing their contents',
    () async {
      await File(store.filePath).writeAsString(token);

      expect(await runRegister(), 1);
      expect(reads, 0);
      expect(requests, isEmpty);
      expect(logger.stderrMessages, [t.register.secret.loginRequired]);
      expect(await File(store.filePath).readAsString(), token);
    },
  );

  for (final value in [null, '', ' \r\n ']) {
    test('does not save an empty value or cancelled input: $value', () async {
      readInput = () async =>
          value == null ? null : (name: 'API_TOKEN', value: value);
      expect(await runRegister(), 1);
      expect(requests, isEmpty);
      expect(logger.stderrMessages, [t.register.secret.inputRequired]);
    });
  }

  test('does not print input errors that may contain the secret', () async {
    readInput = () async => throw const FormatException(secretValue);
    expect(await runRegister(), 1);
    expect(requests, isEmpty);
    expect(logger.stderrMessages, [t.register.secret.inputFailed]);
  });

  for (final status in [400, 401, 403, 500, 302]) {
    test('reports HTTP $status without printing the response body', () async {
      handler = (_) async => http.Response(
        jsonEncode({'success': false, 'error': secretValue}),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      expect(await runRegister(), 1);
      expect(logger.stdoutMessages, isEmpty);
      expect(logger.stderrMessages, [
        status == 401 || status == 403
            ? t.register.secret.loginRequired
            : t.register.secret.requestFailed(status: status),
      ]);
    });
  }

  for (final error in [
    http.ClientException(secretValue),
    TimeoutException(secretValue),
  ]) {
    test(
      'reports ${error.runtimeType} without disclosing the secret',
      () async {
        handler = (_) async => throw error;

        expect(await runRegister(), 1);
        expect(logger.stdoutMessages, isEmpty);
        expect(logger.stderrMessages, [t.register.secret.saveFailed]);
      },
    );
  }
}
