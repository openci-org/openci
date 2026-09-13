import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class _MockOrchardApiClient extends Mock implements OrchardApiClient {}

void main() {
  late OrchardApiClient api;
  late BuildJob job;
  late List<String> commands;
  var writeExitCode = 0;
  var checkoutExitCode = 0;
  Object? checkoutError;

  Future<void> checkout({
    String token = 'test-only-token',
    String workspacePath = '/tmp/workspace',
  }) => checkoutRepository(
    api: api,
    vmName: 'vm-1',
    job: job,
    token: token,
    workspacePath: workspacePath,
  );

  setUpAll(() => registerFallbackValue((String line, String stream) {}));

  setUp(() {
    api = _MockOrchardApiClient();
    commands = [];
    writeExitCode = 0;
    checkoutExitCode = 0;
    checkoutError = null;
    final now = DateTime.utc(2026, 9, 7);
    job = BuildJob(
      id: 'job-1',
      status: BuildJobStatus.IN_PROGRESS,
      owner: 'acme',
      repo: 'app',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      commitSha: 'abc123',
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
      if (commands.length == 1) {
        onLog('private setup output', 'stdout');
        return writeExitCode;
      }
      onLog('fetching', 'stdout');
      onLog('checkout result', 'stderr');
      if (checkoutError != null) throw checkoutError!;
      return checkoutExitCode;
    });
  });

  tearDown(() {
    verifyNever(api.close);
  });

  group('checkoutRepository', () {
    test('executes checkout after writing the script', () async {
      await checkout();
      expect(commands, hasLength(2));
    });

    test('does not execute checkout if script writing fails', () async {
      writeExitCode = 1;

      await expectLater(checkout(), throwsStateError);

      expect(commands, hasLength(1));
    });

    test('reports the checkout exit code', () async {
      checkoutExitCode = 128;

      await expectLater(
        checkout(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Git checkout failed with exit code 128.',
          ),
        ),
      );
    });

    test('propagates execution errors', () async {
      checkoutError = StateError('Orchard connection closed before exit');

      await expectLater(checkout(), throwsA(same(checkoutError)));
    });

    test('rejects an empty token before contacting Orchard', () async {
      await expectLater(checkout(token: ''), throwsArgumentError);
      verifyZeroInteractions(api);
    });

    for (final baseUrl in [
      'file:///tmp/repo',
      'https:///repo',
      'https://user:password@github.com',
      'https://github.com?query=1',
      'https://github.com#fragment',
    ]) {
      test('rejects invalid repository base URL $baseUrl', () async {
        job = job.copyWith(githubBaseUrl: baseUrl);

        await expectLater(checkout(), throwsArgumentError);

        verifyZeroInteractions(api);
      });
    }

    for (final path in ['relative/path', '/', '/tmp/work\u0000space']) {
      test('rejects an invalid workspace path', () async {
        await expectLater(checkout(workspacePath: path), throwsArgumentError);
        verifyZeroInteractions(api);
      });
    }

    test('rejects a ref containing NUL before contacting Orchard', () async {
      job = job.copyWith(commitSha: 'abc\u0000123');

      await expectLater(checkout(), throwsArgumentError);

      verifyZeroInteractions(api);
    });
  });
}
