import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/src/commands/dev/seed_local_data.dart';
import 'package:openci_cli/src/i18n/i18n.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
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

void main() {
  group('seedLocalData', () {
    late _RecordingLogger logger;
    late Directory projectRoot;

    setUp(() async {
      logger = _RecordingLogger();
      projectRoot = await Directory.systemTemp.createTemp(
        'seed_local_data_test_',
      );
    });

    tearDown(() async {
      await projectRoot.delete(recursive: true);
    });

    test('requests the default seed data exactly once', () async {
      const serverUrl = 'http://localhost:9090';
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"success":true,"jobId":"job-test"}', 200);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {
            'OPENCI_SERVER_URL': serverUrl,
            'INTERNAL_API_KEY': 'test-internal-key',
          },
        ),
        () => client,
      );

      expect(result, isTrue);
      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('$serverUrl/internal/seed'));
      expect(request.headers['content-type'], 'application/json');
      expect(request.headers['authorization'], 'Bearer test-internal-key');
      expect(jsonDecode(request.body), isEmpty);
      expect(logger.stderrMessages, isEmpty);
      expect(logger.stdoutMessages, [
        '\n${t.dev.start.stepSeed}',
        t.dev.start.stepSeedCompleted,
      ]);
    });

    test('uses the default server URL and HTTP client', () async {
      var requestCount = 0;

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        ),
        () => MockClient((request) async {
          requestCount++;
          expect(request.url, Uri.parse('http://localhost:8080/internal/seed'));
          expect(request.headers['authorization'], 'Bearer test-internal-key');
          return http.Response('{"success":true,"jobId":"job-test"}', 200);
        }),
      );

      expect(result, isTrue);
      expect(requestCount, 1);
    });

    test('reads the internal key from the project .env file', () async {
      await File(p.join(projectRoot.path, '.env')).writeAsString(
        '# Local development\nINTERNAL_API_KEY = file-key # comment\n',
      );
      var requestCount = 0;

      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => MockClient((request) async {
          requestCount++;
          expect(request.headers['authorization'], 'Bearer file-key');
          return http.Response('{"success":true,"jobId":"job-test"}', 200);
        }),
      );

      expect(result, isTrue);
      expect(requestCount, 1);
    });

    test('uses the shell key before the project .env key', () async {
      await File(
        p.join(projectRoot.path, '.env'),
      ).writeAsString('INTERNAL_API_KEY=file-key\n');

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'INTERNAL_API_KEY': 'shell-key'},
        ),
        () => MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer shell-key');
          return http.Response('{"success":true,"jobId":"job-test"}', 200);
        }),
      );

      expect(result, isTrue);
    });

    test('does not send the project key to a remote server', () async {
      await File(
        p.join(projectRoot.path, '.env'),
      ).writeAsString('INTERNAL_API_KEY=file-key\n');
      var requestCount = 0;

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'OPENCI_SERVER_URL': 'https://ci.example.com'},
        ),
        () => MockClient((_) async {
          requestCount++;
          return http.Response('', 200);
        }),
      );

      expect(result, isFalse);
      expect(requestCount, 0);
      expect(logger.stderrMessages.single, contains('INTERNAL_API_KEY'));
      expect(logger.stderrMessages.single, isNot(contains('file-key')));
    });

    test('returns false when the seed request fails', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        expect(request.url, Uri.parse('http://localhost:8080/internal/seed'));
        return http.Response('seed failed', 500);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: const {'INTERNAL_API_KEY': 'test-internal-key'},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(requestCount, 1);
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepSeedFailed),
      );
      expect(logger.stderrMessages.single, contains('Status: 500'));
      expect(logger.stderrMessages.single, contains('Body: seed failed'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('reports rejected credentials without logging the key', () async {
      final client = MockClient((_) async {
        return http.Response('{"error":"Authentication required"}', 401);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(logger.stderrMessages.single, contains('Status: 401'));
      expect(
        logger.stderrMessages.single,
        isNot(contains('test-internal-key')),
      );
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('returns false when an HTTP request throws', () async {
      final client = MockClient(
        (_) async => throw Exception('connection failed'),
      );

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: const {'INTERNAL_API_KEY': 'test-internal-key'},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(logger.stderrMessages.single, contains('connection failed'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('returns false when the seed request times out', () async {
      final client = MockClient((_) => Completer<http.Response>().future);

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: const {'INTERNAL_API_KEY': 'test-internal-key'},
          timeout: const Duration(milliseconds: 50),
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(logger.stderrMessages.single, contains('TimeoutException'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('does not send a request when the internal key is unset', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('', 200);
      });

      final result = await http.runWithClient(
        () => seedLocalData(logger, projectRoot: projectRoot, environment: {}),
        () => client,
      );

      expect(result, isFalse);
      expect(requestCount, 0);
      expect(logger.stderrMessages.single, contains('INTERNAL_API_KEY'));
    });

    test('does not send a request when the internal key is empty', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return http.Response('', 200);
      });

      final result = await http.runWithClient(
        () => seedLocalData(
          logger,
          projectRoot: projectRoot,
          environment: {'INTERNAL_API_KEY': ''},
        ),
        () => client,
      );

      expect(result, isFalse);
      expect(requestCount, 0);
      expect(logger.stderrMessages.single, contains('INTERNAL_API_KEY'));
    });
  });
}
