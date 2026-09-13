import 'dart:async';
import 'dart:convert';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCiApiService extends Mock implements OpenCiApiService {}

class _MockOrchardApiClient extends Mock implements OrchardApiClient {}

class _TrackingClient extends MockClient {
  _TrackingClient(super.handler);

  var closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  const config = Config(
    serverUrl: 'http://server:8080',
    internalApiKey: 'test-key',
    orchardServiceAccountName: 'test-account',
    orchardServiceAccountToken: 'test-token',
    baseVmName: 'test-macos-image',
    internalLokiUrl: 'http://worker-loki:3100',
    lokiUrl: 'http://vm-loki:3100',
  );
  const secretsContent = 'WORKER_TEST_SECRET=test-only-value';
  const token = 'test-only-github-token';
  final sourceStack = StackTrace.fromString('Execution failed here');
  late OpenCiApiService api;
  late OrchardApiClient orchardApi;
  late _TrackingClient lokiClient;
  late BuildJob job;
  late List<String> events;
  late List<String> runIds;
  late List<String> vmNames;
  late List<String> deletedVms;
  late List<(String, String)> commands;
  late Map<String, String> files;
  late Map<String, Map<String, dynamic>> completions;
  late List<(Object, StackTrace)> errors;
  late List<http.Request> logRequests;
  late List<String> vmLogs;
  late Map<String, Object> failures;
  late Map<String, Completer<void>> pending;
  late Future<http.Response> Function(http.Request) respondToLog;
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
    lokiClient: lokiClient,
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

