import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/src/commands/login/read_login_credentials.dart';
import 'package:openci_cli/src/commands/login_command.dart';
import 'package:openci_cli/src/credential_store/credential_config.dart';
import 'package:openci_cli/src/credential_store/credential_store.dart';
import 'package:openci_cli/src/credential_store/read_authenticated_profile.dart';
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
  const token = 'private-local-id-token';
  const refreshToken = 'private-refresh-token';
  const password = 'private-password';
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
  late LoginCredentials? credentials;
  late int prompts;
  late Future<http.Response> Function() authenticate;
  late Future<http.Response> Function() fetchTeams;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    tempDir = await Directory.systemTemp.createTemp('openci-login-test-');
    store = CredentialStore(customFilePath: '${tempDir.path}/credentials.json');
    await store.set(existingConfig);
    originalCredentials = await File(store.filePath).readAsString();
    logger = _RecordingLogger();
    requests = [];
    credentials = (email: 'local@example.test', password: password);
    prompts = 0;
    authenticate = () async => http.Response(
      jsonEncode({
        'idToken': token,
        'refreshToken': refreshToken,
        'expiresIn': '3600',
      }),
      200,
    );
    fetchTeams = () async => http.Response('[{"id":"test-team"}]', 200);
    client = _TrackingClient((request) async {
      requests.add(request);
      return request.url.path ==
              '/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
          ? authenticate()
          : fetchTeams();
    });
  });

  tearDown(() async {
    for (final secret in [
      token,
      refreshToken,
      password,
      'previous-local-key',
    ]) {
      expect(
        [...logger.stdoutMessages, ...logger.stderrMessages].join('\n'),
        isNot(contains(secret)),
      );
    }
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tempDir.delete(recursive: true);
  });

  Future<LoginCredentials?> readCredentials() async {
    prompts++;
    return credentials;
  }

  Future<int?> runLogin([
    List<String> options = const [],
    Duration timeout = const Duration(seconds: 10),
  ]) {
    final runner = CommandRunner<int>('openci', 'test')
      ..addCommand(
        LoginCommand(
          logger: logger,
          credentialStore: store,
          readCredentials: readCredentials,
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

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test('help describes local Auth Emulator login in $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      final runner = CommandRunner<int>('openci', 'test')
        ..addCommand(
          LoginCommand(
            credentialStore: store,
            readCredentials: readCredentials,
            client: client,
          ),
        );
      final output = <String>[];
      await runZoned(
        () => runner.run(['login', '--help']),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, message) => output.add(message),
        ),
      );

      final help = output.join('\n');
      expect(help, contains(t.login.flags.local));
      expect(help, contains('127.0.0.1:9099'));
      for (final option in [
        '--local',
        '--server',
        '--team-id',
        '--firebase-api-key',
      ]) {
        expect(help, contains(option));
      }
      expect(prompts, 0);
      expect(requests, isEmpty);
      await expectCredentialsUnchanged();
    });
  }

  test(
    'authenticates a user and replaces the old local API key profile',
    () async {
      expect(await runLogin(), 0);

      expect(prompts, 1);
      expect(requests, hasLength(2));
      final authRequest = requests.first;
      expect(authRequest.method, 'POST');
      expect(
        authRequest.url,
        Uri.parse(
          'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-openci-api-key',
        ),
      );
      expect(jsonDecode(authRequest.body), {
        'email': 'local@example.test',
        'password': password,
        'returnSecureToken': true,
      });
      expect(authRequest.followRedirects, isFalse);
      final teamRequest = requests.last;
      expect(teamRequest.method, 'GET');
      expect(teamRequest.url, Uri.parse('http://localhost:8080/teams'));
      expect(teamRequest.headers['Authorization'], 'Bearer $token');
      expect(teamRequest.followRedirects, isFalse);
      expect(teamRequest.body, isEmpty);
      expect(client.closed, isTrue);
      final config = await store.get();
      expect(config.activeProfile, 'local');
      final local = config.profiles['local']!;
      expect(local.serverUrl, 'http://localhost:8080');
      expect(local.teamId, 'test-team');
      expect(local.authType, 'firebase');
      expect(local.token, token);
      expect(local.refreshToken, refreshToken);
      expect(local.firebaseApiKey, 'demo-openci-api-key');
      expect(local.firebaseAuthEmulatorHost, '127.0.0.1:9099');
      expect(local.expiresAt!.isAfter(DateTime.now().toUtc()), isTrue);
      expect(config.profiles['cloud'], existingConfig.profiles['cloud']);
      expect(
        await File(store.filePath).readAsString(),
        isNot(contains(password)),
      );
      expect(logger.stderrMessages, isEmpty);
      expect(logger.stdoutMessages, [
        t.login.loggingIn,
        t.login.savedSuccess(profile: 'local'),
      ]);
    },
  );

  test('supports -l with the default HTTP client', () async {
    final runner = CommandRunner<int>('openci', 'test')
      ..addCommand(
        LoginCommand(
          logger: logger,
          credentialStore: store,
          readCredentials: readCredentials,
        ),
      );
    final result = await http.runWithClient(
      () => runner.run(['login', '-l']),
      () => client,
    );
    expect(result, 0);
    expect(requests, hasLength(2));
    expect(requests.last.url, Uri.parse('http://localhost:8080/teams'));
    expect(client.closed, isTrue);
  });

  test(
    'persists the default emulator address for later token refreshes',
    () async {
      expect(await runLogin(), 0);
      expect(requests.first.url.host, '127.0.0.1');
      expect(requests.first.url.port, 9099);
      final local = (await store.getActiveProfile())!;
      expect(local.firebaseAuthEmulatorHost, '127.0.0.1:9099');
      await store.saveProfile(
        'local',
        local.copyWith(expiresAt: DateTime.utc(2000)),
      );
      final refreshRequests = <http.Request>[];
      final refreshed = await http.runWithClient(
        () => readAuthenticatedProfile(
          CredentialStore(customFilePath: store.filePath),
        ),
        () => MockClient((request) async {
          refreshRequests.add(request);
          return http.Response(
            jsonEncode({
              'id_token': 'refreshed-token',
              'refresh_token': 'rotated-token',
              'expires_in': '3600',
            }),
            200,
          );
        }),
      );
      expect(
        refreshRequests.single.url,
        Uri.parse(
          'http://127.0.0.1:9099/securetoken.googleapis.com/v1/token?key=demo-openci-api-key',
        ),
      );
      expect(refreshRequests.single.bodyFields['refresh_token'], refreshToken);
      expect(refreshed!.token, 'refreshed-token');
      expect(await store.getProfile('local'), refreshed);
      expect((await store.get()).activeProfile, 'local');
      expect(await store.getProfile('cloud'), existingConfig.profiles['cloud']);
    },
  );

  for (final options in [
    ['--server', 'http://localhost:8080'],
    ['--team-id', 'test-team'],
    ['--firebase-api-key', 'real-project-key'],
    ['--profile', 'local'],
    ['unexpected-argument'],
  ]) {
    test('rejects invalid arguments before prompting: $options', () async {
      await expectLater(runLogin(options), throwsA(isA<UsageException>()));
      expect(prompts, 0);
      expect(requests, isEmpty);
      await expectCredentialsUnchanged();
    });
  }

  test('cancelling credentials makes no requests or changes', () async {
    credentials = null;
    expect(await runLogin(), 1);
    expect(logger.stderrMessages, [t.login.inputRequired]);
    expect(requests, isEmpty);
    expect(client.closed, isTrue);
    await expectCredentialsUnchanged();
  });

  for (final (label, respond) in <(String, Future<http.Response> Function())>[
    (
      'missing user or wrong password',
      () async => http.Response(password, 400),
    ),
    (
      'redirect',
      () async => http.Response(
        token,
        302,
        headers: {'location': 'https://example.com'},
      ),
    ),
    ('unavailable emulator', () async => throw http.ClientException(password)),
    ('timeout', () => Completer<http.Response>().future),
  ]) {
    test('preserves credentials after Auth Emulator $label', () async {
      authenticate = respond;
      expect(await runLogin([], const Duration(milliseconds: 20)), 1);
      expect(logger.stderrMessages, [t.login.emulatorAuthenticationFailed]);
      expect(requests, hasLength(1));
      expect(requests.single.url.host, '127.0.0.1');
      expect(client.closed, isTrue);
      await expectCredentialsUnchanged();
    });
  }

  for (final status in [401, 403, 500, 302]) {
    test(
      'preserves credentials when the server returns HTTP $status',
      () async {
        fetchTeams = () async => http.Response(
          token,
          status,
          headers: {'location': 'https://example.com/teams'},
        );
        expect(await runLogin(), 1);
        expect(logger.stderrMessages, [
          status == 401 || status == 403
              ? t.login.authenticationFailed
              : t.login.requestFailed(status: status),
        ]);
        expect(requests, hasLength(2));
        expect(client.closed, isTrue);
        await expectCredentialsUnchanged();
      },
    );
  }

  for (final body in [
    token,
    '{}',
    'null',
    '[null]',
    '[{"id":42}]',
    '[{"id":""}]',
  ]) {
    test('rejects an invalid team response: $body', () async {
      fetchTeams = () async => http.Response(body, 200);
      expect(await runLogin(), 1);
      expect(logger.stderrMessages, [t.login.invalidResponse]);
      expect(client.closed, isTrue);
      await expectCredentialsUnchanged();
    });
  }

  for (final body in ['[]', '[{"id":"another-team"}]']) {
    test('rejects a membership list without test-team: $body', () async {
      fetchTeams = () async => http.Response(body, 200);
      expect(await runLogin(), 1);
      expect(logger.stderrMessages, [t.login.localTeamRequired]);
      expect(client.closed, isTrue);
      await expectCredentialsUnchanged();
    });
  }

  test('selects test-team from multiple confirmed memberships', () async {
    fetchTeams = () async =>
        http.Response('[{"id":"other-team"},{"id":"test-team"}]', 200);
    expect(await runLogin(), 0);
    expect((await store.getActiveProfile())!.teamId, 'test-team');
  });

  for (final (label, respond) in <(String, Future<http.Response> Function())>[
    ('network failure', () async => throw http.ClientException(token)),
    ('timeout', () => Completer<http.Response>().future),
  ]) {
    test('preserves credentials on local API $label', () async {
      fetchTeams = respond;
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
