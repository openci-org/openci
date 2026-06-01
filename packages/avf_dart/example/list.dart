import 'package:avf_dart/avf_dart.dart';

void main() async {
  print('Local Virtual Machines:');
  try {
    final list = await VirtualMachine.list();
    if (list.isEmpty) {
      print('  No local VMs found.');
    } else {
      print(
          '  ${"Name".padRight(20)} ${"Disk Size".padRight(24)} ${"Created"}');
      print('  ${"-" * 72}');
      for (final vm in list) {
        final sizeGb =
            (vm.diskSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
        final usedGb =
            (vm.diskSizeUsedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
        final sizeStr = '$usedGb GB / $sizeGb GB';
        print(
            '  ${vm.name.padRight(20)} ${sizeStr.padRight(24)} ${vm.created.toLocal()}');
      }
    }
  } catch (e) {
    print('Error listing VMs: $e');
  }
}
