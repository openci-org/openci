import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:genuineci_cli/src/i18n/i18n.dart';
import 'package:genuineci_cli/src/update/cli_updater.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _Client extends MockClient {
  _Client(super.handler);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

class _Process implements Process {
  _Process(this.code);

  final int code;

  @override
  Future<int> get exitCode async => code;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

http.Response _package(String version) => http.Response(
  jsonEncode({
    'name': 'genuineci_cli',
    'latest': {'version': version},
  }),
  200,
);

void main() {
  group('getLatestUpdate', () {
    for (final (current, latest, update) in [
      ('0.1.0', '0.2.0', '0.2.0'),
      ('0.9.0', '0.10.0', '0.10.0'),
      ('0.1.0', '0.1.0', null),
      ('0.2.0', '0.1.0', null),
      ('0.2.0-dev.1', '0.1.0', null),
      ('0.2.0-dev.1', '0.2.0', '0.2.0'),
      ('0.1.0', '0.2.0-dev.1', null),
    ]) {
      test('$current with published $latest returns $update', () async {
        final client = _Client((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://pub.dev/api/packages/genuineci_cli',
          );
          expect(request.headers.containsKey('authorization'), isFalse);
          return _package(latest);
        });
        final updater = CliUpdater(
          currentVersion: current,
          clientFactory: () => client,
        );

        expect(await updater.getLatestUpdate(), update);
        expect(client.closed, isTrue);
      });
    }

    for (final (name, response) in [
      ('HTTP failure', http.Response('unavailable', 503)),
      ('invalid JSON', http.Response('not JSON', 200)),
      ('missing package', http.Response('{}', 200)),
      ('missing version', http.Response('{"name":"genuineci_cli"}', 200)),
      ('invalid version', _package('not-a-version')),
    ]) {
      test('closes the connection after $name', () async {
        final client = _Client((_) async => response);
        final updater = CliUpdater(clientFactory: () => client);

        await expectLater(updater.getLatestUpdate(), throwsA(anything));
        expect(client.closed, isTrue);
      });
    }

    test('closes the connection after a network failure', () async {
      final client = _Client(
        (_) async => throw const SocketException('offline'),
      );
      final updater = CliUpdater(clientFactory: () => client);

      await expectLater(
        updater.getLatestUpdate(),
        throwsA(isA<SocketException>()),
      );
      expect(client.closed, isTrue);
    });

    test('times out and closes a stalled connection', () async {
      final response = Completer<http.Response>();
      final client = _Client((_) => response.future);
      final updater = CliUpdater(clientFactory: () => client);

      await expectLater(
        updater.getLatestUpdate(timeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );
      expect(client.closed, isTrue);
      response.complete(_package('0.2.0'));
    });
  });

  group('install', () {
    for (final (childCode, expectedCode) in [(0, 0), (65, 65), (-2, 130)]) {
      test('runs Dart on PATH and preserves exit $childCode', () async {
        final logger = _Logger();
        final updater = CliUpdater(
          processStarter:
              (
                executable,
                arguments, {
                required runInShell,
                required mode,
              }) async {
                expect(executable, 'dart');
                expect(arguments, ['install', 'genuineci_cli', '0.2.0']);
                expect(runInShell, Platform.isWindows);
                expect(mode, ProcessStartMode.inheritStdio);
                return _Process(childCode);
              },
        );

        expect(await updater.install('0.2.0', logger), expectedCode);
        expect(logger.output.first, t.update.updating(version: '0.2.0'));
        if (childCode == 0) {
          expect(logger.output.last, t.update.updated(version: '0.2.0'));
          expect(logger.errors, isEmpty);
        } else {
          expect(logger.output, hasLength(1));
          expect(logger.errors, [t.update.installFailed]);
        }
      });
    }

    test('reports a missing Dart SDK without claiming success', () async {
      final logger = _Logger();
      final updater = CliUpdater(
        processStarter:
            (
              executable,
              arguments, {
              required runInShell,
              required mode,
            }) async =>
                throw ProcessException(executable, arguments, 'not found'),
      );

      expect(await updater.install('0.2.0', logger), 1);
      expect(logger.output, [t.update.updating(version: '0.2.0')]);
      expect(logger.errors, [t.update.dartUnavailable]);
    });
  });
}
