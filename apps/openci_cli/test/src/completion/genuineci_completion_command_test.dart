import 'package:args/command_runner.dart';
import 'package:cli_completion/parser.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/update/cli_updater.dart';
import 'package:test/test.dart';

const _defaultServer = 'https://openci-worker-01.tail4beb18.ts.net';
const _otherServer = 'https://ci.example.com';

class _Store extends CredentialStore {
  int reads = 0;
  Object? error;

  @override
  Future<CredentialConfig> get() async {
    reads++;
    if (error != null) throw error!;
    return const CredentialConfig(
      profiles: {
        'remote': AuthProfile(
          serverUrl: _defaultServer,
          teamId: 'remote-team',
          firebaseApiKey: 'remote-web-api-key',
          token: 'never-suggest-access-token',
          refreshToken: 'never-suggest-refresh-token',
        ),
        'other': AuthProfile(
          serverUrl: '$_otherServer/',
          teamId: 'other-team',
          firebaseApiKey: 'other-web-api-key',
        ),
        'local': AuthProfile(
          serverUrl: 'http://localhost:8080',
          teamId: 'local-team',
          firebaseApiKey: 'local-key',
        ),
        'invalid': AuthProfile(
          serverUrl: 'https://user:password@ci.example.com',
        ),
        'unsafe': AuthProfile(serverUrl: _defaultServer, teamId: 'bad\nvalue'),
      },
    );
  }

  @override
  Future<void> set(CredentialConfig config) async =>
      fail('Completion must not write credentials.');
}

class _Updater extends CliUpdater {
  @override
  Future<String?> getLatestUpdate({
    Duration timeout = const Duration(seconds: 2),
  }) async => fail('Completion must not check for updates.');
}

class _Logger implements Logger {
  @override
  void stdout(String message) => fail('Unexpected command output: $message');

