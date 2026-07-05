import 'dart:async';
import 'dart:io';

import 'package:lume_dart/src/virtual_machine/clone.dart';
import 'package:test/test.dart';

void main() {
  group('lume clone unit tests', () {
    test('clone passes correct arguments to lume', () async {
      final capturedArgs = <String>[];
      await clone(
        sourceName: 'src-vm',
        targetName: 'dest-vm',
        showLogs: false,
        runProcess: (executable, args) async {
          capturedArgs.addAll(args);
          return ProcessResult(0, 0, '', '');
        },
      );
      expect(capturedArgs, equals(['clone', 'src-vm', 'dest-vm']));
    });

    test('clone throws StateError when process fails', () async {
      expect(
        () => clone(
          sourceName: 'src-vm',
          targetName: 'dest-vm',
          showLogs: false,
          runProcess: (executable, args) async {
            return ProcessResult(0, 1, '', 'lume: command not found');
          },
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('clone prints logs when showLogs is true', () async {
      final logs = <String>[];
      await runZoned(
        () => clone(
          sourceName: 'src-vm',
          targetName: 'dest-vm',
          showLogs: true,
          runProcess: (executable, args) async => ProcessResult(0, 0, '', ''),
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
      expect(
        logs,
        contains('Cloning macOS VM "src-vm" to "dest-vm" via Lume...'),
      );
      expect(logs, contains('VM cloned successfully: "src-vm" -> "dest-vm"'));
    });

    test('clone does not print logs when showLogs is false', () async {
      final logs = <String>[];
      await runZoned(
        () => clone(
          sourceName: 'src-vm',
          targetName: 'dest-vm',
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
