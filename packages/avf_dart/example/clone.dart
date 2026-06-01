import 'dart:io';

import 'package:avf_dart/avf_dart.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('Error: Missing arguments.');
    print(
        'Usage: dart run example/clone.dart <source-vm-name> <target-vm-name>');
    exit(1);
  }

  final source = args[0];
  final target = args[1];
  try {
    await VirtualMachine.clone(sourceName: source, targetName: target);
  } catch (e) {
    print('Error cloning VM: $e');
  }
}
