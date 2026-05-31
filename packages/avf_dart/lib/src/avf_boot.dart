import 'dart:io';
import 'dart:isolate';

class AppleVirtualization {
  /// Launches the virtualization helper binary with the given kernel and initramfs paths.
  ///
  /// Under the hood, this handles:
  /// 1. Copying the files to `/tmp` (to bypass macOS Sandbox/TCC permissions).
  /// 2. Decompressing the kernel if it is a PE32+ EFI stub containing a gzip payload.
  /// 3. Applying appropriate execution permissions.
  /// 4. Automatically cleaning up the temporary files in `/tmp` once the process exits.
  static Future<Process> boot({
    required String kernelPath,
    required String initramfsPath,
  }) async {
    // 1. Resolve packages/avf_dart to locate helper
    final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) {
      throw StateError('Could not resolve package:avf_dart URI. Ensure the package is properly imported and resolved.');
    }

    // resolvedUri points to 'package:avf_dart/lib/avf_dart.dart'
    // We get the directory containing avf_dart.dart, which is packages/avf_dart/lib
    final libDir = File(resolvedUri.toFilePath()).parent;
    final packageRoot = libDir.parent;
    final helperBinary = '${packageRoot.path}/.dart_tool/avf_dart/avf_helper';

    if (!File(helperBinary).existsSync()) {
      throw StateError(
        'avf_helper binary not found at $helperBinary.\n'
        'Please ensure build hooks have run by running "dart pub get" or "dart test" in the avf_dart directory.'
      );
    }

    // 2. Prepare temporary assets in /tmp
    final tmpKernelPath = '/tmp/avf_vmlinuz';
    final tmpInitramfsPath = '/tmp/avf_initramfs';

    try {
      if (File(tmpKernelPath).existsSync()) {
        File(tmpKernelPath).deleteSync();
      }
      if (File(tmpInitramfsPath).existsSync()) {
        File(tmpInitramfsPath).deleteSync();
      }

      // Process kernel (Check for PE32+ EFI stub containing gzip payload)
      final kernelBytes = File(kernelPath).readAsBytesSync();
      final gzipMagic = [0x1f, 0x8b];
      int gzipIdx = -1;
      for (int i = 0; i < kernelBytes.length - 1; i++) {
        if (kernelBytes[i] == gzipMagic[0] &&
            kernelBytes[i + 1] == gzipMagic[1]) {
          gzipIdx = i;
          break;
        }
      }

      if (gzipIdx != -1 && gzipIdx > 0) {
        final compressedBytes = kernelBytes.sublist(gzipIdx);
        final tmpGzPath = '$tmpKernelPath.gz';
        File(tmpGzPath).writeAsBytesSync(compressedBytes);

        // Decompress gzip payload using gunzip process
        final gunzipResult = Process.runSync('gunzip', ['-f', tmpGzPath]);
        if (gunzipResult.exitCode != 0 && !File(tmpKernelPath).existsSync()) {
          throw ProcessException('gunzip', [], 'Failed to decompress kernel payload: ${gunzipResult.stderr}');
        }
      } else {
        File(kernelPath).copySync(tmpKernelPath);
      }

      // Copy initramfs directly
      File(initramfsPath).copySync(tmpInitramfsPath);

      // Apply permissions
      final chmodResult = Process.runSync('chmod', ['644', tmpKernelPath, tmpInitramfsPath]);
      if (chmodResult.exitCode != 0) {
        throw ProcessException('chmod', ['644', tmpKernelPath, tmpInitramfsPath], 'Failed to set permissions: ${chmodResult.stderr}');
      }
    } catch (e) {
      throw StateError('Failed to prepare assets in /tmp: $e');
    }

    // 3. Start VM process using the helper binary
    final Process process;
    try {
      process = await Process.start(helperBinary, [tmpKernelPath, tmpInitramfsPath]);
    } catch (e) {
      // Clean up on failure to start
      try {
        if (File(tmpKernelPath).existsSync()) File(tmpKernelPath).deleteSync();
        if (File(tmpInitramfsPath).existsSync()) File(tmpInitramfsPath).deleteSync();
      } catch (_) {}
      rethrow;
    }

    // 4. Automatically clean up temporary files in /tmp when process exits
    process.exitCode.then((_) {
      try {
        if (File(tmpKernelPath).existsSync()) {
          File(tmpKernelPath).deleteSync();
        }
        if (File(tmpInitramfsPath).existsSync()) {
          File(tmpInitramfsPath).deleteSync();
        }
      } catch (_) {
        // Suppress errors during cleanup
      }
    });

    return process;
  }

  /// Searches for `vmlinuz` and `initramfs` inside the given [directoryPath],
  /// verifies their existence, and boots the VM.
  static Future<Process> bootFromDirectory(String directoryPath) async {
    final kernelPath = '$directoryPath/vmlinuz';
    final initramfsPath = '$directoryPath/initramfs';

    if (!File(kernelPath).existsSync()) {
      throw FileSystemException('Kernel image not found', kernelPath);
    }
    if (!File(initramfsPath).existsSync()) {
      throw FileSystemException('Initramfs image not found', initramfsPath);
    }

    return boot(kernelPath: kernelPath, initramfsPath: initramfsPath);
  }

  /// Automatically resolves the example assets directory within the `avf_dart` package
  /// and boots the VM using those assets.
  static Future<Process> bootExample() async {
    final packageUri = Uri.parse('package:avf_dart/avf_dart.dart');
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    if (resolvedUri == null) {
      throw StateError('Could not resolve package:avf_dart URI. Ensure the package is properly resolved.');
    }

    final libDir = File(resolvedUri.toFilePath()).parent;
    final packageRoot = libDir.parent;
    final assetsDir = '${packageRoot.path}/example/assets';

    return bootFromDirectory(assetsDir);
  }
}
