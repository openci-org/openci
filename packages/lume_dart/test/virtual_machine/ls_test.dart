import 'dart:async';
import 'dart:io';

import 'package:lume_dart/src/virtual_machine/ls.dart';
import 'package:test/test.dart';

void main() {
  group('lume ls unit tests', () {
    const mockJsonOutput = '''
[
  {
    "sshAvailable" : true,
    "downloadProgress" : null,
    "status" : "running",
    "cpuCount" : 4,
    "ipAddress" : "192.168.64.10",
    "diskSize" : {
      "allocated" : 78601256960,
      "total" : 128849018880
    },
    "provisioningOperation" : null,
    "os" : "macOS",
    "memorySize" : 8589934592,
    "display" : "1024x768",
    "networkMode" : "nat",
    "locationName" : "home",
    "name" : "test-vm",
    "vncUrl" : "vnc://admin:pass@127.0.0.1:5900",
    "sharedDirectories" : null
  }
]
''';

    test(
      'ls passes correct arguments and parses JSON list successfully',
      () async {
        final capturedArgs = <String>[];
        final result = await ls(
          showLogs: false,
          runProcess: (executable, args) async {
            capturedArgs.addAll(args);
            return ProcessResult(0, 0, mockJsonOutput, '');
          },
        );

        expect(capturedArgs, equals(['ls', '--format', 'json']));
        expect(result.length, equals(1));
        final vm = result.first;
        expect(vm.name, equals('test-vm'));
        expect(vm.status, equals('running'));
        expect(vm.ipAddress, equals('192.168.64.10'));
        expect(vm.sshAvailable, isTrue);
        expect(vm.cpuCount, equals(4));
        expect(vm.memorySize, equals(8589934592));
        expect(vm.display, equals('1024x768'));
        expect(vm.networkMode, equals('nat'));
        expect(vm.os, equals('macOS'));
        expect(vm.locationName, equals('home'));
        expect(vm.vncUrl, equals('vnc://admin:pass@127.0.0.1:5900'));
        expect(vm.diskSize, isNotNull);
        expect(vm.diskSize!.allocated, equals(78601256960));
        expect(vm.diskSize!.total, equals(128849018880));
      },
    );

    test('ls throws StateError when process fails', () async {
      expect(
        () => ls(
          showLogs: false,
          runProcess: (executable, args) async {
            return ProcessResult(0, 1, '', 'lume: command not found');
          },
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('ls prints logs when showLogs is true', () async {
      final logs = <String>[];
      await runZoned(
        () => ls(
          showLogs: true,
          runProcess: (executable, args) async => ProcessResult(0, 0, '[]', ''),
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
      expect(logs, contains('Listing macOS VMs via Lume...'));
    });

    test('ls does not print logs when showLogs is false', () async {
      final logs = <String>[];
      await runZoned(
        () => ls(
          showLogs: false,
          runProcess: (executable, args) async => ProcessResult(0, 0, '[]', ''),
        ),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            logs.add(line);
          },
        ),
      );
      expect(logs, isEmpty);
    });

    group('parseLumeVms tests', () {
      test('successfully parses JSON even with surrounding log messages', () {
        const outputWithLogs = '''
[2026-07-10T07:04:45Z] INFO: Cleaned up stale session file name=openci-vm-worker
[2026-07-10T07:04:46Z] WARN: Some warning message
[
  {
    "sshAvailable" : true,
    "downloadProgress" : null,
    "status" : "running",
    "cpuCount" : 4,
    "ipAddress" : "192.168.64.10",
    "diskSize" : {
      "allocated" : 78601256960,
      "total" : 128849018880
    },
    "provisioningOperation" : null,
    "os" : "macOS",
    "memorySize" : 8589934592,
    "display" : "1024x768",
    "networkMode" : "nat",
    "locationName" : "home",
    "name" : "test-vm",
    "vncUrl" : "vnc://admin:pass@127.0.0.1:5900",
    "sharedDirectories" : null
  }
]
[2026-07-10T07:04:47Z] INFO: Post-run log message
''';

        final result = parseLumeVms(outputWithLogs);
        expect(result.length, equals(1));
        expect(result.first.name, equals('test-vm'));
      });

      test('throws FormatException when no JSON array is found', () {
        const invalidOutput = 'Some log message without any JSON';
        expect(
          () => parseLumeVms(invalidOutput),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when JSON array is incomplete', () {
        const incompleteOutput = '[ {"name": "test-vm"';
        expect(
          () => parseLumeVms(incompleteOutput),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
