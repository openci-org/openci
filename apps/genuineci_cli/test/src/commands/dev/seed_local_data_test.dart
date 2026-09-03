import 'dart:async';
import 'dart:convert';

import 'package:cli_util/cli_logging.dart';
import 'package:crypto/crypto.dart';
import 'package:genuineci_cli/src/commands/dev/seed_local_data.dart';
import 'package:genuineci_cli/src/i18n/i18n.dart';
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

void main() {
  group('seedLocalData', () {
    late _RecordingLogger logger;

    setUp(() {
      logger = _RecordingLogger();
    });

    test('seeds a team and dispatches a signed push webhook', () async {
      const serverUrl = 'http://localhost:9090';
      const webhookSecret = 'test-secret';
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      });

      final result = await seedLocalData(
        logger,
        client: client,
        environment: {
          'OPENCI_SERVER_URL': serverUrl,
          'GITHUB_WEBHOOK_SECRET': webhookSecret,
        },
      );

      expect(result, isTrue);
      expect(requests, hasLength(2));

      final seedRequest = requests[0];
      expect(seedRequest.method, equals('POST'));
      expect(seedRequest.url, equals(Uri.parse('$serverUrl/internal/seed')));
      expect(seedRequest.headers['content-type'], equals('application/json'));
      expect(jsonDecode(seedRequest.body), equals({}));

      final webhookRequest = requests[1];
      expect(webhookRequest.method, equals('POST'));
      expect(webhookRequest.url, equals(Uri.parse('$serverUrl/webhook')));
      expect(webhookRequest.headers['x-github-event'], equals('push'));
      expect(
        webhookRequest.headers['x-github-delivery'],
        matches(RegExp(r'^delivery-\d+$')),
      );
      final expectedDigest = Hmac(
        sha256,
        utf8.encode(webhookSecret),
      ).convert(utf8.encode(webhookRequest.body));
      expect(
        webhookRequest.headers['x-hub-signature-256'],
        equals('sha256=$expectedDigest'),
      );
      expect(
        jsonDecode(webhookRequest.body),
        containsPair('ref', 'refs/heads/main'),
      );
      expect(logger.stderrMessages, isEmpty);
      expect(logger.stdoutMessages, [
        '\n${t.dev.start.stepSeed}',
        t.dev.start.stepSeedCompleted,
      ]);
    });

    test('returns false when the seed request fails', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('seed failed', 500);
      });

      final result = await seedLocalData(
        logger,
        client: client,
        environment: const {},
      );

      expect(result, isFalse);
      expect(requestCount, equals(1));
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepSeedFailed),
      );
      expect(logger.stderrMessages.single, contains('Status: 500'));
      expect(logger.stderrMessages.single, contains('Body: seed failed'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('returns false when the webhook request fails', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/webhook') {
          return http.Response('webhook failed', 500);
        }
        return http.Response('{}', 200);
      });

      final result = await seedLocalData(
        logger,
        client: client,
        environment: const {},
      );

      expect(result, isFalse);
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepSeedFailed),
      );
      expect(logger.stderrMessages.single, contains('Body: webhook failed'));
    });

    test('returns false when an HTTP request throws', () async {
      final client = MockClient(
        (_) async => throw Exception('connection failed'),
      );

      final result = await seedLocalData(
        logger,
        client: client,
        environment: const {},
      );

      expect(result, isFalse);
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepSeedFailed),
      );
      expect(logger.stderrMessages.single, contains('connection failed'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('returns false when seed request times out', () async {
      final client = MockClient((_) => Completer<http.Response>().future);

      final result = await seedLocalData(
        logger,
        client: client,
        environment: const {},
        timeout: const Duration(milliseconds: 50),
      );

      expect(result, isFalse);
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepSeedFailed),
      );
      expect(logger.stderrMessages.single, contains('TimeoutException'));
      expect(logger.stdoutMessages, ['\n${t.dev.start.stepSeed}']);
    });

    test('returns false when webhook request times out', () async {
      final client = MockClient((request) {
        if (request.url.path == '/internal/seed') {
          return Future.value(http.Response('{}', 200));
        }
        return Completer<http.Response>().future;
      });

      final result = await seedLocalData(
        logger,
        client: client,
        environment: const {},
        timeout: const Duration(milliseconds: 50),
      );

      expect(result, isFalse);
      expect(
        logger.stderrMessages.single,
        contains(t.dev.start.stepSeedFailed),
      );
      expect(logger.stderrMessages.single, contains('TimeoutException'));
    });
  });
}
