import 'dart:async';
import 'dart:convert';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCiApiService extends Mock implements OpenCiApiService {}

class _MockOrchardApiClient extends Mock implements OrchardApiClient {}

void main() {
  const config = Config(
    serverUrl: 'http://server:8080',
    internalApiKey: 'test-key',
    orchardServiceAccountName: 'test-account',
    orchardServiceAccountToken: 'test-token',
    baseVmName: 'test-macos-image',
  );
  const secretsContent = 'WORKER_TEST_SECRET=test-only-value';
  const token = 'test-only-github-token';
  final sourceStack = StackTrace.fromString('Execution failed here');
  late OpenCiApiService api;
  late OrchardApiClient orchardApi;
  late BuildJob job;
  late List<String> events;
  late List<String> runIds;
  late List<String> vmNames;
  late List<String> deletedVms;
  late List<(String, String)> commands;
  late Map<String, String> files;
  late Map<String, Map<String, dynamic>> completions;
  late List<(Object, StackTrace)> errors;
  late List<String> apiLogs;
  late Map<String, Object> failures;
  late Map<String, Completer<void>> pending;
  var leaseId = 'lease-1';
  var workflowExitCode = 0;

  Future<void> record(String stage) async {
    events.add(stage);
    final wait = pending[stage];
    if (wait != null) await wait.future;
    final error = failures[stage];
    if (error != null) Error.throwWithStackTrace(error, sourceStack);
  }

  Future<BuildJobStatus> execute({
    Duration finalizationTimeout = const Duration(seconds: 10),
    void Function(Object, StackTrace)? onError,
  }) => executeBuildJob(
    api: api,
    orchardApi: orchardApi,
    config: config,
    job: job,
    finalizationTimeout: finalizationTimeout,
    onError: onError ?? (error, stack) => errors.add((error, stack)),
  );

  void expectCompletion(BuildJobStatus status, {bool hasRun = true}) {
    final payload = {
      'status': 'completed',
      'conclusion': status.name.toLowerCase(),
    };
    expect(completions['completeRun'], hasRun ? payload : isNull);
    expect(completions['completeCheck'], payload);
    final jobCompletion = completions['completeJob']!;
    expect(jobCompletion['status'], status.name);
    expect(
      DateTime.parse(jobCompletion['completedAt'] as String).isUtc,
      isTrue,
    );
  }

  setUpAll(() {
    registerFallbackValue((String line, String stream) {});
  });

  setUp(() {
    api = _MockOpenCiApiService();
    orchardApi = _MockOrchardApiClient();
    events = [];
    runIds = [];
    vmNames = [];
    deletedVms = [];
    commands = [];
    files = {};
    completions = {};
    errors = [];
    apiLogs = [];
    failures = {};
    pending = {};
    leaseId = 'lease-1';
    workflowExitCode = 0;
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

    when(() => api.createRun(job.id, any())).thenAnswer((invocation) async {
      final body = invocation.positionalArguments[1] as Map<String, dynamic>;
      runIds.add(body['id'] as String);
      await record('createRun');
      return createMockResponse<void>(null);
    });
    when(
      () => api.appendStepLog(job.id, any(), 'prepare_vm', any()),
    ).thenAnswer((invocation) async {
      expect(invocation.positionalArguments[1], runIds.single);
      final body = invocation.positionalArguments[3] as Map<String, dynamic>;
      final entry =
          (body['logs'] as List<dynamic>).single as Map<String, dynamic>;
      apiLogs.add(entry['message'] as String);
      return createMockResponse<void>(null);
    });
    when(() => api.resolveInstallationToken(job.id)).thenAnswer((_) async {
      await record('token');
      return createMockResponse({'token': token});
    });
    when(
      () => orchardApi.createLease(
        imageName: config.baseVmName,
        vmName: any(named: 'vmName'),
      ),
    ).thenAnswer((invocation) async {
      vmNames.add(invocation.namedArguments[#vmName] as String);
      await record('createVm');
      return OrchardLease(id: leaseId, vmName: vmNames.last, status: 'pending');
    });
    when(
      () => orchardApi.waitForVmRunning(
        any(),
        timeout: const Duration(minutes: 15),
      ),
    ).thenAnswer((_) async {
      await record('waitVm');
      return OrchardLease(id: leaseId, vmName: vmNames.last, status: 'running');
    });
    when(
      () => orchardApi.execCommandWebSocket(
        vmName: any(named: 'vmName'),
        command: any(named: 'command'),
        onLog: any(named: 'onLog'),
      ),
    ).thenAnswer((invocation) async {
      final vmName = invocation.namedArguments[#vmName] as String;
      final command = invocation.namedArguments[#command] as String;
      final onLog =
          invocation.namedArguments[#onLog] as void Function(String, String);
      commands.add((vmName, command));
      final isCheckout = command.contains('workspace.checkout.sh');
      final String stage;
      if (command.startsWith('/bin/sh ')) {
        stage = isCheckout ? 'checkout' : 'workflow';
        onLog('$stage output', isCheckout ? 'stdout' : 'stderr');
      } else {
        stage = isCheckout
            ? 'writeCheckout'
            : command.contains('workspace.workflow.sh')
            ? 'writeWorkflow'
            : 'writeSecrets';
        final encoded = RegExp(
          r"printf %s '([^']*)'",
        ).firstMatch(command)!.group(1)!;
        files[stage] = utf8.decode(base64Decode(encoded));
      }
      await record(stage);
      return stage == 'workflow' ? workflowExitCode : 0;
    });
    when(() => api.getJobSecrets(job.id)).thenAnswer((_) async {
      await record('secrets');
      return createMockResponse({
        'success': true,
        'secretsContent': secretsContent,
      });
    });
    when(() => api.updateRunStatus(job.id, any(), any())).thenAnswer((
      invocation,
    ) async {
      completions['completeRun'] =
          invocation.positionalArguments[2] as Map<String, dynamic>;
      await record('completeRun');
      return createMockResponse<void>(null);
    });
    when(() => api.completeJob(job.id, any())).thenAnswer((invocation) async {
      completions['completeJob'] =
          invocation.positionalArguments[1] as Map<String, dynamic>;
      await record('completeJob');
      return createMockResponse<void>(null);
    });
    when(() => api.updateCheckRun(job.id, any())).thenAnswer((
      invocation,
    ) async {
      completions['completeCheck'] =
          invocation.positionalArguments[1] as Map<String, dynamic>;
      await record('completeCheck');
      return createMockResponse<void>(null);
    });
    when(() => orchardApi.deleteLease(any())).thenAnswer((invocation) async {
      deletedVms.add(invocation.positionalArguments.single as String);
      await record('deleteVm');
    });
  });

  tearDown(() {
    verifyNever(orchardApi.close);
    verifyNever(() => api.claimNextJob(any()));
    verifyNever(() => api.handleBuildJobStatusChange(any(), any()));
  });

  group('executeBuildJob', () {
    test(
      'executes a claimed job, saves success and deletes its lease',
      () async {
        expect(await execute(), BuildJobStatus.SUCCESS);

        expect(events, [
          'createRun',
          'token',
          'createVm',
          'waitVm',
          'writeCheckout',
          'checkout',
          'secrets',
          'writeSecrets',
          'writeWorkflow',
          'workflow',
          'completeRun',
          'completeJob',
          'completeCheck',
          'deleteVm',
        ]);
        expect(runIds.single, isNotEmpty);
        expect(vmNames.single, matches(RegExp(r'^[a-z0-9-]+$')));
        expect(commands.map((entry) => entry.$1), everyElement(vmNames.single));
        expect(files['writeCheckout'], contains('abc123'));
        expect(
          files['writeCheckout'],
          contains(base64Encode(utf8.encode('x-access-token:$token'))),
        );
        expect(files['writeSecrets'], secretsContent);
        expect(files['writeWorkflow'], contains(secretsContent));
        expect(files['writeWorkflow'], contains(runIds.single));
        expect(files['writeWorkflow'], contains(job.id));
        expect(files['writeWorkflow'], contains('genuine_ci/ci.dart'));
        expectCompletion(BuildJobStatus.SUCCESS);
        verify(
          () => api.updateRunStatus(job.id, runIds.single, any()),
        ).called(1);
        verify(
          () => orchardApi.waitForVmRunning(
            'lease-1',
            timeout: const Duration(minutes: 15),
          ),
        ).called(1);
        expect(deletedVms, ['lease-1']);
        expect(errors, isEmpty);

        expect(apiLogs, [
          'Creating VM from test-macos-image and waiting for it to start.',
          'VM is ready.',
        ]);
      },
    );

    test(
      'records a nonzero workflow exit code as failure and cleans up',
      () async {
        workflowExitCode = 23;

        expect(await execute(), BuildJobStatus.FAILURE);

        expectCompletion(BuildJobStatus.FAILURE);
        expect(deletedVms, ['lease-1']);
        expect(errors, isEmpty);
      },
    );

    test('generates a new run and VM name for each execution', () async {
      await execute();
      await execute();

      expect(runIds.toSet(), hasLength(2));
      expect(vmNames.toSet(), hasLength(2));
    });

    for (final status in BuildJobStatus.values.where(
      (status) => status != BuildJobStatus.IN_PROGRESS,
    )) {
      test('rejects ${status.name} without contacting any service', () async {
        job = job.copyWith(status: status);

        await expectLater(execute(), throwsArgumentError);

        verifyZeroInteractions(api);
        verifyZeroInteractions(orchardApi);
      });
    }

    for (final timeout in [Duration.zero, const Duration(seconds: -1)]) {
      test('rejects a nonpositive finalization timeout: $timeout', () async {
        await expectLater(
          execute(finalizationTimeout: timeout),
          throwsArgumentError,
        );

        verifyZeroInteractions(api);
        verifyZeroInteractions(orchardApi);
      });
    }

    for (final stage in [
      'createRun',
      'token',
      'createVm',
      'waitVm',
      'writeCheckout',
      'checkout',
      'secrets',
      'writeSecrets',
      'writeWorkflow',
      'workflow',
    ]) {
      test('finalizes failure and cleans up after $stage fails', () async {
        failures[stage] = StateError('$stage failed');

        expect(await execute(), BuildJobStatus.FAILURE);

        expectCompletion(BuildJobStatus.FAILURE, hasRun: stage != 'createRun');
        expect(apiLogs, [
          if (!['createRun', 'token'].contains(stage)) ...[
            'Creating VM from test-macos-image and waiting for it to start.',
            ['createVm', 'waitVm'].contains(stage)
                ? 'VM setup failed.'
                : 'VM is ready.',
          ],
        ]);
        expect(errors, hasLength(1));
        expect(errors.single.$2.toString(), sourceStack.toString());
        expect(events.where((event) => event == stage), hasLength(1));
        if (['createRun', 'token', 'createVm'].contains(stage)) {
          expect(deletedVms, isEmpty);
          verifyNever(
            () => orchardApi.execCommandWebSocket(
              vmName: any(named: 'vmName'),
              command: any(named: 'command'),
              onLog: any(named: 'onLog'),
            ),
          );
        } else {
          expect(deletedVms, ['lease-1']);
        }
        if (stage != 'workflow') expect(events, isNot(contains('workflow')));
        if (stage == 'createRun') expect(events, isNot(contains('token')));
        if (stage == 'token') expect(events, isNot(contains('createVm')));
        if (stage == 'waitVm') {
          expect(
            events.indexOf('deleteVm'),
            lessThan(events.indexOf('completeRun')),
          );
        }
      });
    }

    test(
      'uses the requested VM name for cleanup when the lease has no ID',
      () async {
        leaseId = '';

        expect(await execute(), BuildJobStatus.SUCCESS);

        expect(deletedVms, vmNames);
        verify(
          () => orchardApi.waitForVmRunning(
            vmNames.single,
            timeout: const Duration(minutes: 15),
          ),
        ).called(1);
      },
    );

    for (final stage in [
      'completeRun',
      'completeJob',
      'completeCheck',
      'deleteVm',
    ]) {
      test(
        'reports $stage failure and attempts all remaining finalizers',
        () async {
          failures[stage] = StateError('$stage failed');

          expect(await execute(), BuildJobStatus.SUCCESS);

          expectCompletion(BuildJobStatus.SUCCESS);
          expect(events.sublist(events.length - 4), [
            'completeRun',
            'completeJob',
            'completeCheck',
            'deleteVm',
          ]);
          expect(deletedVms, ['lease-1']);
          expect(errors, hasLength(1));
          expect(errors.single.$2.toString(), sourceStack.toString());
        },
      );
    }

    test(
      'does not lose execution errors when completion and cleanup also fail',
      () async {
        for (final stage in [
          'workflow',
          'completeRun',
          'completeJob',
          'completeCheck',
          'deleteVm',
        ]) {
          failures[stage] = StateError('$stage failed');
        }

        expect(await execute(), BuildJobStatus.FAILURE);

        expectCompletion(BuildJobStatus.FAILURE);
        expect(errors, hasLength(5));
        expect(errors.first.$1, same(failures['workflow']));
        expect(errors.last.$1, same(failures['deleteVm']));
        expect(deletedVms, ['lease-1']);
      },
    );

    test(
      'handles an unsuccessful completion response without skipping VM cleanup',
      () async {
        when(() => api.completeJob(job.id, any())).thenAnswer((_) async {
          await record('completeJob');
          return createMockResponse<void>(null, statusCode: 503);
        });

        expect(await execute(), BuildJobStatus.SUCCESS);

        expect(errors.single.$1.toString(), contains('HTTP 503'));
        expect(events, contains('completeCheck'));
        expect(deletedVms, ['lease-1']);
      },
    );

    for (final stage in ['completeRun', 'deleteVm']) {
      test('limits waiting for $stage and handles a late failure', () async {
        final wait = pending[stage] = Completer<void>();

        expect(
          await execute(finalizationTimeout: const Duration(milliseconds: 20)),
          BuildJobStatus.SUCCESS,
        );

        expectCompletion(BuildJobStatus.SUCCESS);
        expect(deletedVms, ['lease-1']);
        expect(errors.single.$1, isA<TimeoutException>());
        wait.completeError(StateError('Late failure'));
        await Future<void>.delayed(Duration.zero);
        expect(errors, hasLength(1));
      });
    }

    test('reports API log failures without failing the workflow', () async {
      when(
        () => api.appendStepLog(job.id, any(), 'prepare_vm', any()),
      ).thenAnswer(
        (_) async => createMockResponse<void>(null, statusCode: 503),
      );

      expect(await execute(), BuildJobStatus.SUCCESS);

      expectCompletion(BuildJobStatus.SUCCESS);
      expect(errors, hasLength(2));
      expect(
        errors.map((entry) => entry.$1.toString()),
        everyElement(contains('HTTP 503')),
      );
      expect(deletedVms, ['lease-1']);
    });

    test('continues after API log delivery times out', () async {
      final response = Completer<void>();
      var calls = 0;
      when(
        () => api.appendStepLog(job.id, any(), 'prepare_vm', any()),
      ).thenAnswer((_) async {
        if (++calls == 1) await response.future;
        return createMockResponse<void>(null);
      });

      expect(await execute(), BuildJobStatus.SUCCESS);
      expectCompletion(BuildJobStatus.SUCCESS);
      expect(deletedVms, ['lease-1']);
      expect(errors.single.$1, isA<TimeoutException>());
      response.completeError(StateError('Late delivery failure'));
      await Future<void>.delayed(Duration.zero);
      expect(errors, hasLength(1));
    });

    test(
      'finishes cleanup before invoking an error reporter that throws',
      () async {
        failures['workflow'] = StateError('Workflow failed');
        final reporterError = StateError('Reporter failed');

        await expectLater(
          execute(onError: (_, _) => throw reporterError),
          throwsA(same(reporterError)),
        );

        expectCompletion(BuildJobStatus.FAILURE);
        expect(deletedVms, ['lease-1']);
      },
    );
  });
}
