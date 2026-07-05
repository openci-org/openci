import 'dart:async';
import 'dart:io';

import 'package:lume_dart/src/virtual_machine/stop.dart';
import 'package:test/test.dart';

void main() {
  group('lume stop unit tests', () {
    test('stop passes correct arguments to lume', () async {
      final capturedArgs = <String>[];
      await stop(
        name: 'test-vm',
        showLogs: false,
        runProcess: (executable, args) async {
          capturedArgs.addAll(args);
          return ProcessResult(0, 0, '', '');
        },
      );
      expect(capturedArgs, equals(['stop', 'test-vm']));
    });

    test('stop throws StateError when process fails', () async {
      expect(
        () => stop(
          name: 'test-vm',
          showLogs: false,
          runProcess: (executable, args) async {
            return ProcessResult(0, 1, '', 'lume: command not found');
          },
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('stop prints logs when showLogs is true', () async {
      final logs = <String>[];
      await runZoned(
        () => stop(
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
      expect(logs, contains('Stopping macOS VM "test-vm" via Lume...'));
      expect(logs, contains('VM stopped successfully: "test-vm"'));
    });

    test('stop does not print logs when showLogs is false', () async {
      final logs = <String>[];
      await runZoned(
        () => stop(
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
