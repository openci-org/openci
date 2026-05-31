import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Apple Virtualization Framework Linux Boot PoC (Wrapper) ===');

  final currentDir = Directory.current.absolute.path;
  final kernelPath = '$currentDir/example/assets/vmlinuz';
  final initramfsPath = '$currentDir/example/assets/initramfs';

  print('Kernel path: $kernelPath');
  print('Initramfs path: $initramfsPath');

  if (!File(kernelPath).existsSync() || !File(initramfsPath).existsSync()) {
    print('Error: Alpine Linux assets are missing. Download them first.');
    return;
  }

  // Copy assets to /tmp to avoid macOS TCC/Sandbox permission issues with home directory files
  final tmpKernelPath = '/tmp/avf_vmlinuz';
  final tmpInitramfsPath = '/tmp/avf_initramfs';
  print('Preparing assets in /tmp...');
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
      if (kernelBytes[i] == gzipMagic[0] && kernelBytes[i+1] == gzipMagic[1]) {
        gzipIdx = i;
        break;
      }
    }

    if (gzipIdx != -1 && gzipIdx > 0) {
      print('Detected EFI stub (PE32+) kernel. Extracting gzip payload...');
      final compressedBytes = kernelBytes.sublist(gzipIdx);
      final tmpGzPath = '$tmpKernelPath.gz';
      File(tmpGzPath).writeAsBytesSync(compressedBytes);

      // Decompress gzip payload using gunzip process
      final gunzipResult = Process.runSync('gunzip', ['-f', tmpGzPath]);
      // gunzip can return 1 on warnings (like trailing garbage), so we also check if the output file was created
      if (gunzipResult.exitCode != 0 && !File(tmpKernelPath).existsSync()) {
        print('Failed to decompress kernel payload: ${gunzipResult.stderr}');
        return;
      }
      print('Extracted and decompressed raw ARM64 kernel image successfully.');
    } else {
      print('Kernel is already a raw image or uncompressed. Copying directly...');
      File(kernelPath).copySync(tmpKernelPath);
    }

    // Copy initramfs directly
    File(initramfsPath).copySync(tmpInitramfsPath);

    // Apply permissions
    Process.runSync('chmod', ['644', tmpKernelPath, tmpInitramfsPath]);
  } catch (e) {
    print('Failed to prepare assets in /tmp: $e');
    return;
  }

  // Locate compiled helper binary produced by the build hook
  final helperBinary = '$currentDir/.dart_tool/avf_dart/avf_helper';

  if (!File(helperBinary).existsSync()) {
    print('Error: avf_helper binary not found at $helperBinary.');
    print('Please ensure build hooks have run by running "dart pub get" or "dart test".');
    return;
  }

  // 3. avf_helper プロセスを起動する
  print('\nLaunching VM...');
  final process = await Process.start(helperBinary, [tmpKernelPath, tmpInitramfsPath]);

  // プロセスの Stdout/Stderr を標準出力に転送
  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });

  // プロセスの終了を待つ
  final exitCode = await process.exitCode;
  print('\nHelper process exited with code $exitCode');

  // クリーンアップ
  try {
    if (File(tmpKernelPath).existsSync()) {
      File(tmpKernelPath).deleteSync();
    }
    if (File(tmpInitramfsPath).existsSync()) {
      File(tmpInitramfsPath).deleteSync();
    }
    print('Cleaned up temporary assets in /tmp.');
  } catch (e) {
    print('Cleanup failed: $e');
  }
}
