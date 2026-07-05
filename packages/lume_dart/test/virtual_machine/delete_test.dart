import 'dart:async';
import 'dart:io';

import 'package:lume_dart/src/virtual_machine/delete.dart';
import 'package:test/test.dart';

void main() {
  group('lume delete unit tests', () {
    test('delete passes correct arguments to lume', () async {
      final capturedArgs = <String>[];
      await delete(
        name: 'test-vm',
        showLogs: false,
        runProcess: (executable, args) async {
          capturedArgs.addAll(args);
          return ProcessResult(0, 0, '', '');
        },
      );
      expect(capturedArgs, equals(['delete', 'test-vm', '--force']));
    });

    test('delete throws StateError when process fails', () async {
      expect(
        () => delete(
          name: 'test-vm',
          showLogs: false,
          runProcess: (executable, args) async {
            return ProcessResult(0, 1, '', 'lume: command not found');
          },
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('delete prints logs when showLogs is true', () async {
      final logs = <String>[];
      await runZoned(
        () => delete(
          name: 'test-vm',
          showLogs: true,
          runProcess: (executable, args) async => ProcessResult(0, 0, '', ''),
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
      expect(logs, contains('Deleting macOS VM "test-vm" via Lume...'));
      expect(logs, contains('VM deleted successfully: "test-vm"'));
    });

    test('delete does not print logs when showLogs is false', () async {
      final logs = <String>[];
      await runZoned(
        () => delete(
          name: 'test-vm',
          showLogs: false,
          runProcess: (executable, args) async => ProcessResult(0, 0, '', ''),
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
