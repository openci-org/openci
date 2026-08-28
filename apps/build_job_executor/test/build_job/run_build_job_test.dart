import 'package:mocktail/mocktail.dart';
import 'package:build_job_executor/src/build_job/run_build_job.dart';
import 'package:build_job_executor/src/orchard/orchard_vm_service.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class MockOpenCiApiService extends Mock implements OpenCiApiService {}

class MockOrchardVmService extends Mock implements OrchardVmService {}

void main() {
  late MockOpenCiApiService mockApiService;
  late MockOrchardVmService mockOrchardVmService;
  late RunBuildJob runner;

  setUp(() {
    mockApiService = MockOpenCiApiService();
    mockOrchardVmService = MockOrchardVmService();
    when(
      () => mockOrchardVmService.writeFile(
        any(),
        any(),
        any(),
        mode: any(named: 'mode'),
      ),
    ).thenAnswer((_) async {});
    runner = RunBuildJob(
      apiService: mockApiService,
      orchardVmService: mockOrchardVmService,
    );
  });

  group('RunBuildJob', () {
    test(
      'executes flutter pub run genuine_ci/<workflowFileName> with exit code 0 and returns SUCCESS',
      () async {
        final now = DateTime.now();
        final job = BuildJob(
          id: 'job-123',
          status: BuildJobStatus.QUEUED,
          owner: 'openci-org',
          repo: 'openci',
          workflowName: 'Dashboard CI',
          workflowFileName: 'dashboard_ci.dart',
          createdAt: now,
          updatedAt: now,
        );

        String? writtenScript;

        when(
          () => mockOrchardVmService.writeFile(
            'openci-vm-123',
            '/tmp/run_workflow.sh',
            any(),
            mode: '+x',
          ),
        ).thenAnswer((invocation) async {
          writtenScript = invocation.positionalArguments[2] as String;
        });

        when(
          () => mockOrchardVmService.executeCommandStreaming(
            containerName: 'openci-vm-123',
            command: any(named: 'command'),
            onLog: any(named: 'onLog'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenAnswer((_) async => 0);

        final result = await runner(
          job: job,
          vmName: 'openci-vm-123',
          runId: 'run-456',
        );

        expect(result, equals(BuildJobStatus.SUCCESS));
        expect(writtenScript, contains('export GENUINE_CI_RUN_ID="run-456"'));
        expect(
          writtenScript,
          contains('export GENUINE_CI_BUILD_JOB_ID="job-123"'),
        );
        expect(
          writtenScript,
          contains('export FLUTTER_ROOT="/Users/admin/fvm/default"'),
        );
        expect(
          writtenScript,
          contains('export PATH="/Users/admin/fvm/default/bin:'),
        );
        expect(
          writtenScript,
          contains('flutter pub get'),
        );
        expect(
          writtenScript,
          contains('flutter pub run genuine_ci/dashboard_ci.dart'),
        );
      },
    );

    test('returns FAILURE when exit code is non-zero', () async {
      final now = DateTime.now();
      final job = BuildJob(
        id: 'job-123',
        status: BuildJobStatus.QUEUED,
        owner: 'openci-org',
        repo: 'openci',
        workflowName: 'Dashboard CI',
        workflowFileName: 'dashboard_ci.dart',
        createdAt: now,
        updatedAt: now,
      );

      when(
        () => mockOrchardVmService.executeCommandStreaming(
          containerName: any(named: 'containerName'),
          command: any(named: 'command'),
          onLog: any(named: 'onLog'),
          isCancelled: any(named: 'isCancelled'),
        ),
      ).thenAnswer((_) async => 1);

      final result = await runner(job: job, vmName: 'openci-vm-123');

      expect(result, equals(BuildJobStatus.FAILURE));
    });
  });
}
