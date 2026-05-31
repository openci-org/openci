import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'avf_boot.dart';

class VirtualMachine {
  final Process _process;
  final String name;

  VirtualMachine._(this._process, this.name);

  /// Default directory where Virtual Machines are stored.
  /// Defaults to `~/.avf_dart/vms`.
  static String get defaultVmsDir {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    return '$home/.avf_dart/vms';
  }

  /// Launches the virtualization helper for the VM with the given [name].
  ///
  /// Under the hood, this resolves the VM directory, performs necessary
  /// asset copying, decompressing, and executes the helper binary.
  /// If [showLogs] is true, VM status updates and output logs will be printed to stdout.
  static Future<VirtualMachine> boot({
    required String name,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Booting VM "$name"...');
    }

    final vmDir = '$defaultVmsDir/$name';
    final Process process;
    try {
      process = await AppleVirtualization.bootFromDirectory(vmDir);
    } catch (e) {
      if (showLogs) {
        print('Failed to boot VM: $e');
      }
      rethrow;
    }

    if (showLogs) {
      process.stdout.transform(utf8.decoder).listen(stdout.write);
      process.stderr.transform(utf8.decoder).listen(stderr.write);

      process.exitCode.then((code) {
        print('\nVM "$name" exited with code $code');
      });
    }

    return VirtualMachine._(process, name);
  }

  /// Stops the VM process gracefully (sends SIGTERM).
  Future<void> stop() async {
    _process.kill(ProcessSignal.sigterm);
    await _process.exitCode;
  }

  /// Returns the future that completes when the VM process terminates.
  Future<int> get exitCode => _process.exitCode;

  /// Clones the VM assets from [sourceName] to [targetName].
  ///
  /// If [sourceName] is `'example'`, it automatically resolves the default Alpine Linux
  /// assets packaged within the `avf_dart` project.
  /// Otherwise, it clones from the existing VM directory under [defaultVmsDir].
  /// If [showLogs] is true, status updates will be printed.
  static Future<void> clone({
    required String sourceName,
    required String targetName,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Cloning VM "$sourceName" to "$targetName"...');
    }

    try {
      final String sourceDir;
      if (sourceName == 'example') {
        final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
        final resolvedUri = await Isolate.resolvePackageUri(packageUri);
        if (resolvedUri == null) {
          throw StateError('Could not resolve package:avf_dart URI. Ensure the package is properly resolved.');
        }
        final libDir = File(resolvedUri.toFilePath()).parent;
        final packageRoot = libDir.parent;
        sourceDir = '${packageRoot.path}/example/assets';
      } else {
        sourceDir = '$defaultVmsDir/$sourceName';
      }

      final targetDir = '$defaultVmsDir/$targetName';

      final srcDir = Directory(sourceDir);
      if (!srcDir.existsSync()) {
        throw FileSystemException('Source directory does not exist', sourceDir);
      }

      final target = Directory(targetDir);
      if (!target.existsSync()) {
        await target.create(recursive: true);
      }

      final kernel = File('$sourceDir/vmlinuz');
      final initramfs = File('$sourceDir/initramfs');

      if (!kernel.existsSync()) {
        throw FileSystemException('Kernel image vmlinuz not found in source directory', kernel.path);
      }
      if (!initramfs.existsSync()) {
        throw FileSystemException('Initramfs image initramfs not found in source directory', initramfs.path);
      }

      await kernel.copy('$targetDir/vmlinuz');
      await initramfs.copy('$targetDir/initramfs');
    } catch (e) {
      if (showLogs) {
        print('Failed to clone VM assets: $e');
      }
      rethrow;
    }
  }

  /// Deletes the VM directory with the given [name] under [defaultVmsDir].
  ///
  /// If [showLogs] is true, status updates will be printed.
  static Future<void> delete(
    String name, {
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Cleaning up VM "$name"...');
    }

    try {
      final vmDir = Directory('$defaultVmsDir/$name');
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
}