  @override
  void stderr(String message) => fail('Unexpected command error: $message');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Runner extends GenuineCICommandRunner {
  _Runner(_Store store)
    : super(
        logger: _Logger(),
        updater: _Updater(),
        hasTerminal: true,
        completionCredentialStore: store,
      );

  final suggestions = <String, String?>{};

  @override
  void renderCompletionResult(CompletionResult result) {
    suggestions.addAll(result.completions);
  }

  Future<Set<String>> complete(
    String line,
    String shell, {
    List<String>? shellWords,
  }) async {
    suggestions.clear();
    final words = shellWords ?? line.split(' ');
    environmentOverride = {
      'SHELL': '/bin/$shell',
      'COMP_LINE': line,
      'COMP_POINT': '${line.length}',
      'COMP_CWORD': '${words.length - 1}',
    };
    expect(await run(['completion', '--', ...words]), 0);
    expect(suggestions.keys.join(' '), isNot(contains('never-suggest')));
    return suggestions.keys.toSet();
  }
}

Iterable<(String, Command<int>)> _commands(
  Map<String, Command<int>> commands, [
  String prefix = '',
]) sync* {
  for (final command in commands.values) {
    if (command.hidden) continue;
    final path = '$prefix${command.name}';
    yield (path, command);
    yield* _commands(command.subcommands, '$path ');
  }
}

void main() {
  late _Store store;
  late _Runner runner;

  setUp(() {
    store = _Store();
    runner = _Runner(store);
  });

  test('Bash replaces only the word after a colon or equals sign', () async {
    expect(
      await runner.complete(
        'genuineci login --server https://ci',
        'bash',
        shellWords: ['genuineci', 'login', '--server', 'https', ':', '//ci'],
      ),
      {'//ci.example.com'},
    );
    expect(
      await runner.complete(
        'genuineci login --server=https://ci',
        'bash',
        shellWords: [
          'genuineci',
          'login',
          '--server',
          '=',
          'https',
          ':',
          '//ci',
        ],
      ),
      {'//ci.example.com'},
    );
    expect(
      await runner.complete(
        'genuineci login --server https:',
        'bash',
        shellWords: ['genuineci', 'login', '--server', 'https', ':'],
      ),
      {'//openci-worker-01.tail4beb18.ts.net', '//ci.example.com'},
    );
  });

  for (final shell in ['bash', 'zsh']) {
    group(shell, () {
      test(
        'completes every command, subcommand and registered option',
        () async {
          expect(
            await runner.complete('genuineci ', shell),
            containsAll([
              'login',
              'status',
              'list',
              'register',
              'switch',
              'use',
              'dev',
              'sync',
              'update',
              'help',
            ]),
          );
          for (final (path, command) in _commands(runner.commands)) {
            expect(
              await runner.complete('genuineci $path', shell),
              contains(command.name),
              reason: path,
            );
            final suggestions = await runner.complete(
              'genuineci $path ',
              shell,
            );
            expect(
              suggestions,
              containsAll([
                for (final child in command.subcommands.values)
                  if (!child.hidden) child.name,
                for (final option in command.argParser.options.values)
                  if (!option.hide) '--${option.name}',
                '--verbose',
                '--version',
                '--check-updates',
                '--no-check-updates',
              ]),
              reason: path,
            );
            for (final option in command.argParser.options.values) {
              if (option.hide) continue;
              expect(
                await runner.complete(
                  'genuineci $path --${option.name}',
                  shell,
                ),
                contains('--${option.name}'),
                reason: path,
              );
              if (option.abbr != null) {
                expect(
                  await runner.complete('genuineci $path -', shell),
                  contains('-${option.abbr}'),
                  reason: path,
                );
              }
            }
          }
          expect(store.reads, 0);
        },
      );

      test('completes help targets at every command depth', () async {
        for (final (path, command) in _commands(runner.commands)) {
          expect(
            await runner.complete('genuineci help $path', shell),
            contains(command.name),
            reason: path,
          );
        }
        expect(await runner.complete('genuineci help register se', shell), {
          'secret',
          'secretFile',
        });
        expect(
          await runner.complete('genuineci help unknown ', shell),
          isEmpty,
        );
        expect(await runner.complete('genuineci help login t', shell), isEmpty);
        expect(store.reads, 0);
      });

      test(
        'completes language arguments and respects completed positions',
        () async {
          expect(
            await runner.complete('genuineci use ', shell),
            containsAll(['japanese', 'english']),
          );
          expect(await runner.complete('genuineci use ja', shell), {
            'japanese',
          });
          expect(await runner.complete('genuineci use EN', shell), {'english'});
          expect(
            await runner.complete(
              'genuineci --verbose use --no-check-updates ja',
              shell,
            ),
            {'japanese'},
          );
          expect(
            await runner.complete('genuineci use english j', shell),
            isEmpty,
          );
          expect(
            await runner.complete('genuineci use english ', shell),
            isNot(contains('japanese')),
          );
          expect(store.reads, 0);
        },
      );

      test('completes defaults and saved remote server URLs', () async {
        expect(await runner.complete('genuineci login --server ', shell), {
          _defaultServer,
          _otherServer,
        });
        expect(
          await runner.complete('genuineci login --server https://ci', shell),
          {shell == 'bash' ? '//ci.example.com' : _otherServer},
        );
        expect(
          await runner.complete('genuineci login --server=https://ci', shell),
          {shell == 'bash' ? '//ci.example.com' : '--server=$_otherServer'},
        );
        expect(
          await runner.complete(
            'genuineci login --server https://new.example ',
            shell,
          ),
          contains('--team-id'),
        );
        expect(
          runner.parse([
            'login',
            '--server',
            'https://new.example',
          ]).command!['server'],
          'https://new.example',
        );
      });

      test(
        'completes saved team IDs and Web API keys for the selected server',
        () async {
          expect(await runner.complete('genuineci login --team-id ', shell), {
            'remote-team',
          });
          expect(
            await runner.complete('genuineci login --team-id rem', shell),
            {'remote-team'},
          );
          expect(
            await runner.complete(
              'genuineci login --server $_otherServer/ --team-id ',
              shell,
            ),
            {'other-team'},
          );
          expect(
            await runner.complete(
              'genuineci login --firebase-api-key remote',
              shell,
            ),
            {'remote-web-api-key'},
          );
          expect(
            await runner.complete(
              'genuineci login --server $_otherServer --firebase-api-key other',
              shell,
            ),
            {'other-web-api-key'},
          );
          expect(
            await runner.complete(
              'genuineci login --server https://new.example --team-id ',
              shell,
            ),
            isEmpty,
          );
        },
      );

      test(
        'keeps completion quiet when saved credentials cannot be read',
        () async {
          for (final error in [
            const FormatException('invalid JSON'),
            StateError('invalid data'),
          ]) {
            store.error = error;
            expect(await runner.complete('genuineci login --server ', shell), {
              _defaultServer,
            });
            expect(
              await runner.complete('genuineci login --team-id ', shell),
              isEmpty,
            );
          }
        },
      );

      test('does not suggest hidden setup commands', () async {
        final suggestions = await runner.complete('genuineci ', shell);
        expect(suggestions, isNot(contains('completion')));
        expect(suggestions, isNot(contains('install-completion-files')));
        expect(suggestions, isNot(contains('uninstall-completion-files')));
        expect(await runner.complete('genuineci completion ', shell), isEmpty);
      });
    });
  }
}
