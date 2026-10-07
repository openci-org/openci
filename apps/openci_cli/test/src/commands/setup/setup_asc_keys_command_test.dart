import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/asc/find_cached_asc_executable.dart';
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
  late AppLocale originalLocale;
  late _RecordingLogger logger;
  late Future<File?> Function() findCachedExecutable;
  late int lookups;

  setUp(() {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    logger = _RecordingLogger();
    findCachedExecutable = () async => null;
    lookups = 0;
  });

  tearDown(() {
    LocaleSettings.setLocaleSync(originalLocale);
  });

  Future<int?> run([List<String> arguments = const []]) {
    final runner = CommandRunner<int>('genuineci setup', 'test')
      ..addCommand(
        SetupAscKeysCommand(
          logger: logger,
          findCachedExecutable: () {
            lookups++;
            return findCachedExecutable();
          },
        ),
      );
    return runner.run(['asc-keys', ...arguments]);
  }

  for (final locale in [AppLocale.en, AppLocale.ja]) {
    test('reports a cached file but not successful setup: $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      final file = File('cached-asc');
      findCachedExecutable = () async => file;

      expect(await run(), 1);

      expect(lookups, 1);
      expect(logger.output, [
        t.setup.ascKeys.cacheFound(version: ascVersion, path: file.path),
      ]);
      expect(logger.errors, [t.setup.ascKeys.notImplemented]);
    });

    test(
      'reports a missing file without claiming installation: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);

        expect(await run(), 1);

        expect(lookups, 1);
        expect(logger.output, isEmpty);
        expect(logger.errors, [
          t.setup.ascKeys.cacheMissing(version: ascVersion),
        ]);
      },
    );
  }

  test('reports an unsupported platform', () async {
    findCachedExecutable = () async => throw UnsupportedError('unsupported');

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.unsupportedPlatform]);
  });

  test('reports filesystem failures', () async {
    findCachedExecutable = () async =>
        throw const FileSystemException('denied');

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.cacheCheckFailed]);
  });

  test('rejects positional arguments before inspecting the cache', () async {
    await expectLater(run(['unexpected']), throwsA(isA<UsageException>()));

    expect(lookups, 0);
    expect(logger.output, isEmpty);
    expect(logger.errors, isEmpty);
  });

  test('shows help without inspecting the cache', () async {
    expect(await run(['--help']), isNull);

    expect(lookups, 0);
    expect(logger.errors, isEmpty);
  });
}
