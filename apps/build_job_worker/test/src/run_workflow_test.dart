import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class _MockOrchardApiClient extends Mock implements OrchardApiClient {}

void main() {
  late OrchardApiClient api;
  late BuildJob job;
  late List<String> commands;
  int? failedWrite;
  var workflowExitCode = 0;
  Object? executionError;

  Future<int> run({
    String secretsContent = 'WORKER_TEST_SECRET=test-only-value',
    String workspacePath = '/tmp/workspace',
    String vmHomePath = '/Users/admin',
    String runId = 'run-1',
  }) => runWorkflow(
    api: api,
    vmName: 'vm-1',
    job: job,
    runId: runId,
    secretsContent: secretsContent,
    workspacePath: workspacePath,
    vmHomePath: vmHomePath,
  );

  setUpAll(() => registerFallbackValue((String line, String stream) {}));

  setUp(() {
    api = _MockOrchardApiClient();
    commands = [];
    failedWrite = null;
    workflowExitCode = 0;
    executionError = null;
    final now = DateTime.utc(2026, 9, 7);
    job = BuildJob(
      id: 'job-1',
      status: BuildJobStatus.IN_PROGRESS,
      owner: 'acme',
      repo: 'app',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      createdAt: now,
      updatedAt: now,
    );
    when(
      () => api.execCommandWebSocket(
        vmName: 'vm-1',
        command: any(named: 'command'),
        onLog: any(named: 'onLog'),
      ),
    ).thenAnswer((invocation) async {
      commands.add(invocation.namedArguments[#command] as String);
      final onLog =
          invocation.namedArguments[#onLog] as void Function(String, String);
      if (commands.length <= 2) {
        onLog('WORKER_TEST_SECRET=test-only-value', 'stdout');
        return commands.length == failedWrite ? 1 : 0;
      }
      onLog('workflow output', 'stdout');
      onLog('workflow error output', 'stderr');
      if (executionError != null) throw executionError!;
      return workflowExitCode;
    });
  });

  tearDown(() {
    verifyNever(api.close);
  });

  group('runWorkflow', () {
    for (final exitCode in [0, 23]) {
      test('returns exit code $exitCode', () async {
        workflowExitCode = exitCode;

        expect(await run(), exitCode);

        expect(commands, hasLength(3));
      });
    }

    for (final writeNumber in [1, 2]) {
      test(
        'stops before execution when file write $writeNumber fails',
        () async {
          failedWrite = writeNumber;

          await expectLater(run(), throwsStateError);

          expect(commands, hasLength(writeNumber));
        },
      );
    }

    test('propagates execution errors', () async {
      executionError = StateError('Orchard connection closed before exit');

      await expectLater(run(), throwsA(same(executionError)));
    });

    for (final invalidSecrets in [
      'test-only-value',
      'BAD-KEY=test-only-value',
      'KEY=test-only-value\nnot-an-assignment',
      'KEY=test-only-value\u0000',
    ]) {
      test('rejects invalid secrets without exposing their content', () async {
        await expectLater(
          run(secretsContent: invalidSecrets),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.toString(),
              'message',
              isNot(contains('test-only-value')),
            ),
          ),
        );

        verifyZeroInteractions(api);
      });
    }

    for (final name in ['', '../ci.dart', '/ci.dart', 'ci\u0000.dart']) {
      test(
        'rejects an invalid workflow path before contacting Orchard',
        () async {
          job = job.copyWith(workflowFileName: name);

          await expectLater(run(), throwsArgumentError);

          verifyZeroInteractions(api);
        },
      );
    }

    test('rejects invalid VM paths before contacting Orchard', () async {
      await expectLater(run(workspacePath: '/'), throwsArgumentError);
      await expectLater(run(vmHomePath: 'relative'), throwsArgumentError);
      await expectLater(
        run(workspacePath: '/tmp/work\u0000space'),
        throwsArgumentError,
      );
      verifyZeroInteractions(api);
    });

    test('rejects invalid run IDs before contacting Orchard', () async {
      await expectLater(run(runId: ''), throwsArgumentError);
      await expectLater(run(runId: 'run\u0000id'), throwsArgumentError);
      verifyZeroInteractions(api);
    });
  });
}
