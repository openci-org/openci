import 'dart:io';

import 'package:avf_dart/avf_dart.dart';
import 'package:test/test.dart';

void main() {
  group('VirtualMachine E2E & Integration Tests (macOS Only)', () {
    test('fetchLatestIpswUrl returns a valid macOS restore image URI',
        () async {
      final url = await AppleVirtualization.fetchLatestIpswUrl();
      expect(url, isNotNull);
      expect(url.scheme, anyOf(equals('http'), equals('https')));
      expect(url.path, endsWith('.ipsw'));
    });

    test('boot throws StateError when VM files are corrupt or empty', () async {
      final tempDir = await Directory.systemTemp.createTemp('avf_e2e_boot_');
      try {
        final vmName = 'corrupt-vm';
        final vmDir = '${tempDir.path}/$vmName';
        await Directory(vmDir).create(recursive: true);

        // 1. Missing disk image & NVRAM
        final configFile = File('$vmDir/config.json');
        await configFile.writeAsString('''{
          "os": "macOS",
          "hardwareModel": "aGFyZHdhcmVNb2RlbA==",
          "machineIdentifier": "bWFjaGluZUlkZW50aWZpZXI=",
          "macAddress": "ea:de:15:32:cb:ac"
        }''');

        // Should throw FileSystemException because disk.img is missing
        expect(
          () => VirtualMachine.boot(
              name: vmName, customVmsDir: tempDir.path, showLogs: false),
          throwsA(isA<FileSystemException>()),
        );

        // 2. Create blank files (invalid format)
        final diskFile = File('$vmDir/disk.img');
        await diskFile.writeAsString('');
        final nvramFile = File('$vmDir/nvram.bin');
        await nvramFile.writeAsString('');

        // Boot should fail now due to empty/corrupt disk image, throwing StateError
        expect(
          () => VirtualMachine.boot(
              name: vmName, customVmsDir: tempDir.path, showLogs: false),
          throwsA(isA<StateError>()),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  },
      skip: (Platform.isMacOS && Platform.environment['RUN_AVF_E2E'] == 'true')
          ? null
          : 'E2E tests require physical macOS and RUN_AVF_E2E=true env var');
}
