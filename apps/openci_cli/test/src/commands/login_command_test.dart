import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/src/commands/login_command.dart';
import 'package:openci_cli/src/credential_store/credential_config.dart';
import 'package:openci_cli/src/credential_store/credential_store.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
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
  const token = 'private-local-api-key';
  const existingConfig = CredentialConfig(
    activeProfile: 'cloud',
    profiles: {
      'cloud': AuthProfile(
        serverUrl: 'https://example.com',
        token: 'cloud-key',
      ),
      'local': AuthProfile(
        token: 'previous-local-key',
        teamId: 'previous-team',
      ),
    },
  );
  late Directory tempDir;
  late CredentialStore store;
  late String originalCredentials;
  late _RecordingLogger logger;
  late List<http.Request> requests;
  late _TrackingClient client;
  late int dockerCalls;
  late Future<ProcessResult> Function(String, List<String>) processRunner;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('openci-login-test-');
    store = CredentialStore(customFilePath: '${tempDir.path}/credentials.json');
    await store.set(existingConfig);
    originalCredentials = await File(store.filePath).readAsString();
    logger = _RecordingLogger();
    requests = [];
    client = _TrackingClient((request) async {
      requests.add(request);
      return http.Response('[{"id":"test-team"}]', 200);
    });
    dockerCalls = 0;
    processRunner = (executable, arguments) async {
      dockerCalls++;
      expect(executable, 'docker');
      expect(arguments, [
        'exec',
        'genuineci-server',
        'printenv',
        'INTERNAL_API_KEY',
      ]);
      return ProcessResult(1, 0, '$token\n', '');
    };
  });

  tearDown(() async {
    // Neither successful output nor error diagnostics should disclose the key.
    expect(
      [...logger.stdoutMessages, ...logger.stderrMessages].join('\n'),
      isNot(contains(token)),
    );
    await tempDir.delete(recursive: true);
  });

  Future<int?> runLogin([
    List<String> options = const [],
    Duration timeout = const Duration(seconds: 10),
  ]) {
    final runner = CommandRunner<int>('openci', 'test')
      ..addCommand(
        LoginCommand(
          logger: logger,
          credentialStore: store,
          processRunner: processRunner,
          client: client,
          timeout: timeout,
        ),
      );
    return runner.run(['login', '--local', ...options]);
  }

  Future<void> expectCredentialsUnchanged() async {
    expect(await File(store.filePath).readAsString(), originalCredentials);
    expect(
      logger.stdoutMessages,
      isNot(contains(t.login.savedSuccess(profile: 'local'))),
    );
  }

  test('help explains login without reading or saving keys', () async {
    final runner = CommandRunner<int>('openci', 'test')
      ..addCommand(
        LoginCommand(credentialStore: store, processRunner: processRunner),
      );
    final output = <String>[];

    await runZoned(
      () => runner.run(['login', '--help']),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) => output.add(message),
      ),
    );

    final help = output.join('\n');
    expect(help, contains(t.login.description));
    expect(help, contains('http://localhost:8080'));
    expect(help, contains('--local'));
    for (final option in ['--server', '--team-id', '--firebase-api-key']) {
      expect(help, contains(option));
    }
    expect(dockerCalls, 0);
    await expectCredentialsUnchanged();
  });

  test('authenticates and activates test-team in the local profile', () async {
    expect(await runLogin(), 0);

    expect(dockerCalls, 1);
    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url, Uri.parse('http://localhost:8080/teams'));
    expect(request.headers['Authorization'], 'Bearer $token');
    expect(request.followRedirects, isFalse);
    expect(client.closed, isTrue);
    final config = await store.get();
    expect(config.activeProfile, 'local');
    expect(
      config.profiles['local'],
      const AuthProfile(token: token, teamId: 'test-team'),
    );
    expect(config.profiles['cloud'], existingConfig.profiles['cloud']);
    expect(logger.stderrMessages, isEmpty);
    expect(logger.stdoutMessages, [
      t.login.loggingIn,
      t.login.savedSuccess(profile: 'local'),
    ]);
  });

  test('supports -l with the default HTTP client', () async {
    final runner = CommandRunner<int>('openci', 'test')
      ..addCommand(
        LoginCommand(
          logger: logger,
          credentialStore: store,
          processRunner: processRunner,
        ),
      );
    final result = await http.runWithClient(
      () => runner.run(['login', '-l']),
      () => client,
    );

    expect(result, 0);
    expect(requests.single.url, Uri.parse('http://localhost:8080/teams'));
    expect(client.closed, isTrue);
  });

  for (final options in [
    ['--server', 'http://localhost:8080'],
    ['--team-id', 'test-team'],
    ['--profile', 'local'],
    ['unexpected-argument'],
  ]) {
    test(
      'rejects invalid arguments before reading credentials: $options',
      () async {
        await expectLater(runLogin(options), throwsA(isA<UsageException>()));
        expect(dockerCalls, 0);
        expect(requests, isEmpty);
        await expectCredentialsUnchanged();
      },
    );
  }

  for (final (label, readKey) in <(String, Future<ProcessResult> Function())>[
    ('stopped server', () async => ProcessResult(1, 1, token, token)),
    ('missing key', () async => ProcessResult(1, 0, '\n', '')),
    ('multiline key', () async => ProcessResult(1, 0, '$token\ninvalid', '')),
    ('missing Docker', () async => throw ProcessException('docker', [], token)),
    ('timeout', () => Completer<ProcessResult>().future),
  ]) {
    test('preserves credentials when reading the key fails: $label', () async {
      processRunner = (_, _) => readKey();

      expect(await runLogin([], const Duration(milliseconds: 20)), 1);

      expect(logger.stderrMessages, [t.login.localServerUnavailable]);
      expect(requests, isEmpty);
      await expectCredentialsUnchanged();
    });
  }

  for (final status in [401, 403, 500, 302]) {
    test(
      'preserves credentials when the server returns HTTP $status',
      () async {
        client = _TrackingClient(
          (_) async => http.Response(
            token,
            status,
            headers: {'location': 'https://example.com/teams'},
          ),
        );

        expect(await runLogin(), 1);

        expect(logger.stderrMessages, [
          status == 401 || status == 403
              ? t.login.authenticationFailed
              : t.login.requestFailed(status: status),
        ]);
        expect(client.closed, isTrue);
        await expectCredentialsUnchanged();
      },
    );
  }

  for (final body in [token, '{}', 'null', '[null]', '[{"id":42}]']) {
    test('rejects an invalid team response: $body', () async {
      client = _TrackingClient((_) async => http.Response(body, 200));

      expect(await runLogin(), 1);

      expect(logger.stderrMessages, [t.login.invalidResponse]);
      expect(client.closed, isTrue);
      await expectCredentialsUnchanged();
    });
  }

  for (final body in ['[]', '[{"id":"another-team"}]']) {
    test(
      'fails without selecting another team when test-team is missing from $body',
      () async {
        client = _TrackingClient((_) async => http.Response(body, 200));

        expect(await runLogin(), 1);

        expect(logger.stderrMessages, [t.login.seedRequired]);
        expect(client.closed, isTrue);
        await expectCredentialsUnchanged();
      },
    );
  }

  for (final (label, respond) in <(String, Future<http.Response> Function())>[
    ('network failure', () async => throw http.ClientException(token)),
    ('timeout', () => Completer<http.Response>().future),
  ]) {
    test('preserves credentials on $label', () async {
      client = _TrackingClient((_) => respond());

      expect(await runLogin([], const Duration(milliseconds: 20)), 1);

      expect(logger.stderrMessages, [t.login.connectionFailed]);
      expect(client.closed, isTrue);
      await expectCredentialsUnchanged();
    });
  }

  test('does not overwrite a malformed credentials file', () async {
    await File(store.filePath).writeAsString(token);
    originalCredentials = token;

    expect(await runLogin(), 1);

    expect(logger.stderrMessages, [t.login.saveFailed]);
    await expectCredentialsUnchanged();
  });

  test('does not report success when credentials cannot be written', () async {
    final parentFile = File('${tempDir.path}/not-a-directory');
    await parentFile.writeAsString('existing file');
    store = CredentialStore(
      customFilePath: '${parentFile.path}/credentials.json',
    );

    expect(await runLogin(), 1);

    expect(logger.stderrMessages, [t.login.saveFailed]);
    expect(await parentFile.readAsString(), 'existing file');
    expect(logger.stdoutMessages, [t.login.loggingIn]);
  });
}
