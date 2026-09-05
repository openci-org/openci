import 'dart:async';

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
    when(() => api.deleteLease(any())).thenAnswer((_) async {});
  });

  group('prepareVm', () {
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
