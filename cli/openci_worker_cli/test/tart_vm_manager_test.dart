import 'package:mocktail/mocktail.dart';
import 'package:openci_worker_cli/src/tart_vm_manager.dart';
import 'package:process_run/process_run.dart';
import 'package:test/test.dart';

class MockShellRunner extends Mock implements ShellRunner {}

class FakeProcessResult extends Fake implements ProcessResult {
  final int _exitCode;
  final String _stdout;
  final String _stderr;

  FakeProcessResult({
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
  })  : _exitCode = exitCode,
        _stdout = stdout,
        _stderr = stderr;

  @override
  int get exitCode => _exitCode;

  @override
  dynamic get stdout => _stdout;

  @override
  dynamic get stderr => _stderr;
}

void main() {
  late MockShellRunner mockShellRunner;
  late TartVmManager vmManager;

  setUp(() {
    mockShellRunner = MockShellRunner();
    vmManager = TartVmManager(shellRunner: mockShellRunner);
  });

  group('TartVmManager', () {
    group('stopVm', () {
      test('returns true when VM is stopped successfully', () async {
        when(() => mockShellRunner.run('tart stop test-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 0)]);

        final result = await vmManager.stopVm('test-vm');

        expect(result, isTrue);
        verify(() => mockShellRunner.run('tart stop test-vm')).called(1);
      });

      test('returns false when VM stop fails', () async {
        when(() => mockShellRunner.run('tart stop test-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 1)]);

        final result = await vmManager.stopVm('test-vm');

        expect(result, isFalse);
        verify(() => mockShellRunner.run('tart stop test-vm')).called(1);
      });

      test('returns false when shell returns empty results', () async {
        when(() => mockShellRunner.run('tart stop test-vm'))
            .thenAnswer((_) async => []);

        final result = await vmManager.stopVm('test-vm');

        expect(result, isFalse);
        verify(() => mockShellRunner.run('tart stop test-vm')).called(1);
      });
    });

    group('deleteVm', () {
      test('returns true when VM is deleted successfully', () async {
        when(() => mockShellRunner.run('tart delete test-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 0)]);

        final result = await vmManager.deleteVm('test-vm');

        expect(result, isTrue);
        verify(() => mockShellRunner.run('tart delete test-vm')).called(1);
      });

      test('returns false when VM delete fails', () async {
        when(() => mockShellRunner.run('tart delete test-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 1)]);

        final result = await vmManager.deleteVm('test-vm');

        expect(result, isFalse);
        verify(() => mockShellRunner.run('tart delete test-vm')).called(1);
      });

      test('returns false when shell returns empty results', () async {
        when(() => mockShellRunner.run('tart delete test-vm'))
            .thenAnswer((_) async => []);

        final result = await vmManager.deleteVm('test-vm');

        expect(result, isFalse);
        verify(() => mockShellRunner.run('tart delete test-vm')).called(1);
      });
    });

    group('cleanupVm', () {
      test('returns success when both stop and delete succeed', () async {
        when(() => mockShellRunner.run('tart stop cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 0)]);
        when(() => mockShellRunner.run('tart delete cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 0)]);

        final result = await vmManager.cleanupVm('cleanup-vm');

        expect(result.vmName, equals('cleanup-vm'));
        expect(result.stopSucceeded, isTrue);
        expect(result.deleteSucceeded, isTrue);
        expect(result.isFullyCleanedUp, isTrue);
      });

      test('returns partial success when stop succeeds but delete fails',
          () async {
        when(() => mockShellRunner.run('tart stop cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 0)]);
        when(() => mockShellRunner.run('tart delete cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 1)]);

        final result = await vmManager.cleanupVm('cleanup-vm');

        expect(result.vmName, equals('cleanup-vm'));
        expect(result.stopSucceeded, isTrue);
        expect(result.deleteSucceeded, isFalse);
        expect(result.isFullyCleanedUp, isFalse);
      });

      test('returns partial success when stop fails but delete succeeds',
          () async {
        when(() => mockShellRunner.run('tart stop cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 1)]);
        when(() => mockShellRunner.run('tart delete cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 0)]);

        final result = await vmManager.cleanupVm('cleanup-vm');

        expect(result.vmName, equals('cleanup-vm'));
        expect(result.stopSucceeded, isFalse);
        expect(result.deleteSucceeded, isTrue);
        expect(result.isFullyCleanedUp, isFalse);
      });

      test('returns failure when both stop and delete fail', () async {
        when(() => mockShellRunner.run('tart stop cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 1)]);
        when(() => mockShellRunner.run('tart delete cleanup-vm'))
            .thenAnswer((_) async => [FakeProcessResult(exitCode: 1)]);

        final result = await vmManager.cleanupVm('cleanup-vm');

        expect(result.vmName, equals('cleanup-vm'));
        expect(result.stopSucceeded, isFalse);
        expect(result.deleteSucceeded, isFalse);
        expect(result.isFullyCleanedUp, isFalse);
      });

      test('calls stop before delete', () async {
        final callOrder = <String>[];

        when(() => mockShellRunner.run('tart stop order-vm')).thenAnswer((_) {
          callOrder.add('stop');
          return Future.value([FakeProcessResult(exitCode: 0)]);
        });
        when(() => mockShellRunner.run('tart delete order-vm')).thenAnswer((_) {
          callOrder.add('delete');
          return Future.value([FakeProcessResult(exitCode: 0)]);
        });

        await vmManager.cleanupVm('order-vm');

        expect(callOrder, equals(['stop', 'delete']));
      });
    });
  });

  group('CleanupResult', () {
    test('isFullyCleanedUp returns true when both operations succeed', () {
      final result = CleanupResult(
        vmName: 'test-vm',
        stopSucceeded: true,
        deleteSucceeded: true,
      );

      expect(result.isFullyCleanedUp, isTrue);
    });

    test('isFullyCleanedUp returns false when stop fails', () {
      final result = CleanupResult(
        vmName: 'test-vm',
        stopSucceeded: false,
        deleteSucceeded: true,
      );

      expect(result.isFullyCleanedUp, isFalse);
    });

    test('isFullyCleanedUp returns false when delete fails', () {
      final result = CleanupResult(
        vmName: 'test-vm',
        stopSucceeded: true,
        deleteSucceeded: false,
      );

      expect(result.isFullyCleanedUp, isFalse);
    });

    test('isFullyCleanedUp returns false when both operations fail', () {
      final result = CleanupResult(
        vmName: 'test-vm',
        stopSucceeded: false,
        deleteSucceeded: false,
      );

      expect(result.isFullyCleanedUp, isFalse);
    });
  });

  group('DefaultShellRunner', () {
    test('creates instance with default throwOnError value', () {
      final runner = DefaultShellRunner();
      expect(runner.throwOnError, isFalse);
    });

    test('creates instance with custom throwOnError value', () {
      final runner = DefaultShellRunner(throwOnError: true);
      expect(runner.throwOnError, isTrue);
    });
  });
}
