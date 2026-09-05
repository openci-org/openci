import 'dart:async';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockOrchardApiClient extends Mock implements OrchardApiClient {}

void main() {
  late OrchardApiClient api;
  late http.Client lokiClient;
  late List<http.Request> requests;
  late List<Object> errors;
  late Future<http.Response> Function(http.Request) respond;

  void stubExec(
    Future<int> Function(void Function(String, String) onLog) execute,
  ) {
    when(
      () => api.execCommandWebSocket(
        vmName: 'vm-1',
        command: 'build',
        onLog: any(named: 'onLog'),
      ),
    ).thenAnswer((invocation) {
      final onLog =
          invocation.namedArguments[#onLog] as void Function(String, String);
      return execute(onLog);
    });
  }

  Future<int> runCommand({Duration logTimeout = const Duration(seconds: 10)}) =>
      executeCommand(
        api: api,
        lokiClient: lokiClient,
        lokiUrl: 'http://loki:3100',
        vmName: 'vm-1',
        command: 'build',
        runId: 'run-1',
        jobId: 'job-1',
        onLogError: (error, _) => errors.add(error),
        logTimeout: logTimeout,
      );

  setUpAll(() {
    registerFallbackValue((String line, String stream) {});
  });

  setUp(() {
    api = _MockOrchardApiClient();
    requests = [];
    errors = [];
    respond = (_) async => http.Response('', 204);
    lokiClient = MockClient((request) {
      requests.add(request);
      return respond(request);
    });
    stubExec((onLog) async {
      onLog('first', 'stdout');
      onLog('last', 'stderr');
      return 23;
    });
  });

  tearDown(() {
    verifyNever(api.close);
    lokiClient.close();
  });

  group('executeCommand', () {
    test(
      'sends logs serially and waits before returning the exit code',
      () async {
        final started = Completer<void>();
        final response = Completer<http.Response>();
        final lastStarted = Completer<void>();
        final lastResponse = Completer<http.Response>();
        respond = (_) {
          if (requests.length == 1) {
            started.complete();
            return response.future;
          }
          lastStarted.complete();
          return lastResponse.future;
        };
        var finished = false;

        final result = runCommand().then((code) {
          finished = true;
          return code;
        });
        await started.future;

        expect(requests, hasLength(1));
        expect(finished, isFalse);
        response.complete(http.Response('', 204));
        await lastStarted.future;
        expect(finished, isFalse);
        lastResponse.complete(http.Response('', 204));
        expect(await result, 23);
        expect(requests, hasLength(2));
        expect(errors, isEmpty);
      },
    );

    for (final failure in <Object>[
      http.Response('', 500),
      http.ClientException('Connection refused'),
    ]) {
      test(
        'reports ${failure.runtimeType} and continues sending logs',
        () async {
          respond = (_) async {
            if (requests.length > 1) return http.Response('', 204);
            if (failure is http.Response) return failure;
            throw failure;
          };
          stubExec((onLog) async {
            onLog('first', 'stdout');
            // Delivery can fail while the command is still running.
            await Future<void>.delayed(Duration.zero);
            onLog('last', 'stderr');
            return 23;
          });

          expect(await runCommand(), 23);
          expect(requests, hasLength(2));
          expect(errors, hasLength(1));
          expect(
            errors.single,
            failure is http.Response ? isA<StateError>() : same(failure),
          );
        },
      );
    }

    test(
      'drains logs and preserves an execution error when Loki fails',
      () async {
        final error = StateError('Orchard connection closed before exit');
        final started = Completer<void>();
        final response = Completer<http.Response>();
        stubExec((onLog) async {
          onLog('last output', 'stderr');
          throw error;
        });
        respond = (_) {
          started.complete();
          return response.future;
        };
        var finished = false;

        final result = expectLater(runCommand(), throwsA(same(error))).then((
          _,
        ) {
          finished = true;
        });
        await started.future;

        expect(finished, isFalse);
        response.complete(http.Response('', 500));
        await result;
        expect(errors.single, isA<StateError>());
      },
    );

    test('times out a delivery and handles a late transport failure', () async {
      final response = Completer<http.Response>();
      respond = (_) => requests.length == 1
          ? response.future
          : Future.value(http.Response('', 204));

      expect(
        await runCommand(logTimeout: const Duration(milliseconds: 20)),
        23,
      );
      expect(requests, hasLength(2));
      expect(errors.single, isA<TimeoutException>());

      response.completeError(http.ClientException('Late failure'));
      await Future<void>.delayed(Duration.zero);
      expect(errors, hasLength(1));
    });

    test(
      'returns successfully without contacting Loki for a silent command',
      () async {
        stubExec((_) async => 0);

        expect(await runCommand(), 0);
        expect(requests, isEmpty);
        expect(errors, isEmpty);
      },
    );
  });
}
