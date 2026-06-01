import 'dart:io';

import 'package:avf_dart/avf_dart.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Error: Missing VM name to delete.');
    print('Usage: dart run example/delete.dart <vm-name>');
    exit(1);
  }

  final name = args[0];
  try {
    await VirtualMachine.delete(name);
  } catch (e) {
    print('Error deleting VM: $e');
  }
}
