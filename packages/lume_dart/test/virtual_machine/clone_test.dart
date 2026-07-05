import 'dart:async';
import 'dart:io';

import 'package:lume_dart/lume_dart.dart';
import 'package:lume_dart/src/virtual_machine/clone.dart';
import 'package:test/test.dart';

void main() {
  group('lume clone unit tests', () {
    late List<String> capturedArgs;
    late int mockExitCode;
    late String mockStderr;

    setUp(() {
      capturedArgs = [];
      mockExitCode = 0;
      mockStderr = '';

      runProcess = (executable, args) async {
        capturedArgs = args;
        return ProcessResult(0, mockExitCode, '', mockStderr);
      };
    });

    tearDown(() {
      runProcess = Process.run;
    });

    test('clone passes correct arguments to lume', () async {
      await clone(sourceName: 'src-vm', targetName: 'dest-vm', showLogs: false);
      expect(capturedArgs, equals(['clone', 'src-vm', 'dest-vm']));
    });

    test('clone throws StateError when process fails', () async {
      mockExitCode = 1;
      mockStderr = 'lume: command not found';

      expect(
        () =>
            clone(sourceName: 'src-vm', targetName: 'dest-vm', showLogs: false),
        throwsA(isA<StateError>()),
      );
    });

    test('clone prints logs when showLogs is true', () async {
      final logs = <String>[];
      await runZoned(
        () =>
            clone(sourceName: 'src-vm', targetName: 'dest-vm', showLogs: true),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
      expect(
          logs, contains('Cloning macOS VM "src-vm" to "dest-vm" via Lume...'));
      expect(logs, contains('VM cloned successfully: "src-vm" -> "dest-vm"'));
    });

    test('clone does not print logs when showLogs is false', () async {
      final logs = <String>[];
      await runZoned(
        () =>
            clone(sourceName: 'src-vm', targetName: 'dest-vm', showLogs: false),
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
