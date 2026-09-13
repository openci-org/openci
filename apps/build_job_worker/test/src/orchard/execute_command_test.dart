import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockOrchardApiClient extends Mock implements OrchardApiClient {}

void main() {
  late OrchardApiClient api;

  setUpAll(() => registerFallbackValue((String line, String stream) {}));
  setUp(() => api = _MockOrchardApiClient());

  Future<int> run() => executeCommand(
    api: api,
    vmName: 'vm-1',
    command: 'build',
    waitSeconds: 123,
  );

  for (final exitCode in [0, 23]) {
    test(
      'returns command exit code $exitCode despite command output',
      () async {
        when(
          () => api.execCommandWebSocket(
            vmName: 'vm-1',
            command: 'build',
            waitSeconds: 123,
            onLog: any(named: 'onLog'),
          ),
        ).thenAnswer((invocation) async {
          final onLog =
              invocation.namedArguments[#onLog]
                  as void Function(String, String);
          onLog('output', 'stdout');
          onLog('error output', 'stderr');
          return exitCode;
        });

        expect(await run(), exitCode);
        verifyNever(api.close);
      },
    );
  }

  test('propagates an Orchard execution failure', () async {
    final error = StateError('Connection closed before exit');
    when(
      () => api.execCommandWebSocket(
        vmName: 'vm-1',
        command: 'build',
        waitSeconds: 123,
        onLog: any(named: 'onLog'),
      ),
    ).thenThrow(error);

    await expectLater(run(), throwsA(same(error)));
    verifyNever(api.close);
  });
}
