import 'dart:convert';
import 'dart:io';

import 'avf_boot.dart';
import 'local_vm.dart';
import 'virtual_machine.dart';

class VirtualMachineManager {
  /// Starts a new macOS VM installation using the provided IPSW image file.
  static Future<void> install({
    required String name,
    required String ipswPath,
    String? customVmsDir,
    void Function(double progress)? onProgress,
  }) async {
    final vmsDir = customVmsDir ?? VirtualMachine.defaultVmsDir;
    final vmDir = '$vmsDir/$name';

    final targetDir = Directory(vmDir);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final diskImgPath = '$vmDir/disk.img';
    final nvramPath = '$vmDir/nvram.bin';
    final configJsonPath = '$vmDir/config.json';

    final process = await AppleVirtualization.install(
      ipswPath: ipswPath,
      diskImgPath: diskImgPath,
      nvramPath: nvramPath,
      configJsonPath: configJsonPath,
    );

    // Parse progress from standard output: "Progress: XX.XX%"
    final progressRegExp = RegExp(r'Progress:\s+(\d+\.\d+)%');

    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
      final match = progressRegExp.firstMatch(line);
      if (match != null && onProgress != null) {
        final progressVal = double.tryParse(match.group(1) ?? '');
        if (progressVal != null) {
          onProgress(progressVal / 100.0);
        }
      } else {
        print(line);
      }
    });

    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .listen(stderr.write)
        .asFuture<void>();

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (exitCode != 0) {
      throw StateError('macOS installation failed with exit code $exitCode');
    }
  }

  /// Clones the VM assets from [sourceName] to [targetName].
  static Future<void> clone({
    required String sourceName,
    required String targetName,
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Cloning macOS VM "$sourceName" to "$targetName"...');
    }

    try {
      final vmsDir = customVmsDir ?? VirtualMachine.defaultVmsDir;
      final sourceDir = '$vmsDir/$sourceName';
      final targetDir = '$vmsDir/$targetName';

      final srcDir = Directory(sourceDir);
      if (!srcDir.existsSync()) {
        throw FileSystemException('Source directory does not exist', sourceDir);
      }

      final target = Directory(targetDir);
      if (!target.existsSync()) {
        await target.create(recursive: true);
      }

      final configFile = File('$sourceDir/config.json');
      final diskFile = File('$sourceDir/disk.img');
      final nvramFile = File('$sourceDir/nvram.bin');

      if (!configFile.existsSync()) {
        throw FileSystemException(
            'config.json not found in source directory', configFile.path);
      }
      if (!diskFile.existsSync()) {
        throw FileSystemException(
            'disk.img not found in source directory', diskFile.path);
      }
      if (!nvramFile.existsSync()) {
        throw FileSystemException(
            'nvram.bin not found in source directory', nvramFile.path);
      }

      if (Platform.isMacOS) {
        // Use copy-on-write clone on macOS for instant copy and sparse file support
        final result = await Process.run('cp', [
          '-c',
          configFile.path,
          '$targetDir/config.json',
        ]);
        if (result.exitCode != 0) {
          throw StateError('Failed to clone config.json: ${result.stderr}');
        }

        final diskResult = await Process.run('cp', [
          '-c',
          diskFile.path,
          '$targetDir/disk.img',
        ]);
        if (diskResult.exitCode != 0) {
          throw StateError('Failed to clone disk.img: ${diskResult.stderr}');
        }

        final nvramResult = await Process.run('cp', [
          '-c',
          nvramFile.path,
          '$targetDir/nvram.bin',
        ]);
        if (nvramResult.exitCode != 0) {
          throw StateError('Failed to clone nvram.bin: ${nvramResult.stderr}');
        }
      } else {
        await configFile.copy('$targetDir/config.json');
        await diskFile.copy('$targetDir/disk.img');
        await nvramFile.copy('$targetDir/nvram.bin');
      }


    } catch (e) {
      if (showLogs) {
        print('Failed to clone VM assets: $e');
      }
      rethrow;
    }
  }



  /// Deletes the VM directory with the given [name] under VM directory.
  static Future<void> delete(
    String name, {
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Cleaning up VM "$name"...');
    }

    try {
      final vmsDir = customVmsDir ?? VirtualMachine.defaultVmsDir;
      final vmDir = Directory('$vmsDir/$name');
      if (vmDir.existsSync()) {
        await vmDir.delete(recursive: true);
      }
      if (showLogs) {
        print('Cleanup complete.');
      }
    } catch (e) {
      if (showLogs) {
        print('Cleanup failed: $e');
      }
      rethrow;
    }
  }

  /// Lists all local Virtual Machines available in the VM directory.
  static Future<List<LocalVM>> list({String? customVmsDir}) async {
    final vmsDir = Directory(customVmsDir ?? VirtualMachine.defaultVmsDir);
    if (!vmsDir.existsSync()) {
      return [];
    }

    final list = <LocalVM>[];
    await for (final entity in vmsDir.list()) {
      if (entity is Directory) {
        final name = entity.path.split('/').last;
        final configFile = File('${entity.path}/config.json');
        final diskFile = File('${entity.path}/disk.img');
        final nvramFile = File('${entity.path}/nvram.bin');

        // A directory is considered a valid VM if all core assets are present
        if (configFile.existsSync() &&
            diskFile.existsSync() &&
            nvramFile.existsSync()) {
          final diskSize = diskFile.lengthSync();
          int diskSizeUsed = diskSize;

          if (Platform.isMacOS) {
            try {
              final statResult =
                  await Process.run('stat', ['-f', '%b', diskFile.path]);
              if (statResult.exitCode == 0) {
                final blocks =
                    int.tryParse(statResult.stdout.toString().trim());
                if (blocks != null) {
                  diskSizeUsed = blocks * 512;
                }
              }
            } catch (_) {
              // Fallback to logical size on error
            }
          }

          final stat = entity.statSync();
          list.add(LocalVM(
            name: name,
            path: entity.path,
            diskSizeBytes: diskSize,
            diskSizeUsedBytes: diskSizeUsed,
            created: stat.changed,
          ));
        }
      }
    }
    // Sort alphabetically by name
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}
