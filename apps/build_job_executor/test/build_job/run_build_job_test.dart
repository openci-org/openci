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
    runner = RunBuildJob(
      apiService: mockApiService,
      orchardVmService: mockOrchardVmService,
    );
  });

  group('RunBuildJob', () {
    test(
      'executes dart run genuine_ci/<workflowFileName> with exit code 0 and returns SUCCESS',
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

        String? executedCommand;

        when(
          () => mockOrchardVmService.executeCommandStreaming(
            containerName: 'openci-vm-123',
            command: any(named: 'command'),
            onLog: any(named: 'onLog'),
            isCancelled: any(named: 'isCancelled'),
          ),
        ).thenAnswer((invocation) async {
          final cmdList = invocation.namedArguments[#command] as List<String>;
          executedCommand = cmdList.last;
          return 0;
        });

        final result = await runner(
          job: job,
          vmName: 'openci-vm-123',
          runId: 'run-456',
        );

        expect(result, equals(BuildJobStatus.SUCCESS));
        expect(executedCommand, contains('export GENUINE_CI_RUN_ID="run-456"'));
        expect(
          executedCommand,
          contains('export GENUINE_CI_BUILD_JOB_ID="job-123"'),
        );
        expect(
          executedCommand,
          contains('dart run genuine_ci/dashboard_ci.dart'),
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
