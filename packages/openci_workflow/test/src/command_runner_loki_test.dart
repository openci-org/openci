import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  group('runCommand with Loki', () {
    late HttpServer server;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test(
      'batches uploads and forwards every line in each stream in order',
      () async {
        var activeRequests = 0;
        var maximumActiveRequests = 0;
        var requestCount = 0;
        final messages = <String, List<String>>{'stdout': [], 'stderr': []};
        const command = r'''
i=0
while [ "$i" -lt 200 ]; do
  echo "out-$i"
  echo "err-$i" >&2
  i=$((i + 1))
done
''';

        server.listen((request) async {
          requestCount++;
          activeRequests++;
          if (activeRequests > maximumActiveRequests) {
            maximumActiveRequests = activeRequests;
          }
          try {
            final payload =
                jsonDecode(await utf8.decoder.bind(request).join())
                    as Map<String, dynamic>;
            final stream = (payload['streams'] as List).single as Map;
            final labels = stream['stream'] as Map;
            expect(labels['command'], command);
            expect(labels['run_id'], 'test-run');
            expect(labels['build_job_id'], 'test-job');
            expect(labels['step_id'], 'test-step');
            expect(labels['type'], 'step_log');
            final values = stream['values'] as List;
            expect(values.length, inInclusiveRange(1, 100));
            for (final value in values.cast<List>()) {
              messages[labels['stream']]!.add(value[1] as String);
            }

            // Hold connections open long enough to expose unbounded uploads.
            await Future<void>.delayed(const Duration(milliseconds: 10));
            request.response.statusCode = HttpStatus.noContent;
            await request.response.close();
          } finally {
            activeRequests--;
          }
        });

        final result = await _runCommand(command, server);

        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(maximumActiveRequests, inInclusiveRange(1, 2));
        expect(requestCount, lessThanOrEqualTo(8));
        expect(messages['stdout'], List.generate(200, (i) => 'out-$i'));
        expect(messages['stderr'], List.generate(200, (i) => 'err-$i'));
        expect(result.stdout, contains('[STDOUT] out-199'));
        expect(result.stderr, contains('[STDERR] err-199'));
        expect(result.stderr, isNot(contains('[WARN]')));
      },
    );

    for (final exitCode in [0, 7]) {
      test('preserves exit code $exitCode when Loki rejects uploads', () async {
        var requestCount = 0;
        server.listen((request) async {
          requestCount++;
          await request.drain<void>();
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.write('unavailable');
          await request.response.close();
        });

        final result = await _runCommand('''
echo first
echo error >&2
sleep 0.1
echo last
exit $exitCode
''', server);

        expect(result.exitCode, exitCode, reason: result.stderr as String);
        expect(result.stdout, contains('[STDOUT] first'));
        expect(result.stdout, contains('[STDOUT] last'));
        expect(result.stderr, contains('[STDERR] error'));
        expect(result.stderr, contains('HTTP 503'));
        expect('[WARN]'.allMatches(result.stderr as String), hasLength(1));
        expect(requestCount, inInclusiveRange(1, 2));
      });
    }

    test('continues when the Loki connection fails', () async {
      server.listen((request) async {
        await request.drain<void>();
        final socket = await request.response.detachSocket();
        socket.destroy();
      });

      final result = await _runCommand('''
echo first
sleep 0.1
echo last
''', server);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(result.stdout, contains('[STDOUT] last'));
      expect(result.stderr, contains('[WARN]'));
      expect(result.stderr, contains('ClientException'));
    });

    test('stops forwarding when Loki never responds', () async {
      var requestCount = 0;
      server.listen((request) async {
        requestCount++;
        await request.drain<void>();
      });

      final result = await _runCommand('echo first; echo last', server);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(result.stdout, contains('[STDOUT] last'));
      expect(result.stderr, contains('[WARN]'));
      expect(result.stderr, contains('TimeoutException'));
      expect(requestCount, 1);
    });
  });
}

Future<ProcessResult> _runCommand(String command, HttpServer server) async {
  final packageConfig = (await Isolate.packageConfig)!;
  final process = await Process.start(
    'dart',
    [
      '--packages=${packageConfig.toFilePath()}',
      'test/fixtures/run_command.dart',
      command,
    ],
    environment: {
      'LOKI_URL': 'http://${server.address.host}:${server.port}',
      'GENUINE_CI_RUN_ID': 'test-run',
      'GENUINE_CI_BUILD_JOB_ID': 'test-job',
      'GENUINE_CI_STEP_ID': 'test-step',
    },
  );
  addTearDown(() async {
    process.kill();
    await process.exitCode;
  });

  final output = utf8.decoder.bind(process.stdout).join();
  final errors = utf8.decoder.bind(process.stderr).join();
  return ProcessResult(
    process.pid,
    await process.exitCode,
    await output,
    await errors,
  );
}
