import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:genuineci_cli/src/asc/asc_release.dart';
import 'package:genuineci_cli/src/asc/install_asc.dart';
import 'package:genuineci_cli/src/asc/verify_asc_executable.dart';
import 'package:genuineci_cli/src/commands/setup/read_apple_id.dart';
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

class _LoginProcess implements Process {
  _LoginProcess(this.exitCode);

  @override
  final Future<int> exitCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppLocale originalLocale;
  late _RecordingLogger logger;
  late Future<File?> Function() findCachedExecutable;
  late Future<File> Function() installExecutable;
  late Future<void> Function(File) verifyExecutable;
  late Future<String?> Function() readAppleId;
  late Future<Process> Function(File, String) startLogin;
  late List<String> steps;
  late List<File> verifiedFiles;
  late List<(File, String)> startedLogins;
  late int lookups;
  late int installs;
  late int reads;

  setUp(() {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    logger = _RecordingLogger();
    findCachedExecutable = () async => null;
    installExecutable = () async => File('installed-asc');
    verifyExecutable = (_) async {};
    readAppleId = () async => 'user@example.com';
    startLogin = (_, _) async => _LoginProcess(Future.value(0));
    steps = [];
    verifiedFiles = [];
    startedLogins = [];
    lookups = 0;
    installs = 0;
    reads = 0;
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
            steps.add('find');
            lookups++;
            return findCachedExecutable();
          },
          installExecutable: () {
            steps.add('install');
            installs++;
            return installExecutable();
          },
          verifyExecutable: (file) {
            steps.add('verify');
            verifiedFiles.add(file);
            return verifyExecutable(file);
          },
          readAppleIdInput: () {
            steps.add('read');
            reads++;
            return readAppleId();
          },
          startLogin: (file, appleId) {
            steps.add('login');
            startedLogins.add((file, appleId));
            return startLogin(file, appleId);
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
      expect(installs, 0);
      expect(verifiedFiles, [file]);
      expect(steps, ['find', 'verify', 'read', 'login']);
      expect(startedLogins, [(file, 'user@example.com')]);
      expect(logger.output, [
        t.setup.ascKeys.cacheFound(version: ascVersion, path: file.path),
        t.setup.ascKeys.versionVerified(version: ascVersion),
        t.setup.ascKeys.appleIdReceived,
      ]);
      expect(logger.errors, [t.setup.ascKeys.notImplemented]);
    });

