import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:http/http.dart' as http;
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

void main() {
  const token = 'private-status-token';
  const refreshToken = 'private-status-refresh-token';
  const apiKey = 'private-status-api-key';
  const remote = AuthProfile(
    serverUrl: 'https://ci.example.com/proxy/',
    teamId: 'remote-team',
    authType: 'firebase',
    token: token,
    refreshToken: refreshToken,
    firebaseApiKey: apiKey,
  );
  const local = AuthProfile(
    serverUrl: 'http://localhost:8080',
    teamId: 'test-team',
    authType: 'firebase',
    token: token,
    refreshToken: refreshToken,
    firebaseApiKey: apiKey,
    firebaseAuthEmulatorHost: '127.0.0.1:9099',
  );

  late Directory root;
  late CredentialStore store;
  late _RecordingLogger logger;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    root = await Directory.systemTemp.createTemp('genuineci-status-');
    store = CredentialStore(
      customFilePath: p.join(root.path, 'credentials.json'),
    );
    logger = _RecordingLogger();
    await store.set(
      const CredentialConfig(
        activeProfile: 'remote',
        profiles: {'remote': remote, 'local': local},
      ),
    );
  });

  tearDown(() async {
    final output = [...logger.output, ...logger.errors].join('\n');
    for (final secret in [token, refreshToken, apiKey]) {
      expect(output, isNot(contains(secret)));
    }
    LocaleSettings.setLocaleSync(AppLocale.en);
    await root.delete(recursive: true);
  });

  Future<int?> run([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('genuineci', 'test')
      ..addCommand(StatusCommand(logger: logger, credentialStore: store));
    return http.runWithClient(
      () => runner.run(['status', ...arguments]),
      () => throw StateError('Status must not create an HTTP client'),
    );
  }

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    for (final name in ['remote', 'local']) {
      test(
        'shows the selected $name profile in ${locale.languageCode}',
        () async {
          LocaleSettings.setLocaleSync(locale);
          final profile = (name == 'remote' ? remote : local).copyWith(
            expiresAt: DateTime.utc(2020),
          );
          final config = await store.get();
          await store.set(
            config.copyWith(
              activeProfile: name,
              profiles: {...config.profiles, name: profile},
            ),
          );
          final before = await File(store.filePath).readAsBytes();

          expect(await run(), 0);

          expect(logger.output, [
            t.status.profile(value: name),
            t.status.server(value: profile.serverUrl),
            t.status.team(value: profile.teamId),
          ]);
          expect(logger.errors, isEmpty);
          expect(await File(store.filePath).readAsBytes(), before);
        },
      );
    }
  }

  test(
    'shows a login hint without creating a missing credentials file',
    () async {
      await File(store.filePath).delete();

      expect(await run(), 0);

      expect(logger.output, [t.status.noActiveProfile]);
      expect(logger.errors, isEmpty);
      expect(await File(store.filePath).exists(), isFalse);
    },
  );

  test('shows a login hint when no profiles are saved', () async {
    await store.set(const CredentialConfig());

    expect(await run(), 0);

    expect(logger.output, [t.status.noActiveProfile]);
    expect(logger.errors, isEmpty);
  });

  test(
    'reports a missing active profile instead of selecting another',
    () async {
      final config = (await store.get()).copyWith(activeProfile: 'removed');
      await store.set(config);

      expect(await run(), 1);

      expect(logger.output, isEmpty);
      expect(logger.errors, [t.status.profileMissing(profile: 'removed')]);
      expect(await store.get(), config);
    },
  );

  test('marks an unset server and team explicitly', () async {
    await store.saveProfile(
      'remote',
      remote.copyWith(serverUrl: '', teamId: '  '),
    );

    expect(await run(), 0);

    expect(logger.output, [
      t.status.profile(value: 'remote'),
      t.status.server(value: t.status.notSet),
      t.status.team(value: t.status.notSet),
    ]);
  });

  for (final server in [
    'https://user:$token@ci.example.com',
    'https://ci.example.com?token=$token',
    'https://ci.example.com#$token',
    'file:///$token',
    'https://[invalid',
  ]) {
    test('does not print an invalid server URL: $server', () async {
      await store.saveProfile('remote', remote.copyWith(serverUrl: server));

      expect(await run(), 0);

      expect(logger.output[1], t.status.server(value: t.status.invalidServer));
      expect(logger.errors, isEmpty);
    });
  }

  test('escapes terminal control characters in displayed fields', () async {
    await store.saveProfile(
      'remote\n\x1b[31m',
      remote.copyWith(
        serverUrl: 'https://ci.example.com/\x1b[31m',
        teamId: 'team\t\u0085',
      ),
    );

    expect(await run(), 0);

    expect(logger.output, [
      t.status.profile(value: r'remote\x0a\x1b[31m'),
      t.status.server(value: r'https://ci.example.com/\x1b[31m'),
      t.status.team(value: r'team\x09\x85'),
    ]);
  });

  for (final contents in [
    '',
    '{"token":"$token", broken',
    '["$token"]',
    '{"profiles":{"remote":{"team_id":["$token"]}}}',
  ]) {
    test(
      'reports unreadable credential data without exposing it: $contents',
      () async {
        await File(store.filePath).writeAsString(contents);

        expect(await run(), 1);

        expect(logger.output, isEmpty);
        expect(logger.errors, [t.status.readFailed]);
        expect(await File(store.filePath).readAsString(), contents);
      },
    );
  }

  test('rejects positional arguments before reading credentials', () async {
    await File(store.filePath).writeAsString('broken');

    await expectLater(
      run(['unexpected']),
      throwsA(
        isA<UsageException>().having(
          (error) => error.message,
          'message',
          t.status.noArguments,
        ),
      ),
    );

    expect(logger.output, isEmpty);
    expect(logger.errors, isEmpty);
  });

  test('help is available when credentials cannot be read', () async {
    await File(store.filePath).writeAsString('broken');
    final messages = <String>[];

    await runZoned(
      () => run(['--help']),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) => messages.add(message),
      ),
    );

    expect(messages.join('\n'), contains('Usage: genuineci status'));
    expect(logger.output, isEmpty);
    expect(logger.errors, isEmpty);
  });
}
