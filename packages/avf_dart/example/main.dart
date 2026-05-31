import 'dart:convert';
import 'dart:io';

import 'package:avf_dart/avf_dart.dart';

void main() async {
  print('=== Apple Virtualization Framework Linux Boot PoC (Wrapper) ===');

  // Resolve assets relative to this script's directory (works regardless of CWD)
  final scriptUri = Platform.script;
  final String scriptDir;
  if (scriptUri.scheme == 'file') {
    scriptDir = File(scriptUri.toFilePath()).parent.path;
  } else {
    // Fallback if run in a context where script is not a file URI
    final currentDir = Directory.current.absolute.path;
    scriptDir =
        currentDir.endsWith('/example') ? currentDir : '$currentDir/example';
  }

  final kernelPath = '$scriptDir/assets/vmlinuz';
  final initramfsPath = '$scriptDir/assets/initramfs';

  print('Kernel path: $kernelPath');
  print('Initramfs path: $initramfsPath');

  if (!File(kernelPath).existsSync() || !File(initramfsPath).existsSync()) {
    print('Error: Alpine Linux assets are missing. Download them first.');
    return;
  }

  // 3. avf_helper プロセスを起動する
  print('\nLaunching VM...');
  final Process process;
  try {
    process = await AppleVirtualization.boot(
      kernelPath: kernelPath,
      initramfsPath: initramfsPath,
    );
  } catch (e) {
    print('Failed to launch VM: $e');
    return;
  }

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
}
