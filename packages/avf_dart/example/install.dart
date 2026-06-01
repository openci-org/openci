import 'dart:io';

import 'package:avf_dart/avf_dart.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Error: Missing IPSW file path.');
    print('Usage: dart run example/install.dart <ipsw-path> [<vm-name>]');
    exit(1);
  }
  final ipswPath = args[0];
  final name = args.length > 1 ? args[1] : 'tahoe-base';

  print(
      'Starting macOS installation onto VM "$name" using IPSW "$ipswPath"...');
  try {
    await VirtualMachine.install(
      name: name,
      ipswPath: ipswPath,
      onProgress: (progress) {
        stdout.write(
            '\rInstalling macOS... ${(progress * 100.0).toStringAsFixed(2)}%');
      },
    );
    print('\nSuccess: macOS installation complete!');
  } catch (e) {
    print('\nError during installation: $e');
  }
}