    test(
      'installs a missing file but does not claim successful key setup: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);

        expect(await run(), 1);

        expect(lookups, 1);
        expect(installs, 1);
        expect(verifiedFiles.map((file) => file.path), ['installed-asc']);
        expect(steps, ['find', 'install', 'verify', 'read', 'login']);
        expect(startedLogins, [(verifiedFiles.single, 'user@example.com')]);
        expect(logger.output, [
          t.setup.ascKeys.installing(version: ascVersion),
          t.setup.ascKeys.installed(version: ascVersion, path: 'installed-asc'),
          t.setup.ascKeys.versionVerified(version: ascVersion),
          t.setup.ascKeys.appleIdReceived,
        ]);
        expect(logger.errors, [t.setup.ascKeys.notImplemented]);
      },
    );

    for (final cached in [true, false]) {
      for (final failure in AscVerificationFailure.values) {
        test('reports $failure (cached: $cached, locale: $locale)', () async {
          LocaleSettings.setLocaleSync(locale);
          final file = File('cached-asc');
          findCachedExecutable = () async => cached ? file : null;
          verifyExecutable = (_) async =>
              throw AscVerificationException(failure);

          expect(await run(), 1);
          expect(reads, 0);
          expect(startedLogins, isEmpty);

          expect(installs, cached ? 0 : 1);
          expect(verifiedFiles.map((file) => file.path), [
            cached ? file.path : 'installed-asc',
          ]);
          expect(logger.output, [
            if (cached)
              t.setup.ascKeys.cacheFound(version: ascVersion, path: file.path)
            else ...[
              t.setup.ascKeys.installing(version: ascVersion),
              t.setup.ascKeys.installed(
                version: ascVersion,
                path: 'installed-asc',
              ),
            ],
          ]);
          expect(logger.errors, [
            switch (failure) {
              AscVerificationFailure.checksum =>
                t.setup.ascKeys.cachedChecksumFailed,
              AscVerificationFailure.execution =>
                t.setup.ascKeys.executionFailed,
              AscVerificationFailure.timeout => t.setup.ascKeys.versionTimedOut,
              AscVerificationFailure.version => t.setup.ascKeys.versionMismatch(
                version: ascVersion,
              ),
            },
          ]);
        });
      }
    }

    test('stops when no Apple ID is entered: $locale', () async {
      LocaleSettings.setLocaleSync(locale);
      readAppleId = () async => null;

      expect(await run(), 1);

      expect(reads, 1);
      expect(startedLogins, isEmpty);
      expect(logger.output, isNot(contains(t.setup.ascKeys.appleIdReceived)));
      expect(logger.errors, [t.setup.ascKeys.appleIdRequired]);
    });

    for (final failure in AppleIdInputFailure.values) {
      test('reports $failure during Apple ID input: $locale', () async {
        LocaleSettings.setLocaleSync(locale);
        readAppleId = () async => throw AppleIdInputException(failure);

        expect(await run(), 1);

        expect(reads, 1);
        expect(startedLogins, isEmpty);
        expect(logger.output, isNot(contains(t.setup.ascKeys.appleIdReceived)));
        expect(logger.errors, [
          switch (failure) {
            AppleIdInputFailure.notInteractive =>
              t.setup.ascKeys.terminalRequired,
            AppleIdInputFailure.read => t.setup.ascKeys.appleIdInputFailed,
          },
        ]);
      });
    }

    test(
      'reports login startup failure without raw details: $locale',
      () async {
        LocaleSettings.setLocaleSync(locale);
        startLogin = (file, appleId) async =>
            throw ProcessException(file.path, [appleId], 'private diagnostic');

        expect(await run(), 1);

        expect(startedLogins, hasLength(1));
        expect(logger.errors, [t.setup.ascKeys.loginStartFailed]);
      },
    );

    for (final (code, expected) in [
      (1, 1),
      (7, 7),
      (130, 130),
      (-2, 130),
      (-15, 143),
    ]) {
      test('propagates asc exit $code without proceeding: $locale', () async {
        LocaleSettings.setLocaleSync(locale);
        startLogin = (_, _) async => _LoginProcess(Future.value(code));

        expect(await run(), expected);

        expect(startedLogins, hasLength(1));
        expect(logger.errors, isEmpty);
      });
    }
  }

  test('waits for asc before reporting that key setup is unfinished', () async {
    final started = Completer<void>();
    final exited = Completer<int>();
    addTearDown(() {
      if (!exited.isCompleted) exited.complete(1);
    });
    startLogin = (_, _) async {
      started.complete();
      return _LoginProcess(exited.future);
    };
    var completed = false;
    final result = run().whenComplete(() => completed = true);
    await started.future;
    await Future<void>.delayed(Duration.zero);

    expect(completed, isFalse);
    expect(logger.errors, isEmpty);
    exited.complete(0);

    expect(await result, 1);
    expect(logger.errors, [t.setup.ascKeys.notImplemented]);
  });

  test('reports an unsupported platform', () async {
    findCachedExecutable = () async => throw UnsupportedError('unsupported');

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.unsupportedPlatform]);
    expect(installs, 0);
    expect(verifiedFiles, isEmpty);
    expect(reads, 0);
    expect(startedLogins, isEmpty);
  });

  test('reports filesystem failures', () async {
    findCachedExecutable = () async =>
        throw const FileSystemException('denied');

    expect(await run(), 1);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.setup.ascKeys.cacheFailed]);
    expect(installs, 0);
    expect(verifiedFiles, isEmpty);
    expect(reads, 0);
    expect(startedLogins, isEmpty);
  });

  for (final failure in AscInstallFailure.values) {
    test('reports $failure without claiming installation', () async {
      installExecutable = () async => throw AscInstallException(failure);

      expect(await run(), 1);
      expect(installs, 1);
      expect(verifiedFiles, isEmpty);
      expect(reads, 0);
      expect(startedLogins, isEmpty);
      expect(logger.output, [t.setup.ascKeys.installing(version: ascVersion)]);
      expect(logger.errors, [
        switch (failure) {
          AscInstallFailure.download => t.setup.ascKeys.downloadFailed,
          AscInstallFailure.checksum => t.setup.ascKeys.checksumFailed,
          AscInstallFailure.permission => t.setup.ascKeys.permissionFailed,
        },
      ]);
    });
  }

  test('reports cache write failures during installation', () async {
    installExecutable = () async =>
        throw const FileSystemException('disk full');

    expect(await run(), 1);
    expect(logger.output, [t.setup.ascKeys.installing(version: ascVersion)]);
    expect(logger.errors, [t.setup.ascKeys.cacheFailed]);
    expect(verifiedFiles, isEmpty);
    expect(reads, 0);
    expect(startedLogins, isEmpty);
  });

  test('reports cache read failures during verification', () async {
    findCachedExecutable = () async => File('cached-asc');
    verifyExecutable = (_) async => throw const FileSystemException('denied');

    expect(await run(), 1);
    expect(logger.output, [
      t.setup.ascKeys.cacheFound(version: ascVersion, path: 'cached-asc'),
    ]);
    expect(logger.errors, [t.setup.ascKeys.cacheFailed]);
    expect(installs, 0);
    expect(reads, 0);
    expect(startedLogins, isEmpty);
  });

  test('rejects positional arguments before inspecting the cache', () async {
    await expectLater(run(['unexpected']), throwsA(isA<UsageException>()));

    expect(lookups, 0);
    expect(installs, 0);
    expect(verifiedFiles, isEmpty);
    expect(reads, 0);
    expect(startedLogins, isEmpty);
    expect(logger.output, isEmpty);
    expect(logger.errors, isEmpty);
  });

  test('shows help without inspecting the cache', () async {
    expect(await run(['--help']), isNull);

    expect(lookups, 0);
    expect(installs, 0);
    expect(verifiedFiles, isEmpty);
    expect(reads, 0);
    expect(startedLogins, isEmpty);
    expect(logger.errors, isEmpty);
  });
}
