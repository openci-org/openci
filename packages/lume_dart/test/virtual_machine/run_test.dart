import 'dart:async';
import 'dart:io';

import 'package:lume_dart/src/virtual_machine/run.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockProcess extends Mock implements Process {}

void main() {
  group('lume run unit tests', () {
    test('run passes correct arguments to lume with defaults', () async {
      final capturedArgs = <String>[];
      final mockProcess = MockProcess();
      when(
        () => mockProcess.stdout,
      ).thenAnswer((_) => const Stream<List<int>>.empty());
      when(
        () => mockProcess.stderr,
      ).thenAnswer((_) => const Stream<List<int>>.empty());

      final resultProcess = await run(
        name: 'test-vm',
        showLogs: false,
        startProcess: (executable, args) async {
          capturedArgs.addAll(args);
          return mockProcess;
        },
      );

      expect(resultProcess, equals(mockProcess));
      expect(capturedArgs, equals(['run', '--no-display', 'test-vm']));
    });

    test(
      'run passes correct arguments to lume when noDisplay is false',
      () async {
        final capturedArgs = <String>[];
        final mockProcess = MockProcess();
        when(
          () => mockProcess.stdout,
        ).thenAnswer((_) => const Stream<List<int>>.empty());
        when(
          () => mockProcess.stderr,
        ).thenAnswer((_) => const Stream<List<int>>.empty());

        await run(
          name: 'test-vm',
          noDisplay: false,
          showLogs: false,
          startProcess: (executable, args) async {
            capturedArgs.addAll(args);
            return mockProcess;
          },
        );

        expect(capturedArgs, equals(['run', 'test-vm']));
      },
    );

    test('run throws StateError when process fails to start', () async {
      expect(
        () => run(
          name: 'test-vm',
          showLogs: false,
          startProcess: (executable, args) async {
            throw ProcessException('lume', args, 'Failed to start');
          },
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('run prints logs when showLogs is true', () async {
      final logs = <String>[];
      final mockProcess = MockProcess();
      when(
        () => mockProcess.stdout,
      ).thenAnswer((_) => const Stream<List<int>>.empty());
      when(
        () => mockProcess.stderr,
      ).thenAnswer((_) => const Stream<List<int>>.empty());

      await runZoned(
        () => run(
          name: 'test-vm',
          showLogs: true,
          startProcess: (executable, args) async => mockProcess,
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
      expect(logs, contains('Starting macOS VM "test-vm" via Lume...'));
    });

    test('run does not print logs when showLogs is false', () async {
      final logs = <String>[];
      final mockProcess = MockProcess();
      when(
        () => mockProcess.stdout,
      ).thenAnswer((_) => const Stream<List<int>>.empty());
      when(
        () => mockProcess.stderr,
      ).thenAnswer((_) => const Stream<List<int>>.empty());

      await runZoned(
        () => run(
          name: 'test-vm',
          showLogs: false,
          startProcess: (executable, args) async => mockProcess,
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
      expect(logs, isEmpty);
    });
  });
}
