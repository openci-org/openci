import 'dart:async';
import 'dart:io';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockOrchardApiClient extends Mock implements OrchardApiClient {}

void main() {
  const createdLease = OrchardLease(
    id: 'lease-1',
    vmName: 'vm-1',
    status: 'pending',
  );
  const runningLease = OrchardLease(
    id: 'lease-1',
    vmName: 'vm-1',
    status: 'running',
    ipAddress: '100.64.0.1',
  );
  const startupTimeout = Duration(minutes: 15);
  late OrchardApiClient api;

  setUp(() {
    api = _MockOrchardApiClient();
    when(
      () => api.createLease(imageName: 'base-macos', vmName: 'vm-1'),
    ).thenAnswer((_) async => createdLease);
    when(
      () => api.waitForVmRunning('lease-1', timeout: startupTimeout),
    ).thenAnswer((_) async => runningLease);
    when(
      () => api.execCommandWebSocket(
        vmName: 'lease-1',
        command: 'true',
        onLog: any(named: 'onLog'),
        waitSeconds: any(named: 'waitSeconds'),
      ),
    ).thenAnswer((_) async => 0);
    when(() => api.deleteLease(any())).thenAnswer((_) async {});
  });

  group('prepareVm', () {
    test('does not return a running VM until SSH commands succeed', () async {
      final sshReady = Completer<int>();
      when(
        () => api.execCommandWebSocket(
          vmName: 'lease-1',
          command: 'true',
          onLog: any(named: 'onLog'),
          waitSeconds: any(named: 'waitSeconds'),
        ),
      ).thenAnswer((_) => sshReady.future);
      var completed = false;
      final preparing =
          prepareVm(api: api, baseVmName: 'base-macos', vmName: 'vm-1').then((
            lease,
          ) {
            completed = true;
            return lease;
          });

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      sshReady.complete(0);
      expect(await preparing, same(runningLease));
    });

    test('retries an unavailable SSH connection during VM startup', () async {
      var attempts = 0;
      when(
        () => api.execCommandWebSocket(
          vmName: 'lease-1',
          command: 'true',
          onLog: any(named: 'onLog'),
          waitSeconds: any(named: 'waitSeconds'),
        ),
      ).thenAnswer((_) async {
        if (attempts++ == 0) {
          throw const WebSocketException('SSH is not ready', 503);
        }
        return 0;
      });

      expect(
        await prepareVm(api: api, baseVmName: 'base-macos', vmName: 'vm-1'),
        same(runningLease),
      );
      expect(attempts, 2);
      verifyNever(() => api.deleteLease(any()));
    });

    test('deletes the VM when SSH never becomes available', () async {
      const timeout = Duration(milliseconds: 20);
      when(
        () => api.waitForVmRunning('lease-1', timeout: timeout),
      ).thenAnswer((_) async => runningLease);
      when(
        () => api.execCommandWebSocket(
          vmName: 'lease-1',
          command: 'true',
          onLog: any(named: 'onLog'),
          waitSeconds: any(named: 'waitSeconds'),
        ),
      ).thenAnswer(
        (_) async => throw const WebSocketException('SSH is not ready', 503),
      );

      await expectLater(
        prepareVm(
          api: api,
          baseVmName: 'base-macos',
          vmName: 'vm-1',
          startupTimeout: timeout,
        ),
        throwsA(isA<TimeoutException>()),
      );
      verify(() => api.deleteLease('lease-1')).called(1);
    });

    test('does not retry an authentication error and deletes the VM', () async {
      const error = WebSocketException('Unauthorized', 401);
      when(
        () => api.execCommandWebSocket(
          vmName: 'lease-1',
          command: 'true',
          onLog: any(named: 'onLog'),
          waitSeconds: any(named: 'waitSeconds'),
        ),
      ).thenAnswer((_) async => throw error);

      await expectLater(
        prepareVm(api: api, baseVmName: 'base-macos', vmName: 'vm-1'),
        throwsA(same(error)),
      );
      verify(
        () => api.execCommandWebSocket(
          vmName: 'lease-1',
          command: 'true',
          onLog: any(named: 'onLog'),
          waitSeconds: any(named: 'waitSeconds'),
        ),
      ).called(1);
      verify(() => api.deleteLease('lease-1')).called(1);
    });

    test('creates a VM and returns its updated running lease', () async {
      final lease = await prepareVm(
        api: api,
        baseVmName: 'base-macos',
        vmName: 'vm-1',
      );

      expect(lease, same(runningLease));
      verifyInOrder([
        () => api.createLease(imageName: 'base-macos', vmName: 'vm-1'),
        () => api.waitForVmRunning('lease-1', timeout: startupTimeout),
      ]);
      verifyNever(() => api.deleteLease(any()));
      verifyNever(() => api.close());
    });

    test('forwards the requested startup timeout', () async {
      const timeout = Duration(minutes: 2);
      when(
        () => api.waitForVmRunning('lease-1', timeout: timeout),
      ).thenAnswer((_) async => runningLease);

      await prepareVm(
        api: api,
        baseVmName: 'base-macos',
        vmName: 'vm-1',
        startupTimeout: timeout,
      );

      verify(() => api.waitForVmRunning('lease-1', timeout: timeout)).called(1);
    });

    test('does not wait or delete a VM when creation fails', () async {
      final error = StateError('Creation failed');
      when(
        () => api.createLease(imageName: 'base-macos', vmName: 'vm-1'),
      ).thenAnswer((_) async => throw error);

      await expectLater(
        prepareVm(api: api, baseVmName: 'base-macos', vmName: 'vm-1'),
        throwsA(same(error)),
      );

      verifyNever(() => api.waitForVmRunning(any(), timeout: startupTimeout));
      verifyNever(() => api.deleteLease(any()));
    });

    for (final error in <Object>[
      StateError('Status request failed'),
      TimeoutException('VM startup timed out'),
    ]) {
      test('deletes the created VM after ${error.runtimeType}', () async {
        when(
          () => api.waitForVmRunning('lease-1', timeout: startupTimeout),
        ).thenAnswer((_) async => throw error);

        await expectLater(
          prepareVm(api: api, baseVmName: 'base-macos', vmName: 'vm-1'),
          throwsA(same(error)),
        );

        verify(() => api.deleteLease('lease-1')).called(1);
      });
    }

    test('uses the requested VM name when the lease ID is missing', () async {
      final error = TimeoutException('VM startup timed out');
      when(
        () => api.createLease(imageName: 'base-macos', vmName: 'vm-1'),
      ).thenAnswer(
        (_) async => const OrchardLease(id: '', vmName: '', status: 'pending'),
      );
      when(
        () => api.waitForVmRunning('vm-1', timeout: startupTimeout),
      ).thenAnswer((_) async => throw error);

      await expectLater(
        prepareVm(api: api, baseVmName: 'base-macos', vmName: 'vm-1'),
        throwsA(same(error)),
      );

      verify(() => api.deleteLease('vm-1')).called(1);
      verifyNever(() => api.deleteLease(''));
    });

    test('reports both startup and cleanup failures', () async {
      when(
        () => api.waitForVmRunning('lease-1', timeout: startupTimeout),
      ).thenAnswer((_) async => throw StateError('Status request failed'));
      when(
        () => api.deleteLease('lease-1'),
      ).thenAnswer((_) async => throw StateError('Deletion failed'));

      await expectLater(
        prepareVm(api: api, baseVmName: 'base-macos', vmName: 'vm-1'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('lease-1'),
              contains('Status request failed'),
              contains('Deletion failed'),
            ),
          ),
        ),
      );
    });
  });
}
