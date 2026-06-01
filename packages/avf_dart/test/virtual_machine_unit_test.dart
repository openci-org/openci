import 'dart:convert';
import 'dart:io';

import 'package:avf_dart/avf_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TransferProgress Unit Tests', () {
    test('Calculates percent correctly', () {
      final progress = TransferProgress(
        downloaded: 50,
        total: 100,
        speedMb: 2.5,
        elapsed: const Duration(seconds: 10),
      );
      expect(progress.percent, equals(50.0));
    });

    test('Handles zero total gracefully', () {
      final progress = TransferProgress(
        downloaded: 0,
        total: 0,
        speedMb: 0,
        elapsed: Duration.zero,
      );
      expect(progress.percent, equals(0.0));
    });

    test('Formats speed string correctly', () {
      final progress = TransferProgress(
        downloaded: 10,
        total: 100,
        speedMb: 5.25,
        elapsed: const Duration(seconds: 1),
      );
      expect(progress.speedStr, equals('5.3 MB/s'));
    });

    test('Formats elapsed string correctly', () {
      final progress = TransferProgress(
        downloaded: 10,
        total: 100,
        speedMb: 1.0,
        elapsed: const Duration(minutes: 2, seconds: 5),
      );
      expect(progress.elapsedStr, equals('2m 5s'));
    });

    test('Formats eta string correctly', () {
      final progress1 = TransferProgress(
        downloaded: 10,
        total: 100,
        speedMb: 1.0,
        elapsed: const Duration(seconds: 1),
        remaining: const Duration(seconds: 45),
      );
      expect(progress1.etaStr, equals('45s'));

      final progress2 = TransferProgress(
        downloaded: 10,
        total: 100,
        speedMb: 1.0,
        elapsed: const Duration(seconds: 1),
        remaining: const Duration(minutes: 2, seconds: 15),
      );
      expect(progress2.etaStr, equals('2m 15s'));

      final progress3 = TransferProgress(
        downloaded: 10,
        total: 100,
        speedMb: 1.0,
        elapsed: const Duration(seconds: 1),
        remaining: const Duration(hours: 1, minutes: 5, seconds: 10),
      );
      expect(progress3.etaStr, equals('1h 5m 10s'));
    });
  });

  group('VirtualMachine File Operations Unit Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('avf_test_vms_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> createDummyVm(
      String name, {
      bool createConfig = true,
      bool createDisk = true,
      bool createNvram = true,
      String os = 'macOS',
    }) async {
      final vmPath = '${tempDir.path}/$name';
      await Directory(vmPath).create(recursive: true);

      if (createConfig) {
        final configFile = File('$vmPath/config.json');
        await configFile.writeAsString(jsonEncode({
          'os': os,
          'hardwareModel': 'aGFyZHdhcmVNb2RlbA==',
          'machineIdentifier': 'bWFjaGluZUlkZW50aWZpZXI=',
          'macAddress': 'ea:de:15:32:cb:ac',
        }));
      }
      if (createDisk) {
        final diskFile = File('$vmPath/disk.img');
        await diskFile.writeAsString('dummy disk image content');
      }
      if (createNvram) {
        final nvramFile = File('$vmPath/nvram.bin');
        await nvramFile.writeAsString('dummy nvram content');
      }
    }

    test('list() finds valid VMs and ignores invalid ones', () async {
      // 1. Valid VM
      await createDummyVm('vm-valid-1');
      // 2. Another Valid VM
      await createDummyVm('vm-valid-2');
      // 3. Missing disk.img
      await createDummyVm('vm-invalid-missing-disk', createDisk: false);
      // 4. Missing config.json
      await createDummyVm('vm-invalid-missing-config', createConfig: false);

      final vms = await VirtualMachine.list(customVmsDir: tempDir.path);

      expect(vms.length, equals(2));
      expect(vms[0].name, equals('vm-valid-1'));
      expect(vms[1].name, equals('vm-valid-2'));
      expect(Directory(vms[0].path).existsSync(), isTrue);
    });

    test('clone() replicates VM config and image files', () async {
      await createDummyVm('source-vm');

      await VirtualMachine.clone(
        sourceName: 'source-vm',
        targetName: 'target-vm',
        customVmsDir: tempDir.path,
        showLogs: false,
      );

      final targetVmDir = Directory('${tempDir.path}/target-vm');
      expect(await targetVmDir.exists(), isTrue);

      final config = File('${targetVmDir.path}/config.json');
      final disk = File('${targetVmDir.path}/disk.img');
      final nvram = File('${targetVmDir.path}/nvram.bin');

      expect(await config.exists(), isTrue);
      expect(await disk.exists(), isTrue);
      expect(await nvram.exists(), isTrue);

      final configContent = jsonDecode(await config.readAsString());
      expect(configContent['os'], equals('macOS'));
    });

    test('clone() fails if source VM does not exist', () async {
      expect(
        () => VirtualMachine.clone(
          sourceName: 'non-existent',
          targetName: 'target-vm',
          customVmsDir: tempDir.path,
          showLogs: false,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('delete() removes the VM directory completely', () async {
      await createDummyVm('to-be-deleted');
      final vmDir = Directory('${tempDir.path}/to-be-deleted');
      expect(await vmDir.exists(), isTrue);

      await VirtualMachine.delete(
        'to-be-deleted',
        customVmsDir: tempDir.path,
        showLogs: false,
      );

      expect(await vmDir.exists(), isFalse);
    });
  });
}