  List<BuildStep> stepEvents(String stepId) => logRequests
      .map(_lokiStream)
      .where((stream) {
        final labels = stream['stream'] as Map<String, dynamic>;
        return labels['type'] == 'step_event' && labels['step_id'] == stepId;
      })
      .map((stream) {
        final values =
            (stream['values'] as List<dynamic>).single as List<dynamic>;
        return BuildStep.fromJson(
          jsonDecode(values[1] as String) as Map<String, dynamic>,
        );
      })
      .toList();

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
    logRequests = [];
    vmLogs = [];
    failures = {};
    pending = {};
    leaseId = 'lease-1';
    workflowExitCode = 0;
    respondToLog = (_) async => http.Response('', 204);
    lokiClient = _TrackingClient((request) {
      logRequests.add(request);
      final stream = _lokiStream(request);
      final labels = stream['stream'] as Map<String, dynamic>;
      if (labels['type'] == 'step_event') {
        final stepId = labels['step_id'] as String;
        events.add('$stepId:${stepEvents(stepId).last.status.name}');
      } else if (labels['type'] == 'step_log' &&
          labels['step_id'] == 'prepare_vm') {
        final values =
            (stream['values'] as List<dynamic>).single as List<dynamic>;
        vmLogs.add(values[1] as String);
      }
      return respondToLog(request);
    });
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
    expect(lokiClient.closed, isFalse);
    lokiClient.close();
  });

  group('executeBuildJob', () {
    test(
      'executes a claimed job, saves success and deletes its lease',
      () async {
        expect(await execute(), BuildJobStatus.SUCCESS);

        expect(events, [
          'createRun',
          'token',
          'prepare_vm:IN_PROGRESS',
          'createVm',
          'waitVm',
          'prepare_vm:SUCCESS',
          'checkout:IN_PROGRESS',
          'writeCheckout',
          'checkout',
          'checkout:SUCCESS',
          'secrets',
          'run_workflow:IN_PROGRESS',
          'writeSecrets',
          'writeWorkflow',
          'workflow',
          'run_workflow:SUCCESS',
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
        expect(files['writeWorkflow'], contains(config.lokiUrl));
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

        final steps = stepEvents('prepare_vm');
        expect(steps.map((step) => step.status), [
          BuildJobStatus.IN_PROGRESS,
          BuildJobStatus.SUCCESS,
        ]);
        for (final step in steps) {
          expect(step.id, 'prepare_vm');
          expect(step.runId, runIds.single);
          expect(step.name, 'Set up VM');
          expect(step.stepOrder, 0);
          expect(step.createdAt.isUtc, isTrue);
          expect(step.updatedAt.isUtc, isTrue);
        }
        expect(steps.first.durationMs, 0);
        expect(steps.last.durationMs, greaterThanOrEqualTo(0));
        expect(steps.last.createdAt, steps.first.createdAt);
        expect(steps.last.updatedAt.isBefore(steps.first.updatedAt), isFalse);

        expect(vmLogs, [
          'Creating VM from test-macos-image and waiting for it to start.',
          'VM is ready.',
        ]);
        verifyNever(() => api.appendStepLog(any(), any(), any(), any()));
        expect(logRequests, hasLength(10));
        for (final (index, step) in [
          'prepare_vm',
          'prepare_vm',
          'prepare_vm',
          'prepare_vm',
          'checkout',
          'checkout',
          'checkout',
          'run_workflow',
          'run_workflow',
          'run_workflow',
        ].indexed) {
          final request = logRequests[index];
          expect(
            request.url.toString(),
            '${config.internalLokiUrl}/loki/api/v1/push',
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final stream =
              (body['streams'] as List<dynamic>).single as Map<String, dynamic>;
          expect(stream['stream'], containsPair('run_id', runIds.single));
          expect(stream['stream'], containsPair('build_job_id', job.id));
          expect(stream['stream'], containsPair('step_id', step));
        }
      },
    );

    test(
      'reports progress during VM preparation and measures its duration',
      () async {
        final started = Completer<void>();
        final finish = Completer<void>();
        addTearDown(() {
          if (!finish.isCompleted) finish.complete();
        });
        when(
          () => orchardApi.waitForVmRunning(
            'lease-1',
            timeout: const Duration(minutes: 15),
          ),
        ).thenAnswer((_) async {
          started.complete();
          await finish.future;
          return OrchardLease(
            id: leaseId,
            vmName: vmNames.single,
            status: 'running',
          );
        });

        final result = execute();
        await started.future;
        expect(
          stepEvents('prepare_vm').single.status,
          BuildJobStatus.IN_PROGRESS,
        );
        expect(vmLogs, [
          'Creating VM from test-macos-image and waiting for it to start.',
        ]);
        expect(commands, isEmpty);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        finish.complete();

        expect(await result, BuildJobStatus.SUCCESS);
        expect(stepEvents('prepare_vm').last.status, BuildJobStatus.SUCCESS);
        expect(
          stepEvents('prepare_vm').last.durationMs,
          greaterThanOrEqualTo(10),
        );
      },
    );

    test('reports checkout progress and duration', () async {
      final started = Completer<void>();
      final finish = pending['checkout'] = Completer<void>();
      addTearDown(() {
        if (!finish.isCompleted) finish.complete();
      });
      respondToLog = (request) async {
        final labels = _lokiStream(request)['stream'] as Map<String, dynamic>;
        if (labels['type'] == 'step_log' && labels['step_id'] == 'checkout') {
          started.complete();
        }
        return http.Response('', 204);
      };

      final result = execute();
      await started.future;
      final inProgress = stepEvents('checkout').single;
      expect(inProgress.status, BuildJobStatus.IN_PROGRESS);
      expect(inProgress.id, 'checkout');
      expect(inProgress.runId, runIds.single);
      expect(inProgress.name, 'Checkout Repository');
      expect(inProgress.stepOrder, 1);
      expect(inProgress.durationMs, 0);
      expect(inProgress.createdAt.isUtc, isTrue);
      expect(inProgress.updatedAt, inProgress.createdAt);
      expect(events, isNot(contains('workflow')));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      finish.complete();

      expect(await result, BuildJobStatus.SUCCESS);
      final completed = stepEvents('checkout').last;
      expect(completed.status, BuildJobStatus.SUCCESS);
      expect(completed.createdAt, inProgress.createdAt);
      expect(completed.updatedAt.isBefore(inProgress.updatedAt), isFalse);
      expect(completed.durationMs, greaterThanOrEqualTo(10));
    });

    test('reports workflow progress and duration', () async {
      final started = Completer<void>();
      final finish = pending['workflow'] = Completer<void>();
      addTearDown(() {
        if (!finish.isCompleted) finish.complete();
      });
      respondToLog = (request) async {
        final labels = _lokiStream(request)['stream'] as Map<String, dynamic>;
        if (labels['type'] == 'step_log' &&
            labels['step_id'] == 'run_workflow') {
          started.complete();
        }
        return http.Response('', 204);
      };

      final result = execute();
      await started.future;
      final inProgress = stepEvents('run_workflow').single;
      expect(inProgress.status, BuildJobStatus.IN_PROGRESS);
      expect(inProgress.id, 'run_workflow');
      expect(inProgress.runId, runIds.single);
      expect(inProgress.name, 'Run workflow');
      expect(inProgress.stepOrder, 2);
      expect(inProgress.durationMs, 0);
      expect(inProgress.createdAt.isUtc, isTrue);
      expect(inProgress.updatedAt, inProgress.createdAt);
      expect(completions, isEmpty);
      expect(deletedVms, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      finish.complete();

      expect(await result, BuildJobStatus.SUCCESS);
      final completed = stepEvents('run_workflow').last;
      expect(completed.status, BuildJobStatus.SUCCESS);
      expect(completed.createdAt, inProgress.createdAt);
      expect(completed.updatedAt.isBefore(inProgress.updatedAt), isFalse);
      expect(completed.durationMs, greaterThanOrEqualTo(10));
    });

    test(
      'records a nonzero workflow exit code as failure and cleans up',
      () async {
        workflowExitCode = 23;

        expect(await execute(), BuildJobStatus.FAILURE);

        expectCompletion(BuildJobStatus.FAILURE);
        expect(stepEvents('checkout').last.status, BuildJobStatus.SUCCESS);
        expect(stepEvents('run_workflow').map((step) => step.status), [
          BuildJobStatus.IN_PROGRESS,
          BuildJobStatus.FAILURE,
        ]);
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
        expect(logRequests, isEmpty);
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
        expect(stepEvents('prepare_vm').map((step) => step.status), [
          if (!['createRun', 'token'].contains(stage)) ...[
            BuildJobStatus.IN_PROGRESS,
            ['createVm', 'waitVm'].contains(stage)
                ? BuildJobStatus.FAILURE
                : BuildJobStatus.SUCCESS,
          ],
        ]);
        expect(vmLogs, [
          if (!['createRun', 'token'].contains(stage)) ...[
            'Creating VM from test-macos-image and waiting for it to start.',
            ['createVm', 'waitVm'].contains(stage)
                ? 'VM setup failed.'
                : 'VM is ready.',
          ],
        ]);
        expect(stepEvents('checkout').map((step) => step.status), [
          if (![
            'createRun',
            'token',
            'createVm',
            'waitVm',
          ].contains(stage)) ...[
            BuildJobStatus.IN_PROGRESS,
            ['writeCheckout', 'checkout'].contains(stage)
                ? BuildJobStatus.FAILURE
                : BuildJobStatus.SUCCESS,
          ],
        ]);
        expect(stepEvents('run_workflow').map((step) => step.status), [
          if ([
            'writeSecrets',
            'writeWorkflow',
            'workflow',
          ].contains(stage)) ...[
            BuildJobStatus.IN_PROGRESS,
            BuildJobStatus.FAILURE,
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

    test('reports VM log failures without failing the workflow', () async {
      respondToLog = (request) async {
        final labels = _lokiStream(request)['stream'] as Map<String, dynamic>;
        return http.Response(
          '',
          labels['type'] == 'step_log' && labels['step_id'] == 'prepare_vm'
              ? 503
              : 204,
        );
      };

      expect(await execute(), BuildJobStatus.SUCCESS);

      expectCompletion(BuildJobStatus.SUCCESS);
      expect(errors, hasLength(2));
      expect(
        errors.map((entry) => entry.$1.toString()),
        everyElement(contains('HTTP 503')),
      );
      expect(deletedVms, ['lease-1']);
    });

    test('reports Loki failures without failing the workflow', () async {
      respondToLog = (_) async => http.Response('', 503);

      expect(await execute(), BuildJobStatus.SUCCESS);

      expectCompletion(BuildJobStatus.SUCCESS);
      expect(errors, hasLength(10));
      expect(deletedVms, ['lease-1']);
    });

    test('preserves VM failure when progress delivery also fails', () async {
      final vmError = failures['waitVm'] = StateError('VM failed');
      respondToLog = (_) async => http.Response('', 503);

      expect(await execute(), BuildJobStatus.FAILURE);

      expectCompletion(BuildJobStatus.FAILURE);
      expect(stepEvents('prepare_vm').last.status, BuildJobStatus.FAILURE);
      expect(errors, hasLength(5));
      expect(errors.last.$1, same(vmError));
      expect(errors.last.$2.toString(), sourceStack.toString());
      expect(deletedVms, ['lease-1']);
    });

    test('preserves checkout failure when progress delivery fails', () async {
      final checkoutError = failures['checkout'] = StateError(
        'Checkout failed',
      );
      respondToLog = (request) async {
        final labels = _lokiStream(request)['stream'] as Map<String, dynamic>;
        return http.Response(
          '',
          labels['type'] == 'step_event' && labels['step_id'] == 'checkout'
              ? 503
              : 204,
        );
      };

      expect(await execute(), BuildJobStatus.FAILURE);

      expectCompletion(BuildJobStatus.FAILURE);
      expect(stepEvents('checkout').last.status, BuildJobStatus.FAILURE);
      expect(events, isNot(contains('workflow')));
      expect(errors, hasLength(3));
      expect(errors.last.$1, same(checkoutError));
      expect(errors.last.$2.toString(), sourceStack.toString());
      expect(deletedVms, ['lease-1']);
    });

    test('preserves workflow failure when progress delivery fails', () async {
      final workflowError = failures['workflow'] = StateError(
        'Workflow failed',
      );
      respondToLog = (request) async {
        final labels = _lokiStream(request)['stream'] as Map<String, dynamic>;
        return http.Response(
          '',
          labels['type'] == 'step_event' && labels['step_id'] == 'run_workflow'
              ? 503
              : 204,
        );
      };

      expect(await execute(), BuildJobStatus.FAILURE);

      expectCompletion(BuildJobStatus.FAILURE);
      expect(stepEvents('run_workflow').last.status, BuildJobStatus.FAILURE);
      expect(errors, hasLength(3));
      expect(errors.last.$1, same(workflowError));
      expect(errors.last.$2.toString(), sourceStack.toString());
      expect(deletedVms, ['lease-1']);
    });

    for (final (stepId, type) in [
      ('prepare_vm', 'step_event'),
      ('prepare_vm', 'step_log'),
      ('checkout', 'step_event'),
      ('run_workflow', 'step_event'),
    ]) {
      test('continues after $stepId $type delivery times out', () async {
        final response = Completer<http.Response>();
        respondToLog = (request) {
          final labels = _lokiStream(request)['stream'] as Map<String, dynamic>;
          if (labels['type'] == type &&
              labels['step_id'] == stepId &&
              stepEvents(stepId).last.status == BuildJobStatus.IN_PROGRESS) {
            return response.future;
          }
          return Future.value(http.Response('', 204));
        };

        expect(await execute(), BuildJobStatus.SUCCESS);

        expectCompletion(BuildJobStatus.SUCCESS);
        expect(deletedVms, ['lease-1']);
        expect(errors.single.$1, isA<TimeoutException>());
        expect(stepEvents(stepId).last.status, BuildJobStatus.SUCCESS);
        response.completeError(StateError('Late progress failure'));
        await Future<void>.delayed(Duration.zero);
        expect(errors, hasLength(1));
      });
    }

    test(
      'waits for workflow log delivery before finalizing and deleting the VM',
      () async {
        final started = Completer<void>();
        final response = Completer<http.Response>();
        respondToLog = (request) {
          final labels = _lokiStream(request)['stream'] as Map<String, dynamic>;
          if (labels['type'] != 'step_log' ||
              labels['step_id'] != 'run_workflow') {
            return Future.value(http.Response('', 204));
          }
          started.complete();
          return response.future;
        };

        final result = execute();
        await started.future;

        expect(completions, isEmpty);
        expect(deletedVms, isEmpty);
        response.complete(http.Response('', 204));
        expect(await result, BuildJobStatus.SUCCESS);
        expect(deletedVms, ['lease-1']);
      },
    );

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

Map<String, dynamic> _lokiStream(http.Request request) {
  final body = jsonDecode(request.body) as Map<String, dynamic>;
  return (body['streams'] as List<dynamic>).single as Map<String, dynamic>;
}
